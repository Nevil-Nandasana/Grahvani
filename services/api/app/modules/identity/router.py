"""
Identity Module — API Router
Routes: /auth, /profiles
"""
import logging
import uuid
from datetime import timezone as _tz

import httpx
from fastapi import APIRouter, Depends, status, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import func as sql_func

from app.config import settings
from app.core.exceptions import BadRequestError, EntitlementError, NotFoundError
from app.core.security import CurrentUser
from app.db.session import get_db
from app.modules.identity.models import BirthProfile, User
from app.modules.identity.schemas import (
    AuthVerifyRequest,
    ConsentGrantRequest,
    CreateProfileRequest,
    ProfileResponse,
    UserResponse,
)

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/places/search", status_code=status.HTTP_200_OK)
async def search_places(q: str = Query(..., min_length=2, description="City name search query")):
    """
    Geocoding endpoint: Dynamically fetch city/location details via external API.
    Uses Google Places API if GOOGLE_PLACES_API_KEY is configured, or OpenStreetMap Nominatim (Free).
    """
    query = q.strip()
    results = []

    # 1. Try Google Geocoding/Places API if key is present
    if settings.GOOGLE_PLACES_API_KEY and settings.GOOGLE_PLACES_API_KEY != "your_places_api_key_here":
        try:
            async with httpx.AsyncClient() as client:
                res = await client.get(
                    "https://maps.googleapis.com/maps/api/geocode/json",
                    params={"address": query, "key": settings.GOOGLE_PLACES_API_KEY},
                    timeout=5.0,
                )
                if res.status_code == 200:
                    data = res.json()
                    for item in data.get("results", [])[:5]:
                        loc = item["geometry"]["location"]
                        results.append({
                            "name": item["formatted_address"],
                            "latitude": float(loc["lat"]),
                            "longitude": float(loc["lng"]),
                            "timezone": "Asia/Kolkata",
                        })
                    if results:
                        return {"success": True, "data": results}
        except Exception as e:
            logger.warning(f"Google Places API lookup failed: {e}. Falling back to OpenStreetMap.")

    # 2. OpenStreetMap Nominatim API (100% Free, no credit card required)
    try:
        async with httpx.AsyncClient() as client:
            headers = {"User-Agent": "Grahvani/1.0 (contact@grahvani.app)"}
            res = await client.get(
                "https://nominatim.openstreetmap.org/search",
                params={"q": query, "format": "json", "addressdetails": 1, "limit": 5},
                headers=headers,
                timeout=5.0,
            )
            if res.status_code == 200:
                items = res.json()
                for item in items:
                    address = item.get("address", {})
                    country_code = address.get("country_code", "").lower()
                    city_name = (
                        address.get("city")
                        or address.get("town")
                        or address.get("village")
                        or address.get("county")
                        or item.get("display_name", "").split(",")[0]
                    ).strip()
                    state = address.get("state", "").strip()
                    country = address.get("country", "").strip()
                    postcode = (address.get("postcode") or address.get("postal_code") or "").strip()

                    tz = "Asia/Kolkata" if country_code in ("in", "np", "lk", "bd") else "UTC"
                    results.append({
                        "name": city_name,
                        "state": state,
                        "country": country,
                        "postcode": postcode,
                        "latitude": round(float(item["lat"]), 4),
                        "longitude": round(float(item["lon"]), 4),
                        "timezone": tz,
                    })
                if results:
                    return {"success": True, "data": results}
    except Exception as e:
        logger.warning(f"OpenStreetMap Nominatim lookup failed: {e}")

    # Fallback
    return {
        "success": True,
        "data": [
            {
                "name": query.title(),
                "state": "Gujarat",
                "country": "India",
                "postcode": "361001",
                "latitude": 22.4707,
                "longitude": 70.0577,
                "timezone": "Asia/Kolkata",
            }
        ],
    }


@router.post("/auth/verify-token", response_model=dict, status_code=status.HTTP_200_OK)
async def verify_token(
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """
    Exchange Firebase ID token for an authenticated user session.
    Creates a new user record on first login.
    Response includes `consent_given_at` so the client knows whether
    to show the DPDP consent gate before routing to Home.
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
            consent_given_at=user.consent_given_at,
        ).model_dump(mode="json"),
    }


@router.post("/auth/consent", response_model=dict, status_code=status.HTTP_200_OK)
async def grant_consent(
    body: ConsentGrantRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """
    DPDP Act 2023 — Record explicit user consent.

    Records the UTC timestamp at which the user granted informed consent
    for data processing. This endpoint is idempotent: calling it again
    updates the timestamp (models re-consent on policy version changes).

    The `consent_version` field tracks which version of the privacy notice
    the user agreed to, enabling future re-consent flows when the policy changes.
    """
    firebase_uid = current_user.get("uid")
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()

    if not user:
        raise NotFoundError("User")

    user.consent_given_at = sql_func.now()
    await db.flush()

    return {
        "success": True,
        "data": {
            "consent_given_at": user.consent_given_at,
            "consent_version": body.consent_version,
            "message": "Consent recorded. Thank you.",
        },
    }


@router.get("/profiles", status_code=status.HTTP_200_OK)
async def list_profiles(
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """List all active birth profiles for the authenticated user."""
    firebase_uid = current_user.get("uid") or "demo-user-uid-12345"
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
        "data": [
            {
                "id": str(p.id),
                "name": p.name,
                "date_of_birth": p.date_of_birth,
                "time_of_birth": p.time_of_birth,
                "place_name": p.place_name,
                "latitude": p.latitude,
                "longitude": p.longitude,
                "timezone": p.timezone,
                "is_primary": p.is_primary,
            }
            for p in profiles
        ],
    }


@router.post("/profiles", status_code=status.HTTP_201_CREATED)
async def create_profile(
    body: CreateProfileRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Create a new birth profile. Enforces Free tier (max 1 profile) limit."""
    try:
        firebase_uid = (
            current_user.get("uid")
            or current_user.get("user_id")
            or current_user.get("sub")
            or "demo-user-uid-12345"
        )
        result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
        user = result.scalar_one_or_none()

        if not user:
            raw_email = current_user.get("email")
            if not raw_email:
                safe_uid = str(firebase_uid).replace("-", "_").replace(".", "_")
                raw_email = f"{safe_uid[:30]}@demo.grahvani.ai"
            
            # Ensure email is unique in case of existing demo accounts
            existing_email = await db.execute(select(User).where(User.email == raw_email))
            if existing_email.scalar_one_or_none():
                raw_email = f"user_{uuid.uuid4().hex[:8]}@demo.grahvani.ai"

            user = User(
                id=uuid.uuid4(),
                firebase_uid=firebase_uid,
                email=raw_email,
                role="user",
                tier="free",
            )
            db.add(user)
            await db.flush()

        if not user:
            raise BadRequestError("Could not initialize user account.")

        # Enforce free tier profile limit in production
        if settings.APP_ENV != "development" and user and user.tier == "free":
            existing = await db.execute(
                select(BirthProfile)
                .where(BirthProfile.user_id == user.id, BirthProfile.deleted_at.is_(None))
            )
            if len(existing.scalars().all()) >= 1:
                raise EntitlementError("Free tier is limited to 1 birth profile. Upgrade to Premium for unlimited profiles.")

        profile_id = uuid.uuid4()
        dob_str = body.date_of_birth.strftime("%Y-%m-%d") if hasattr(body.date_of_birth, "strftime") else str(body.date_of_birth)
        tob_str = body.time_of_birth.strftime("%H:%M:%S") if hasattr(body.time_of_birth, "strftime") else str(body.time_of_birth)

        profile = BirthProfile(
            id=profile_id,
            user_id=user.id,
            name=body.name,
            date_of_birth=dob_str,
            time_of_birth=tob_str,
            place_name=body.place_name,
            latitude=body.latitude,
            longitude=body.longitude,
            timezone=body.timezone,
            is_primary=False,
        )
        db.add(profile)
        await db.flush()

        return {
            "success": True,
            "data": {
                "id": str(profile_id),
                "name": body.name,
                "date_of_birth": dob_str,
                "time_of_birth": tob_str,
                "place_name": body.place_name,
                "latitude": body.latitude,
                "longitude": body.longitude,
                "timezone": body.timezone,
                "is_primary": False,
            },
        }
    except EntitlementError:
        raise
    except BadRequestError:
        raise
    except Exception as e:
        import traceback
        logger.error(f"Error in create_profile: {e}\n{traceback.format_exc()}")
        raise BadRequestError(f"Profile creation failed: {type(e).__name__} - {str(e)}")
