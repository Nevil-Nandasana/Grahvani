# ADR-002: Single PostgreSQL Store with `pgvector` vs Dedicated Vector Database

> [[ADR Index](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/adr/README.md) | [Database Design](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/DATABASE_DESIGN.md) | [Vector Search](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/VECTOR_SEARCH.md)]

---

## Metadata
- **Status**: Accepted
- **Date**: 2026-08-01
- **Deciders**: Database Architect, AI Engineering Lead
- **Technical Story**: Selecting a storage architecture for relational user/chart data and dense 768-dimensional vector embeddings used in RAG search.

---

## Context & Problem Statement

Grahvani requires storing standard relational entities (user accounts, birth profiles, subscription states, payment logs) alongside 768-dimensional vector embeddings of classical Vedic astrology texts. We must decide whether to use a unified database or split data across a relational DB and a specialized vector DB.

---

## Options Considered

### Option 1: Dual Store (PostgreSQL + External Vector DB like Pinecone / Qdrant / Weaviate)
Store relational data in PostgreSQL and delegate vector similarity search to a dedicated cloud vector database service.

- **Pros**: Specialized vector indexing algorithms; offloads memory-intensive vector search from primary DB.
- **Cons**: Adds a second managed database service ($$$ cloud bill); synchronization delays between PostgreSQL metadata and vector records; lack of transactional ACID consistency across relational and vector data.

---

### Option 2: Single PostgreSQL 16 Store with `pgvector` Extension — **ACCEPTED**
Use **PostgreSQL 16 with `pgvector` (v0.6+)** as the unified primary storage layer for both relational schemas and dense vector embeddings.

- **Pros**:
  - **Zero Additional Managed Infrastructure**: Eliminates extra SaaS database fees and network hop latencies.
  - **ACID Transaction Boundaries**: Metadata updates and embedding ingestion occur in single transactions.
  - **HNSW Index Support**: Delivers sub-15ms cosine distance similarity search over 100k+ document chunks.
  - **Hybrid Search**: Enables single-query Reciprocal Rank Fusion (RRF) combining SQL GIN full-text search with vector cosine search.
- **Cons**: High memory consumption when vector index scales beyond tens of millions of records.

---

## Decision Outcome

**Chosen Option**: **Option 2: Single PostgreSQL Store with `pgvector`**.

### Positive Consequences
- Reduced infrastructure cost and operational overhead.
- Single database backup & recovery pipeline ([Backup & Recovery](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/infrastructure/BACKUP_AND_RECOVERY.md)).
- Unified SQL interface for developer team.

---

## Re-evaluation Trigger
- Re-evaluate if total vector storage exceeds **10 million document chunks** or if HNSW index memory footprint exceeds 16 GB on primary RDS instances.
