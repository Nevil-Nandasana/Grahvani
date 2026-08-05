"""
Billing Module — Pydantic v2 Schemas (Request / Response)
"""
import uuid
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class SubscriptionTier(str, Enum):
    FREE = "free"
    PREMIUM = "premium"
    FAMILY = "family"
    PRO = "pro"


class SubscriptionProvider(str, Enum):
    RAZORPAY = "razorpay"
    GOOGLE_PLAY = "google_play"
    APPLE = "apple"


class SubscriptionStatus(str, Enum):
    ACTIVE = "active"
    CANCELED = "canceled"
    EXPIRED = "expired"
    PAUSED = "paused"


class SubscriptionResponse(BaseModel):
    """API response schema for user subscription state."""
    id: uuid.UUID
    user_id: uuid.UUID
    provider: SubscriptionProvider
    external_subscription_id: str | None
    status: SubscriptionStatus
    tier: SubscriptionTier
    expires_at: datetime | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class EntitlementsResponse(BaseModel):
    """API response schema for user entitlements."""
    tier: SubscriptionTier
    is_active: bool
    daily_queries_limit: int
    queries_remaining: int
    expires_at: datetime | None


class RazorpayWebhookPayload(BaseModel):
    """Razorpay webhook payload schema (subset of fields)."""
    event: str = Field(..., examples=["subscription.activated", "subscription.charged", "subscription.cancelled"])
    contains: list[str] = Field(default_factory=lambda: ["subscription", "customer", "payment"])
    payload: dict = Field(..., examples=[{
        "subscription": {
            "id": "sub_Ln7uFZ2eZ1W9gA",
            "entity": "subscription",
            "plan_id": "plan_Ln7uFZ2eZ1W9gA",
            "status": "active",
            "current_start": 1722864000,
            "current_end": 1725456000,
            "customer_id": "cust_Ln7uFZ2eZ1W9gA"
        },
        "customer": {
            "id": "cust_Ln7uFZ2eZ1W9gA",
            "entity": "customer",
            "email": "user@example.com",
            "notes": {"user_id": "123e4567-e89b-12d3-a456-426614174000"}
        }
    }])


class WebhookEventRequest(BaseModel):
    """Generic webhook event request schema."""
    provider: SubscriptionProvider
    event_type: str
    payload: dict
    signature: str | None = None
    signature_valid: bool = False


class WebhookEventResponse(BaseModel):
    """API response schema for webhook event processing."""
    id: uuid.UUID
    provider: SubscriptionProvider
    event_type: str
    external_id: str
    signature_valid: bool
    processed: bool
    error_message: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}