# Vector Search Specification (`pgvector`)

> [[README.md](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/README.md) | [Database Design](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/DATABASE_DESIGN.md) | [Tables DDL](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/TABLES.md) | [Indexing Strategy](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/INDEXING.md) | [RAG Architecture](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/ai/RAG.md)]

---

## 1. Overview & Vector Space Specification

Grahvani leverages PostgreSQL's **`pgvector` 0.6+ extension** to deliver high-performance, in-database similarity search over curated classical Vedic astrology texts (Brihat Parashara Hora Shastra, Saravali, Phaladeepika, etc.). By maintaining vector embeddings directly alongside traditional relational tables, Grahvani eliminates the operational overhead and synchronization delays of external vector databases (such as Pinecone or Qdrant).

### Model & Space Parameters
- **Vector Extension**: `pgvector` v0.6+
- **Embedding Model**: Google `text-embedding-004` via Gemini Embeddings API.
- **Dimensions**: **768 floating-point dimensions**.
- **Distance Metric**: **Cosine Distance (`<=>`)**.
- **Chunking Strategy**: 512 tokens per chunk with 64-token sliding window overlap.

---

## 2. Table Schema Definition

The vector embeddings for classical texts are stored in the `document_chunks` table:

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE document_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL DEFAULT 'Traditional',
    kanda_or_chapter VARCHAR(255),
    sloka_number VARCHAR(64),
    content TEXT NOT NULL,
    token_count INT NOT NULL,
    embedding vector(768) NOT NULL,
    fts_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('english', source_title || ' ' || content)
    ) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

---

## 3. HNSW Index Configuration & Tuning

To maintain sub-15ms vector retrieval latency as the classical text knowledge base grows to hundreds of thousands of chunks, an **HNSW (Hierarchical Navigable Small World)** index is configured:

```sql
CREATE INDEX idx_document_chunks_embedding_hnsw 
ON document_chunks USING hnsw (embedding vector_cosine_ops)
WITH (
    m = 16,                -- Max number of bi-directional links per node
    ef_construction = 64   -- Size of dynamic candidate list during index build
);
```

### Dynamic Search Precision Tuning
At query execution time, the search candidate list depth (`ef_search`) is dynamically set per session to balance recall vs. latency:

```sql
-- Executed at the start of a RAG retrieval database session
SET LOCAL hnsw.ef_search = 40;
```

| Parameter | Default | Production Value | Trade-off / Impact |
| :--- | :---: | :---: | :--- |
| `m` | 16 | **16** | Higher values increase recall on complex queries at cost of index memory size. |
| `ef_construction` | 64 | **64** | Controls index creation time and initial graph connectivity quality. |
| `ef_search` | 40 | **40** | Higher values increase search accuracy (recall @ 10) at slight latency cost. |

---

## 4. Retrieval Algorithms

### A. Pure Vector Similarity Query (Cosine Distance)

```sql
SELECT 
    id, 
    source_title, 
    kanda_or_chapter, 
    sloka_number, 
    content,
    1 - (embedding <=> :query_vector) AS cosine_similarity
FROM document_chunks
WHERE 1 - (embedding <=> :query_vector) >= 0.65
ORDER BY embedding <=> :query_vector
LIMIT 10;
```

---

### B. Reciprocal Rank Fusion (RRF) Hybrid Search Query

Grahvani combines **BM25 keyword search** (via PostgreSQL GIN full-text search) with **dense vector similarity search** using Reciprocal Rank Fusion (RRF) to capture both exact sanskrit transliterated terms (e.g., *"Kalsarp Dasha"*, *"Jupiter in 10th house"*) and semantic context:

```sql
WITH vector_search AS (
    SELECT id, RANK() OVER (ORDER BY embedding <=> :query_vector) AS rank_vec
    FROM document_chunks
    ORDER BY embedding <=> :query_vector
    LIMIT 20
),
fts_search AS (
    SELECT id, RANK() OVER (ORDER BY ts_rank(fts_vector, websearch_to_tsquery('english', :search_text)) DESC) AS rank_fts
    FROM document_chunks
    WHERE fts_vector @@ websearch_to_tsquery('english', :search_text)
    ORDER BY ts_rank(fts_vector, websearch_to_tsquery('english', :search_text)) DESC
    LIMIT 20
)
SELECT 
    c.id,
    c.source_title,
    c.kanda_or_chapter,
    c.sloka_number,
    c.content,
    COALESCE(1.0 / (60 + v.rank_vec), 0.0) + COALESCE(1.0 / (60 + f.rank_fts), 0.0) AS rrf_score
FROM document_chunks c
LEFT JOIN vector_search v ON c.id = v.id
LEFT JOIN fts_search f ON c.id = f.id
WHERE v.id IS NOT NULL OR f.id IS NOT NULL
ORDER BY rrf_score DESC
LIMIT 10;
```

---

## 5. Performance Targets & SLA

- **Vector Query Latency**: < 15 ms (p95) over 100,000 document chunks.
- **Hybrid RRF Search Latency**: < 30 ms (p95).
- **Recall Target**: **Recall @ 10 > 96%** against brute-force exact cosine search baseline.
- **Index Build Overhead**: ~ 1.5 GB memory for 100,000 768-dim embeddings.

---

## 6. Related Documents

- [Database Design](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/DATABASE_DESIGN.md) — Main database architecture and connection pooling.
- [Indexing Strategy](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/database/INDEXING.md) — General database indexes (B-Tree, GIN, HNSW).
- [RAG Engine Specs](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/ai/RAG.md) — End-to-end AI RAG retrieval pipeline and prompt construction.
