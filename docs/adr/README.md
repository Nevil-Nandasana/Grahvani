# Architecture Decision Records (ADR) Index

Welcome to the Architecture Decision Records (ADRs) index for **Grahvani**.

---

## 📂 ADR Catalog

- 🏛️ **[ADR-001: Modular Monolith Architecture](ADR_001_ARCHITECTURE.md)** — Decision to adopt a FastAPI modular monolith over microservices.
- 🗄️ **[ADR-002: Single PostgreSQL Store with pgvector](ADR_002_DATABASE.md)** — Decision to use PostgreSQL + `pgvector` instead of a separate vector DB.
- 🤖 **[ADR-003: Custom RAG Engine over Heavy Frameworks](ADR_003_AI.md)** — Decision to build direct LLM RAG pipelines instead of using LangChain.
- 🪐 **[ADR-004: Swiss Ephemeris Calculation Primacy](ADR_004_ASTROLOGY.md)** — Decision to compute charts deterministically via C-library.
- 💳 **[ADR-005: Native In-App Purchases + Razorpay Web](ADR_005_BILLING.md)** — Decision to enforce 100% server-side entitlements with native store billing.
