# Apple In-App Purchases Integration Specification

## Purpose
This document describes the technical integration of Apple's In-App Purchase (IAP) system for Grahvani's premium iOS subscription tier. It covers the App Store Server Notifications v2 webhook protocol, JWS payload decoding, supported notification types, and the entitlement state update flow.

## Scope
Applies to all iOS clients running Grahvani on iPhone and iPad. Does not apply to Android (see [GOOGLE_PLAY.md](GOOGLE_PLAY.md)) or web (see [RAZORPAY.md](RAZORPAY.md)).

---

## 1. App Store Server Notifications v2

Apple delivers real-time subscription lifecycle events to the backend via **App Store Server Notifications v2**, which uses signed **JSON Web Signatures (JWS)** for tamper-proof payload delivery.

Webhook endpoint: `POST /api/v1/billing/webhooks/apple`

### 1.1 JWS Payload Verification

Apple signs all notification payloads using a certificate chain rooted at Apple's Root CA. The backend must verify this chain before trusting any event:

```python
import jwt
import httpx
from jwt.algorithms import RSAAlgorithm

APPLE_ROOT_CA_URL = "https://appleid.apple.com/.well-known/apple-app-site-association"

async def verify_apple_jws(signed_payload: str) -> dict:
    """
    Decode and verify an Apple App Store Server Notification JWS payload.
    Returns the decoded notification payload dict on success.
    Raises ValueError on invalid signature or expired certificate.
    """
    # Decode header to extract kid (key ID)
    header = jwt.get_unverified_header(signed_payload)

    # Fetch Apple's public keys and find matching key by kid
    async with httpx.AsyncClient() as client:
        resp = await client.get("https://api.storekit-sandbox.itunes.apple.com/.well-known/apple-app-site-association")
        apple_keys = resp.json()["keys"]

    public_key = None
    for key in apple_keys:
        if key["kid"] == header["kid"]:
            public_key = RSAAlgorithm.from_jwk(key)
            break

    if not public_key:
        raise ValueError("No matching Apple public key found for kid")

    # Verify and decode
    payload = jwt.decode(
        signed_payload,
        public_key,
        algorithms=["RS256"],
        audience="com.grahvani.app",  # Must match your App Store bundle ID
    )
    return payload
```

---

### 1.2 Supported Notification Types

| `notificationType` | `subtype` | Action Required |
| :--- | :--- | :--- |
| `SUBSCRIBED` | `INITIAL_BUY` | Grant premium; set `tier='premium'`, `status='active'`, `current_period_end` |
| `DID_RENEW` | -- | Extend `current_period_end` for successful auto-renewal |
| `DID_FAIL_TO_RENEW` | `GRACE_PERIOD` | Set `status='grace_period'`; user retains premium access |
| `DID_FAIL_TO_RENEW` | -- | Set `status='grace_period'`; begin 7-day grace window |
| `EXPIRED` | `VOLUNTARY` | Set `status='canceled'`; trigger free-tier downgrade |
| `EXPIRED` | `BILLING_RETRY` | Set `status='canceled'`; payment retry window exhausted |
| `REVOKE` | -- | Set `status='canceled'` immediately (family sharing revocation) |
| `REFUND` | -- | Set `status='canceled'`, log refund event |

---

### 1.3 Webhook Handler Implementation

```python
from fastapi import APIRouter, Request, HTTPException
from app.modules.billing.service import BillingService

router = APIRouter()

@router.post("/api/v1/billing/webhooks/apple", status_code=200)
async def apple_webhook(request: Request, billing_service: BillingService):
    """
    Receives Apple App Store Server Notification v2 events.
    Returns HTTP 200 to acknowledge receipt (even if processing is deferred).
    Apple retries on any non-200 response with exponential backoff.
    """
    body = await request.body()
    signed_payload = (await request.json()).get("signedPayload")

    if not signed_payload:
        raise HTTPException(status_code=400, detail="Missing signedPayload")

    try:
        payload = await verify_apple_jws(signed_payload)
    except ValueError as e:
        # Log the failure but return 200 to prevent Apple retry storms
        # Security note: log the raw IP and headers for investigation
        return {"status": "signature_verification_failed"}

    # Idempotency check -- skip if already processed
    event_id = payload.get("notificationUUID")
    if await billing_service.is_webhook_processed(event_id):
        return {"status": "already_processed"}

    # Process the event
    await billing_service.process_apple_notification(payload)
    return {"status": "processed"}
```

---

## 2. Sandbox vs. Production Environment

| Environment | Notification URL Setting | Notes |
| :--- | :--- | :--- |
| **Sandbox** (TestFlight) | App Store Connect > Sandbox Notifications URL | Use staging backend endpoint |
| **Production** | App Store Connect > Production Notifications URL | Use production backend endpoint |

> **Important**: Always test the full notification cycle (purchase, renewal failure, grace period, expiry) in the sandbox environment before production submission. Apple's sandbox renewal periods are accelerated (1-month sub renews every 5 minutes).

---

## 3. Rationale

**Why not use RevenueCat?**  
This is an open decision (see [OPEN_DECISIONS.md](../OPEN_DECISIONS.md) OD-002). The current architecture builds direct IAP verification to avoid adding a third-party billing SaaS dependency and to maintain full control over subscription state in our own PostgreSQL database. If cross-platform parity testing proves too complex, RevenueCat will be re-evaluated in Phase 2.

---

## 4. Trade-offs

| Pro | Con |
| :--- | :--- |
| No additional third-party billing SDK dependency | Complex JWS key rotation logic needs maintenance |
| Full control over subscription state in our own DB | Apple sandbox environment has quirks requiring separate test procedures |
| Exactly matches our server-authoritative billing model | Must handle Apple's grace period timing nuances manually |

---

## 5. Related Documents

- [SUBSCRIPTIONS.md](SUBSCRIPTIONS.md) -- Full subscription state machine
- [ENTITLEMENTS.md](ENTITLEMENTS.md) -- How entitlement grants work after webhook receipt
- [GOOGLE_PLAY.md](GOOGLE_PLAY.md) -- Android equivalent
- [OPEN_DECISIONS.md](../OPEN_DECISIONS.md) OD-002 -- RevenueCat evaluation status
