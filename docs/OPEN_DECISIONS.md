# Open Decisions and Deferred Items

This document tracks active engineering decisions, unresolved design options, and deferred features currently under evaluation for **Grahvani**. Every item here blocks a specific implementation choice. Items are closed by creating an ADR in `docs/adr/`.

---

## Active Decision Backlog

| Item ID | Topic / Question | Current Options | Target Evaluation Phase | Owner |
| :--- | :--- | :--- | :---: | :--- |
| **OD-001** | Post-Retrieval Reranking | Option A: Baseline hybrid vector+FTS search (RRF only).<br/>Option B: Add `bge-reranker-large` cross-encoder reranker after RRF. | Phase 2 (Post-RAG Evaluation) | AI Lead |
| **OD-002** | IAP SDK: Direct vs. RevenueCat | Option A: Build custom Apple + Google + Razorpay verification adapters (current).<br/>Option B: Integrate RevenueCat SDK to manage all three in one. | Phase 2 (Billing Implementation) | Backend Lead |
| **OD-003** | Localized Language Translation | Option A: LLM-based translation (Gemini) at response time.<br/>Option B: Pre-translated corpus + DeepL for static content. | Phase 3 (Multi-Language Growth) | Product Lead |
| **OD-004** | Historical Timezone Database | Option A: IANA Time Zone Database (`tzdata`) -- Python `zoneinfo`.<br/>Option B: Custom historical Indian timezone correction table (pre-1947 India). | Phase 1 (Astrology Engine QA) | Domain Lead |
| **OD-005** | LLM Model and Provider | Option A: Google Gemini Flash series (current candidate).<br/>Option B: Claude 3.5 Haiku (stronger instruction following).<br/>Option C: GPT-4o-mini (mature ecosystem).<br/>Option D: Open-source hosted model (lower cost). | Phase 1 (AI Integration) | AI Lead |

---

## Evaluation Criteria and Notes

### OD-001 (Post-Retrieval Reranking)
Evaluate on the 100-question golden dataset. If baseline `pgvector` hybrid RRF search achieves >= 85% citation precision, defer the reranker to avoid an additional 100-150 ms latency penalty per request. The reranker adds GPU inference cost (~$0.001/request at Cohere Rerank pricing).

**Decision Trigger**: Run evaluation after Phase 1 RAG integration is complete with 50,000+ chunks indexed.

### OD-002 (RevenueCat vs. Direct)
If maintaining separate Apple App Store Server Notifications v2 and Google Play RTDN webhook handlers introduces more than 3 unique production billing incidents in the first 60 days, migrate to RevenueCat. RevenueCat cost: ~$0.01 per monthly active subscriber.

**Decision Trigger**: 60 days post-launch billing incident review.

### OD-004 (Historical Timezone)
The Python `zoneinfo` module handles post-1970 IANA timezone data reliably for India (`Asia/Kolkata`). The risk is pre-1947 birth dates where historical IST offsets differed. Evaluate if more than 5% of test users report pre-1950 birth dates.

**Decision Trigger**: User demographic data from first 1,000 registrations.

### OD-005 (LLM Model and Provider)
The LLM provider is abstracted via `LLMProvider` interface (see [ai/MODEL_SELECTION.md](ai/MODEL_SELECTION.md)). The specific model is set via `LLM_MODEL_NAME` and `LLM_PROVIDER` environment variables. Evaluation metrics: groundedness score >= 0.85 on 100-question golden dataset, TTFB p50 < 1,200 ms, cost per question < $0.001.

**Decision Trigger**: Complete the 100-question golden dataset evaluation with at least 2 provider candidates before Phase 1 release.

---

## Closed Decisions (Moved to ADR)

| Item ID | Decision Made | ADR Reference |
| :--- | :--- | :--- |
| Architecture Style | Modular Monolith on FastAPI | [ADR-001](adr/ADR_001_ARCHITECTURE.md) |
| Database | PostgreSQL 16 + pgvector | [ADR-002](adr/ADR_002_DATABASE.md) |
| AI Strategy | Grounded RAG, no freeform LLM astrology | [ADR-003](adr/ADR_003_AI.md) |
| Calculation Engine | Swiss Ephemeris (pyswisseph) | [ADR-004](adr/ADR_004_ASTROLOGY.md) |
| Billing Architecture | Server-authoritative entitlements | [ADR-005](adr/ADR_005_BILLING.md) |
