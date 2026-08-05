"""
Grahvani — SQLAlchemy Declarative Base
All ORM models import from this module.
"""
import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """
    SQLAlchemy declarative base for all Grahvani ORM models.
    Provides UUID primary keys and automatic UTC timestamps.
    """
    pass


class TimestampMixin:
    """Mixin that adds created_at and updated_at TIMESTAMPTZ columns to any model."""
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
