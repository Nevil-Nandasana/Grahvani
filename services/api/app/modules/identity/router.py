"""
Identity Module — API Router
Routes: /auth, /profiles
"""
import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import EntitlementError, NotFoundError
from app.core.security import CurrentUser
from app.db.session import get_db
from app.modules.identity.models import BirthProfile, User
from app.modules.identity.schemas import (
    AuthVerifyRequest,
    CreateProfileRequest,
    ProfileResponse,
    UserResponse,
)

router = APIRouter()


@router.post("/auth/verify-token", response_model=dict, status_code=status.HTTP_200_OK)
async def verify_token(
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """
    Exchange Firebase ID token for an authenticated user session.
    Creates a new user record on first login.
    """
    firebase_uid = current_user.get("uid")
    email = current_user.get("email")

    # Get or create user record
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    is_new_user = False

    if not user:
        user = User(firebase_uid=firebase_uid, email=email, role="user", tier="free")
        db.add(user)
        await db.flush()
        is_new_user = True

    return {
        "success": True,
        "data": UserResponse(
            user_id=user.id,
            email=user.email,
            role=user.role,
            tier=user.tier,
            is_new_user=is_new_user,
        ).model_dump(),
    }


@router.get("/profiles", status_code=status.HTTP_200_OK)
async def list_profiles(
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """List all active birth profiles for the authenticated user."""
    firebase_uid = current_user.get("uid")
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    if not user:
        return {"success": True, "data": []}

    result = await db.execute(
        select(BirthProfile)
        .where(BirthProfile.user_id == user.id, BirthProfile.deleted_at.is_(None))
        .order_by(BirthProfile.created_at.desc())
    )
    profiles = result.scalars().all()
    return {
        "success": True,
        "data": [ProfileResponse.model_validate(p).model_dump() for p in profiles],
    }


@router.post("/profiles", status_code=status.HTTP_201_CREATED)
async def create_profile(
    body: CreateProfileRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Create a new birth profile. Enforces Free tier (max 1 profile) limit."""
    firebase_uid = current_user.get("uid")
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()

    if not user:
        raise NotFoundError("User")

    # Enforce free tier profile limit
    if user.tier == "free":
        existing = await db.execute(
            select(BirthProfile)
            .where(BirthProfile.user_id == user.id, BirthProfile.deleted_at.is_(None))
        )
        if len(existing.scalars().all()) >= 1:
            raise EntitlementError("Free tier is limited to 1 birth profile. Upgrade to Premium for unlimited profiles.")

    profile = BirthProfile(
        user_id=user.id,
        name=body.name,
        date_of_birth=str(body.date_of_birth),
        time_of_birth=str(body.time_of_birth),
        place_name=body.place_name,
        latitude=body.latitude,
        longitude=body.longitude,
        timezone=body.timezone,
    )
    db.add(profile)
    await db.flush()

    return {"success": True, "data": ProfileResponse.model_validate(profile).model_dump()}
