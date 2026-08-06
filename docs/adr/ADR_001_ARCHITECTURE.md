# ADR-001: Modular Monolith vs. Microservices Architecture

> [[ADR Index](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/adr/README.md) | [System Architecture](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/SYSTEM_ARCHITECTURE.md) | [FastAPI Architecture](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/FASTAPI_ARCHITECTURE.md)]

---

## Metadata
- **Status**: Accepted
- **Date**: 2026-08-01
- **Deciders**: Lead Architect, Backend Engineering Lead, DevOps Lead
- **Technical Story**: Establishing the backend system topology for Grahvani to achieve fast feature iteration, operational simplicity, and low cloud deployment overhead during early scaling phases.

---

## Context & Problem Statement

Grahvani is an early-stage production Vedic astrology application combining deterministic calculation modules, vector search, background workers, and mobile clients. We need an architecture that supports modular domain separation (`identity`, `birth_chart`, `interpretation`, `billing`) without introducing premature operational complexity, distributed transaction handling, and inter-service network latency.

---

## Options Considered

### Option 1: Microservices Architecture (Independent Microservices)
Split the application into separate microservices (Auth Service, Ephemeris Service, RAG Service, Payment Service) each with its own repository, database, and gRPC/REST communication layer.

- **Pros**: Independent scalability of calculation worker nodes; distinct deployment lifecycles per team.
- **Cons**: Severe operational overhead for a small engineering team; cross-service latency for API requests; complex distributed tracing; data consistency challenges across service databases.

---

### Option 2: Serverless Functions (AWS Lambda / Google Cloud Functions)
Implement API endpoints as independent serverless functions connected to cloud databases.

- **Pros**: Zero infrastructure management; auto-scaling to zero when idle.
- **Cons**: Cold start latencies unacceptable for heavy Python packages (`pyswisseph`, `numpy`); connection pooling limits with PostgreSQL; difficulty running long background processing jobs.

---

### Option 3: Modular Monolith Architecture (FastAPI Monolith) — **ACCEPTED**
Build Grahvani as a single-repository **FastAPI Modular Monolith** where each domain module (`identity`, `birth_chart`, `interpretation`, `billing`) is isolated in its own package with clear, strict interface boundaries.

- **Pros**:
  - **Single Command Local Execution**: Simple developer experience (`docker compose up`).
  - **Unified Data Store**: ACID transactions in a single PostgreSQL database.
  - **Low Operational Cost**: Deployed cleanly on AWS App Runner with minimal DevOps complexity.
  - **Future Extraction Path**: Well-defined module boundaries allow extracting the calculation worker into an independent microservice later if traffic requires it.
- **Cons**: Requires team discipline to enforce module boundaries and prevent cross-module database joins.

---

## Decision Outcome

**Chosen Option**: **Option 3: Modular Monolith Architecture (FastAPI)**.

### Positive Consequences
- Streamlined CI/CD pipeline and single container deployment.
- High developer velocity and fast debugging without distributed tracing tools.
- Unified database connection pooling and zero network hop overhead between modules.

### Negative Consequences
- Codebase must be strictly structured using Python packages and strict internal service contracts to prevent tight coupling.

---

## Validation & Re-evaluation Trigger
- **Re-evaluation Criteria**: If any single domain module (e.g. calculation engine) accounts for > 70% of CPU load and requires isolated scaling beyond 20 App Runner instances, that module will be extracted into a standalone worker microservice.
