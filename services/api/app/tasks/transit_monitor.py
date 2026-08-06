"""
Dramatiq Task — Daily Transit Monitoring & Sade Sati Detection
Runs daily at 6 AM IST to check planetary transits and send push notifications.
"""
import asyncio
import uuid
from datetime import datetime, timezone, timedelta
from typing import Optional, List

import dramatiq
import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy import select

from app.config import settings
from app.db.session import AsyncSessionLocal
from app.modules.birth_chart.ephemeris_service import calculate_chart
from app.modules.identity.models import BirthProfile, User


# ─── FCM Initialization ───────────────────────────────────────────────────────
def _init_fcm():
    """Initialize Firebase Admin SDK if not already initialized."""
    if not firebase_admin._apps:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)


# ─── Transit Calculation Helpers ──────────────────────────────────────────────
def _calculate_planet_position(
    year: int, month: int, day: int,
    hour: int, minute: int, second: int,
    latitude: float, longitude: float,
    planet_name: str,
    ayanamsa: str = "lahiri",
) -> dict:
    """Calculate a single planet's position for a given date/time."""
    from app.modules.birth_chart.ephemeris_service import PLANETS, AYANAMSA_MAP, ZODIAC_SIGNS
    import swisseph as swe

    sid_mode = AYANAMSA_MAP.get(ayanamsa, swe.SIDM_LAHIRI)
    swe.set_sid_mode(sid_mode)

    jd = swe.julday(year, month, day, hour + minute / 60.0 + second / 3600.0)
    planet_id = PLANETS.get(planet_name)
    if not planet_id:
        return {}

    flags = swe.FLG_SWIEPH | swe.FLG_SIDEREAL
    pos, ret = swe.calc_ut(jd, planet_id, flags)
    sidereal_lon = pos[0]
    speed = pos[3]

    is_retrograde = speed < 0
    zodiac_index = int(sidereal_lon / 30)
    degree_in_sign = sidereal_lon % 30

    return {
        "name": planet_name,
        "longitude": round(sidereal_lon, 6),
        "zodiac_sign": ZODIAC_SIGNS[zodiac_index],
        "degree_in_sign": round(degree_in_sign, 4),
        "is_retrograde": is_retrograde,
        "julian_day": jd,
    }


def _calculate_saturn_position(
    year: int, month: int, day: int,
    hour: int = 12, minute: int = 0, second: int = 0,
    latitude: float = 0.0, longitude: float = 0.0,
    ayanamsa: str = "lahiri",
) -> dict:
    """Calculate Saturn position for a given date (defaults to noon UTC)."""
    return _calculate_planet_position(
        year, month, day, hour, minute, second,
        latitude, longitude, "Saturn", ayanamsa
    )


def _get_moon_sign(profile: BirthProfile) -> str:
    """Extract Moon's zodiac sign from calculated chart."""
    dob = profile.date_of_birth.split("-")
    tob = profile.time_of_birth.split(":")
    
    chart = calculate_chart(
        year=int(dob[0]), month=int(dob[1]), day=int(dob[2]),
        hour=int(tob[0]), minute=int(tob[1]), second=int(tob[2]) if len(tob) > 2 else 0,
        latitude=profile.latitude, longitude=profile.longitude,
        ayanamsa="lahiri",
    )
    
    for planet in chart.get("planets", []):
        if planet["name"] == "Moon":
            return planet["zodiac_sign"]
    return ""


# ─── Sade Sati Detection Logic ────────────────────────────────────────────────
ZODIAC_ORDER = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
]

def _get_zodiac_index(sign: str) -> int:
    """Get 0-based index of zodiac sign."""
    return ZODIAC_ORDER.index(sign) if sign in ZODIAC_ORDER else -1


def _is_saturn_in_sade_sati(moon_sign: str, saturn_sign: str) -> tuple[bool, Optional[str]]:
    """
    Check if Saturn is in Sade Sati position relative to Moon sign.
    
    Sade Sati occurs when Saturn transits through:
    - 12th house from Moon (previous sign)
    - 1st house from Moon (Moon sign itself)  
    - 2nd house from Moon (next sign)
    
    Returns: (is_in_sade_sati, phase)
    Phase can be: "first_phase", "second_phase", "third_phase", or None
    """
    moon_idx = _get_zodiac_index(moon_sign)
    saturn_idx = _get_zodiac_index(saturn_sign)
    
    if moon_idx == -1 or saturn_idx == -1:
        return False, None
    
    # Calculate relative position (0 = same sign, 1 = next sign, 11 = previous sign)
    diff = (saturn_idx - moon_idx) % 12
    
    if diff == 11:  # 12th from Moon
        return True, "first_phase"
    elif diff == 0:  # Moon sign itself
        return True, "second_phase"
    elif diff == 1:  # 2nd from Moon
        return True, "third_phase"
    
    return False, None


def _get_sade_sati_phase_description(phase: str) -> str:
    """Get human-readable description of Sade Sati phase."""
    descriptions = {
        "first_phase": "Saturn is transiting the 12th house from your Moon sign. This is the first phase of Sade Sati — a time of preparation and inner work.",
        "second_phase": "Saturn is transiting directly over your Moon sign. This is the peak phase of Sade Sati — intense transformation and karmic lessons.",
        "third_phase": "Saturn is transiting the 2nd house from your Moon sign. This is the final phase of Sade Sati — integration and harvesting results.",
    }
    return descriptions.get(phase, "")


# ─── Dasha Change Detection ───────────────────────────────────────────────────
def _get_current_dasha(profile: BirthProfile) -> Optional[dict]:
    """Get the currently active Maha Dasha from calculated chart."""
    dob = profile.date_of_birth.split("-")
    tob = profile.time_of_birth.split(":")
    
    chart = calculate_chart(
        year=int(dob[0]), month=int(dob[1]), day=int(dob[2]),
        hour=int(tob[0]), minute=int(tob[1]), second=int(tob[2]) if len(tob) > 2 else 0,
        latitude=profile.latitude, longitude=profile.longitude,
    )
    
    vimshottari = chart.get("vimshottari_dasha", {})
    maha_dashas = vimshottari.get("maha_dashas", [])
    
    today = datetime.now().date()
    for maha in maha_dashas:
        start = datetime.strptime(maha["start_date"], "%Y-%m-%d").date()
        end = datetime.strptime(maha["end_date"], "%Y-%m-%d").date()
        if start <= today <= end:
            return {
                "type": "maha",
                "planet": maha["planet"],
                "start_date": maha["start_date"],
                "end_date": maha["end_date"],
            }
    
    return None


def _check_dasha_transition(profile: BirthProfile) -> Optional[dict]:
    """Check if a Dasha transition is happening soon (within 30 days)."""
    dob = profile.date_of_birth.split("-")
    tob = profile.time_of_birth.split(":")
    
    chart = calculate_chart(
        year=int(dob[0]), month=int(dob[1]), day=int(dob[2]),
        hour=int(tob[0]), minute=int(tob[1]), second=int(tob[2]) if len(tob) > 2 else 0,
        latitude=profile.latitude, longitude=profile.longitude,
    )
    
    vimshottari = chart.get("vimshottari_dasha", {})
    maha_dashas = vimshottari.get("maha_dashas", [])
    
    today = datetime.now().date()
    soon = today + timedelta(days=30)
    
    for maha in maha_dashas:
        start = datetime.strptime(maha["start_date"], "%Y-%m-%d").date()
        end = datetime.strptime(maha["end_date"], "%Y-%m-%d").date()
        
        # Check if a new Maha Dasha starts within 30 days
        if today < start <= soon:
            return {
                "type": "maha_change",
                "from_planet": None,
                "to_planet": maha["planet"],
                "transition_date": maha["start_date"],
                "days_until": (start - today).days,
            }
        
        # Check if current Maha Dasha ends within 30 days
        if today <= end <= soon:
            return {
                "type": "maha_ending",
                "planet": maha["planet"],
                "end_date": maha["end_date"],
                "days_until": (end - today).days,
            }
    
    return None


# ─── Push Notification Sender ─────────────────────────────────────────────────
async def _send_fcm_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: dict,
    profile_id: str,
) -> bool:
    """Send FCM notification to a device token."""
    try:
        _init_fcm()
        
        message = messaging.Message(
            token=fcm_token,
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data={**data, "profile_id": profile_id, "timestamp": datetime.now(timezone.utc).isoformat()},
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="transit_alerts",
                    icon="ic_notification",
                    color="#7C6EFA",
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        alert=messaging.ApsAlert(title=title, body=body),
                        sound="default",
                        badge=1,
                    ),
                ),
            ),
        )
        
        response = messaging.send(message)
        return True
    except messaging.UnregisteredError:
        # Token is invalid/unregistered - should be cleaned up
        return False
    except Exception as e:
        # Log error but don't fail the whole task
        print(f"FCM send error for {fcm_token}: {e}")
        return False


# ─── Main Daily Transit Monitoring Task ───────────────────────────────────────
@dramatiq.actor(queue_name="transit", max_retries=2, time_limit=600_000)
def daily_transit_monitor_task() -> None:
    """
    Daily Dramatiq task that runs at 6 AM IST:
    1. Fetches all active profiles with notification preferences enabled
    2. Calculates current Saturn position
    3. Checks Sade Sati status for each profile
    4. Checks Dasha transitions
    5. Sends FCM notifications for relevant events
    """
    asyncio.run(_daily_transit_monitor_async())


async def _daily_transit_monitor_async() -> None:
    async with AsyncSessionLocal() as db:
        # Fetch all active profiles with notification preferences
        stmt = select(BirthProfile).where(
            BirthProfile.deleted_at.is_(None),
            BirthProfile.notification_enabled == True,  # Will add this column
        )
        result = await db.execute(stmt)
        profiles: List[BirthProfile] = result.scalars().all()
        
        if not profiles:
            return
        
        # Calculate current Saturn position (once per day)
        now_utc = datetime.now(timezone.utc)
        # Convert to IST for date calculation (IST = UTC+5:30)
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
            return
        
        # Process each profile
        for profile in profiles:
            await _process_profile_notifications(db, profile, saturn_sign, now_utc)
        
        await db.commit()


async def _process_profile_notifications(
    db, 
    profile: BirthProfile, 
    saturn_sign: str, 
    now_utc: datetime
) -> None:
    """Process notifications for a single profile."""
    # Get user with FCM token
    user_stmt = select(User).where(User.id == profile.user_id)
    user_result = await db.execute(user_stmt)
    user = user_result.scalar_one_or_none()
    
    if not user or not user.fcm_token:
        return
    
    # Check notification preferences
    prefs = profile.notification_preferences or {}
    if not prefs.get("transit_alerts", True):
        return
    
    # Get Moon sign from birth chart
    moon_sign = _get_moon_sign(profile)
    if not moon_sign:
        return
    
    # ─── Check Sade Sati ─────────────────────────────────────────────────
    if prefs.get("sade_sati_alerts", True):
        is_sade_sati, phase = _is_saturn_in_sade_sati(moon_sign, saturn_sign)
        
        if is_sade_sati:
            # Check if we already sent notification for this phase recently
            last_notified = prefs.get("last_sade_sati_notification", {})
            phase_key = f"{phase}_{moon_sign}"
            
            if last_notified.get(phase_key) != now_utc.date().isoformat():
                title = f"🪐 Sade Sati Alert: {phase.replace('_', ' ').title()}"
                body = _get_sade_sati_phase_description(phase)
                
                data = {
                    "type": "sade_sati",
                    "phase": phase,
                    "moon_sign": moon_sign,
                    "saturn_sign": saturn_sign,
                    "profile_name": profile.name,
                }
                
                sent = await _send_fcm_notification(
                    fcm_token=user.fcm_token,
                    title=title,
                    body=body,
                    data=data,
                    profile_id=str(profile.id),
                )
                
                if sent:
                    # Update last notification date
                    last_notified[phase_key] = now_utc.date().isoformat()
                    prefs["last_sade_sati_notification"] = last_notified
                    profile.notification_preferences = prefs
    
    # ─── Check Dasha Transitions ─────────────────────────────────────────
    if prefs.get("dasha_alerts", True):
        transition = _check_dasha_transition(profile)
        
        if transition:
            # Check if we already notified about this transition
            last_dasha_notified = prefs.get("last_dasha_notification", "")
            transition_key = f"{transition['type']}_{transition.get('to_planet', transition.get('planet'))}_{transition['transition_date']}"
            
            if last_dasha_notified != transition_key:
                if transition["type"] == "maha_change":
                    title = f"🔮 New Maha Dasha Starting Soon"
                    body = f"{transition['to_planet']} Maha Dasha begins in {transition['days_until']} days ({transition['transition_date']})"
                else:  # maha_ending
                    title = f"🔮 Current Maha Dasha Ending Soon"
                    body = f"{transition['planet']} Maha Dasha ends in {transition['days_until']} days ({transition['end_date']})"
                
                data = {
                    "type": "dasha_transition",
                    "transition_type": transition["type"],
                    "planet": transition.get("to_planet") or transition.get("planet"),
                    "date": transition.get("transition_date") or transition.get("end_date"),
                    "days_until": transition["days_until"],
                    "profile_name": profile.name,
                }
                
                sent = await _send_fcm_notification(
                    fcm_token=user.fcm_token,
                    title=title,
                    body=body,
                    data=data,
                    profile_id=str(profile.id),
                )
                
                if sent:
                    prefs["last_dasha_notification"] = transition_key
                    profile.notification_preferences = prefs
    
    # ─── Check Major Transits (Jupiter, Rahu/Ketu) ───────────────────────
    if prefs.get("major_transit_alerts", True):
        # Could add Jupiter return, Rahu/Ketu transit alerts here
        pass


# ─── On-Demand Transit Check Task ────────────────────────────────────────────
@dramatiq.actor(queue_name="transit", max_retries=1, time_limit=60_000)
def check_profile_transits_task(profile_id: str) -> None:
    """
    On-demand task to check transits for a specific profile.
    Triggered when user opens app or manually requests update.
    """
    asyncio.run(_check_profile_transits_async(profile_id))


async def _check_profile_transits_async(profile_id: str) -> None:
    async with AsyncSessionLocal() as db:
        profile = await db.get(BirthProfile, uuid.UUID(profile_id))
        if not profile or profile.deleted_at:
            return
        
        user_stmt = select(User).where(User.id == profile.user_id)
        user_result = await db.execute(user_stmt)
        user = user_result.scalar_one_or_none()
        
        if not user or not user.fcm_token:
            return
        
        # Calculate current positions
        now_utc = datetime.now(timezone.utc)
        ist_offset = timedelta(hours=5, minutes=30)
        now_ist = now_utc + ist_offset
        
        saturn = _calculate_saturn_position(
            year=now_ist.year, month=now_ist.month, day=now_ist.day,
            ayanamsa="lahiri",
        )
        
        if saturn.get("zodiac_sign"):
            await _process_profile_notifications(db, profile, saturn["zodiac_sign"], now_utc)
            await db.commit()