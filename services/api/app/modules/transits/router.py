"""
Transit API Routes — Endpoints for Sade Sati status, transit alerts, and planetary positions.
"""
from datetime import datetime, timezone, timedelta
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.core.security import CurrentUser
from app.db.session import get_db
from app.modules.birth_chart.ephemeris_service import calculate_chart
from app.modules.identity.models import BirthProfile
from app.tasks.transit_monitor import (
    _calculate_saturn_position,
    _get_moon_sign,
    _get_sade_sati_phase_description,
    _is_saturn_in_sade_sati,
)

router = APIRouter(prefix="", tags=["Transits & Sade Sati"])


# ─── Pydantic Models ─────────────────────────────────────────────────────────

class SadeSatiStatusResponse(BaseModel):
    is_sade_sati: bool = Field(..., description="Whether the user is currently in Sade Sati")
    phase: Optional[str] = Field(None, description="Current phase: first_phase, second_phase, third_phase")
    moon_sign: str = Field(..., description="User's Moon sign")
    saturn_sign: str = Field(..., description="Current Saturn sign")
    description: Optional[str] = Field(None, description="Human-readable description of the current phase")
    start_date: Optional[str] = Field(None, description="Estimated start date of current phase (YYYY-MM-DD)")
    end_date: Optional[str] = Field(None, description="Estimated end date of current phase (YYYY-MM-DD)")
    days_remaining: Optional[int] = Field(None, description="Estimated days remaining in current phase")


class TransitAlertRequest(BaseModel):
    transit_alerts: Optional[bool] = None
    sade_sati_alerts: Optional[bool] = None
    dasha_alerts: Optional[bool] = None
    major_transit_alerts: Optional[bool] = None


# ─── Helpers ──────────────────────────────────────────────────────────────────

async def _get_profile_for_user(profile_id: UUID, user_id: UUID, db: AsyncSession) -> BirthProfile:
    """Get a birth profile for the authenticated user."""
    stmt = select(BirthProfile).where(
        BirthProfile.id == profile_id,
        BirthProfile.user_id == user_id,
        BirthProfile.deleted_at.is_(None),
    )
    res = await db.execute(stmt)
    profile = res.scalar_one_or_none()
    if not profile:
        raise NotFoundError("Birth Profile")
    return profile


def _calculate_phase_dates(phase: str, moon_sign: str) -> tuple[Optional[str], Optional[str]]:
    """
    Calculate estimated start and end dates for a Sade Sati phase.
    Each phase lasts approximately 2.5 years.
    """
    if not phase or not moon_sign:
        return None, None
    
    # Each phase lasts ~2.5 years (913 days)
    phase_duration = timedelta(days=913)
    
    # Get current date in IST (UTC+5:30)
    now_utc = datetime.now(timezone.utc)
    ist_offset = timedelta(hours=5, minutes=30)
    now_ist = now_utc + ist_offset
    
    if phase == "first_phase":
        # First phase starts when Saturn enters 12th from Moon
        start_date = now_ist - timedelta(days=913 // 2)  # Middle of phase
        end_date = start_date + phase_duration
    elif phase == "second_phase":
        # Second phase starts when Saturn enters Moon sign
        start_date = now_ist - timedelta(days=913 // 2)
        end_date = start_date + phase_duration
    elif phase == "third_phase":
        # Third phase starts when Saturn enters 2nd from Moon
        start_date = now_ist - timedelta(days=913 // 2)
        end_date = start_date + phase_duration
    else:
        return None, None
    
    return start_date.strftime("%Y-%m-%d"), end_date.strftime("%Y-%m-%d")


# ─── Endpoints ───────────────────────────────────────────────────────────────

@router.get(
    "/sade-sati/{profile_id}",
    status_code=status.HTTP_200_OK,
    response_model=SadeSatiStatusResponse,
)
async def get_sade_sati_status(
    profile_id: UUID,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """
    Get current Sade Sati status for a birth profile.
    
    Returns:
        - Whether the user is currently in Sade Sati
        - Current phase (first_phase, second_phase, third_phase)
        - Moon sign and current Saturn sign
        - Human-readable description of the phase
        - Estimated start/end dates and days remaining
    """
    # Get profile
    profile = await _get_profile_for_user(profile_id, UUID(current_user["uid"]), db)
    
    # Get Moon sign from birth chart
    moon_sign = _get_moon_sign(profile)
    if not moon_sign:
        raise NotFoundError("Moon sign not found in birth chart")
    
    # Calculate current Saturn position
    now_utc = datetime.now(timezone.utc)
    ist_offset = timedelta(hours=5, minutes=30)
    now_ist = now_utc + ist_offset
    
    saturn = _calculate_saturn_position(
        year=now_ist.year,
        month=now_ist.month,
        day=now_ist.day,
        hour=12,  # Noon for consistency
        ayanamsa="lahiri",
    )
    saturn_sign = saturn.get("zodiac_sign", "")
    if not saturn_sign:
        raise NotFoundError("Saturn position not available")
    
    # Check Sade Sati status
    is_sade_sati, phase = _is_saturn_in_sade_sati(moon_sign, saturn_sign)
    description = _get_sade_sati_phase_description(phase) if phase else None
    
    # Calculate phase dates and days remaining
    start_date, end_date = _calculate_phase_dates(phase, moon_sign) if phase else (None, None)
    days_remaining = None
    if end_date:
        end_dt = datetime.strptime(end_date, "%Y-%m-%d").date()
        today = now_ist.date()
        days_remaining = (end_dt - today).days
    
    return {
        "is_sade_sati": is_sade_sati,
        "phase": phase,
        "moon_sign": moon_sign,
        "saturn_sign": saturn_sign,
        "description": description,
        "start_date": start_date,
        "end_date": end_date,
        "days_remaining": days_remaining,
    }