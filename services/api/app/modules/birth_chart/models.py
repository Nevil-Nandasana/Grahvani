"""
Birth Chart Module — ORM Models
Tables: birth_charts
"""
import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin


class BirthChart(Base, TimestampMixin):
    __tablename__ = "birth_charts"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("birth_profiles.id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="pending"
        # Values: pending | calculating | complete | error
    )
    ayanamsa: Mapped[str] = mapped_column(String(64), nullable=False, default="lahiri")
    house_system: Mapped[str] = mapped_column(String(32), nullable=False, default="placidus")
    ephemeris_version: Mapped[str | None] = mapped_column(String(64), nullable=True)
    chart_facts_json: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    calculated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    pdf_status: Mapped[str | None] = mapped_column(String(32), nullable=True)
    pdf_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
