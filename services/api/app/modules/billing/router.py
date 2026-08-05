"""
Billing Module — API Router
Routes: /billing
"""
import hashlib
import hmac
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.exceptions import NotFoundError
from app.core.security import CurrentUser
from app.db.session import get_db
from app.modules.billing.models import Subscription, WebhookEvent
from app.modules.billing.schemas import (
    EntitlementsResponse,
    RazorpayWebhookPayload,
    SubscriptionProvider,
    SubscriptionResponse,
    WebhookEventResponse,
)
from app.modules.billing.google_play_webhook import google_play_handler
from app.modules.billing.apple_webhook import apple_app_store_handler
from app.modules.identity.models import User

router = APIRouter()


@router.get(
    "/billing/entitlements",
    response_model=EntitlementsResponse,
    status_code=status.HTTP_200_OK,
)
async def get_entitlements(
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve current user entitlement state, subscription tier,
    and daily remaining AI question quota.
    """
    firebase_uid = current_user.get("uid")
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundError("User")

    # Get active subscription (if any)
    result = await db.execute(
        select(Subscription)
        .where(
            Subscription.user_id == user.id,
            Subscription.status == "active",
        )
        .order_by(Subscription.created_at.desc())
        .limit(1)
    )
    subscription = result.scalar_one_or_none()

    # Default to free tier if no active subscription
    tier = subscription.tier if subscription else "free"
    expires_at = subscription.expires_at if subscription else None
    is_active = subscription is not None and (
        expires_at is None or expires_at > datetime.now(timezone.utc)
    )

    # Daily query limits by tier
    daily_limits = {
        "free": 3,
        "premium": 100,
        "family": 500,
        "pro": 1000,
    }
    queries_remaining = daily_limits.get(tier, 3)

    return EntitlementsResponse(
        tier=tier,
        is_active=is_active,
        daily_queries_limit=daily_limits[tier],
        queries_remaining=queries_remaining,
        expires_at=expires_at,
    )


@router.post(
    "/billing/webhooks/razorpay",
    response_model=WebhookEventResponse,
    status_code=status.HTTP_200_OK,
)
async def razorpay_webhook(
    request: Request,
    x_razorpay_signature: str = Header(...),
    db: AsyncSession = Depends(get_db),
):
    """
    Webhook receiver for Razorpay subscription events.
    Validates HMAC signature and updates subscription state.
    
    Supported events:
    - subscription.activated
    - subscription.charged
    - subscription.cancelled
    - subscription.paused
    - subscription.resumed
    - subscription.completed
    """
    # Read raw payload
    payload = await request.body()
    payload_str = payload.decode("utf-8")

    # Validate HMAC signature
    secret = settings.RAZORPAY_WEBHOOK_SECRET.encode("utf-8")
    expected_signature = hmac.new(
        secret, payload, hashlib.sha256
    ).hexdigest()

    signature_valid = hmac.compare_digest(expected_signature, x_razorpay_signature)

    # Parse payload
    try:
        data = RazorpayWebhookPayload.model_validate_json(payload_str)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid payload: {str(e)}",
        )

    # Extract user_id from customer notes
    user_id = None
    if data.payload.get("customer", {}).get("notes", {}).get("user_id"):
        try:
            user_id = uuid.UUID(data.payload["customer"]["notes"]["user_id"])
        except (ValueError, KeyError):
            pass

    # Create webhook event audit log
    event = WebhookEvent(
        provider=SubscriptionProvider.RAZORPAY,
        event_type=data.event,
        external_id=data.payload.get("subscription", {}).get("id", "unknown"),
        payload=data.payload,
        signature_valid=signature_valid,
    )
    db.add(event)
    await db.flush()

    if not signature_valid:
        event.error_message = "HMAC signature validation failed"
        await db.commit()
        return WebhookEventResponse.model_validate(event)

    if not user_id:
        event.error_message = "User ID not found in customer notes"
        await db.commit()
        return WebhookEventResponse.model_validate(event)

    # Process subscription events
    subscription_id = data.payload.get("subscription", {}).get("id")
    status = data.payload.get("subscription", {}).get("status")
    plan_id = data.payload.get("subscription", {}).get("plan_id")
    current_start = data.payload.get("subscription", {}).get("current_start")
    current_end = data.payload.get("subscription", {}).get("current_end")

    # Map Razorpay status to our schema
    status_map = {
        "active": "active",
        "completed": "expired",
        "cancelled": "canceled",
        "paused": "paused",
        "resumed": "active",
    }
    mapped_status = status_map.get(status, "active")

    # Map Razorpay plan_id to our tier
    tier_map = {
        "plan_Ln7uFZ2eZ1W9gA": "premium",  # Example: replace with actual plan IDs
        "plan_Family": "family",
        "plan_Pro": "pro",
    }
    tier = tier_map.get(plan_id, "premium")

    # Convert timestamps
    expires_at = None
    if current_end:
        expires_at = datetime.fromtimestamp(current_end, tz=timezone.utc)

    # Upsert subscription record
    result = await db.execute(
        select(Subscription)
        .where(
            Subscription.provider == SubscriptionProvider.RAZORPAY,
            Subscription.external_subscription_id == subscription_id,
        )
    )
    subscription = result.scalar_one_or_none()

    if subscription:
        # Update existing subscription
        subscription.status = mapped_status
        subscription.tier = tier
        subscription.expires_at = expires_at
    else:
        # Create new subscription
        subscription = Subscription(
            user_id=user_id,
            provider=SubscriptionProvider.RAZORPAY,
            external_subscription_id=subscription_id,
            status=mapped_status,
            tier=tier,
            expires_at=expires_at,
        )
        db.add(subscription)

    event.processed = True
    await db.commit()

    return WebhookEventResponse.model_validate(event)


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
    return await google_play_handler.process_webhook(request, message_id, db)


@router.post(
    "/billing/webhooks/apple",
    response_model=WebhookEventResponse,
    status_code=status.HTTP_200_OK,
)
async def apple_store_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """
    Webhook receiver for Apple App Store Server Notifications v2.
    
    Apple sends JWS (JSON Web Signature) signed payloads.
    The payload contains signedTransactionInfo and signedRenewalInfo.
    
    Notification types:
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
    payload = await request.json()
    signed_payload = payload.get("signedPayload")
    
    if not signed_payload:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No signedPayload in Apple notification",
        )
    
    event = await apple_app_store_handler.process_notification(
        {"signedPayload": signed_payload}, db
    )
    
    return WebhookEventResponse.model_validate(event)


@router.get(
    "/billing/subscriptions",
    response_model=list[SubscriptionResponse],
    status_code=status.HTTP_200_OK,
)
async def list_subscriptions(
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """List all subscriptions for the authenticated user."""
    firebase_uid = current_user.get("uid")
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundError("User")

    result = await db.execute(
        select(Subscription)
        .where(Subscription.user_id == user.id)
        .order_by(Subscription.created_at.desc())
    )
    subscriptions = result.scalars().all()

    return [SubscriptionResponse.model_validate(sub) for sub in subscriptions]