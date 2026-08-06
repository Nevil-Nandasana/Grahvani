# Minimum Viable Product (MVP) Scope Boundary

## Purpose
This document defines the exact scope of Grahvani's MVP release -- what is included, what is explicitly excluded, and the acceptance criteria that determine MVP readiness. It is the authoritative reference for scope disputes during Phase 1 development.

## Scope
Applies to the initial public launch of Grahvani, targeting Indian users on Android and iOS.

---

## 1. MVP Release Criteria

The MVP is complete when **all** of the following acceptance criteria are met:

| # | Criterion | Verification Method |
| :--- | :--- | :--- |
| 1 | Flutter Android + iOS apps pass Apple App Store and Google Play Store review | App Store review approval email |
| 2 | Firebase Auth supports Google Sign-In, Apple ID, Phone OTP | Manual E2E test on physical devices |
| 3 | Swiss Ephemeris produces D1 + D9 charts passing 50-vector precision test suite | `pytest tests/astro/` 100% pass rate |
| 4 | Vimshottari Dasha periods are accurate to the verified reference | `pytest tests/astro/test_dasha.py` 100% pass |
| 5 | Grounded RAG AI chat returns responses with source citations | Manual golden dataset evaluation (>= 85% groundedness) |
| 6 | Free tier (1 profile, 3 AI questions/day) enforced server-side | Integration test: 4th question returns 403 ENTITLEMENT_REQUIRED |
| 7 | In-App Purchase paywalls active on Google Play + Apple IAP | Sandbox purchase tested on both platforms |
| 8 | Razorpay subscription active for web users | Sandbox payment flow completed |
| 9 | DPDP Act consent screen displayed and recorded | Database audit: consent records saved correctly |
| 10 | Data deletion API (`DELETE /api/v1/users/me`) purges all data within 30 days | Integration test: all user data removed after deletion |
| 11 | App passes OWASP Mobile Top 10 checklist | Manual security review sign-off |

---

## 2. MVP Feature Inclusions

### Mobile Application (Flutter)
- Google Sign-In, Apple ID, Phone OTP authentication
- DPDP Act consent screen with opt-in / opt-out
- Add up to 1 birth profile (Free tier) -- name, date, time, city autocomplete
- D1 Rasi and D9 Navamsa chart rendering (North Indian diamond style, `CustomPainter`)
- Vimshottari Maha Dasha timeline view
- Grounded AI chat: 3 questions/day (Free), unlimited (Premium)
- AI responses with inline source citations (e.g., `[BPHS, Ch. 12]`)
- Paywall screen: Free vs. Premium comparison + purchase via Google Play / Apple IAP / Razorpay
- Chat history persistence per profile
- Data export and account deletion

### Backend API (FastAPI)
- Firebase JWT authentication middleware
- REST API for all identity, chart, chat, and billing operations
- Grounded RAG pipeline (pgvector hybrid search + Gemini Flash)
- AI guardrails: medical, legal, financial, prompt injection blocking
- Background task queue: chart calculations and PDF generation (Dramatiq + Redis)
- Webhook handlers: Google Play RTDN, Apple App Store Notifications v2, Razorpay
- DPDP compliance APIs: export and deletion

---

## 3. Explicitly Excluded from MVP (Post-MVP Roadmap)

| Feature | Target Phase | Rationale |
| :--- | :--- | :--- |
| D10, D12, D60 divisional charts | Phase 2 (Hardening) | Premium feature; chart engine supports it, UI needs design |
| Antar Dasha and Pratyantar Dasha breakdown | Phase 2 | Data exists; UI component not built |
| PDF chart export | Phase 2 | Dramatiq task implemented; PDF renderer (WeasyPrint) needs production testing |
| Hindi / Tamil language support | Phase 3 | Translation infrastructure not yet built |
| Voice AI consultation | Phase 3 | Requires real-time audio pipeline |
| Human expert marketplace | Phase 4 | Separate product domain |
| Synastry (chart comparison) | Phase 3 | Calculation engine supports it; product scope deferred |
| Web application | Phase 2 | Flutter Web build; Razorpay handles web payments |

---

## 4. Rationale

The MVP scope prioritises the core value loop: **calculate an accurate chart --> ask the AI about it --> get a grounded, cited answer**. Every excluded feature either requires significant additional engineering without demonstrating the core value proposition, or is a growth-stage product feature that depends on validated user engagement data from the MVP.

---

## 5. Related Documents

- [FEATURE_SPECIFICATIONS.md](FEATURE_SPECIFICATIONS.md) -- Detailed feature specs for all MVP features
- [PREMIUM_FEATURES.md](PREMIUM_FEATURES.md) -- Premium tier capabilities detail
- [FUTURE_ROADMAP.md](FUTURE_ROADMAP.md) -- Post-MVP growth features and phases
- [DEVELOPMENT_ROADMAP.md](../DEVELOPMENT_ROADMAP.md) -- Phase timeline and milestones
