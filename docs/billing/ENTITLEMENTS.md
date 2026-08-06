# Unified Entitlement Engine Specification

## Purpose
This document specifies the server-side entitlement enforcement system -- the single authoritative source of truth for what a given user is allowed to do. It defines capability categories, the enforcement pattern, free tier limits, and the Redis-based rate limiting implementation.

## Scope
Applies to every API endpoint that gates functionality behind a subscription tier. The Flutter client may reflect entitlement state in the UI, but **all enforcement happens on the server**.

---

## 1. Design Principle: Server-Authoritative Entitlements

The client app (Flutter) is never trusted to determine whether a user has access to premium features. The server always re-verifies entitlement on every request.

**Why**: Mobile apps can be decompiled and patched. A client that bypasses the paywall screen can still be blocked server-side. All entitlement state lives in the `subscriptions` PostgreSQL table, not in the app.

---

## 2. Capability Registry

| Capability Key | Free Tier | Premium Tier | Description |
| :--- | :---: | :---: | :--- |
| `chart:d1` | Yes | Yes | View D1 Rasi birth chart |
| `chart:d9` | Yes | Yes | View D9 Navamsa chart |
| `chart:dasha_timeline` | Yes | Yes | View Vimshottari Maha Dasha |
| `chat:ai_query` | 3/day | 60/hour | AI grounded chat question |
| `chart:d10` | No | Yes | View D10 Dasamsa chart |
| `chart:d12` | No | Yes | View D12 Dwadasamsa chart |
| `chart:d60` | No | Yes | View D60 Shashtiamsa chart |
| `chart:antar_dasha` | No | Yes | View Antar/Pratyantar Dasha |
| `profile:unlimited` | No (max 1) | Yes | Create unlimited profiles |
| `export:pdf` | No | Yes | Download PDF chart export |
| `chat:priority_queue` | No | Yes | Priority SSE streaming |

---

## 3. Core Entitlement Check Implementation

```python
# app/modules/billing/entitlements.py
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from app.models import Subscription

FREE_TIER_CAPABILITIES = {
    "chart:d1",
    "chart:d9",
    "chart:dasha_timeline",
    "chat:ai_query",   # Rate-limited to 3/day via Redis
}

PREMIUM_TIER_CAPABILITIES = FREE_TIER_CAPABILITIES | {
    "chart:d10",
    "chart:d12",
    "chart:d60",
    "chart:antar_dasha",
    "profile:unlimited",
    "export:pdf",
    "chat:priority_queue",
}

async def check_entitlement(
    user_id: UUID,
    required_capability: str,
    session: AsyncSession,
) -> bool:
    """
    Returns True if the user has access to the required_capability.
    Called on every API request that gates a premium feature.
    """
    subscription = await session.get(Subscription, user_id)
    is_premium_active = (
        subscription is not None
        and subscription.status in ("active", "grace_period")
        and subscription.tier == "premium"
    )
    if is_premium_active:
        return required_capability in PREMIUM_TIER_CAPABILITIES
    else:
        return required_capability in FREE_TIER_CAPABILITIES


async def enforce_entitlement(
    user_id: UUID,
    required_capability: str,
    session: AsyncSession,
) -> None:
    """
    Raises EntitlementRequiredException if the user lacks access.
    Use as a dependency in FastAPI route handlers.
    """
    from app.core.exceptions import EntitlementRequiredException
    if not await check_entitlement(user_id, required_capability, session):
        raise EntitlementRequiredException(
            detail=f"This feature requires a Premium subscription. "
                   f"Required capability: '{required_capability}'."
        )
```

---

## 4. AI Chat Rate Limiting (Redis)

For `chat:ai_query`, a Redis sliding window tracks daily question counts per user:

```python
# app/modules/interpretation/rate_limiter.py
import redis.asyncio as aioredis
from datetime import datetime, timezone
from uuid import UUID

REDIS_KEY_PREFIX = "grahvani:chat_rate"

async def check_and_increment_chat_quota(
    user_id: UUID,
    tier: str,  # "free" or "premium"
    redis: aioredis.Redis,
) -> tuple[bool, int, int]:
    """
    Checks whether the user has chat quota remaining and increments the counter.

    Returns:
        (allowed: bool, current_count: int, daily_limit: int)
    """
    if tier == "premium":
        # Premium: 60 questions per hour sliding window
        window_key = f"{REDIS_KEY_PREFIX}:premium:{user_id}:{datetime.now(timezone.utc).strftime('%Y%m%d%H')}"
        limit = 60
        ttl_seconds = 3600
    else:
        # Free: 3 questions per day (resets at midnight IST)
        window_key = f"{REDIS_KEY_PREFIX}:free:{user_id}:{datetime.now(timezone.utc).strftime('%Y%m%d')}"
        limit = 3
        ttl_seconds = 86400

    pipe = redis.pipeline()
    pipe.incr(window_key)
    pipe.expire(window_key, ttl_seconds, nx=True)  # Set TTL only if key is new
    results = await pipe.execute()
    current_count = results[0]

    return current_count <= limit, current_count, limit
```

---

## 5. FastAPI Dependency Usage

```python
# app/modules/interpretation/router.py
from fastapi import APIRouter, Depends
from app.modules.billing.entitlements import enforce_entitlement

router = APIRouter()

@router.post("/api/v1/chat/stream")
async def stream_ai_response(
    request: ChatRequest,
    user_id: UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_db_session),
    redis: aioredis.Redis = Depends(get_redis),
    _: None = Depends(lambda: enforce_entitlement(user_id, "chat:ai_query", session)),
):
    """Entitlement enforcement is a FastAPI dependency -- no entitlement code in route handler."""
    ...
```

---

## 6. Grace Period Behaviour

When a subscription enters `grace_period` (payment failure, 7-day window):
- Premium capabilities remain fully accessible.
- A banner is displayed in the Flutter app: "Payment issue detected. Please update your payment method to continue Premium access."
- After 7 days in `grace_period`, the subscription transitions to `canceled` and entitlements revert to Free tier.

---

## 7. Rationale

Combining a capability registry (Python set) with a Redis rate limiter for time-windowed quotas gives the best of both worlds:
- Binary feature gates (PDF export, D10 charts) are instant database lookups.
- Usage quotas (3 AI questions/day) are Redis-based to avoid database write-per-question overhead.

---

## 8. Future Improvements

- **Enterprise/Teams Tier**: Add a third capability set for team accounts with shared profile pools.
- **Consumable Credits**: Allow one-time PDF export purchase without requiring Premium subscription.

---

## 9. Related Documents

- [SUBSCRIPTIONS.md](SUBSCRIPTIONS.md) -- Subscription lifecycle and state machine
- [billing/GOOGLE_PLAY.md](GOOGLE_PLAY.md) -- How Google Play events update the subscription table
- [billing/APP_STORE.md](APP_STORE.md) -- How Apple events update the subscription table
- [backend/ERROR_HANDLING.md](../backend/ERROR_HANDLING.md) -- ENTITLEMENT_REQUIRED error response format
