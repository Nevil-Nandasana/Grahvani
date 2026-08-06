# Product Requirements Document (PRD)

## 1. Functional Requirements

### 1.1 Authentication & Profile Management
- **Multi-Factor Mobile Auth**: Users must authenticate via Firebase Auth supporting Google Sign-In, Apple ID (required for App Store compliance), and Phone OTP (India-first focus).
- **Birth Profiles**: Users can save multiple profiles (Self, Family, Friends) with:
  - Full Name
  - Exact Date of Birth (`YYYY-MM-DD`)
  - Exact Time of Birth (`HH:MM:SS`) or "Time Unknown" flag
  - Location Name, Latitude, Longitude, and IANA Timezone identifier (e.g., `Asia/Kolkata`).
- **Data Privacy & Deletion**: One-tap explicit consent management and complete account/profile deletion flow compliant with the Indian DPDP Act.

### 1.2 Deterministic Birth Chart Generation
- **Astronomical Precision**: Compute exact planetary longitudes for Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Rahu, Ketu, and Ascendant (Lagna).
- **Vedic Calculations**:
  - Divisional Charts: D1 (Rasi) and D9 (Navamsa) minimum for MVP; D10 (Dasamsa) for career insights.
  - Ayanamsa support: Lahiri (Chitra Paksha) as default, with option for Raman / Krishnamurti (KP).
  - House System: Equal / Whole Sign / Placidus option.
  - Dasha System: Vimshottari Dasha calculations down to Pratyantar Dasha level.
- **Immutable Snapshots**: Once a chart is calculated, save its facts as an immutable JSON snapshot. Future library or software updates must never alter historical stored chart facts.

### 1.3 Grounded AI Interpretation & Chat
- **Fact-Constrained Prompts**: AI prompt context must contain strictly validated birth chart facts and retrieved source chunks. AI must never calculate positions.
- **RAG Citations**: Factual astrological statements in responses must contain inline citations (e.g., `[Brihat Parasara Hora Shastra, Ch. 12]`).
- **Low Confidence Fallback**: When retrieved text confidence score falls below defined threshold (`0.65`), the AI must respond: *"I do not have sufficient verified classical literature to answer this specific query accurately."*
- **Streaming Responses**: Chat responses must stream using Server-Sent Events (SSE) for sub-second initial token latency.

### 1.4 Subscription & Entitlement Management
- **Free Tier**: Single birth profile, basic D1/D9 chart rendering, Vimshottari Maha Dasha overview, 3 AI questions per day.
- **Premium Tier**: Unlimited profiles, full divisional charts, Dasha breakdown down to Sukshma level, unlimited RAG AI chat, PDF chart export.
- **Cross-Platform Billing**:
  - Android: Native Google Play Billing.
  - iOS: Native Apple In-App Purchase.
  - Web: Razorpay Subscription checkout with UPI Autopay support.
  - Entitlements enforced 100% server-side via FastAPI backend.

---

## 2. Non-Functional Requirements (NFRs)

| NFR Domain | Requirement Target | Measurement / Validation |
| :--- | :--- | :--- |
| **API Latency** | Chart Calculation: $< 200\text{ ms}$<br/>AI First Token (TTFT): $< 800\text{ ms}$ | Measured at FastAPI middleware & Sentry APM |
| **Availability** | $99.9\%$ Uptime for core REST endpoints | AWS App Runner auto-scaling (min 2 instances) |
| **Data Integrity** | Immutable chart snapshots with cryptographic checksums | PostgreSQL `birth_charts` table constraints |
| **Security** | TLS 1.3 in transit, AES-256 for database at rest, JWT signature verification | Security scanning via GitHub Actions & OWASP ZAP |
| **Concurrency** | 500 concurrent chat SSE streams without degradation | Locust load testing on Redis + FastAPI worker |
| **Storage Limits** | Max 100 profiles per premium user, vector embeddings capped at 1536 dims | Database constraint & validation logic |

---

## 3. Product Boundary: MVP vs Out of Scope

```mermaid
graph TD
    subgraph IN_MVP["IN MVP SCOPE"]
        A[Flutter Android & iOS Client]
        B[Firebase Auth - Google/Apple/OTP]
        C[Swiss Ephemeris D1/D9 & Vimshottari Dasha]
        D[PostgreSQL + pgvector Hybrid RAG]
        E[Gemini 1.5 Flash Grounded AI Chat]
        F[Google Play / App Store / Razorpay Entitlements]
    end

    subgraph OUT_OF_SCOPE["OUT OF SCOPE FOR MVP"]
        G[Autonomous AI Agents]
        H[Human Expert Marketplace]
        I[Palmistry / Face Reading]
        J[Kubernetes Orchestration]
        K[Standalone Vector DB Cluster (Pinecone/Milvus)]
        L[Microservices Architecture]
    end
```

---

## 4. Key Acceptance Criteria Examples
1. **Reproducibility Test**: Given birth details (`1995-10-24 14:30:00, Kolkata`), recalculating the chart 1 year later using the same settings must produce identical floating-point longitudes down to $10^{-6}$ degrees.
2. **Safety & Policy Guardrail**: If a user asks *"Will I get cured of my illness next month?"*, the AI engine must refuse to give medical diagnoses and return the mandatory health disclaimer.
3. **Billing Webhook Test**: Revoking a subscription via Razorpay or Google Play RTDN webhook must update the backend entitlement status within 30 seconds, immediately restricting client premium access.
