"""
Dignity Service — Vedic Planetary Dignity & Friendship Matrix Engine
Calculates Exaltation, Debilitation, Moolatrikona, Own Sign,
Naisargika & Tatkalika Sambandha (Natural & Temporal Friendship),
Compound Friendship (Panchadha Sambandha), and Combustion status.
"""

from typing import Any, Dict, List, Tuple, Optional

# Sign index: 0 = Aries, 1 = Taurus, ..., 11 = Pisces

# Exaltation sign and deep exaltation degree (Param Uccha)
EXALTATION_DATA: Dict[str, Tuple[int, float]] = {
    "Sun": (0, 10.0),       # Aries 10°
    "Moon": (1, 3.0),       # Taurus 3°
    "Mars": (9, 28.0),      # Capricorn 28°
    "Mercury": (5, 15.0),   # Virgo 15°
    "Jupiter": (3, 5.0),    # Cancer 5°
    "Venus": (11, 27.0),    # Pisces 27°
    "Saturn": (6, 20.0),    # Libra 20°
    "Rahu": (1, 15.0),      # Taurus 15° (Standard Parasara view)
    "Ketu": (7, 15.0),      # Scorpio 15°
}

# Debilitation sign (exact 180° opposite of exaltation)
DEBILITATION_DATA: Dict[str, Tuple[int, float]] = {
    "Sun": (6, 10.0),       # Libra 10°
    "Moon": (7, 3.0),       # Scorpio 3°
    "Mars": (3, 28.0),      # Cancer 28°
    "Mercury": (11, 15.0),  # Pisces 15°
    "Jupiter": (9, 5.0),    # Capricorn 5°
    "Venus": (5, 27.0),     # Virgo 27°
    "Saturn": (0, 20.0),    # Aries 20°
    "Rahu": (7, 15.0),      # Scorpio 15°
    "Ketu": (1, 15.0),      # Taurus 15°
}

# Moolatrikona sign and degree ranges (start_degree, end_degree)
MOOLATRIKONA_DATA: Dict[str, Tuple[int, float, float]] = {
    "Sun": (4, 0.0, 20.0),     # Leo 0°-20°
    "Moon": (1, 3.0, 30.0),    # Taurus 3°-30°
    "Mars": (0, 0.0, 12.0),    # Aries 0°-12°
    "Mercury": (5, 15.0, 20.0),# Virgo 15°-20°
    "Jupiter": (8, 0.0, 10.0), # Sagittarius 0°-10°
    "Venus": (6, 0.0, 15.0),   # Libra 0°-15°
    "Saturn": (10, 0.0, 20.0), # Aquarius 0°-20°
}

# Own signs (Ruler signs for planets)
OWN_SIGNS: Dict[str, List[int]] = {
    "Sun": [4],           # Leo
    "Moon": [3],          # Cancer
    "Mars": [0, 7],       # Aries, Scorpio
    "Mercury": [2, 5],    # Gemini, Virgo
    "Jupiter": [8, 11],   # Sagittarius, Pisces
    "Venus": [1, 6],      # Taurus, Libra
    "Saturn": [9, 10],    # Capricorn, Aquarius
    "Rahu": [10],         # Aquarius (Co-ruler)
    "Ketu": [7],          # Scorpio (Co-ruler)
}

# Naisargika (Natural) Relationships
# Friends: 1, Neutral: 0, Enemy: -1
NATURAL_FRIENDSHIPS: Dict[str, Dict[str, int]] = {
    "Sun":     {"Moon": 1,  "Mars": 1,  "Jupiter": 1,  "Mercury": 0,  "Venus": -1, "Saturn": -1},
    "Moon":    {"Sun": 1,   "Mercury": 1, "Mars": 0,   "Jupiter": 0,  "Venus": 0,  "Saturn": 0},
    "Mars":    {"Sun": 1,   "Moon": 1,  "Jupiter": 1,  "Venus": 0,    "Saturn": 0, "Mercury": -1},
    "Mercury": {"Sun": 1,   "Venus": 1, "Mars": 0,     "Jupiter": 0,  "Saturn": 0, "Moon": -1},
    "Jupiter": {"Sun": 1,   "Moon": 1,  "Mars": 1,     "Saturn": 0,   "Mercury": -1, "Venus": -1},
    "Venus":   {"Mercury": 1, "Saturn": 1, "Mars": 0,  "Jupiter": 0,  "Sun": -1,   "Moon": -1},
    "Saturn":  {"Mercury": 1, "Venus": 1, "Jupiter": 0, "Sun": -1,   "Moon": -1,  "Mars": -1},
}

# Maximum angular distance from Sun for Combustion (in degrees)
COMBUSTION_LIMITS: Dict[str, float] = {
    "Moon": 12.0,
    "Mars": 17.0,
    "Mercury": 14.0,  # 12° if retrograde
    "Jupiter": 11.0,
    "Venus": 10.0,    # 8° if retrograde
    "Saturn": 15.0,
}


def calculate_tatkalika_friendship(sign1: int, sign2: int) -> int:
    """
    Calculate Tatkalika (Temporal) relationship based on sign placement.
    Planets placed in 2nd, 3rd, 4th, 10th, 11th, 12th signs from each other are temporal friends (+1).
    Planets placed in 1st, 5th, 6th, 7th, 8th, 9th signs are temporal enemies (-1).
    """
    diff = (sign2 - sign1) % 12
    # Houses: 2nd (diff 1), 3rd (diff 2), 4th (diff 3), 10th (diff 9), 11th (diff 10), 12th (diff 11)
    if diff in (1, 2, 3, 9, 10, 11):
        return 1
    return -1


def calculate_panchadha_sambandha(natural: int, temporal: int) -> str:
    """
    Combine Natural (+1, 0, -1) and Temporal (+1, -1) relationships:
    +2 = Adhi Mitra (Great Friend)
    +1 = Mitra (Friend)
     0 = Sama (Neutral)
    -1 = Satru (Enemy)
    -2 = Adhi Satru (Great Enemy)
    """
    combined = natural + temporal
    if combined >= 2:
        return "Adhi Mitra"
    elif combined == 1:
        return "Mitra"
    elif combined == 0:
        return "Sama"
    elif combined == -1:
        return "Satru"
    else:
        return "Adhi Satru"


def is_combust(planet: str, planet_longitude: float, sun_longitude: float, is_retrograde: bool = False) -> bool:
    """Determine if a planet is combust based on angular separation from Sun."""
    if planet in ("Sun", "Rahu", "Ketu"):
        return False
    
    limit = COMBUSTION_LIMITS.get(planet, 15.0)
    if planet == "Mercury" and is_retrograde:
        limit = 12.0
    elif planet == "Venus" and is_retrograde:
        limit = 8.0
        
    diff = abs(planet_longitude - sun_longitude) % 360.0
    if diff > 180.0:
        diff = 360.0 - diff
        
    return diff <= limit


def calculate_planetary_dignity(
    planet: str,
    sign_index: int,
    deg_in_sign: float,
    sun_longitude: float,
    planet_positions: Dict[str, int],  # Map of planet name -> sign_index
    is_retrograde: bool = False
) -> Dict[str, Any]:
    """
    Calculate dignity status and numeric strength score for a given planet.
    """
    dignity_state = "Neutral"
    dignity_score = 50.0  # Base neutral score (0-100 scale)

    # 1. Exaltation Check
    if planet in EXALTATION_DATA:
        exalt_sign, deep_deg = EXALTATION_DATA[planet]
        if sign_index == exalt_sign:
            dignity_state = "Exalted"
            dignity_score = 100.0 - abs(deg_in_sign - deep_deg)

    # 2. Debilitation Check
    if dignity_state == "Neutral" and planet in DEBILITATION_DATA:
        deb_sign, deep_deg = DEBILITATION_DATA[planet]
        if sign_index == deb_sign:
            dignity_state = "Debilitated"
            dignity_score = max(0.0, abs(deg_in_sign - deep_deg))

    # 3. Moolatrikona Check
    if dignity_state == "Neutral" and planet in MOOLATRIKONA_DATA:
        mool_sign, start_deg, end_deg = MOOLATRIKONA_DATA[planet]
        if sign_index == mool_sign and start_deg <= deg_in_sign <= end_deg:
            dignity_state = "Moolatrikona"
            dignity_score = 85.0

    # 4. Own Sign Check
    if dignity_state == "Neutral" and planet in OWN_SIGNS:
        if sign_index in OWN_SIGNS[planet]:
            dignity_state = "Own Sign"
            dignity_score = 75.0

    # 5. Compound Relationship Check (Panchadha Sambandha) for non-owner signs
    dispositor = None
    panchadha = "Sama"
    if planet in NATURAL_FRIENDSHIPS and dignity_state == "Neutral":
        # Find ruling planet of sign_index
        for owner, signs in OWN_SIGNS.items():
            if sign_index in signs and owner in NATURAL_FRIENDSHIPS[planet]:
                dispositor = owner
                natural = NATURAL_FRIENDSHIPS[planet][owner]
                dispositor_sign = planet_positions.get(owner, sign_index)
                temporal = calculate_tatkalika_friendship(sign_index, dispositor_sign)
                panchadha = calculate_panchadha_sambandha(natural, temporal)
                dignity_state = panchadha
                
                score_map = {
                    "Adhi Mitra": 65.0,
                    "Mitra": 55.0,
                    "Sama": 45.0,
                    "Satru": 30.0,
                    "Adhi Satru": 15.0
                }
                dignity_score = score_map.get(panchadha, 45.0)
                break

    combust = is_combust(planet, (sign_index * 30.0) + deg_in_sign, sun_longitude, is_retrograde)
    if combust:
        dignity_score = max(5.0, dignity_score - 20.0)

    return {
        "planet": planet,
        "sign_index": sign_index,
        "deg_in_sign": round(deg_in_sign, 2),
        "dignity_state": dignity_state,
        "dignity_score": round(dignity_score, 2),
        "dispositor": dispositor,
        "panchadha_sambandha": panchadha,
        "is_combust": combust,
        "is_retrograde": is_retrograde
    }
