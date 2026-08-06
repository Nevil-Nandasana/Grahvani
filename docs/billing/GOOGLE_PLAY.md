# Google Play Billing Integration Specification

## Purpose
This document specifies how Grahvani integrates with **Google Play Billing v7** for Android subscription purchases. It covers Real-Time Developer Notifications (RTDN) via Google Cloud Pub/Sub, purchase token verification, and entitlement state updates.

## Scope
Applies to all Android clients. Does not cover iOS (see [APP_STORE.md](APP_STORE.md)) or web (see [RAZORPAY.md](RAZORPAY.md)).

---

## 1. Real-Time Developer Notifications (RTDN) via Pub/Sub

Google Play delivers subscription lifecycle events to a **Google Cloud Pub/Sub topic** which forwards them to the Grahvani backend webhook endpoint.

Webhook endpoint: `POST /api/v1/billing/webhooks/google`

### 1.1 Pub/Sub Setup

1. In Google Cloud Console, create a Pub/Sub topic: `grahvani-play-rtdn-prod`.
2. In Google Play Console, configure the RTDN topic to point to this Pub/Sub topic.
3. Create a Pub/Sub push subscription targeting `POST https://api.grahvani.app/api/v1/billing/webhooks/google`.
4. The push subscription delivers messages with a **Google-signed JWT** in the `Authorization` header that must be verified.

### 1.2 JWT Signature Verification

```python
import httpx
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

GOOGLE_PUBSUB_AUDIENCE = "https://api.grahvani.app/api/v1/billing/webhooks/google"

async def verify_google_pubsub_jwt(authorization_header: str) -> dict:
    """
    Verifies the Google-signed JWT sent by Cloud Pub/Sub push subscriptions.
    Raises google.auth.exceptions.TransportError on failure.
    """
    bearer_token = authorization_header.replace("Bearer ", "")
    claims = id_token.verify_oauth2_token(
        bearer_token,
        google_requests.Request(),
        audience=GOOGLE_PUBSUB_AUDIENCE,
    )
    return claims
```

---

### 1.3 Purchase Token Verification

After receiving an RTDN notification, the backend must verify the `purchaseToken` via the **Google Play Developer API** before updating the subscription state:

```python
from googleapiclient.discovery import build
from google.oauth2 import service_account

SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
PACKAGE_NAME = "com.grahvani.app"

def verify_google_play_subscription(purchase_token: str, product_id: str) -> dict:
    """
    Calls Google Play Developer API purchases.subscriptionsv2.get to verify
    a subscription purchase token and retrieve its current state.
    """
    credentials = service_account.Credentials.from_service_account_info(
        settings.GOOGLE_SERVICE_ACCOUNT_JSON,
        scopes=SCOPES,
    )
    service = build("androidpublisher", "v3", credentials=credentials)
    result = service.purchases().subscriptionsv2().get(
        packageName=PACKAGE_NAME,
        token=purchase_token,
    ).execute()
    return result
```

---

### 1.4 Supported Notification Types

| `notificationType` | Meaning | Action Required |
| :---: | :--- | :--- |
| `1` | `SUBSCRIPTION_RECOVERED` | Payment retry succeeded; restore active status |
| `2` | `SUBSCRIPTION_RENEWED` | Auto-renewal succeeded; extend `current_period_end` |
| `3` | `SUBSCRIPTION_CANCELED` | User cancelled; active until period end |
| `4` | `SUBSCRIPTION_PURCHASED` | New purchase; grant premium, set `status='active'` |
| `5` | `SUBSCRIPTION_ON_HOLD` | Payment issue; set `status='grace_period'` |
| `6` | `SUBSCRIPTION_IN_GRACE_PERIOD` | Grace period started; user retains premium access |
| `7` | `SUBSCRIPTION_RESTARTED` | User re-subscribed after cancellation |
| `12` | `SUBSCRIPTION_REVOKED` | Access revoked; set `status='canceled'` immediately |
| `13` | `SUBSCRIPTION_EXPIRED` | Subscription fully expired; downgrade to free |

---

## 2. Webhook Handler

```python
import base64, json
from fastapi import APIRouter, Request, Header

router = APIRouter()

@router.post("/api/v1/billing/webhooks/google", status_code=200)
async def google_play_webhook(
    request: Request,
    authorization: str = Header(None),
    billing_service: BillingService = Depends(),
):
    """
    Receives Google Play RTDN via Cloud Pub/Sub push subscription.
    The Pub/Sub message wraps the actual DeveloperNotification in base64.
    Always returns 200 to prevent Pub/Sub retry loops.
    """
    # 1. Verify Pub/Sub JWT
    await verify_google_pubsub_jwt(authorization)

    # 2. Decode the base64-encoded Pub/Sub message
    body = await request.json()
    encoded_data = body["message"]["data"]
    notification = json.loads(base64.b64decode(encoded_data).decode("utf-8"))

    # 3. Extract subscription notification
    sub_notification = notification.get("subscriptionNotification")
    if not sub_notification:
        return {"status": "not_a_subscription_event"}  # e.g., one-time purchases

    # 4. Idempotency check
    purchase_token = sub_notification["purchaseToken"]
    if await billing_service.is_webhook_processed(purchase_token):
        return {"status": "already_processed"}

    # 5. Verify token with Google Play API and update entitlements
    verified = verify_google_play_subscription(
        purchase_token=purchase_token,
        product_id=sub_notification["subscriptionId"],
    )
    await billing_service.process_google_play_notification(
        purchase_token=purchase_token,
        notification_type=sub_notification["notificationType"],
        verified_subscription=verified,
    )
    return {"status": "processed"}
```

---

## 3. Rationale

Google Play's RTDN system is the authoritative source of subscription truth for Android. Relying solely on client-side purchase receipts is insecure -- a compromised device could replay purchase tokens. Server-side verification via `subscriptionsv2.get` ensures that only genuine, unexpired subscriptions grant premium access.

---

## 4. Trade-offs

| Pro | Con |
| :--- | :--- |
| Server-authoritative billing prevents client-side bypass | Requires a Google service account JSON credential in AWS Secrets Manager |
| RTDN provides near-real-time subscription state changes | Pub/Sub message delivery is asynchronous; brief delay possible on renewal |
| No third-party billing SDK dependency | Developer API quota limits (600 requests/min) must be monitored |

---

## 5. Related Documents

- [SUBSCRIPTIONS.md](SUBSCRIPTIONS.md) -- Subscription lifecycle state machine
- [ENTITLEMENTS.md](ENTITLEMENTS.md) -- Server-side entitlement enforcement
- [APP_STORE.md](APP_STORE.md) -- iOS Apple IAP equivalent
- [OPEN_DECISIONS.md](../OPEN_DECISIONS.md) OD-002 -- RevenueCat evaluation status
