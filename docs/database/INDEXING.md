# Database Indexing Strategy Specification

> [[README.md](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/README.md) | [Database Design](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/DATABASE_DESIGN.md) | [Tables DDL](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/TABLES.md) | [Vector Search](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/VECTOR_SEARCH.md) | [Migrations](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/MIGRATIONS.md)]

---

## 1. Overview & Performance Goals

In **Grahvani**, indexes are strategically configured to ensure that **p95 read query latency remains under 20ms** for API operations and under 15ms for vector search retrievals. Every index carries write overhead (I/O and buffer maintenance); therefore, indexes are added strictly based on query patterns, join boundaries, filtering conditions, and sorting requirements.

---

## 2. Relational & B-Tree Index Definitions

### A. Foreign Key & Entity Lookup Indexes
Every foreign key column in Grahvani is indexed with a B-Tree index to prevent full table scans during JOIN operations and cascading updates:

```sql
-- Core User & Profile Lookups
CREATE INDEX idx_birth_profiles_user_id ON birth_profiles(user_id);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_external_id ON subscriptions(external_subscription_id);
CREATE INDEX idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX idx_chat_messages_session_id ON chat_messages(session_id);
```

---

### B. Composite & Sorted Pagination Indexes
To support cursor-based pagination for history lists (e.g., chat conversations, profile listings), multi-column composite indexes are created matching exact `WHERE ... ORDER BY` clauses:

```sql
-- Composite index for paginated chat message retrieval
CREATE INDEX idx_chat_messages_session_created 
ON chat_messages(session_id, created_at DESC);

-- Composite index for active profile listing per user
CREATE INDEX idx_birth_profiles_user_created 
ON birth_profiles(user_id, created_at DESC) 
WHERE deleted_at IS NULL;
```

---

### C. Partial Indexes (Filtered Indexing)
Partial indexes are used to index only active, non-deleted rows or unhandled background jobs, drastically reducing index memory footprint:

```sql
-- Partial index for active subscription lookups
CREATE INDEX idx_subscriptions_active_user 
ON subscriptions(user_id) 
WHERE status = 'active';

-- Partial index for pending background task processing
CREATE INDEX idx_background_tasks_pending 
ON background_tasks(created_at ASC) 
WHERE status = 'pending';
```

---

## 3. GIN Indexes (JSONB & Full-Text Search)

### A. GIN Index on Document Chunk Full-Text Search
```sql
CREATE INDEX idx_document_chunks_fts 
ON document_chunks USING GIN(fts_vector);
```

### B. GIN Index on JSONB Chart Facts
Grahvani stores calculated planetary longitudes and house positions in `JSONB`. To accelerate queries querying specific planetary placements (e.g., *"Find charts where Sun is in Aries"*):

```sql
CREATE INDEX idx_birth_charts_facts_jsonb 
ON birth_charts USING GIN(chart_facts_json jsonb_path_ops);
```

---

## 4. HNSW Vector Similarity Index (`pgvector`)

Hierarchical Navigable Small World (HNSW) index for 768-dimensional dense vector similarity search:

```sql
CREATE INDEX idx_document_chunks_embedding_hnsw 
ON document_chunks USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
```

---

## 5. Index Maintenance & Performance Diagnostics

### A. Identifying Unused or Low-Scan Indexes
```sql
SELECT 
    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan AS number_of_scans,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0 
  AND indexrelname NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

### B. Monitoring Index Bloat & Non-Blocking Reindexing
When high update volume degrades B-Tree efficiency, indexes are rebuilt concurrently without acquiring exclusive write locks:

```sql
-- Rebuild index concurrently in production without blocking API writes
REINDEX INDEX CONCURRENTLY idx_chat_messages_session_created;
```

---

## 6. Related Documents

- [Database Design](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/DATABASE_DESIGN.md) — Main database architecture and connection pooling.
- [Tables DDL](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/TABLES.md) — Full SQL table DDL specifications.
- [Vector Search](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/VECTOR_SEARCH.md) — `pgvector` HNSW index and hybrid search queries.
