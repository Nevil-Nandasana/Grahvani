# Error Handling & Problem Details Specification

## 1. Design Philosophy
Error handling in Grahvani follows two guiding principles:
1. **Client-Actionable**: Every error response tells the client what went wrong and how to recover (if possible).
2. **Leak-Nothing**: Internal details — stack traces, SQL errors, table names, library versions — are logged internally but never exposed to the API response body.

---

## 2. Error Response Standard: RFC 7807 Problem Details

All error responses from the Grahvani API conform to the **RFC 7807 Problem Details** standard. This provides a machine-parseable structure that Flutter clients can reliably detect and handle:

```json
{
  "type": "https://api.grahvani.app/errors/EPHEMERIS_INVALID_TIME",
  "title": "Invalid Birth Time Provided",
  "status": 422,
  "detail": "The specified birth time '25:61:00' is not a valid 24-hour timestamp. Please use HH:MM format.",
  "instance": "/api/v1/profiles/9b1d.../charts/calculate",
  "error_code": "EPHEMERIS_INVALID_TIME",
  "meta": {
    "request_id": "req-7a4f91bb",
    "timestamp": "2026-08-04T14:00:00Z"
  }
}
```

**Field Definitions:**
| Field | Type | Purpose |
| :--- | :--- | :--- |
| `type` | URI | Stable, unique identifier for this error type (human-readable docs URL) |
| `title` | string | Short, human-readable summary (consistent for the same `type`) |
| `status` | int | HTTP status code repeated inside the body |
| `detail` | string | Specific, actionable description for this occurrence |
| `instance` | string | The URL path that generated this error |
| `error_code` | string | Machine-parseable code for Flutter to handle programmatically |

---

## 3. Error Code Registry

| `error_code` | HTTP Status | Cause | Client Action |
| :--- | :---: | :--- | :--- |
| `UNAUTHORIZED` | 401 | Missing or expired Firebase JWT | Re-authenticate, get a new token |
| `FORBIDDEN` | 403 | Valid auth but not permitted for this resource | Display "Access denied" to user |
| `PROFILE_NOT_FOUND` | 404 | `profile_id` doesn't exist or is soft-deleted | Prompt user to create a new profile |
| `CHART_CALCULATION_FAILED` | 422 | Invalid birth coordinates or time format | Prompt user to correct birth details |
| `EPHEMERIS_INVALID_TIME` | 422 | Invalid HH:MM birth time | Show time picker with validation |
| `RATE_LIMIT_EXCEEDED` | 429 | User exceeded API rate limit | Show `Retry-After` seconds to user, offer upgrade |
| `AI_INSUFFICIENT_SOURCES` | 422 | RAG found no relevant chunks above confidence threshold | Display "I don't have sources for this question" |
| `AI_POLICY_VIOLATION` | 422 | Question triggered guardrail (medical/legal/financial) | Display appropriate policy disclaimer |
| `ENTITLEMENT_REQUIRED` | 403 | Feature requires premium subscription | Trigger paywall sheet |
| `INTERNAL_SERVER_ERROR` | 500 | Unhandled server-side exception | Display generic error, include `request_id` for support |

---

## 4. FastAPI Exception Hierarchy

```python
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from datetime import datetime, timezone

class GrahvaniException(Exception):
    """Base exception for all business logic errors."""
    status_code: int = 500
    error_code: str = "INTERNAL_SERVER_ERROR"

    def __init__(self, detail: str, error_code: str | None = None):
        self.detail = detail
        if error_code:
            self.error_code = error_code

class ProfileNotFoundException(GrahvaniException):
    status_code = 404
    error_code = "PROFILE_NOT_FOUND"

class EntitlementRequiredException(GrahvaniException):
    status_code = 403
    error_code = "ENTITLEMENT_REQUIRED"

class RateLimitExceededException(GrahvaniException):
    status_code = 429
    error_code = "RATE_LIMIT_EXCEEDED"

class AIInsufficientSourcesException(GrahvaniException):
    status_code = 422
    error_code = "AI_INSUFFICIENT_SOURCES"

class AIPolicyViolationException(GrahvaniException):
    status_code = 422
    error_code = "AI_POLICY_VIOLATION"


# --- Global exception handler registered in app.main ---

async def grahvani_exception_handler(request: Request, exc: GrahvaniException) -> JSONResponse:
    """Converts all GrahvaniExceptions to RFC 7807 JSON responses."""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "type": f"https://api.grahvani.app/errors/{exc.error_code}",
            "title": exc.error_code.replace("_", " ").title(),
            "status": exc.status_code,
            "detail": exc.detail,
            "instance": str(request.url.path),
            "error_code": exc.error_code,
            "meta": {
                "request_id": request.state.request_id,  # set by RequestIDMiddleware
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        },
    )

async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Catch-all for unexpected exceptions — logs traceback internally, returns generic 500."""
    import traceback
    import logging
    logger = logging.getLogger(__name__)
    logger.error(
        "Unhandled exception",
        extra={
            "request_id": request.state.request_id,
            "path": request.url.path,
            "traceback": traceback.format_exc(),  # Only in CloudWatch, never in response
        }
    )
    return JSONResponse(
        status_code=500,
        content={
            "type": "https://api.grahvani.app/errors/INTERNAL_SERVER_ERROR",
            "title": "Internal Server Error",
            "status": 500,
            "detail": "An unexpected error occurred. Please contact support if the issue persists.",
            "instance": str(request.url.path),
            "error_code": "INTERNAL_SERVER_ERROR",
            "meta": {
                "request_id": request.state.request_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        },
    )
```

---

## 5. Pydantic Validation Error Handler

FastAPI's built-in `RequestValidationError` is intercepted and reformatted to match the RFC 7807 envelope:

```python
from fastapi.exceptions import RequestValidationError

async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """Maps Pydantic validation failures to RFC 7807 format with field-level detail."""
    field_errors = [
        f"Field '{'.'.join(str(loc) for loc in e['loc'])}': {e['msg']}"
        for e in exc.errors()
    ]
    return JSONResponse(
        status_code=422,
        content={
            "type": "https://api.grahvani.app/errors/VALIDATION_ERROR",
            "title": "Validation Error",
            "status": 422,
            "detail": "; ".join(field_errors),
            "instance": str(request.url.path),
            "error_code": "VALIDATION_ERROR",
            "meta": {
                "request_id": request.state.request_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        },
    )
```

---

## 6. Flutter Client Error Handling Pattern

The Flutter app uses a unified API interceptor (via Dio) to parse all error responses and route them to the appropriate UX state:

```dart
// lib/core/network/api_error_interceptor.dart
class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final body = err.response?.data as Map<String, dynamic>?;
    final errorCode = body?['error_code'] as String? ?? 'UNKNOWN';

    switch (errorCode) {
      case 'UNAUTHORIZED':
        // Trigger re-authentication flow
        ref.read(authProvider.notifier).signOut();
      case 'ENTITLEMENT_REQUIRED':
        // Show paywall bottom sheet
        ref.read(paywallProvider.notifier).show();
      case 'RATE_LIMIT_EXCEEDED':
        final retryAfter = err.response?.headers.value('Retry-After') ?? '60';
        // Show countdown to user
      default:
        // Show user-friendly toast with error detail
        final detail = body?['detail'] ?? 'Something went wrong. Please try again.';
        showErrorSnackbar(detail);
    }
    handler.next(err);
  }
}
```
