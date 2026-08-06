"""Add pdf_status and pdf_url to birth_charts

Revision ID: 002_add_pdf_export_fields
Revises: 001_initial_schema
Create Date: 2026-08-06
"""
from alembic import op
import sqlalchemy as sa


revision = "002_add_pdf_export_fields"
down_revision = "001_initial_schema"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("birth_charts", sa.Column("pdf_status", sa.String(32), nullable=True))
    op.add_column("birth_charts", sa.Column("pdf_url", sa.String(512), nullable=True))


def downgrade() -> None:
    op.drop_column("birth_charts", "pdf_url")
    op.drop_column("birth_charts", "pdf_status")
