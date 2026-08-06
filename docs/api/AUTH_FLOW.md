# Authentication and Identity Flow Specification

## Purpose
This document details the authentication mechanism for the Grahvani API. It explains how Firebase Auth is integrated, the anatomy of the required HTTP headers, the server-side verification process, and the handling of token expiration.

## Scope
Applies to all HTTP and SSE routes in the FastAPI backend, except for explicitly unauthenticated routes (e.g., `/api/v1/health`, webhook endpoints).

---

## 1. Architecture: Firebase Auth + FastAPI

Grahvani delegates all credential management (passwords, OTPs, OAuth flows) to **Firebase Authentication**. The FastAPI backend never sees or stores passwords. It only verifies cryptographically signed JSON Web Tokens (JWTs) issued by Google.

```mermaid
sequenceDiagram
    participant User
    participant FlutterApp
    participant Firebase
    participant FastAPI_Backend
    participant Database
    
    User->>FlutterApp: Sign in with Google / Apple
    FlutterApp->>Firebase: Authenticate credential
    Firebase-->>FlutterApp: Returns Firebase ID Token (JWT)
    FlutterApp->>FastAPI_Backend: POST /api/v1/auth/verify (Bearer Token)
    FastAPI_Backend->>FastAPI_Backend: Verify JWT signature via Firebase Admin SDK
    FastAPI_Backend->>Database: Upsert User record (UID mapped to UUID)
    Database-->>FastAPI_Backend: Return internal User UUID
    FastAPI_Backend-->>FlutterApp: 200 OK + internal profile IDs
    
    Note over FlutterApp,FastAPI_Backend: Subsequent API Calls
    FlutterApp->>FastAPI_Backend: GET /api/v1/profiles (Bearer Token)
    FastAPI_Backend->>FastAPI_Backend: JWT Middleware verifies token
    FastAPI_Backend-->>FlutterApp: 200 OK + Data
```

---

## 2. HTTP Header Contract

All protected endpoints require the Firebase ID Token to be sent in the standard HTTP `Authorization` header:

```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...
```

### 2.1 Token Verification Failures
If the header is missing, malformed, or the token is expired/invalid, the backend returns an RFC 7807 compliant HTTP 401 response:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Firebase ID Token is expired or invalid."
  },
  "meta": {
    "timestamp": "2026-08-04T13:30:00Z",
    "request_id": "req-948201"
  }
}
```

---

## 3. Server-Side Verification (FastAPI Dependency)

The backend uses a FastAPI dependency to verify the token on every request. This ensures that no route can accidentally bypass authentication.

```python
# app/core/security.py
import firebase_admin
from firebase_admin import auth
from fastapi import Request, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from uuid import UUID

security = HTTPBearer()

async def get_current_user_id(
    request: Request, 
    credentials: HTTPAuthorizationCredentials = Security(security)
) -> UUID:
    """
    Verifies the Firebase JWT and returns the internal Grahvani user UUID.
    Caches the verification result in request.state to prevent duplicate checks.
    """
    if hasattr(request.state, "user_id"):
        return request.state.user_id

    token = credentials.credentials
    try:
        # Verify signature, expiration, and audience
        decoded_token = auth.verify_id_token(token, check_revoked=True)
        firebase_uid = decoded_token['uid']
        
        # Look up internal UUID (cached in Redis for performance)
        internal_uuid = await resolve_internal_uuid(firebase_uid, request.app.state.db)
        
        request.state.user_id = internal_uuid
        return internal_uuid
        
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=401, 
            detail={"error_code": "TOKEN_EXPIRED", "message": "Token expired."}
        )
    except Exception as e:
        raise HTTPException(
            status_code=401, 
            detail={"error_code": "UNAUTHORIZED", "message": "Invalid token."}
        )
```

---

## 4. Token Expiration and Refresh (Client-Side)

Firebase ID tokens expire exactly **1 hour** after issuance. 

The Flutter client must handle token refresh transparently:
1. The Flutter HTTP interceptor catches any `HTTP 401` response with `error_code: TOKEN_EXPIRED`.
2. The interceptor pauses the queue of outgoing requests.
3. The interceptor calls `FirebaseAuth.instance.currentUser?.getIdToken(true)` to force a refresh.
4. The interceptor updates the `Authorization` header and retries the failed request(s).

---

## 5. Rationale

**Why map Firebase UID to an internal UUID?**
Firebase UIDs are strings (e.g., `yXk9...`). PostgreSQL handles indexing and joining on native UUIDs much faster than on variable-length strings. Furthermore, abstracting the identity provider ID behind an internal UUID makes it possible to migrate away from Firebase in Phase 4 without rewriting the entire database schema.

**Why verify on every request instead of issuing a session cookie?**
Grahvani is a mobile-first application. Stateless JWT verification (where Firebase handles the signing key rotation) scales infinitely horizontally and avoids the complexity of sticky sessions or distributed session state in Redis.

---

## 6. Related Documents

- [api/REQUEST_RESPONSE.md](REQUEST_RESPONSE.md) -- The error envelope format used for 401s
- [security/SECRETS.md](../security/SECRETS.md) -- How the Firebase Admin SDK credentials are securely loaded
- [api/RATE_LIMITING.md](RATE_LIMITING.md) -- How the verified `user_id` is used to enforce limits
