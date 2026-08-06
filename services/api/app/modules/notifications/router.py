"""
Notification API Routes — Endpoints for FCM tokens and per-profile notification preferences.
"""
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError, BadRequestError
from app.core.security import CurrentUser
from app.db.session import get_db
from app.modules.identity.models import BirthProfile, User

router = APIRouter(prefix="/notifications", tags=["Notifications & User Settings"])


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
    transit_alerts: bool = True
    sade_sati_alerts: bool = True
    dasha_alerts: bool = True
    major_transit_alerts: bool = True
    quiet_hours_start: str = "22:00"
    quiet_hours_end: str = "07:00"
    last_sade_sati_notification: dict = Field(default_factory=dict)
    last_dasha_notification: str = ""


class ProfileNotificationStatusResponse(BaseModel):
    profile_id: str
    profile_name: str
    notification_enabled: bool
    preferences: NotificationPreferencesResponse


# ─── Helpers ──────────────────────────────────────────────────────────────────

async def _get_authenticated_user(current_user: CurrentUser, db: AsyncSession) -> User:
    firebase_uid = current_user.get("uid")
    res = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = res.scalar_one_or_none()
    if not user:
        raise NotFoundError("User")
    return user


async def _get_profile_for_user(profile_id: UUID, user_id: UUID, db: AsyncSession) -> BirthProfile:
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


def _build_status_response(profile: BirthProfile) -> dict:
    prefs = profile.notification_preferences or {}
    return {
        "profile_id": str(profile.id),
        "profile_name": profile.name,
        "notification_enabled": profile.notification_enabled,
        "preferences": {
            "transit_alerts": prefs.get("transit_alerts", True),
            "sade_sati_alerts": prefs.get("sade_sati_alerts", True),
            "dasha_alerts": prefs.get("dasha_alerts", True),
            "major_transit_alerts": prefs.get("major_transit_alerts", True),
            "quiet_hours_start": prefs.get("quiet_hours_start", "22:00"),
            "quiet_hours_end": prefs.get("quiet_hours_end", "07:00"),
            "last_sade_sati_notification": prefs.get("last_sade_sati_notification", {}),
            "last_dasha_notification": prefs.get("last_dasha_notification", ""),
        },
    }


# ─── Endpoints ───────────────────────────────────────────────────────────────

@router.post("/fcm-token", status_code=status.HTTP_200_OK)
async def update_fcm_token(
    request: FCMTokenRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Update or register the user's Firebase Cloud Messaging (FCM) token."""
    user = await _get_authenticated_user(current_user, db)
    user.fcm_token = request.fcm_token
    await db.commit()
    return {"success": True, "data": {"message": "FCM token updated successfully"}}


@router.get("/preferences/{profile_id}", status_code=status.HTTP_200_OK)
async def get_notification_preferences(
    profile_id: UUID,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Get push notification preferences for a specific birth profile."""
    user = await _get_authenticated_user(current_user, db)
    profile = await _get_profile_for_user(profile_id, user.id, db)
    return {"success": True, "data": _build_status_response(profile)}


@router.patch("/preferences/{profile_id}", status_code=status.HTTP_200_OK)
async def update_notification_preferences(
    profile_id: UUID,
    request: NotificationPreferencesRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Update notification preferences (alerts, quiet hours) for a profile."""
    user = await _get_authenticated_user(current_user, db)
    profile = await _get_profile_for_user(profile_id, user.id, db)

    current_prefs = profile.notification_preferences or {}
    update_data = request.model_dump(exclude_unset=True)
    current_prefs.update(update_data)

    profile.notification_preferences = current_prefs
    await db.commit()

    return {"success": True, "data": _build_status_response(profile)}


@router.post("/preferences/{profile_id}/toggle", status_code=status.HTTP_200_OK)
async def toggle_notifications(
    profile_id: UUID,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Toggle master push notification enabled setting for a profile on/off."""
    user = await _get_authenticated_user(current_user, db)
    profile = await _get_profile_for_user(profile_id, user.id, db)

    profile.notification_enabled = not profile.notification_enabled
    await db.commit()

    return {"success": True, "data": _build_status_response(profile)}


@router.post("/test/{profile_id}", status_code=status.HTTP_200_OK)
async def send_test_notification(
    profile_id: UUID,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Send a test push notification to verify FCM setup."""
    from app.tasks.transit_monitor import check_profile_transits_task

    user = await _get_authenticated_user(current_user, db)
    profile = await _get_profile_for_user(profile_id, user.id, db)

    if not user.fcm_token:
        raise BadRequestError("No FCM token registered. Please update your FCM token first.")

    check_profile_transits_task.send(str(profile.id))
    return {"success": True, "data": {"message": "Test notification triggered. Check your device."}}


@router.get("/history/{profile_id}", status_code=status.HTTP_200_OK)
async def get_notification_history(
    profile_id: UUID,
    limit: int = 50,
    offset: int = 0,
    current_user: CurrentUser = Depends(CurrentUser),
    db: AsyncSession = Depends(get_db),
):
    """Get notification history for a profile."""
    user = await _get_authenticated_user(current_user, db)
    await _get_profile_for_user(profile_id, user.id, db)
    return {
        "success": True,
        "data": {
            "notifications": [],
            "total": 0,
            "limit": limit,
            "offset": offset,
        },
    }