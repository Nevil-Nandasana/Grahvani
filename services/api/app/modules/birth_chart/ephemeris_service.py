"""
Birth Chart Module — Swiss Ephemeris Calculation Service
Wraps pyswisseph for deterministic planetary position calculations
and computes the complete Vimshottari Dasha timeline (Maha, Antar, Pratyantar).
"""
import swisseph as swe
from datetime import datetime, timezone, timedelta

# ─── Ayanamsa Constants ───────────────────────────────────────────────────────
AYANAMSA_MAP = {
    "lahiri":        swe.SIDM_LAHIRI,
    "raman":         swe.SIDM_RAMAN,
    "krishnamurti":  swe.SIDM_KRISHNAMURTHY,
    "fagan_bradley": swe.SIDM_FAGAN_BRADLEY,
}

# ─── Planet Constants ─────────────────────────────────────────────────────────
PLANETS = {
    "Sun":     swe.SUN,
    "Moon":    swe.MOON,
    "Mars":    swe.MARS,
    "Mercury": swe.MERCURY,
    "Jupiter": swe.JUPITER,
    "Venus":   swe.VENUS,
    "Saturn":  swe.SATURN,
    "Rahu":    swe.MEAN_NODE,  # North Node (Rahu)
}

NAKSHATRAS = [
    "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra",
    "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni", "Uttara Phalguni",
    "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha", "Jyeshtha",
    "Mula", "Purva Ashadha", "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
    "Purva Bhadrapada", "Uttara Bhadrapada", "Revati",
]

ZODIAC_SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
]

# ─── Vimshottari Dasha Constants ──────────────────────────────────────────────

# The 9-planet sequence in Vimshottari order (Ketu first).
VIMSHOTTARI_SEQUENCE = [
    "Ketu", "Venus", "Sun", "Moon", "Mars",
    "Rahu", "Jupiter", "Saturn", "Mercury",
]

# Duration of each planet's Maha Dasha in years (total = 120 years).
VIMSHOTTARI_YEARS: dict[str, int] = {
    "Ketu":    7,
    "Venus":   20,
    "Sun":     6,
    "Moon":    10,
    "Mars":    7,
    "Rahu":    18,
    "Jupiter": 16,
    "Saturn":  19,
    "Mercury": 17,
}

VIMSHOTTARI_TOTAL_YEARS = 120  # Sum of all Maha Dasha years.

# Nakshatra lord mapping (index 0 = Ashwini → Ketu, repeats every 9 across 27 nakshatras).
_NAKSHATRA_LORDS = [
    "Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury",  # 0-8
    "Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury",  # 9-17
    "Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury",  # 18-26
]

# Degrees per nakshatra (360 / 27)
_NAKSHATRA_SPAN = 360.0 / 27.0


def _get_nakshatra(longitude: float) -> tuple[str, int]:
    """Return nakshatra name and pada (1–4) for a given sidereal longitude."""
    nak_index = int(longitude / _NAKSHATRA_SPAN) % 27
    pada = int((longitude % _NAKSHATRA_SPAN) / (_NAKSHATRA_SPAN / 4)) + 1
    return NAKSHATRAS[nak_index], pada


def _jd_to_date(jd: float) -> str:
    """Convert a Julian Day number to an ISO-8601 date string (YYYY-MM-DD)."""
    # swe.revjul returns (year, month, day, hour_decimal) in Gregorian
    y, m, d, _ = swe.revjul(jd, swe.GREG_CAL)
    return f"{int(y):04d}-{int(m):02d}-{int(d):02d}"


def _years_to_days(years: float) -> float:
    """Convert tropical years to days using the standard 365.25 days/year."""
    return years * 365.25


# ─── Vimshottari Dasha Engine ─────────────────────────────────────────────────

def calculate_vimshottari_dasha(moon_longitude: float, birth_jd: float) -> dict:
    """
    Calculate the complete Vimshottari Dasha timeline from Moon's sidereal longitude
    and the birth Julian Day number.

    The algorithm:
    1.  Determine Moon's birth nakshatra index (0-26).
    2.  Compute the elapsed fraction within that nakshatra.
    3.  The remaining (balance) Maha Dasha = lord_years × (1 - elapsed_fraction).
    4.  Build 9 sequential Maha Dasha periods starting from the balance.
    5.  Inside each Maha Dasha, build 9 Antar Dasha sub-periods.
    6.  Inside each Antar Dasha, build 9 Pratyantar Dasha sub-sub-periods.

    All dates are ISO-8601 strings (YYYY-MM-DD). Durations are in fractional years.

    Args:
        moon_longitude: Sidereal longitude of the Moon in degrees (0–360).
        birth_jd: Julian Day number of the birth moment (UTC).

    Returns:
        dict: Structured Vimshottari dasha data with maha_dashas list.
    """
    # ── 1. Birth nakshatra & dasha balance ─────────────────────────────────
    nak_index = int(moon_longitude / _NAKSHATRA_SPAN) % 27
    birth_nakshatra = NAKSHATRAS[nak_index]
    birth_lord = _NAKSHATRA_LORDS[nak_index]

    # Fraction of the nakshatra already traversed at birth (0.0 – 1.0)
    elapsed_in_nak = (moon_longitude % _NAKSHATRA_SPAN) / _NAKSHATRA_SPAN
    remaining_fraction = 1.0 - elapsed_in_nak

    birth_lord_total_years = VIMSHOTTARI_YEARS[birth_lord]
    balance_years = birth_lord_total_years * remaining_fraction

    # ── 2. Build the starting position in the Vimshottari sequence ─────────
    start_idx = VIMSHOTTARI_SEQUENCE.index(birth_lord)

    # ── 3. Generate 9 Maha Dashas ───────────────────────────────────────────
    maha_dashas = []
    cursor_jd = birth_jd  # Running cursor in Julian Days

    for i in range(9):
        seq_idx = (start_idx + i) % 9
        maha_planet = VIMSHOTTARI_SEQUENCE[seq_idx]
        maha_total_years = VIMSHOTTARI_YEARS[maha_planet]

        # The first Maha Dasha uses the balance; subsequent ones use full duration.
        if i == 0:
            maha_duration_years = balance_years
        else:
            maha_duration_years = float(maha_total_years)

        maha_duration_days = _years_to_days(maha_duration_years)
        maha_start_jd = cursor_jd
        maha_end_jd = cursor_jd + maha_duration_days

        # ── 4. Generate 9 Antar Dashas within this Maha Dasha ──────────────
        antar_dashas = _build_antar_dashas(
            maha_planet=maha_planet,
            maha_total_years=maha_total_years,
            maha_duration_years=maha_duration_years,
            maha_start_jd=maha_start_jd,
            start_seq_idx=seq_idx,
        )

        maha_dashas.append({
            "planet": maha_planet,
            "start_date": _jd_to_date(maha_start_jd),
            "end_date": _jd_to_date(maha_end_jd),
            "duration_years": round(maha_duration_years, 4),
            "antar_dashas": antar_dashas,
        })

        cursor_jd = maha_end_jd

    return {
        "birth_nakshatra": birth_nakshatra,
        "birth_nakshatra_lord": birth_lord,
        "dasha_balance_at_birth": {
            "planet": birth_lord,
            "years_remaining": round(balance_years, 4),
        },
        "maha_dashas": maha_dashas,
    }


def _build_antar_dashas(
    maha_planet: str,
    maha_total_years: int,
    maha_duration_years: float,
    maha_start_jd: float,
    start_seq_idx: int,
) -> list[dict]:
    """
    Build the 9 Antar Dasha sub-periods within a Maha Dasha.

    The proportion of each Antar Dasha within a Maha Dasha is:
        antar_fraction = antar_planet_years / VIMSHOTTARI_TOTAL_YEARS

    The actual duration of the Antar Dasha within this specific Maha Dasha is:
        antar_duration = antar_fraction × maha_planet_total_years × (maha_duration_years / maha_total_years)

    This correctly handles the first (partial) Maha Dasha.
    """
    antar_dashas = []
    cursor_jd = maha_start_jd

    # Proportionality factor for the first (possibly partial) Maha Dasha
    maha_proportion = maha_duration_years / maha_total_years

    for j in range(9):
        antar_seq_idx = (start_seq_idx + j) % 9
        antar_planet = VIMSHOTTARI_SEQUENCE[antar_seq_idx]
        antar_planet_years = VIMSHOTTARI_YEARS[antar_planet]

        # Antar duration as a fraction of the full Maha Dasha total years
        antar_duration_years = (
            (antar_planet_years / VIMSHOTTARI_TOTAL_YEARS)
            * maha_total_years
            * maha_proportion
        )
        antar_duration_days = _years_to_days(antar_duration_years)
        antar_start_jd = cursor_jd
        antar_end_jd = cursor_jd + antar_duration_days

        # ── 5. Generate 9 Pratyantar Dashas within this Antar Dasha ────────
        pratyantar_dashas = _build_pratyantar_dashas(
            antar_planet=antar_planet,
            antar_planet_years=antar_planet_years,
            antar_duration_years=antar_duration_years,
            antar_start_jd=antar_start_jd,
            start_seq_idx=antar_seq_idx,
        )

        antar_dashas.append({
            "planet": antar_planet,
            "start_date": _jd_to_date(antar_start_jd),
            "end_date": _jd_to_date(antar_end_jd),
            "duration_years": round(antar_duration_years, 6),
            "pratyantar_dashas": pratyantar_dashas,
        })

        cursor_jd = antar_end_jd

    return antar_dashas


def _build_pratyantar_dashas(
    antar_planet: str,
    antar_planet_years: int,
    antar_duration_years: float,
    antar_start_jd: float,
    start_seq_idx: int,
) -> list[dict]:
    """
    Build the 9 Pratyantar Dasha sub-sub-periods within an Antar Dasha.

    The proportion of each Pratyantar within the Antar is:
        pratyantar_fraction = pratyantar_planet_years / VIMSHOTTARI_TOTAL_YEARS
    Scaled by antar_planet_years to get actual duration.
    """
    pratyantar_dashas = []
    cursor_jd = antar_start_jd

    # Proportionality factor for this specific Antar Dasha duration
    antar_proportion = antar_duration_years / antar_planet_years

    for k in range(9):
        prat_seq_idx = (start_seq_idx + k) % 9
        prat_planet = VIMSHOTTARI_SEQUENCE[prat_seq_idx]
        prat_planet_years = VIMSHOTTARI_YEARS[prat_planet]

        prat_duration_years = (
            (prat_planet_years / VIMSHOTTARI_TOTAL_YEARS)
            * antar_planet_years
            * antar_proportion
        )
        prat_duration_days = _years_to_days(prat_duration_years)
        prat_start_jd = cursor_jd
        prat_end_jd = cursor_jd + prat_duration_days

        pratyantar_dashas.append({
            "planet": prat_planet,
            "start_date": _jd_to_date(prat_start_jd),
            "end_date": _jd_to_date(prat_end_jd),
            "duration_years": round(prat_duration_years, 8),
        })

        cursor_jd = prat_end_jd

    return pratyantar_dashas


# ─── Main Chart Calculation ───────────────────────────────────────────────────

def calculate_chart(
    year: int, month: int, day: int,
    hour: int, minute: int, second: int,
    latitude: float, longitude: float,
    ayanamsa: str = "lahiri",
    house_system: str = "P",  # Placidus
) -> dict:
    """
    Calculates a complete Vedic birth chart using Swiss Ephemeris.

    Args:
        year, month, day: Birth date (local time)
        hour, minute, second: Birth time (local time)
        latitude, longitude: Birth coordinates
        ayanamsa: Ayanamsa standard (default: lahiri)
        house_system: House system code (P=Placidus, E=Equal)

    Returns:
        dict: Immutable chart_facts_json containing planets, houses, dasha timeline.
    """
    # Set sidereal mode
    sid_mode = AYANAMSA_MAP.get(ayanamsa, swe.SIDM_LAHIRI)
    swe.set_sid_mode(sid_mode)

    # Convert local birth datetime to Julian Day (UTC approximation)
    jd = swe.julday(year, month, day, hour + minute / 60.0 + second / 3600.0)

    planets_data = []
    moon_sidereal_lon: float = 0.0  # Captured for dasha calculation

    for planet_name, planet_id in PLANETS.items():
        flags = swe.FLG_SWIEPH | swe.FLG_SIDEREAL
        pos, ret = swe.calc_ut(jd, planet_id, flags)
        sidereal_lon = pos[0]
        speed = pos[3]

        is_retrograde = speed < 0
        zodiac_index = int(sidereal_lon / 30)
        degree_in_sign = sidereal_lon % 30
        house = int(sidereal_lon / 30) + 1
        nakshatra, pada = _get_nakshatra(sidereal_lon)

        # Capture Moon longitude for Vimshottari calculation
        if planet_name == "Moon":
            moon_sidereal_lon = sidereal_lon

        # Calculate Ketu as exact opposite of Rahu
        if planet_name == "Rahu":
            planets_data.append({
                "name": "Rahu",
                "longitude": round(sidereal_lon, 6),
                "zodiac_sign": ZODIAC_SIGNS[zodiac_index],
                "house": house,
                "degree_in_sign": round(degree_in_sign, 4),
                "nakshatra": nakshatra,
                "pada": pada,
                "is_retrograde": True,
            })
            ketu_lon = (sidereal_lon + 180) % 360
            ketu_nak, ketu_pada = _get_nakshatra(ketu_lon)
            planets_data.append({
                "name": "Ketu",
                "longitude": round(ketu_lon, 6),
                "zodiac_sign": ZODIAC_SIGNS[int(ketu_lon / 30)],
                "house": int(ketu_lon / 30) + 1,
                "degree_in_sign": round(ketu_lon % 30, 4),
                "nakshatra": ketu_nak,
                "pada": ketu_pada,
                "is_retrograde": True,
            })
        else:
            planets_data.append({
                "name": planet_name,
                "longitude": round(sidereal_lon, 6),
                "zodiac_sign": ZODIAC_SIGNS[zodiac_index],
                "house": house,
                "degree_in_sign": round(degree_in_sign, 4),
                "nakshatra": nakshatra,
                "pada": pada,
                "is_retrograde": is_retrograde,
            })

    # Calculate house cusps
    cusps, ascmc = swe.houses_ex(jd, latitude, longitude, bytes(house_system, "utf-8"), swe.FLG_SIDEREAL)
    ascendant_lon = ascmc[0] % 360

    # ── Vimshottari Dasha Timeline ────────────────────────────────────────────
    vimshottari_dasha = calculate_vimshottari_dasha(
        moon_longitude=moon_sidereal_lon,
        birth_jd=jd,
    )

    return {
        "ayanamsa": ayanamsa,
        "house_system": house_system,
        "ascendant": {
            "longitude": round(ascendant_lon, 6),
            "zodiac_sign": ZODIAC_SIGNS[int(ascendant_lon / 30)],
        },
        "planets": planets_data,
        "house_cusps": [round(c, 6) for c in cusps[:12]],
        "julian_day": jd,
        "vimshottari_dasha": vimshottari_dasha,
    }
