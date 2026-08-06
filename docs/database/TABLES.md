# Database Tables DDL Specification

## 1. Overview
This document contains the complete, production-ready PostgreSQL DDL for all **Grahvani** system tables. Each table is owned by exactly one backend domain module. Cross-module joins are prohibited in application code.

> [!IMPORTANT]
> All tables use UUID v4 primary keys (via `gen_random_uuid()`), `TIMESTAMPTZ` for all datetime fields (stored in UTC), and `CHECK` constraints for enumerated string columns. Every schema change must go through an Alembic migration.

---

## 2. PostgreSQL Extensions (Run Once)

```sql
-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgvector for 768-dim vector embeddings (RAG)
CREATE EXTENSION IF NOT EXISTS "vector";

-- Enable pg_trgm for trigram-based similarity search (city name autocomplete)
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
```

---

## 3. Identity Module Tables

```sql
-- ===================================================================
-- USERS TABLE — Core user identity, synced from Firebase Auth
-- Module: identity
-- ===================================================================
CREATE TABLE users (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid    VARCHAR(128) UNIQUE NOT NULL,           -- Firebase UID (immutable)
    email           VARCHAR(255),                           -- Nullable (phone-only users)
    phone_number    VARCHAR(32),                            -- E.164 format: +919876543210
    role            VARCHAR(32) NOT NULL DEFAULT 'user'
                    CHECK (role IN ('user', 'editor', 'admin')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at   TIMESTAMPTZ
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);

-- ===================================================================
-- BIRTH PROFILES TABLE — Personal birth details for chart generation
-- Module: identity
-- ===================================================================
CREATE TABLE birth_profiles (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    full_name       VARCHAR(100) NOT NULL,
    birth_date      DATE        NOT NULL CHECK (birth_date BETWEEN '1900-01-01' AND '2100-12-31'),
    birth_time      TIME,                                   -- NULL = "Time Unknown"
    time_unknown    BOOLEAN     NOT NULL DEFAULT false,
    latitude        DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90.0 AND 90.0),
    longitude       DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180.0 AND 180.0),
    timezone_id     VARCHAR(64) NOT NULL,                   -- IANA timezone e.g. 'Asia/Kolkata'
    city_name       VARCHAR(255),                           -- Human-readable city for display
    relationship    VARCHAR(32) NOT NULL DEFAULT 'self'
                    CHECK (relationship IN ('self', 'spouse', 'child', 'parent', 'friend', 'other')),
    deleted_at      TIMESTAMPTZ,                            -- Soft delete for DPDP compliance
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_birth_profiles_user_id ON birth_profiles(user_id);
CREATE INDEX idx_birth_profiles_deleted_at ON birth_profiles(deleted_at) WHERE deleted_at IS NULL;

-- ===================================================================
-- USER CONSENTS TABLE — DPDP Act explicit consent records
-- Module: identity
-- ===================================================================
CREATE TABLE user_consents (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consent_type    VARCHAR(64) NOT NULL                    -- 'data_processing', 'marketing_notifications'
                    CHECK (consent_type IN ('data_processing', 'marketing_notifications', 'analytics')),
    granted         BOOLEAN     NOT NULL,
    ip_address      INET,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ===================================================================
-- DEVICE TOKENS TABLE — FCM tokens for push notifications
-- Module: identity
-- ===================================================================
CREATE TABLE device_tokens (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token           VARCHAR(512) NOT NULL,
    platform        VARCHAR(16) NOT NULL CHECK (platform IN ('android', 'ios')),
    is_active       BOOLEAN     NOT NULL DEFAULT true,
    last_used_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_device_token UNIQUE (token)
);
```

---

## 4. Birth Chart Module Tables

```sql
-- ===================================================================
-- BIRTH CHARTS TABLE — Immutable chart snapshots (never updated)
-- Module: birth_chart
-- ===================================================================
CREATE TABLE birth_charts (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id      UUID        NOT NULL REFERENCES birth_profiles(id) ON DELETE CASCADE,
    ayanamsha_id    SMALLINT    NOT NULL DEFAULT 1,         -- 1=Lahiri, 2=Raman, 3=KP
    ayanamsha_name  VARCHAR(50) NOT NULL DEFAULT 'Lahiri',
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'calculating', 'complete', 'failed')),
    chart_facts_json JSONB,                                 -- NULL until status='complete'
    ephemeris_version VARCHAR(20),                          -- e.g., '2.10.3' for audit trail
    calculated_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Immutability: a profile + ayanamsha combination has exactly one chart
    CONSTRAINT unique_profile_ayanamsha UNIQUE (profile_id, ayanamsha_id)
);

CREATE INDEX idx_birth_charts_profile_id ON birth_charts(profile_id);
CREATE INDEX idx_birth_charts_status ON birth_charts(status);
-- GIN index on JSONB for efficient key-path queries
CREATE INDEX idx_birth_charts_json ON birth_charts USING GIN (chart_facts_json);
```

---

## 5. Astrology Content Module Tables (RAG Knowledge Base)

```sql
-- ===================================================================
-- SOURCE DOCUMENTS TABLE — Classical text metadata
-- Module: astrology_content
-- ===================================================================
CREATE TABLE source_documents (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(255) NOT NULL,
    abbreviation    VARCHAR(20) NOT NULL,                   -- e.g., 'BPHS', 'SAR'
    author          VARCHAR(255),
    translator      VARCHAR(255),
    s3_key          VARCHAR(512),                           -- Path to PDF in S3
    status          VARCHAR(20) NOT NULL DEFAULT 'staging'
                    CHECK (status IN ('staging', 'approved', 'deprecated')),
    ingested_version INT NOT NULL DEFAULT 1,
    approved_by     UUID REFERENCES users(id),
    approved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ===================================================================
-- DOCUMENT CHUNKS TABLE — Text chunks with vector embeddings for RAG
-- Module: astrology_content
-- ===================================================================
CREATE TABLE document_chunks (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id     UUID        NOT NULL REFERENCES source_documents(id) ON DELETE CASCADE,
    source_title    VARCHAR(255) NOT NULL,                  -- Denormalised for fast retrieval
    chapter         VARCHAR(100),
    verse_range     VARCHAR(50),                            -- e.g., '4-8' or 'Verse 12'
    content         TEXT        NOT NULL,
    topic_tags      TEXT[],                                 -- e.g., ['jupiter', '5th-house', 'children']
    metadata_json   JSONB,                                  -- Full chunk metadata blob
    embedding       VECTOR(768),                            -- Google text-embedding-004
    fts_vector      TSVECTOR GENERATED ALWAYS AS (to_tsvector('english', content)) STORED,
    staging         BOOLEAN     NOT NULL DEFAULT true,      -- true = not yet approved for production RAG
    deprecated      BOOLEAN     NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chunks_document_id ON document_chunks(document_id);
CREATE INDEX idx_chunks_fts ON document_chunks USING GIN (fts_vector);
CREATE INDEX idx_chunks_embedding_hnsw ON document_chunks
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
-- Partial index: only index non-staging, non-deprecated chunks for faster production search
CREATE INDEX idx_chunks_active_embedding ON document_chunks(id)
    WHERE staging = false AND deprecated = false;
```

---

## 6. Chat Module Tables

```sql
-- ===================================================================
-- CHAT SESSIONS TABLE — Conversation container per birth profile
-- Module: chat
-- ===================================================================
CREATE TABLE chat_sessions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    profile_id      UUID        NOT NULL REFERENCES birth_profiles(id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL DEFAULT 'New Conversation',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMPTZ
);

CREATE INDEX idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX idx_chat_sessions_profile_id ON chat_sessions(profile_id);
CREATE INDEX idx_chat_sessions_last_message ON chat_sessions(last_message_at DESC);

-- ===================================================================
-- CHAT MESSAGES TABLE — Individual turns in a conversation
-- Module: chat
-- ===================================================================
CREATE TABLE chat_messages (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID        NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    sender_type     VARCHAR(16) NOT NULL CHECK (sender_type IN ('user', 'assistant')),
    content         TEXT        NOT NULL,
    citations_json  JSONB,      -- [{"id": "chunk-uuid", "source": "BPHS", "chapter": "12"}]
    token_count     INT,        -- Stored for cost accounting
    prompt_version  VARCHAR(20),-- Which prompt template version generated this response
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_messages_session_id ON chat_messages(session_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(session_id, created_at DESC);
```

---

## 7. Billing Module Tables

```sql
-- ===================================================================
-- SUBSCRIPTIONS TABLE — Single source of truth for premium access
-- Module: billing
-- ===================================================================
CREATE TABLE subscriptions (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tier                    VARCHAR(32) NOT NULL DEFAULT 'free'
                            CHECK (tier IN ('free', 'premium')),
    status                  VARCHAR(32) NOT NULL DEFAULT 'active'
                            CHECK (status IN ('active', 'grace_period', 'canceled', 'paused', 'pending_activation')),
    provider                VARCHAR(32) NOT NULL
                            CHECK (provider IN ('none', 'google_play', 'app_store', 'razorpay')),
    external_subscription_id VARCHAR(255),                  -- Google order ID / Apple original txn ID / Razorpay sub ID
    current_period_start    TIMESTAMPTZ,
    current_period_end      TIMESTAMPTZ,
    grace_period_end        TIMESTAMPTZ,
    canceled_at             TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_active_sub UNIQUE (user_id)           -- One subscription record per user
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_external_id ON subscriptions(external_subscription_id);
CREATE INDEX idx_subscriptions_period_end ON subscriptions(current_period_end);

-- ===================================================================
-- WEBHOOK EVENTS TABLE — Idempotency log for store webhooks
-- Module: billing
-- ===================================================================
CREATE TABLE webhook_events (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    provider        VARCHAR(32) NOT NULL CHECK (provider IN ('google_play', 'app_store', 'razorpay')),
    event_id        VARCHAR(255) UNIQUE NOT NULL,            -- Provider-specific event/message ID
    event_type      VARCHAR(100) NOT NULL,                   -- e.g., 'SUBSCRIPTION_PURCHASED'
    payload_json    JSONB       NOT NULL,
    processed_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id         UUID REFERENCES users(id)
);

CREATE INDEX idx_webhook_events_event_id ON webhook_events(event_id);
CREATE INDEX idx_webhook_events_provider ON webhook_events(provider, processed_at DESC);
```

---

## 8. Admin Module Tables

```sql
-- ===================================================================
-- PROMPT TEMPLATES TABLE — Versioned AI prompt management
-- Module: admin
-- ===================================================================
CREATE TABLE prompt_templates (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(100) NOT NULL,               -- e.g., 'vedic_chat'
    version             VARCHAR(20) NOT NULL,                -- SemVer e.g., '1.2.0'
    system_prompt       TEXT        NOT NULL,
    user_prompt_template TEXT       NOT NULL,
    temperature         FLOAT       NOT NULL DEFAULT 0.2 CHECK (temperature BETWEEN 0.0 AND 1.0),
    max_output_tokens   INT         NOT NULL DEFAULT 600,
    is_active           BOOLEAN     NOT NULL DEFAULT false,
    deployed_at         TIMESTAMPTZ,
    deployed_by         UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_prompt_version UNIQUE (name, version)
);

-- Only one active template per name at any time
CREATE UNIQUE INDEX idx_one_active_prompt ON prompt_templates(name)
    WHERE is_active = true;

-- ===================================================================
-- ADMIN AUDIT LOGS TABLE — Immutable record of admin/system actions
-- Module: admin
-- ===================================================================
CREATE TABLE admin_audit_logs (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id   UUID REFERENCES users(id),
    action          VARCHAR(100) NOT NULL,                   -- e.g., 'APPROVE_DOCUMENT', 'DELETE_USER'
    resource_type   VARCHAR(50),                            -- e.g., 'source_document', 'user'
    resource_id     UUID,
    metadata_json   JSONB,
    ip_address      INET,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- Note: No UPDATE or DELETE permissions granted on this table (enforced via DB role)
CREATE INDEX idx_audit_logs_actor ON admin_audit_logs(actor_user_id, created_at DESC);
CREATE INDEX idx_audit_logs_resource ON admin_audit_logs(resource_type, resource_id);
```

---

## 9. Trigger for Auto-updating `updated_at` Columns

```sql
-- Reusable trigger function for all tables with updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all relevant tables
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_birth_profiles_updated_at
    BEFORE UPDATE ON birth_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```
