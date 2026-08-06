"""
Notification API Routes
Endpoints for managing push notification preferences and FCM tokens.
"""
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.db.session import AsyncSessionLocal, get_db
from app.modules.identity.models import BirthProfile, User


router = APIRouter(prefix="/notifications", tags=["notifications"])


# ─── Pydantic Models ─────────────────────────────────────────────────────────
class FCMTokenRequest(BaseModel):
    fcm_token: str = Field(..., min_length=10, max_length=512)


class NotificationPreferencesRequest(BaseModel):
    transit_alerts: Optional[bool] = None
    sade_sati_alerts: Optional[bool] = None
    dasha_alerts: Optional[bool] = None
    major_transit_alerts: Optional[bool] = None
    quiet_hours_start: Optional[str] = None  # HH:MM format
    quiet_hours_end: Optional[str] = None    # HH:MM format


class NotificationPreferencesResponse(BaseModel):
    transit_alerts: bool
    sade_sati_alerts: bool
    dasha_alerts: bool
    major_transit_alerts: bool
    quiet_hours_start: str
    quiet_hours_end: str
    last_sade_sati_notification: dict
    last_dasha_notification: str


class ProfileNotificationStatusResponse(BaseModel):
    profile_id: str
    profile_name: str
    notification_enabled: bool
    preferences: NotificationPreferencesResponse


# ─── Endpoints ───────────────────────────────────────────────────────────────
@router.post("/fcm-token", status_code=status.HTTP_200_OK)
async def update_fcm_token(
    request: FCMTokenRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update the user's FCM token for push notifications."""
    current_user.fcm_token = request.fcm_token
    await db.commit()
    return {"message": "FCM token updated successfully"}


@router.get("/preferences/{profile_id}", response_model=ProfileNotificationStatusResponse)
async def get_notification_preferences(
    profile_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get notification preferences for a specific profile."""
    # Verify profile ownership
    stmt = select(BirthProfile).where(
        BirthProfile.id == profile_id,
        BirthProfile.user_id == current_user.id,
        BirthProfile.deleted_at.is_(None),
    )
    result = await db.execute(stmt)
    profile = result.scalar_one_or_none()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found",
        )
    
    prefs = profile.notification_preferences or {}
    return ProfileNotificationStatusResponse(
        profile_id=str(profile.id),
        profile_name=profile.name,
        notification_enabled=profile.notification_enabled,
        preferences=NotificationPreferencesResponse(
            transit_alerts=prefs.get("transit_alerts", True),
            sade_sati_alerts=prefs.get("sade_sati_alerts", True),
            dasha_alerts=prefs.get("dasha_alerts", True),
            major_transit_alerts=prefs.get("major_transit_alerts", True),
            quiet_hours_start=prefs.get("quiet_hours_start", "22:00"),
            quiet_hours_end=prefs.get("quiet_hours_end", "07:00"),
            last_sade_sati_notification=prefs.get("last_sade_sati_notification", {}),
            last_dasha_notification=prefs.get("last_dasha_notification", ""),
        ),
    )


@router.patch("/preferences/{profile_id}", response_model=ProfileNotificationStatusResponse)
async def update_notification_preferences(
    profile_id: UUID,
    request: NotificationPreferencesRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update notification preferences for a specific profile."""
    # Verify profile ownership
    stmt = select(BirthProfile).where(
        BirthProfile.id == profile_id,
        BirthProfile.user_id == current_user.id,
        BirthProfile.deleted_at.is_(None),
    )
    result = await db.execute(stmt)
    profile = result.scalar_one_or_none()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found",
        )
    
    # Merge preferences
    current_prefs = profile.notification_preferences or {}
    update_data = request.model_dump(exclude_unset=True)
    current_prefs.update(update_data)
    
    profile.notification_preferences = current_prefs
    await db.commit()
    
    return ProfileNotificationStatusResponse(
        profile_id=str(profile.id),
        profile_name=profile.name,
        notification_enabled=profile.notification_enabled,
        preferences=NotificationPreferencesResponse(
            transit_alerts=current_prefs.get("transit_alerts", True),
            sade_sati_alerts=current_prefs.get("sade_sati_alerts", True),
            dasha_alerts=current_prefs.get("dasha_alerts", True),
            major_transit_alerts=current_prefs.get("major_transit_alerts", True),
            quiet_hours_start=current_prefs.get("quiet_hours_start", "22:00"),
            quiet_hours_end=current_prefs.get("quiet_hours_end", "07:00"),
            last_sade_sati_notification=current_prefs.get("last_sade_sati_notification", {}),
            last_dasha_notification=current_prefs.get("last_dasha_notification", ""),
        ),
    )


@router.post("/preferences/{profile_id}/toggle", response_model=ProfileNotificationStatusResponse)
async def toggle_notifications(
    profile_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Toggle all notifications for a profile on/off."""
    stmt = select(BirthProfile).where(
        BirthProfile.id == profile_id,
        BirthProfile.user_id == current_user.id,
        BirthProfile.deleted_at.is_(None),
    )
    result = await db.execute(stmt)
    profile = result.scalar_one_or_none()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found",
        )
    
    profile.notification_enabled = not profile.notification_enabled
    await db.commit()
    
    prefs = profile.notification_preferences or {}
    return ProfileNotificationStatusResponse(
        profile_id=str(profile.id),
        profile_name=profile.name,
        notification_enabled=profile.notification_enabled,
        preferences=NotificationPreferencesResponse(
            transit_alerts=prefs.get("transit_alerts", True),
            sade_sati_alerts=prefs.get("sade_sati_alerts", True),
            dasha_alerts=prefs.get("dasha_alerts", True),
            major_transit_alerts=prefs.get("major_transit_alerts", True),
            quiet_hours_start=prefs.get("quiet_hours_start", "22:00"),
            quiet_hours_end=prefs.get("quiet_hours_end", "07:00"),
            last_sade_sati_notification=prefs.get("last_sade_sati_notification", {}),
            last_dasha_notification=prefs.get("last_dasha_notification", ""),
        ),
    )


@router.post("/test/{profile_id}")
async def send_test_notification(
    profile_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Send a test notification to verify FCM setup."""
    from app.tasks.transit_monitor import check_profile_transits_task
    
    stmt = select(BirthProfile).where(
        BirthProfile.id == profile_id,
        BirthProfile.user_id == current_user.id,
        BirthProfile.deleted_at.is_(None),
    )
    result = await db.execute(stmt)
    profile = result.scalar_one_or_none()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found",
        )
    
    if not current_user.fcm_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No FCM token registered. Please update your FCM token first.",
        )
    
    # Trigger on-demand transit check
    check_profile_transits_task.send(str(profile_id))
    
    return {"message": "Test notification triggered. Check your device."}


@router.get("/history/{profile_id}")
async def get_notification_history(
    profile_id: UUID,
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get notification history for a profile (placeholder for future implementation)."""
    # This would require a notification_log table
    # For now, return empty list with structure
    return {
        "notifications": [],
        "total": 0,
        "limit": limit,
        "offset": offset,
    }