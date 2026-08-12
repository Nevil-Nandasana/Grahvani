# Original User Request

## 2026-08-12T07:07:49Z

Complete the remaining engineering features and technical requirements for the Grahvani project as documented in `FeatTracking/Master Feature Tracking.md`, `FeatTracking/PROJECT_RULES.md`, and the `docs/` directory.

Working directory: e:\AI-WorkSpace\Projects\Active\Grahvani
Integrity mode: demo

## Execution Batching (run these as SEPARATE checkpointed sessions, not one pass)

Do not implement all 21 features in a single run. Complete **Batch 1 only**, stop, and wait for explicit approval before starting Batch 2. This keeps each review small enough to actually verify against R2/R3.

- **Batch 1 — Phase 2 Hardening & Testing** (do this first):
  - `bge-reranker-large` post-retrieval cross-encoder reranking integration
  - Maestro cross-platform mobile E2E test flows setup
  - Locust performance & load testing scripts
  - 7-Day Free Premium Trial entitlement flow
- **Batch 2 — Phase 3 Expansion** (only after Batch 1 is reviewed and merged):
  - Synastry / Relationship Compatibility calculation engine & UI
  - Western Astrology (Tropical Zodiac `AYANAMSA=0`) support & rendering
  - Horary Astrology (Prashna KP 1–249 seed engine)
  - Multi-profile chart overlay comparison
  - Yearly Varshaphal (Solar Return) calculation engine
  - International payment integration (Stripe / Paddle) backend adapters — **see Payment/Legal Scope Limits below**
  - Voice AI consultation integration hooks (STT/TTS stream handlers)
  - Family Plan subscription sharing & Lifetime license entitlement models
  - Flutter Web build configurations (`flutter build web`)
- **Batch 3 — Phase 4 & Extended Capabilities** (only after Batch 2 is reviewed and merged):
  - Numerology (Pythagorean & Chaldean) & Tarot card draw algorithms + LLM interpretation endpoints
  - Muhurta (Auspicious Event Timing) calculation engine
  - Public B2B API Developer Tier key & quota management
  - Astrologer Pro Tools & client management dashboard scaffold
  - Verified Human Astrologer Marketplace API models & live consultation hooks — **see Payment/Legal Scope Limits below**
  - Community Forum integration interface
  - On-Device LLM local inference fallback interface
  - LangGraph multi-step admin editorial ingestion pipeline

## Requirements

### R1. Sequential Priority Feature Implementation
Within the current batch, implement pending/planned features from `FeatTracking/Master Feature Tracking.md` in priority order while adhering strictly to `FeatTracking/PROJECT_RULES.md`.

### R2. Non-Breaking & Backward Compatibility Guarantee
Every feature addition must preserve existing functionality (authentication, birth profile management, core ephemeris D1/D9 calculations, grounded RAG streaming chat, billing entitlements, notifications, and localized UI).

### R3. Verification & Automated Testing (tightened)
- Validate all backend changes using `pytest` and verify mobile UI integrity using `flutter analyze` or relevant test scripts.
- **Every new route or endpoint must have at least one test that exercises it through the fully assembled app instance (`TestClient(app)` against the real `main.py`), not just against an isolated router.** Router-only tests are not sufficient — this is exactly the gap that let two previously ship-blocking bugs (a broken import path and unregistered routers) pass review undetected.
- Confirm the app boots cleanly end-to-end (`uvicorn app.main:app`) as part of verification for every batch, not just at final delivery.

### R4. Zero Documentation Drift, With Explicit Status Honesty
- Update `FeatTracking/Master Feature Tracking.md` to reflect completed status, update dates/notes, and keep `README.md` and `docs/` synchronized as features are delivered.
- **If "Integrity mode: demo" permits stubbed, mocked, or partial implementations for any feature, that feature must be marked `Implemented (stub — not production-ready)` in the tracking doc, never plain `Implemented`.** Plain `Implemented` is reserved for features that are fully wired, tested via R3, and require no further work before shipping.
- **Do not change the status of the "Swiss Ephemeris Commercial License Procurement" line item, or any other legal/compliance/business-procurement item, under any circumstances.** These require human action outside the codebase (e.g., purchasing a license) and cannot be completed or marked `Implemented` by an implementation agent.

### R5. Payment/Legal Scope Limits (new)
For the following items specifically, implement **backend scaffolding and adapter interfaces only** — no live credentials, no production activation, no real transaction processing:
- International payment integration (Stripe / Paddle)
- Verified Human Astrologer Marketplace (payouts, live consultation billing)
- Family Plan / Lifetime License entitlement models

Mark these `Implemented (scaffold — requires business/compliance review before activation)` in the tracking doc. Do not wire in real API keys, do not enable live payment flows, and flag in the PR/commit notes that these need my explicit sign-off before going live, given KYC, tax, and payout-liability implications.

## Acceptance Criteria (per batch)

### Build & Integrity
- [ ] The backend Python FastAPI service builds without errors and passes all existing & new unit/integration tests (`pytest`), including full-app `TestClient` coverage for every new route (see R3).
- [ ] The Flutter mobile app passes analysis (`flutter analyze`) without breaking syntax or lint errors.
- [ ] No regression in primary functionality (Ephemeris calculations, Grounded RAG response generation, User Auth, and Billing entitlement checks).

### Feature Completeness & Documentation
- [ ] All target features for the current batch are implemented with associated backend routes/logic and Flutter UI components where applicable.
- [ ] `FeatTracking/Master Feature Tracking.md` is updated accurately per R4 (`Implemented`, `Implemented (stub...)`, or `Implemented (scaffold...)` as appropriate — never inflated).
- [ ] Updated architecture and usage documentation recorded in `docs/` and `README.md`.
- [ ] Stop and report back at the end of the batch — do not auto-continue to the next batch.
