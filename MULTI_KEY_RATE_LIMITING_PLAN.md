# Multi-Key Pool & Tiered Rate Limiting System — Technical Architecture Plan

---

## 1. Executive Summary & Goals

The goal of this feature is to manage API key usage efficiently across two distinct user groups while multiplying available API quotas and ensuring zero downtime.

### User Group Breakdown:
1. **VIP / Inner Circle (6–7 Users)**:
   - Personal contacts, family, beta testers who pay nothing.
   - Requires guaranteed throughput, priority queueing, and high rate limits (e.g., 100 requests/min).
   - Exempt from daily message caps.

2. **Public Users (Play Store, App Store & Website)**:
   - General public traffic.
   - Subject to strict per-user daily quotas (e.g., 5 requests/day) and per-minute rate limits (e.g., 5 requests/min) to prevent abuse and API exhaustion.

---

## 2. Architectural Blueprint

```mermaid
flowchart TD
    Req[Incoming User Request] --> Auth[Authenticate User via Firebase / JWT]
    Auth --> TierCheck{Check User Tier}
    
    TierCheck -- VIP User (is_vip=True) --> VIPQuota[Check VIP Rate Limits (100 RPM)]
    TierCheck -- Public User --> PublicQuota[Check Public Daily & Min Quota (5 req/day, 5 RPM)]
    
    PublicQuota -- Limit Exceeded --> Block429[Return 429 Too Many Requests]
    
    VIPQuota -- Pass --> KeyManager[KeyPoolManager: Get Next Healthy Key]
    PublicQuota -- Pass --> KeyManager
    
    KeyManager --> TryKey[Execute LLM Stream with Selected Gemini Key]
    
    TryKey -- Success --> Output[Stream SSE Response to Client]
    TryKey -- 429 / Quota Error --> MarkCooling[Mark Key as Cooling Down (60s)]
    
    MarkCooling --> NextKey{Has Untried Gemini Key in Pool?}
    NextKey -- Yes --> KeyManager
    NextKey -- No (All Keys Exhausted) --> NvidiaFallback[Switch to NVIDIA Nemotron Backup]
    
    NvidiaFallback --> Output
```

---

## 3. Core Component Specifications

### 3.1. API Key Pool Manager (`KeyPoolManager`)

Instead of relying on a single `GEMINI_API_KEY`, the application will maintain a pool of 5–6 Gemini API keys configured in `.env`:

```env
GEMINI_API_KEYS=["GEMINI_API_KEY_1...", "GEMINI_API_KEY_2...", "GEMINI_API_KEY_3...", "GEMINI_API_KEY_4...", "GEMINI_API_KEY_5...", "GEMINI_API_KEY_6..."]
```

#### Key Capabilities:
- **Round-Robin Key Selection**: Requests cycle through active keys evenly.
- **Cool-Down Tracking**: If an API key returns a quota or rate-limit error (`429`), the `KeyPoolManager`:
  1. Temporarily marks that specific key as **"cooling down"** in memory/Redis for 60 seconds.
  2. Automatically grabs the next healthy key in the pool and retries the prompt instantly without throwing an error to the user.
- **Health Recovery**: Once the 60-second window passes, the key is automatically restored to the active pool.

---

### 3.2. User Tiering & Access Control

Users will be categorized at request time:

#### VIP Identification Options:
- **Option A (Email Whitelist)**: Environment variable `VIP_EMAILS=["vip1@gmail.com", "vip2@gmail.com", ...]`
- **Option B (Database Flag)**: `user.is_vip = True` field on the `User` database model.

#### Quota & Rate Limit Matrix:

| Metric | Public Users | VIP / Inner Circle (6–7 Users) |
| :--- | :--- | :--- |
| **Daily Quota** | 5 requests / day | Unlimited (or 500 / day) |
| **Burst Limit** | 5 requests / minute | 100 requests / minute |
| **API Key Pool Access** | Standard Shared Keys | Priority Allocation / Dedicated Key |
| **Fallback Priority** | NVIDIA Nemotron | NVIDIA Nemotron |

---

### 3.3. NVIDIA Fallback Safeguard

If all 5–6 Gemini keys in the pool hit quota exhaustion simultaneously during peak traffic:
1. The `FallbackProvider` catches the all-keys exhausted state.
2. It seamlessly redirects the prompt stream to **NVIDIA Nemotron (`nvidia/nemotron-3-ultra-550b-instruct`)**.
3. The end-user receives their answer without noticing any downtime or error message.

---

## 4. Implementation Steps Roadmap

When you decide to implement this plan, the steps will be:

1. **Update `config.py`**: Add `GEMINI_API_KEYS: List[str]` and `VIP_EMAILS: List[str]` settings.
2. **Implement `KeyPoolManager` in `llm_provider.py`**:
   - Track key health, rotation index, and cool-down timestamps.
   - Add retry loop in `GeminiProvider` to try up to N keys before raising `BillingError`.
3. **Enhance User Model / Auth Middleware**:
   - Check if current user is in `VIP_EMAILS` or has `is_vip=True`.
4. **Update `router.py`**:
   - Enforce daily quota checks for public users.
   - Bypass daily limits for VIP users.
5. **Add Automated Unit & Integration Tests**:
   - Verify multi-key rotation.
   - Verify auto-failover when 1 key fails.
   - Verify public vs VIP quota enforcement.

---

## 5. Notes & Considerations

- **Cost Control**: Gemini free tier provides 15 RPM per key. 6 keys provide up to **90 RPM** aggregate capacity for free.
- **Privacy & Security**: `.env` and `MULTI_KEY_RATE_LIMITING_PLAN.md` are added to `.gitignore` to prevent leaking API keys or internal architecture details on public repositories.
