"""
Ashtakvarga Service — Parasara Ashtakvarga Calculation Engine
Calculates Bhinna Ashtakvarga (BAV) for the 7 classical planets (0–8 points per sign),
Samudaya Ashtakvarga (SAV) total across 12 signs (337 total points),
and maps points to house positions relative to Lagna.
"""

from typing import Dict, List, Any

# Classical Parasara BAV beneficiary house positions (1-indexed) relative to each contributor planet & Lagna
BAV_RULES: Dict[str, Dict[str, List[int]]] = {
    "Sun": {
        "Sun":     [1, 2, 4, 7, 8, 9, 10, 11],
        "Moon":    [3, 6, 10, 11],
        "Mars":    [1, 2, 4, 7, 8, 9, 10, 11],
        "Mercury": [3, 5, 6, 9, 10, 11, 12],
        "Jupiter": [5, 6, 9, 11],
        "Venus":   [6, 7, 12],
        "Saturn":  [1, 2, 4, 7, 8, 9, 10, 11],
        "Lagna":   [3, 4, 6, 10, 11, 12],
    },
    "Moon": {
        "Sun":     [3, 6, 7, 8, 10, 11],
        "Moon":    [1, 3, 6, 7, 10, 11],
        "Mars":    [2, 3, 5, 6, 9, 10, 11],
        "Mercury": [1, 3, 4, 5, 7, 8, 10, 11],
        "Jupiter": [1, 4, 7, 8, 10, 11, 12],
        "Venus":   [3, 4, 5, 7, 9, 10, 11],
        "Saturn":  [3, 5, 6, 11],
        "Lagna":   [3, 6, 10, 11],
    },
    "Mars": {
        "Sun":     [3, 5, 6, 10, 11],
        "Moon":    [3, 6, 11],
        "Mars":    [1, 2, 4, 7, 8, 10, 11],
        "Mercury": [3, 5, 6, 11],
        "Jupiter": [6, 10, 11, 12],
        "Venus":   [6, 8, 11, 12],
        "Saturn":  [1, 4, 7, 8, 9, 10, 11],
        "Lagna":   [1, 3, 6, 10, 11],
    },
    "Mercury": {
        "Sun":     [5, 6, 9, 11, 12],
        "Moon":    [2, 4, 6, 8, 10, 11],
        "Mars":    [1, 2, 4, 7, 8, 9, 10, 11],
        "Mercury": [1, 3, 5, 6, 9, 10, 11, 12],
        "Jupiter": [6, 8, 11, 12],
        "Venus":   [1, 2, 3, 4, 5, 8, 9, 11],
        "Saturn":  [1, 2, 4, 7, 8, 9, 10, 11],
        "Lagna":   [1, 2, 4, 6, 8, 10, 11],
    },
    "Jupiter": {
        "Sun":     [1, 2, 3, 4, 7, 8, 9, 10, 11],
        "Moon":    [2, 5, 7, 9, 11],
        "Mars":    [1, 2, 4, 7, 8, 10, 11],
        "Mercury": [1, 2, 4, 5, 6, 9, 10, 11],
        "Jupiter": [1, 2, 3, 4, 7, 8, 10, 11],
        "Venus":   [2, 5, 6, 9, 10, 11],
        "Saturn":  [3, 5, 6, 12],
        "Lagna":   [1, 2, 4, 5, 6, 7, 9, 10, 11],
    },
    "Venus": {
        "Sun":     [8, 11, 12],
        "Moon":    [1, 2, 3, 4, 5, 8, 9, 11, 12],
        "Mars":    [3, 4, 6, 9, 11, 12],
        "Mercury": [3, 5, 6, 9, 11],
        "Jupiter": [5, 8, 9, 10, 11],
        "Venus":   [1, 2, 3, 4, 5, 8, 9, 10, 11],
        "Saturn":  [3, 4, 5, 8, 9, 10, 11],
        "Lagna":   [1, 2, 3, 4, 5, 8, 9, 11],
    },
    "Saturn": {
        "Sun":     [1, 2, 4, 7, 8, 10, 11],
        "Moon":    [3, 6, 11],
        "Mars":    [3, 5, 6, 10, 11, 12],
        "Mercury": [6, 8, 9, 10, 11, 12],
        "Jupiter": [5, 6, 11, 12],
        "Venus":   [6, 11, 12],
        "Saturn":  [3, 5, 6, 11],
        "Lagna":   [1, 3, 4, 6, 10, 11],
    },
}

ZODIAC_SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
]


def calculate_ashtakvarga(
    planet_signs: Dict[str, int],  # Map of planet name -> sign_index (0=Aries ... 11=Pisces)
    lagna_sign: int                # Lagna sign_index (0-11)
) -> Dict[str, Any]:
    """
    Calculate Bhinna Ashtakvarga (BAV) for the 7 classical planets and
    Samudaya Ashtakvarga (SAV) for the 12 signs.

    Args:
        planet_signs: Dict mapping planet names ("Sun", "Moon", ..., "Saturn") to sign index (0-11).
        lagna_sign: Integer sign index of Lagna/Ascendant (0-11).

    Returns:
        Dict containing:
        - bav: Dict[str, List[int]] -> 7 arrays of 12 sign points (0-8 per sign)
        - sav: List[int] -> Array of 12 sign points (total sum = 337)
        - house_sav: List[Dict[str, Any]] -> 12 house positions (1-12) with sign and SAV points
        - total_points: Total points across entire zodiac (337)
    """
    # Initialize 7 BAV arrays for Aries (0) through Pisces (11)
    bav: Dict[str, List[int]] = {planet: [0] * 12 for planet in BAV_RULES.keys()}

    # All contributors include 7 planets + Lagna
    contributors = dict(planet_signs)
    contributors["Lagna"] = lagna_sign

    # Compute BAV points
    for target_planet, rules in BAV_RULES.items():
        for contributor, benef_houses in rules.items():
            if contributor in contributors:
                contrib_sign = contributors[contributor]
                for h in benef_houses:
                    # 1-indexed house position mapped to sign index
                    target_sign = (contrib_sign + (h - 1)) % 12
                    bav[target_planet][target_sign] += 1

    # Compute Samudaya Ashtakvarga (SAV) by summing the 7 BAV arrays per sign
    sav = [0] * 12
    for sign_idx in range(12):
        sav[sign_idx] = sum(bav[p][sign_idx] for p in BAV_RULES.keys())

    total_points = sum(sav)

    # Map SAV points to House positions relative to Lagna (House 1 = Lagna sign)
    house_sav = []
    for house_num in range(1, 13):
        sign_idx = (lagna_sign + (house_num - 1)) % 12
        house_sav.append({
            "house": house_num,
            "sign": ZODIAC_SIGNS[sign_idx],
            "sign_index": sign_idx,
            "sav_points": sav[sign_idx],
            "strength_rating": "Strong" if sav[sign_idx] >= 28 else ("Average" if sav[sign_idx] >= 25 else "Weak")
        })

    return {
        "bav": bav,
        "sav": sav,
        "house_sav": house_sav,
        "total_points": total_points,
    }
