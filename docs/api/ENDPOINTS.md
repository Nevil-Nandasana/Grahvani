# API Endpoints Catalog

> [[API Index](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/api/README.md) | [Request/Response Envelopes](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/api/REQUEST_RESPONSE.md) | [Auth Flow](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/api/AUTH_FLOW.md) | [SSE Streaming](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/api/STREAMING.md) | [Rate Limiting](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/api/RATE_LIMITING.md)]

---

## 1. Overview & Standard Headers

All REST endpoints in **Grahvani** are hosted under the `/api/v1` prefix. All protected requests require a Firebase JWT bearer token in the HTTP `Authorization` header.

### Required HTTP Headers
- `Authorization`: `Bearer <FIREBASE_ID_TOKEN>` (Required for all protected endpoints)
- `Content-Type`: `application/json`
- `Accept`: `application/json` (or `text/event-stream` for chat streaming)
- `X-App-Version`: e.g. `1.2.0` (Client application build version)

---

## 2. Authentication & Profile Endpoints

### `POST /api/v1/auth/verify-token`
Exchanges a client Firebase ID token for an authenticated user session, initializing the user record in PostgreSQL if logging in for the first time.

- **Auth Required**: No (Token passed in body or header)
- **Request Body**:
  ```json
  {
    "firebase_token": "eyJhbGciOiJSUzI1NiIs..."
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "user_id": "9b1deb4d-3b7d-4149-9b26-89fa8000411a",
      "email": "user@example.com",
      "role": "user",
      "tier": "free",
      "is_new_user": false
    }
  }
  ```

---

### `GET /api/v1/profiles`
Lists all birth profiles created by the authenticated user.

- **Auth Required**: Yes (`user` role)
- **Query Parameters**:
  - `page` (int, default: 1): Page number.
  - `limit` (int, default: 20): Profiles per page (max: 100).
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "c3a1b82e-6d4f-4a92-8e11-123456789abc",
        "name": "Aditya Sharma",
        "date_of_birth": "1992-08-15",
        "time_of_birth": "14:30:00",
        "place_name": "New Delhi, India",
        "latitude": 28.6139,
        "longitude": 77.2090,
        "timezone": "Asia/Kolkata",
        "created_at": "2026-08-01T10:00:00Z"
      }
    ],
    "meta": {
      "total_count": 1,
      "page": 1,
      "limit": 20
    }
  }
  ```

---

### `POST /api/v1/profiles`
Creates a new birth profile for chart calculations.

- **Auth Required**: Yes
- **Request Body**:
  ```json
  {
    "name": "Priya Patel",
    "date_of_birth": "1995-11-24",
    "time_of_birth": "08:15:00",
    "place_name": "Ahmedabad, Gujarat, India",
    "latitude": 23.0225,
    "longitude": 72.5714,
    "timezone": "Asia/Kolkata"
  }
  ```
- **Response `201 Created`**: Returns created profile object.

---

## 3. Birth Charts & Ephemeris Endpoints

### `POST /api/v1/charts/calculate`
Enqueues an asynchronous calculation job via Swiss Ephemeris for a given birth profile.

- **Auth Required**: Yes
- **Request Body**:
  ```json
  {
    "profile_id": "c3a1b82e-6d4f-4a92-8e11-123456789abc",
    "ayanamsa": "lahiri",
    "house_system": "placidus"
  }
  ```
- **Response `202 Accepted`**:
  ```json
  {
    "success": true,
    "data": {
      "chart_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "status": "pending",
      "poll_url": "/api/v1/charts/f47ac10b-58cc-4372-a567-0e02b2c3d479/status"
    }
  }
  ```

---

### `GET /api/v1/charts/{id}`
Fetches the completed immutable birth chart facts JSON (D1 Kundali, D9 Navamsha, Vimshottari Dasha breakdown).

- **Auth Required**: Yes
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "chart_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "status": "complete",
      "ayanamsa_name": "Lahiri",
      "ascendant_sign": "Scorpio",
      "planets": [
        {
          "name": "Sun",
          "longitude": 120.4523,
          "zodiac_sign": "Leo",
          "house": 10,
          "nakshatra": "Magha",
          "padam": 1,
          "is_retrograde": false
        }
      ]
    }
  }
  ```

---

## 4. Grounded AI Interpretation & Chat Endpoints

### `POST /api/v1/chat/sessions`
Initializes a new conversational session linked to a specific birth chart snapshot.

- **Auth Required**: Yes
- **Request Body**:
  ```json
  {
    "chart_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "title": "Career & Career Dasha Query"
  }
  ```
- **Response `201 Created`**: Returns created chat session metadata.

---

### `POST /api/v1/chat/stream` (SSE Endpoint)
Streams real-time, evidence-grounded interpretation responses with classical source citations using Server-Sent Events (SSE).

- **Auth Required**: Yes
- **Accept Header**: `text/event-stream`
- **Request Body**:
  ```json
  {
    "session_id": "8e3b2a1c-9d8e-7f6a-5b4c-3d2e1f0a9b8c",
    "message": "What does my 10th house Sun in Leo mean for my career advancement?"
  }
  ```
- **SSE Stream Response**:
  ```text
  event: metadata
  data: {"citation_sources": ["Brihat Parashara Hora Shastra, Ch. 24, Sloka 12"]}

  event: delta
  data: {"content": "Your 10th house Sun in Leo is Digbala (directional strength). "}

  event: delta
  data: {"content": "According to BPHS, this position confers leadership capability and executive status..."}

  event: done
  data: {"session_id": "8e3b2a1c-9d8e-7f6a-5b4c-3d2e1f0a9b8c", "tokens_used": 184}
  ```

---

## 5. Billing & Webhook Endpoints

### `GET /api/v1/billing/entitlements`
Retrieves current user entitlement state, subscription tier, and daily remaining query quota.

- **Auth Required**: Yes
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "tier": "premium",
      "is_active": true,
      "daily_queries_limit": 50,
      "queries_remaining": 42,
      "expires_at": "2026-09-01T00:00:00Z"
    }
  }
  ```

---

### `POST /api/v1/billing/webhooks/razorpay`
Webhook receiver for Razorpay subscription events (`subscription.charged`, `payment.failed`).

- **Auth Required**: No (HMAC Signature verification required in `X-Razorpay-Signature` header)
- **Response `200 OK`**: `{"status": "processed"}`

---

## 6. HTTP Status Code Mapping

| Status Code | Meaning | Cause / Scenario |
| :---: | :--- | :--- |
| **`200 OK`** | Request Succeeded | Successful read or synchronous update. |
| **`201 Created`** | Resource Created | Successful creation of profile or chat session. |
| **`202 Accepted`** | Asynchronous Processing | Background calculation task enqueued (e.g. chart calculation). |
| **`400 Bad Request`** | Invalid Parameters | Geocoding failure or invalid date format. |
| **`401 Unauthorized`** | Auth Error | Invalid, expired, or missing Firebase JWT token. |
| **`403 Forbidden`** | Entitlement Error | Quota exceeded for free tier user; upgrade required. |
| **`422 Unprocessable Entity`** | Pydantic Validation Error | Missing required JSON body attributes. |
| **`429 Too Many Requests`** | Rate Limit Exceeded | Exceeded requests per minute rate limit. |
| **`500 Internal Error`** | Server Failure | Unhandled backend processing error. |

---

## 7. Related Documents

- [API Design](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/API_DESIGN.md) — RESTful principles and error formatting guidelines.
- [Auth Flow](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/api/AUTH_FLOW.md) — Detailed Firebase JWT validation flow.
- [SSE Streaming](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/api/STREAMING.md) — Server-Sent Events architecture for chat responses.
- [Rate Limiting](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/api/RATE_LIMITING.md) — Redis bucket rate limits per user tier.
