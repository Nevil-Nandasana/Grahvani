# API Design & Conventions Specification

## 1. Overview & Design Philosophy
The Grahvani REST API is the single communication bridge between the Flutter client and the backend system. It is designed with three goals: **predictability** (every route behaves consistently), **observability** (every request is traceable), and **safety** (no sensitive data ever leaks in error messages).

The API is versioned at `/api/v1/` from day one — not because we expect to break contracts soon, but to protect future flexibility without forcing a mobile app update.

---

## 2. RESTful Standards & URL Conventions

| Convention | Rule |
| :--- | :--- |
| **Base URL** | `https://api.grahvani.app/api/v1` |
| **Resource names** | Lowercase plural nouns: `/profiles`, `/charts`, `/sessions` |
| **No verbs in paths** | ❌ `/api/v1/calculateChart` → ✅ `POST /api/v1/charts` |
| **Nested resources** | Parent-child: `/api/v1/profiles/{profile_id}/charts` |
| **HTTP Verbs** | `GET` = read, `POST` = create, `PATCH` = partial update, `DELETE` = remove |
| **Response format** | Always JSON (`Content-Type: application/json`) |
| **Streaming endpoint** | `POST /api/v1/chat/stream` → `text/event-stream` |

---

## 3. Complete API Endpoint Reference

### Identity Module
| Method | Path | Auth | Tier | Description |
| :--- | :--- | :---: | :---: | :--- |
| `GET` | `/api/v1/users/me` | ✅ | Any | Get current user profile |
| `GET` | `/api/v1/users/me/export` | ✅ | Any | Export all personal data (DPDP) |
| `DELETE` | `/api/v1/users/me` | ✅ | Any | Schedule account deletion (30-day purge) |
| `GET` | `/api/v1/profiles` | ✅ | Any | List all birth profiles |
| `POST` | `/api/v1/profiles` | ✅ | Free: max 1, Premium: unlimited | Create a birth profile |
| `GET` | `/api/v1/profiles/{profile_id}` | ✅ | Any | Get a specific birth profile |
| `PATCH` | `/api/v1/profiles/{profile_id}` | ✅ | Any | Update profile details |
| `DELETE` | `/api/v1/profiles/{profile_id}` | ✅ | Any | Soft-delete a birth profile |

### Birth Chart Module
| Method | Path | Auth | Tier | Description |
| :--- | :--- | :---: | :---: | :--- |
| `POST` | `/api/v1/profiles/{profile_id}/charts/calculate` | ✅ | Any | Trigger chart calculation (async, returns 202) |
| `GET` | `/api/v1/profiles/{profile_id}/charts/status` | ✅ | Any | Poll calculation status: pending/complete/failed |
| `GET` | `/api/v1/profiles/{profile_id}/charts` | ✅ | Any | Get latest complete chart snapshot |
| `GET` | `/api/v1/profiles/{profile_id}/dashas` | ✅ | Free: Maha only, Premium: full | Get Vimshottari Dasha breakdown |

### AI Chat Module
| Method | Path | Auth | Tier | Description |
| :--- | :--- | :---: | :---: | :--- |
| `GET` | `/api/v1/chat/sessions` | ✅ | Any | List all chat sessions (paginated) |
| `POST` | `/api/v1/chat/sessions` | ✅ | Any | Create new chat session for a profile |
| `GET` | `/api/v1/chat/sessions/{session_id}/messages` | ✅ | Any | Get message history |
| `POST` | `/api/v1/chat/stream` | ✅ | Free: 3/day, Premium: 60/hr | Stream AI response (SSE) |

### Billing Module
| Method | Path | Auth | Tier | Description |
| :--- | :--- | :---: | :---: | :--- |
| `GET` | `/api/v1/billing/entitlements` | ✅ | Any | Get current tier and capabilities |
| `POST` | `/api/v1/billing/webhooks/google` | ❌ (HMAC) | — | Google Play RTDN webhook receiver |
| `POST` | `/api/v1/billing/webhooks/apple` | ❌ (JWS) | — | Apple IAP v2 notification receiver |
| `POST` | `/api/v1/billing/webhooks/razorpay` | ❌ (HMAC) | — | Razorpay webhook receiver |

### Admin Module (role=admin only)
| Method | Path | Auth | Role | Description |
| :--- | :--- | :---: | :---: | :--- |
| `POST` | `/api/v1/admin/documents` | ✅ | Admin | Upload classical text PDF for ingestion |
| `PATCH` | `/api/v1/admin/documents/{id}/approve` | ✅ | Admin | Approve staged document chunks for production |
| `GET` | `/api/v1/admin/prompt-templates` | ✅ | Admin | List all prompt template versions |
| `POST` | `/api/v1/admin/prompt-templates` | ✅ | Admin | Create a new prompt template draft |
| `PATCH` | `/api/v1/admin/prompt-templates/{id}/activate` | ✅ | Admin | Promote a template to active production |

---

## 4. Standard Response Envelope

**Success Response (2xx):**
```json
{
  "success": true,
  "data": {
    "profile_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "full_name": "Nevil Nandasana",
    "ascendant_sign": "Scorpio"
  },
  "meta": {
    "request_id": "req-7a4f91bb",
    "timestamp": "2026-08-04T14:00:00Z"
  }
}
```

**Error Response (4xx / 5xx) — RFC 7807 Problem Details:**
```json
{
  "success": false,
  "error": {
    "type": "https://grahvani.app/errors/validation-error",
    "title": "Validation Error",
    "status": 422,
    "detail": "birth_date must be between 1900-01-01 and 2100-12-31",
    "instance": "/api/v1/profiles"
  },
  "meta": {
    "request_id": "req-7a4f91bb",
    "timestamp": "2026-08-04T14:00:00Z"
  }
}
```

> [!IMPORTANT]
> Error responses NEVER include Python stack traces, internal table names, SQL errors, or any information that could help an attacker understand the system internals. All such details are logged internally to CloudWatch.

---

## 5. Pagination Convention

All list endpoints (`GET /api/v1/profiles`, `GET /api/v1/chat/sessions`, etc.) use **cursor-based pagination** for consistent performance at scale:

```json
{
  "success": true,
  "data": {
    "items": [...],
    "next_cursor": "MjAyNi0wOC0wNFQxNDowMDowMFo=",
    "has_more": true,
    "total_count": 47
  }
}
```

**Query Parameters**: `GET /api/v1/chat/sessions?limit=20&cursor=<next_cursor>`

---

## 6. SSE Streaming Contract (AI Chat)

For real-time AI answer streaming, the client opens an HTTP connection with `Accept: text/event-stream`. The stream produces a sequence of typed SSE events:

**Request:**
```http
POST /api/v1/chat/stream
Authorization: Bearer <firebase_jwt>
Content-Type: application/json
Accept: text/event-stream

{
  "session_id": "e3d4f5a6-...",
  "question": "What does Jupiter in the 5th house mean for me?"
}
```

**Response Stream (SSE events):**
```text
event: token
data: {"token": "Jupiter's"}

event: token
data: {"token": " placement"}

event: token
data: {"token": " in your 5th house is considered highly auspicious..."}

event: citation
data: {"citation_id": "8a9b2c3d-...", "label": "BPHS, Ch. 12, v. 4-8", "excerpt": "When Jupiter occupies the fifth..."}

event: done
data: {"status": "completed", "total_tokens": 287, "citations_count": 2}
```

**Error Event (policy block or rate limit during streaming):**
```text
event: error
data: {"code": "RATE_LIMIT_EXCEEDED", "message": "Daily question limit reached. Upgrade to Premium for unlimited questions."}
```

---

## 7. Rate Limiting Headers

All API responses include rate limiting metadata:
```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 47
X-RateLimit-Reset: 1722780000
Retry-After: 30  (only present when HTTP 429)
```

---

## 8. OpenAPI & Developer Documentation

FastAPI auto-generates OpenAPI 3.1 specification:
- **Swagger UI**: `GET /api/v1/docs` (interactive, for internal/testing use)
- **ReDoc**: `GET /api/v1/redoc` (read-only, for documentation)
- **OpenAPI JSON**: `GET /api/v1/openapi.json`

Every route handler must declare explicit `response_model`, `summary`, `description`, `status_code`, and `responses` (including documented 4xx error schemas) for the spec to be complete.
