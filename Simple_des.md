Using the complete architecture, technology decisions, implementation strategy, and product plan provided above as the single source of truth, create a comprehensive documentation system for the entire **Grahvani** project.

Generate a complete set of well-organized Markdown (`.md`) files that will serve as the project's official documentation throughout the entire software development lifecycle—from planning and development to deployment, maintenance, and future scaling.

The documentation should be detailed enough that a new developer, AI engineer, designer, DevOps engineer, QA engineer, or future contributor can understand the project and begin working on it without requiring additional context.

## General Requirements

* Do **not** omit any important details from the provided project plan.
* Preserve all architectural decisions, technology choices, implementation rationale, and best practices.
* Expand each topic where necessary with industry-standard documentation.
* Explain **why** decisions were made, not just **what** they are.
* Cross-reference related documents wherever appropriate.
* Use Markdown best practices.
* Include Mermaid diagrams whenever architecture, workflows, or relationships can be visualized.
* Use tables for comparisons, configurations, APIs, database schemas, permissions, technology decisions, and feature matrices.
* Include examples wherever they improve clarity.
* Maintain a consistent documentation style across every file.
* Assume the project is intended to become a production-ready commercial application.

---

# Documentation Structure

Create a complete `/docs` directory similar to the following (expand if necessary):

```text
docs/
│
├── README.md
├── PROJECT_OVERVIEW.md
├── PRODUCT_REQUIREMENTS.md
├── SYSTEM_ARCHITECTURE.md
├── TECH_STACK.md
├── ARCHITECTURE_DECISIONS.md
├── DEVELOPMENT_ROADMAP.md
├── CODING_GUIDELINES.md
├── CONTRIBUTING.md
│
├── frontend/
│   ├── FLUTTER_ARCHITECTURE.md
│   ├── UI_COMPONENTS.md
│   ├── STATE_MANAGEMENT.md
│   ├── NAVIGATION.md
│   └── OFFLINE_STORAGE.md
│
├── backend/
│   ├── FASTAPI_ARCHITECTURE.md
│   ├── MODULES.md
│   ├── API_DESIGN.md
│   ├── AUTHENTICATION.md
│   ├── AUTHORIZATION.md
│   ├── BACKGROUND_JOBS.md
│   └── ERROR_HANDLING.md
│
├── ai/
│   ├── AI_ARCHITECTURE.md
│   ├── RAG.md
│   ├── PROMPT_ENGINEERING.md
│   ├── MODEL_SELECTION.md
│   ├── KNOWLEDGE_BASE.md
│   ├── GUARDRAILS.md
│   ├── OBSERVABILITY.md
│   ├── EVALUATION.md
│   └── FUTURE_AGENTIC_AI.md
│
├── astrology/
│   ├── CALCULATION_ENGINE.md
│   ├── SWISS_EPHEMERIS.md
│   ├── DATA_VALIDATION.md
│   ├── CHART_GENERATION.md
│   ├── ASTROLOGY_WORKFLOW.md
│   └── LICENSING.md
│
├── database/
│   ├── DATABASE_DESIGN.md
│   ├── ER_DIAGRAM.md
│   ├── TABLES.md
│   ├── INDEXING.md
│   ├── VECTOR_SEARCH.md
│   └── MIGRATIONS.md
│
├── api/
│   ├── ENDPOINTS.md
│   ├── REQUEST_RESPONSE.md
│   ├── AUTH_FLOW.md
│   ├── STREAMING.md
│   └── RATE_LIMITING.md
│
├── infrastructure/
│   ├── DEPLOYMENT.md
│   ├── DOCKER.md
│   ├── AWS.md
│   ├── CI_CD.md
│   ├── MONITORING.md
│   ├── SECURITY.md
│   ├── ENVIRONMENT_VARIABLES.md
│   └── BACKUP_AND_RECOVERY.md
│
├── billing/
│   ├── SUBSCRIPTIONS.md
│   ├── ENTITLEMENTS.md
│   ├── GOOGLE_PLAY.md
│   ├── APP_STORE.md
│   └── RAZORPAY.md
│
├── testing/
│   ├── TESTING_STRATEGY.md
│   ├── UNIT_TESTS.md
│   ├── INTEGRATION_TESTS.md
│   ├── E2E_TESTS.md
│   └── LOAD_TESTING.md
│
├── security/
│   ├── THREAT_MODEL.md
│   ├── DATA_PRIVACY.md
│   ├── ENCRYPTION.md
│   ├── SECRETS.md
│   └── COMPLIANCE.md
│
├── product/
│   ├── USER_FLOWS.md
│   ├── FEATURE_SPECIFICATIONS.md
│   ├── MVP.md
│   ├── PREMIUM_FEATURES.md
│   └── FUTURE_ROADMAP.md
│
└── adr/
    ├── ADR_001_ARCHITECTURE.md
    ├── ADR_002_DATABASE.md
    ├── ADR_003_AI.md
    └── ...
```

---

## Each Markdown File Must Include

* Purpose of the document.
* Scope.
* Detailed explanation.
* Design rationale.
* Best practices.
* Trade-offs.
* Future improvements.
* Related documentation links.
* References where applicable.

---

## Additional Requirements

Include comprehensive documentation for:

* Complete Flutter architecture.
* FastAPI modular monolith architecture.
* Domain-driven module boundaries.
* PostgreSQL schema and relationships.
* pgvector implementation.
* Redis usage.
* Firebase Authentication flow.
* JWT verification.
* Swiss Ephemeris integration.
* Birth chart generation pipeline.
* AI interpretation pipeline.
* RAG implementation.
* Prompt versioning strategy.
* Knowledge base ingestion.
* Citation strategy.
* AI evaluation framework.
* Langfuse/LangSmith integration.
* Guardrails.
* Billing architecture.
* Subscription lifecycle.
* Google Play Billing.
* Apple In-App Purchases.
* Razorpay integration.
* Entitlement system.
* Notification architecture.
* Docker setup.
* AWS deployment.
* GitHub Actions CI/CD.
* Monitoring and logging.
* Security architecture.
* Privacy and compliance.
* Performance optimization.
* Scalability strategy.
* Backup and disaster recovery.
* Testing strategy.
* Coding standards.
* Folder structure.
* Development workflow.
* Release management.
* Versioning strategy.
* Risk assessment.
* Future migration path to microservices (only if justified).

---

## Documentation Quality

Write the documentation as if it will be used by a professional software team building a real commercial SaaS product.

Do **not** summarize the project. Instead, produce detailed, implementation-ready documentation that can guide development from start to production.

If any information is missing, infer reasonable, industry-standard approaches that are consistent with the provided architecture, clearly documenting any assumptions.

The final output should feel like the documentation of a mature, enterprise-grade AI application rather than notes or generated summaries.
