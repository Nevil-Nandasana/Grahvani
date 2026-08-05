"""Initial schema — Grahvani complete database DDL

Revision ID: 001_initial_schema
Revises: (none)
Create Date: 2026-08-05
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, JSONB
from pgvector.sqlalchemy import Vector

revision = "001_initial_schema"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Enable Extensions ────────────────────────────────────────────────────
    op.execute("CREATE EXTENSION IF NOT EXISTS vector;")
    op.execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";")

    # ── users ────────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("firebase_uid", sa.String(128), nullable=False, unique=True),
        sa.Column("email", sa.String(255), nullable=True, unique=True),
        sa.Column("phone_number", sa.String(20), nullable=True),
        sa.Column("display_name", sa.String(100), nullable=True),
        sa.Column("role", sa.String(32), nullable=False, server_default="user"),
        sa.Column("tier", sa.String(32), nullable=False, server_default="free"),
        sa.Column("consent_given_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("idx_users_firebase_uid", "users", ["firebase_uid"])

    # ── birth_profiles ───────────────────────────────────────────────────────
    op.create_table(
        "birth_profiles",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("date_of_birth", sa.String(10), nullable=False),
        sa.Column("time_of_birth", sa.String(8), nullable=False),
        sa.Column("place_name", sa.String(255), nullable=False),
        sa.Column("latitude", sa.Numeric(8, 5), nullable=False),
        sa.Column("longitude", sa.Numeric(8, 5), nullable=False),
        sa.Column("timezone", sa.String(64), nullable=False),
        sa.Column("is_primary", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("idx_birth_profiles_user_id", "birth_profiles", ["user_id"])
    op.create_index("idx_birth_profiles_user_active", "birth_profiles", ["user_id"],
                    postgresql_where=sa.text("deleted_at IS NULL"))

    # ── birth_charts ─────────────────────────────────────────────────────────
    op.create_table(
        "birth_charts",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("profile_id", UUID(as_uuid=True), sa.ForeignKey("birth_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("status", sa.String(32), nullable=False, server_default="pending"),
        sa.Column("ayanamsa", sa.String(64), nullable=False, server_default="lahiri"),
        sa.Column("house_system", sa.String(32), nullable=False, server_default="placidus"),
        sa.Column("ephemeris_version", sa.String(64), nullable=True),
        sa.Column("chart_facts_json", JSONB, nullable=True),
        sa.Column("error_message", sa.Text, nullable=True),
        sa.Column("calculated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("idx_birth_charts_profile_id", "birth_charts", ["profile_id"])

    # ── document_chunks (pgvector RAG store) ─────────────────────────────────
    op.create_table(
        "document_chunks",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("source_title", sa.String(255), nullable=False),
        sa.Column("author", sa.String(255), nullable=False, server_default="Traditional"),
        sa.Column("kanda_or_chapter", sa.String(255), nullable=True),
        sa.Column("sloka_number", sa.String(64), nullable=True),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("token_count", sa.Integer, nullable=False),
        sa.Column("embedding", Vector(768), nullable=False),
        sa.Column("fts_vector", sa.Text, nullable=True),  # Managed by trigger
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # HNSW vector similarity index for sub-15ms cosine distance search
    op.execute("""
        CREATE INDEX idx_document_chunks_embedding_hnsw
        ON document_chunks USING hnsw (embedding vector_cosine_ops)
        WITH (m = 16, ef_construction = 64);
    """)

    # GIN full-text search index
    op.execute("""
        ALTER TABLE document_chunks
        ADD COLUMN fts_vector_col tsvector
        GENERATED ALWAYS AS (to_tsvector('english', source_title || ' ' || content)) STORED;
    """)
    op.execute("CREATE INDEX idx_document_chunks_fts ON document_chunks USING GIN(fts_vector_col);")

    # ── subscriptions ────────────────────────────────────────────────────────
    op.create_table(
        "subscriptions",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("provider", sa.String(32), nullable=False),  # razorpay | google_play | apple
        sa.Column("external_subscription_id", sa.String(255), nullable=True, unique=True),
        sa.Column("status", sa.String(32), nullable=False, server_default="active"),
        sa.Column("tier", sa.String(32), nullable=False, server_default="premium"),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("idx_subscriptions_user_id", "subscriptions", ["user_id"])
    op.create_index("idx_subscriptions_active", "subscriptions", ["user_id"],
                    postgresql_where=sa.text("status = 'active'"))

    # ── chat_sessions ────────────────────────────────────────────────────────
    op.create_table(
        "chat_sessions",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("chart_id", UUID(as_uuid=True), sa.ForeignKey("birth_charts.id"), nullable=True),
        sa.Column("title", sa.String(255), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("idx_chat_sessions_user_id", "chat_sessions", ["user_id"])

    # ── chat_messages ────────────────────────────────────────────────────────
    op.create_table(
        "chat_messages",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("session_id", UUID(as_uuid=True), sa.ForeignKey("chat_sessions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("role", sa.String(16), nullable=False),  # user | assistant
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("citations_json", JSONB, nullable=True),
        sa.Column("tokens_used", sa.Integer, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("idx_chat_messages_session_created", "chat_messages", ["session_id", "created_at"])


def downgrade() -> None:
    op.drop_table("chat_messages")
    op.drop_table("chat_sessions")
    op.drop_table("subscriptions")
    op.drop_table("document_chunks")
    op.drop_table("birth_charts")
    op.drop_table("birth_profiles")
    op.drop_table("users")
