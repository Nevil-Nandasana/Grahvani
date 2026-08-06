"""
Identity Module — ORM Models
Tables: users, birth_profiles
"""
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, String, Text, func, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    firebase_uid: Mapped[str] = mapped_column(String(128), unique=True, nullable=False, index=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True)
    phone_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    display_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    role: Mapped[str] = mapped_column(String(32), nullable=False, default="user")
    tier: Mapped[str] = mapped_column(String(32), nullable=False, default="free")
    consent_given_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    fcm_token: Mapped[str | None] = mapped_column(String(512), nullable=True)  # For push notifications

    profiles: Mapped[list["BirthProfile"]] = relationship("BirthProfile", back_populates="user")


class BirthProfile(Base, TimestampMixin):
    __tablename__ = "birth_profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    date_of_birth: Mapped[str] = mapped_column(String(10), nullable=False)   # YYYY-MM-DD
    time_of_birth: Mapped[str] = mapped_column(String(8), nullable=False)    # HH:MM:SS
    place_name: Mapped[str] = mapped_column(String(255), nullable=False)
    latitude: Mapped[float] = mapped_column(nullable=False)
    longitude: Mapped[float] = mapped_column(nullable=False)
    timezone: Mapped[str] = mapped_column(String(64), nullable=False)
    is_primary: Mapped[bool] = mapped_column(default=False, nullable=False)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    
    # Notification preferences (JSON for flexibility)
    notification_enabled: Mapped[bool] = mapped_column(default=True, nullable=False)
    notification_preferences: Mapped[dict] = mapped_column(JSON, nullable=True, default={
        "transit_alerts": True,
        "sade_sati_alerts": True,
        "dasha_alerts": True,
        "major_transit_alerts": True,
        "quiet_hours_start": "22:00",
        "quiet_hours_end": "07:00",
        "last_sade_sati_notification": {},
        "last_dasha_notification": "",
    })

    user: Mapped["User"] = relationship("User", back_populates="profiles")