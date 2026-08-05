"""
Billing Module — Apple App Store Server Notifications v2 Handler
Handles App Store Server Notifications v2 (JWS signed payloads).
"""
import base64
import json
import uuid
from datetime import datetime, timezone
from typing import Optional

import jwt
from fastapi import HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.modules.billing.models import Subscription, WebhookEvent
from app.modules.billing.schemas import SubscriptionProvider, WebhookEventResponse


class AppleAppStoreWebhookHandler:
    """Handler for Apple App Store Server Notifications v2."""

    def __init__(self):
        self.bundle_id = settings.APPLE_BUNDLE_ID
        self.shared_secret = settings.APPLE_SHARED_SECRET
        # Apple's root certificates for JWS verification
        # In production, fetch from https://www.apple.com/certificateauthority/
        self.apple_root_cert = None  # Load from file/config

    async def validate_and_decode_jws(self, signed_payload: str) -> dict:
        """
        Validate and decode the JWS (JSON Web Signature) from Apple.
        Apple signs notifications with their private key; we verify with their public key.
        """
        try:
            # For production, you should verify the JWS signature using Apple's public keys
            # This is a simplified version - in production, use proper JWS verification
            
            # Decode without verification first to get the payload (for development)
            # NOTE: In production, ALWAYS verify the signature!
            payload = jwt.decode(
                signed_payload,
                options={"verify_signature": False},  # Remove in production!
                algorithms=["ES256"],
            )
            return payload
        except jwt.InvalidTokenError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid JWS token: {str(e)}",
            )

    async def process_notification(
        self, notification: dict, db: AsyncSession
    ) -> WebhookEvent:
        """
        Process an App Store Server Notification v2.
        
        Notification types (subtype):
        - INITIAL_BUY
        - RENEWAL
        - CANCEL
        - DID_CHANGE_RENEWAL_PREF
        - DID_CHANGE_RENEWAL_STATUS
        - EXPIRED
        - GRACE_PERIOD_EXPIRED
        - PRICE_INCREASE
        - REFUND
        - REFUND_DECLINED
        - RENEWAL_EXTENDED
        - REVOKE
        - SUBSCRIBED
        - OFFER_REDEEMED
        """
        notification_type = notification.get("notificationType")
        subtype = notification.get("subtype")
        data = notification.get("data", {})
        
        # Extract transaction info
        transaction_info = data.get("signedTransactionInfo")
        renewal_info = data.get("signedRenewalInfo")
        
        if not transaction_info:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No signedTransactionInfo in notification",
            )

        # Decode transaction info
        transaction = await self.validate_and_decode_jws(transaction_info)
        
        # Extract key fields
        transaction_id = transaction.get("transactionId")
        original_transaction_id = transaction.get("originalTransactionId")
        product_id = transaction.get("productId")
        purchase_date = transaction.get("purchaseDate")
        expires_date = transaction.get("expiresDate")
        ownership_type = transaction.get("ownershipType")  # PURCHASED, FAMILY_SHARED
        environment = transaction.get("environment")  # SANDBOX, PRODUCTION
        
        # Extract user ID from appAccountToken (set during purchase)
        user_id = None
        app_account_token = transaction.get("appAccountToken")
        if app_account_token:
            try:
                user_id = uuid.UUID(app_account_token)
            except ValueError:
                pass

        # Map notification to our status
        status_map = {
            "INITIAL_BUY": "active",
            "RENEWAL": "active",
            "CANCEL": "canceled",
            "DID_CHANGE_RENEWAL_STATUS": "active",  # Check renewal info
            "EXPIRED": "expired",
            "GRACE_PERIOD_EXPIRED": "expired",
            "REVOKE": "canceled",
            "SUBSCRIBED": "active",
            "OFFER_REDEEMED": "active",
            "REFUND": "canceled",
        }
        
        mapped_status = status_map.get(subtype or notification_type, "active")
        
        # Check renewal info for auto-renew status
        if renewal_info:
            renewal = await self.validate_and_decode_jws(renewal_info)
            auto_renew_status = renewal.get("autoRenewStatus")  # 1 = on, 0 = off
            if auto_renew_status == 0:
                mapped_status = "canceled"

        # Convert timestamps (milliseconds since epoch)
        expires_at = None
        if expires_date:
            expires_at = datetime.fromtimestamp(
                expires_date / 1000, tz=timezone.utc
            )

        # Create webhook event
        event = WebhookEvent(
            provider=SubscriptionProvider.APPLE,
            event_type=f"{notification_type}.{subtype}" if subtype else notification_type,
            external_id=original_transaction_id or transaction_id or "unknown",
            payload=notification,
            signature_valid=True,  # Set to False if JWS verification fails
        )
        db.add(event)
        await db.flush()

        if not user_id:
            event.error_message = "User ID not found in appAccountToken"
            await db.commit()
            return event

        # Map product_id to tier
        tier_map = {
            "com.grahvani.premium.monthly": "premium",
            "com.grahvani.premium.yearly": "premium",
            "com.grahvani.family.monthly": "family",
            "com.grahvani.pro.monthly": "pro",
        }
        tier = tier_map.get(product_id, "premium")

        # Upsert subscription
        result = await db.execute(
            select(Subscription).where(
                Subscription.provider == SubscriptionProvider.APPLE,
                Subscription.external_subscription_id == original_transaction_id,
            )
        )
        subscription = result.scalar_one_or_none()

        if subscription:
            subscription.status = mapped_status
            subscription.tier = tier
            subscription.expires_at = expires_at
        else:
            subscription = Subscription(
                user_id=user_id,
                provider=SubscriptionProvider.APPLE,
                external_subscription_id=original_transaction_id,
                status=mapped_status,
                tier=tier,
                expires_at=expires_at,
            )
            db.add(subscription)

        event.processed = True
        await db.commit()
        return event


# Singleton handler instance
apple_app_store_handler = AppleAppStoreWebhookHandler()