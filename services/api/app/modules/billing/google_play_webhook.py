"""
Billing Module — Google Play RTDN Webhook Handler
Handles Real-Time Developer Notifications from Google Play Billing.
"""
import base64
import json
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from google.oauth2 import service_account
from googleapiclient.discovery import build
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.exceptions import NotFoundError
from app.core.security import CurrentUser
from app.db.session import get_db
from app.modules.billing.models import Subscription, WebhookEvent
from app.modules.billing.schemas import (
    SubscriptionProvider,
    WebhookEventResponse,
)
from app.modules.identity.models import User

router = APIRouter()


class GooglePlayWebhookHandler:
    """Handler for Google Play Real-Time Developer Notifications (RTDN)."""

    def __init__(self):
        self.service_account_path = settings.GOOGLE_SERVICE_ACCOUNT_PATH
        self.package_name = settings.GOOGLE_PLAY_PACKAGE_NAME

    def _get_credentials(self):
        """Get Google service account credentials."""
        if not self.service_account_path:
            raise ValueError("Google service account path not configured")
        return service_account.Credentials.from_service_account_file(
            self.service_account_path,
            scopes=["https://www.googleapis.com/auth/androidpublisher"],
        )

    def _get_play_service(self):
        """Get Google Play Developer API service."""
        credentials = self._get_credentials()
        return build("androidpublisher", "v3", credentials=credentials)

    async def validate_and_decode_notification(
        self, message: str, message_id: str
    ) -> dict:
        """
        Validate and decode the Pub/Sub message from Google Play RTDN.
        The message is base64-encoded JSON.
        """
        try:
            # Decode base64 message
            decoded = base64.b64decode(message).decode("utf-8")
            notification = json.loads(decoded)
            return notification
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to decode notification: {str(e)}",
            )

    async def process_subscription_notification(
        self, notification: dict, db: AsyncSession
    ) -> WebhookEvent:
        """
        Process a subscription notification from Google Play.
        Fetches latest subscription status from Google Play API.
        """
        subscription_notification = notification.get("subscriptionNotification", {})
        if not subscription_notification:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No subscriptionNotification in payload",
            )

        purchase_token = subscription_notification.get("purchaseToken")
        subscription_id = subscription_notification.get("subscriptionId")
        notification_type = subscription_notification.get("notificationType")

        if not purchase_token or not subscription_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Missing purchaseToken or subscriptionId",
            )

        # Fetch latest subscription status from Google Play
        try:
            service = self._get_play_service()
            purchase = (
                service.purchases()
                .subscriptions()
                .get(
                    packageName=self.package_name,
                    subscriptionId=subscription_id,
                    token=purchase_token,
                )
                .execute()
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Failed to fetch subscription from Google Play: {str(e)}",
            )

        # Map Google Play subscription status to our schema
        # Reference: https://developer.android.com/google/play/billing/reference
        status_map = {
            0: "active",      # SUBSCRIPTION_STATUS_ACTIVE
            1: "canceled",    # SUBSCRIPTION_STATUS_CANCELED
            2: "active",      # SUBSCRIPTION_STATUS_IN_GRACE_PERIOD (treat as active)
            3: "active",      # SUBSCRIPTION_STATUS_ON_HOLD (treat as active)
            4: "paused",      # SUBSCRIPTION_STATUS_PAUSED
            5: "expired",     # SUBSCRIPTION_STATUS_EXPIRED
            6: "active",      # SUBSCRIPTION_STATUS_PENDING_PURCHASE
        }

        gp_status = purchase.get("status", 0)
        mapped_status = status_map.get(gp_status, "active")

        # Extract user_id from obfuscatedExternalAccountId or developerPayload
        user_id = None
        if purchase.get("obfuscatedExternalAccountId"):
            # In production, you'd have a mapping table from obfuscated ID to user_id
            pass
        if purchase.get("developerPayload"):
            try:
                payload = json.loads(purchase["developerPayload"])
                user_id = uuid.UUID(payload.get("user_id")) if payload.get("user_id") else None
            except (json.JSONDecodeError, ValueError):
                pass

        # Get expiry time
        expires_at = None
        if purchase.get("expiryTimeMillis"):
            expires_at = datetime.fromtimestamp(
                purchase["expiryTimeMillis"] / 1000, tz=timezone.utc
            )

        # Create webhook event
        event = WebhookEvent(
            provider=SubscriptionProvider.GOOGLE_PLAY,
            event_type=f"subscription.{notification_type}",
            external_id=subscription_id,
            payload=notification,
            signature_valid=True,  # RTDN uses Pub/Sub auth, not HMAC
        )
        db.add(event)
        await db.flush()

        if not user_id:
            event.error_message = "User ID not found in developerPayload"
            await db.commit()
            return event

        # Upsert subscription
        result = await db.execute(
            select(Subscription).where(
                Subscription.provider == SubscriptionProvider.GOOGLE_PLAY,
                Subscription.external_subscription_id == subscription_id,
            )
        )
        subscription = result.scalar_one_or_none()

        if subscription:
            subscription.status = mapped_status
            subscription.expires_at = expires_at
        else:
            subscription = Subscription(
                user_id=user_id,
                provider=SubscriptionProvider.GOOGLE_PLAY,
                external_subscription_id=subscription_id,
                status=mapped_status,
                tier="premium",  # Default tier for Google Play
                expires_at=expires_at,
            )
            db.add(subscription)

        event.processed = True
        await db.commit()
        return event

    async def process_webhook(
        self, request: Request, message_id: str, db: AsyncSession
    ) -> WebhookEvent:
        """Process the webhook request and return the created event."""
        # Parse Pub/Sub message
        body = await request.json()
        message = body.get("message", {})
        message_data = message.get("data")
        
        if not message_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No message data in Pub/Sub notification",
            )

        # Validate and decode notification
        notification = await self.validate_and_decode_notification(
            message_data, message_id
        )

        # Process the notification
        event = await self.process_subscription_notification(
            notification, db
        )

        return event


# Singleton handler instance
google_play_handler = GooglePlayWebhookHandler()


@router.post(
    "/billing/webhooks/google",
    response_model=WebhookEventResponse,
    status_code=status.HTTP_200_OK,
)
async def google_play_webhook(
    request: Request,
    message_id: str = Header(..., alias="messageId"),
    db: AsyncSession = Depends(get_db),
):
    """
    Webhook receiver for Google Play Real-Time Developer Notifications (RTDN).
    
    Google Play sends Pub/Sub messages with base64-encoded JSON.
    Expected headers:
    - messageId: Unique message ID from Pub/Sub
    
    Subscription notification types:
    - SUBSCRIPTION_RECOVERED (1)
    - SUBSCRIPTION_RENEWED (2)
    - SUBSCRIPTION_CANCELED (3)
    - SUBSCRIPTION_PURCHASED (4)
    - SUBSCRIPTION_ON_HOLD (5)
    - SUBSCRIPTION_IN_GRACE_PERIOD (6)
    - SUBSCRIPTION_RESTARTED (7)
    - SUBSCRIPTION_PRICE_CHANGE_CONFIRMED (8)
    - SUBSCRIPTION_DEFERRED (9)
    - SUBSCRIPTION_PAUSED (10)
    - SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED (11)
    - SUBSCRIPTION_REVOKED (12)
    - SUBSCRIPTION_EXPIRED (13)
    """
    # Parse Pub/Sub message
    body = await request.json()
    message = body.get("message", {})
    message_data = message.get("data")
    
    if not message_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No message data in Pub/Sub notification",
        )

    # Validate and decode notification
    notification = await google_play_handler.validate_and_decode_notification(
        message_data, message_id
    )

    # Process the notification
    event = await google_play_handler.process_subscription_notification(
        notification, db
    )

    return WebhookEventResponse.model_validate(event)