# Project Assumptions

This document records the foundational assumptions underlying technical, business, and domain decisions for **Grahvani**.

---

## 1. Technical & Infrastructure Assumptions
1. **Cloud Hosting Region**: AWS Mumbai (`ap-south-1`) is assumed as the primary production region to minimize network latency for India-first users.
2. **Containerized Execution**: All backend services (FastAPI API server and Dramatiq worker) run as Docker containers built on standard `python:3.12-slim` images.
3. **Database Scale**: PostgreSQL with `pgvector` will efficiently serve initial production loads up to 500,000 active users and 10,000,000 document vector embeddings before requiring a dedicated search cluster.
4. **Third-Party Uptime**: Firebase Auth and Google Gemini APIs are assumed to maintain $\ge 99.9\%$ SLA availability.

---

## 2. Domain & Astrological Assumptions
1. **Default Ayanamsa**: Lahiri (Chitra Paksha) Ayanamsa is accepted as the standard default for Vedic birth chart calculations in India.
2. **Ephemeris Precision**: The Swiss Ephemeris (`pyswisseph`) C-library provides sub-arcsecond astronomical accuracy suitable for commercial astrological applications.
3. **Deterministic Factual Primacy**: Astrological facts (planetary degrees, ascendants, dasha dates) are strictly deterministic; AI generative models must never be used to calculate numerical planetary positions.

---

## 3. Business & Compliance Assumptions
1. **App Store Compliance**: Apple Inc. enforces native In-App Purchase (IAP) for all digital feature unlocks on iOS; Google Play enforces Play Billing on Android. Direct web payment gateways (Razorpay) are restricted to web clients.
2. **Data Privacy Compliance**: Birth details are classified as sensitive personal data under the Indian Digital Personal Data Protection (DPDP) Act, requiring explicit user consent mechanisms and user-initiated data deletion capabilities.
3. **Legal Disclaimer**: Astrological guidance is legally provided for educational and personal insight purposes only, explicitly excluding medical, legal, or financial guarantees.
