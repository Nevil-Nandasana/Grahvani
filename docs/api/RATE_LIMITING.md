# API Rate Limiting Policy

## Purpose
This document defines the rate limiting strategies applied across the Grahvani API to prevent abuse, control infrastructure costs, and enforce subscription tier entitlements.

## Scope
Applies to all HTTP endpoints served by the FastAPI application. Rate limiting is enforced via a Redis-backed sliding window.

---

## 1. Rate Limit Categories and Quotas

API routes are grouped into distinct capability buckets. Each bucket has separate quotas based on the user's subscription tier.

| Route / Capability Bucket | Free Tier Limit | Premium Tier Limit | Enforcement Window |
| :--- | :--- | :--- | :--- |
| **Authentication / Identity**<br>`POST /api/v1/auth/verify` | 10 req / min | 10 req / min | Fixed window (Redis) |
| **Chart Calculation**<br>`POST /api/v1/profiles/{id}/charts` | 5 req / min | 30 req / min | Sliding window (Redis) |
| **AI Chat Queries**<br>`POST /api/v1/chat/stream` | 3 questions / day | 60 questions / hour | Sliding window (Redis)<br>Reset at midnight UTC |
| **Billing Webhooks**<br>`POST /api/v1/webhooks/*` | N/A (Server IP) | N/A (Server IP) | 100 req / sec (WAF) |
| **Global API Fallback**<br>All other `GET` routes | 60 req / min | 120 req / min | Sliding window (Redis) |

---

## 2. Implementation: Redis Sliding Window

Rate limits are enforced using a sliding window algorithm implemented via a Redis Lua script to guarantee atomicity and accuracy.

```python
# app/core/rate_limit.py
import time
from fastapi import Request, HTTPException

# Redis Lua script for sliding window
SLIDING_WINDOW_SCRIPT = """
local key = KEYS[1]
local limit = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local now = tonumber(ARGV[3])
local clear_before = now - window

redis.call('ZREMRANGEBYSCORE', key, 0, clear_before)
local count = redis.call('ZCARD', key)
if count < limit then
    redis.call('ZADD', key, now, now)
    redis.call('EXPIRE', key, window)
    return {1, count + 1}
else
    return {0, count}
end
"""

async def check_rate_limit(request: Request, key_prefix: str, limit: int, window: int) -> int:
    """Returns remaining quota or raises HTTP 429."""
    redis = request.app.state.redis
    now = int(time.time())
    user_id = getattr(request.state, "user_id", request.client.host)
    key = f"rate_limit:{key_prefix}:{user_id}"
    
    script = redis.register_script(SLIDING_WINDOW_SCRIPT)
    allowed, current_count = await script(keys=[key], args=[limit, window, now])
    
    if not allowed:
        raise HTTPException(
            status_code=429, 
            detail="Rate limit exceeded. Please try again later."
        )
    return limit - current_count
```

---

## 3. HTTP Response Headers

Every rate-limited API response includes standard rate limit headers, allowing the Flutter client to proactively pause requests or inform the user.

```http
HTTP/1.1 200 OK
Content-Type: application/json
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 58
X-RateLimit-Reset: 1709251200
```

- `X-RateLimit-Limit`: The total quota for the current window.
- `X-RateLimit-Remaining`: The number of requests remaining in the current window.
- `X-RateLimit-Reset`: Unix timestamp when the window resets (or slides forward to free up capacity).

### 3.1 Rate Limit Exceeded Response (HTTP 429)

```json
{
  "error_code": "RATE_LIMIT_EXCEEDED",
  "message": "You have exceeded the limit of 3 AI questions per day.",
  "details": {
    "retry_after_seconds": 3600,
    "limit": 3,
    "window_type": "daily"
  }
}
```

---

## 4. WAF Network-Level Rate Limiting

In addition to application-level Redis limits, AWS Web Application Firewall (WAF) enforces a hard network limit to protect against volumetric DDoS attacks.

- **WAF Rule**: Block IP if requests > 1,000 per 5 minutes.
- **Action**: Returns HTTP 403 Forbidden at the CloudFront edge (never hits the FastAPI container).

---

## 5. Rationale

The sliding window algorithm (via Redis Sorted Sets) is chosen over a fixed window (simple `INCR`) because it prevents burst traffic at the edges of the window reset period. 

The AI chat limit (3/day for Free users) is strictly enforced as it directly correlates to LLM API variable costs. Chart calculation limits prevent CPU exhaustion on the Swiss Ephemeris engine.

---

## 6. Future Improvements

- **GraphQL Complexity Limiting**: If a GraphQL API is added in Phase 3, transition from request counting to query complexity scoring.
- **Client-Side Backoff**: Implement exponential backoff in the Flutter HTTP interceptor when receiving a 429 response.

---

## 7. Related Documents

- [billing/ENTITLEMENTS.md](../billing/ENTITLEMENTS.md) -- Specific logic for Free vs Premium limits
- [infrastructure/SECURITY.md](../infrastructure/SECURITY.md) -- AWS WAF configuration details
- [backend/ERROR_HANDLING.md](../backend/ERROR_HANDLING.md) -- Standard error response envelopes
