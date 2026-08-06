# API Request and Response Envelopes

## Purpose
This document defines the strict, unified JSON envelope structure used for all REST API requests and responses in Grahvani. It ensures consistent parsing, error handling, and metadata extraction by the Flutter client.

## Scope
Applies to all synchronous REST endpoints (GET, POST, PUT, DELETE, PATCH). Does not apply to the Server-Sent Events (SSE) streaming endpoint, which is documented separately in [STREAMING.md](STREAMING.md).

---

## 1. Success Response Envelope (HTTP 200 / 201)

Every successful API response MUST wrap its payload in the `data` field of a standard envelope.

### Schema Definition

```json
{
  "success": true,
  "data": { ... },       // The actual resource or collection (dict or array)
  "error": null,
  "meta": {
    "timestamp": "2026-08-04T13:30:00Z",
    "request_id": "req-948201",
    "pagination": { ... } // Optional: only present for list endpoints
  }
}
```

### Example: Creating a Profile (POST `/api/v1/profiles`)

**Request Body:**
```json
{
  "full_name": "Nevil Nandasana",
  "birth_date": "1998-10-24",
  "birth_time": "14:30:00",
  "latitude": 22.3072,
  "longitude": 73.1812,
  "timezone_id": "Asia/Kolkata"
}
```

**Response (HTTP 201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "e4b2d184-7a33-4f9e-a892-123456789abc",
    "full_name": "Nevil Nandasana",
    "birth_date": "1998-10-24",
    "birth_time": "14:30:00",
    "latitude": 22.3072,
    "longitude": 73.1812,
    "timezone_id": "Asia/Kolkata",
    "created_at": "2026-08-04T13:30:00Z"
  },
  "error": null,
  "meta": {
    "timestamp": "2026-08-04T13:30:00Z",
    "request_id": "req-5599a8b1"
  }
}
```

---

## 2. Error Response Envelope (HTTP 4xx / 5xx)

When an error occurs, `success` is false, `data` is null, and the `error` object is populated.

### Schema Definition

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "STRING_ENUM",
    "message": "Human-readable description",
    "details": { ... }   // Optional: field-level validation errors or context
  },
  "meta": {
    "timestamp": "2026-08-04T13:30:00Z",
    "request_id": "req-948201"
  }
}
```

### Example: Validation Error (HTTP 422 Unprocessable Entity)

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "The request payload contains invalid fields.",
    "details": {
      "latitude": "Value must be between -90 and 90."
    }
  },
  "meta": {
    "timestamp": "2026-08-04T13:35:12Z",
    "request_id": "req-99f83a22"
  }
}
```

### Example: Entitlement Blocked (HTTP 403 Forbidden)

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "ENTITLEMENT_REQUIRED",
    "message": "This feature requires a Premium subscription.",
    "details": {
      "required_capability": "chart:d10"
    }
  },
  "meta": {
    "timestamp": "2026-08-04T13:40:05Z",
    "request_id": "req-11a2b3c4"
  }
}
```

---

## 3. Pagination Envelope (GET Lists)

For endpoints returning a collection (e.g., `GET /api/v1/profiles`), `data` is an array and `meta.pagination` is populated.

```json
{
  "success": true,
  "data": [
    { "id": "profile-1", "full_name": "Nevil" },
    { "id": "profile-2", "full_name": "Riya" }
  ],
  "error": null,
  "meta": {
    "timestamp": "2026-08-04T14:00:00Z",
    "request_id": "req-77bc991a",
    "pagination": {
      "total_items": 12,
      "page": 1,
      "page_size": 10,
      "total_pages": 2,
      "has_next": true
    }
  }
}
```

---

## 4. FastAPI Implementation (BaseResponse)

To enforce this globally without developer boilerplate, we use a custom APIRoute class in FastAPI that automatically wraps all responses.

```python
# app/core/responses.py
from pydantic import BaseModel
from typing import Generic, TypeVar, Optional, Any

T = TypeVar("T")

class ErrorDetail(BaseModel):
    code: str
    message: str
    details: Optional[dict[str, Any]] = None

class MetaInfo(BaseModel):
    timestamp: str
    request_id: str
    pagination: Optional[dict[str, Any]] = None

class APIResponse(BaseModel, Generic[T]):
    success: bool
    data: Optional[T] = None
    error: Optional[ErrorDetail] = None
    meta: MetaInfo
```

---

## 5. Rationale

Using a unified envelope wrapper instead of raw JSON payloads guarantees that the Flutter client can use a single global interceptor to:
1. Parse the `request_id` for crashlytics logging.
2. Intercept `ENTITLEMENT_REQUIRED` errors to show the paywall globally.
3. Catch `TOKEN_EXPIRED` to trigger Firebase token refresh transparently.

---

## 6. Related Documents

- [backend/ERROR_HANDLING.md](../backend/ERROR_HANDLING.md) -- Exhaustive list of `error.code` enums
- [api/STREAMING.md](STREAMING.md) -- Deviations from this envelope for SSE streams
- [infrastructure/MONITORING.md](../infrastructure/MONITORING.md) -- Request ID middleware generation
