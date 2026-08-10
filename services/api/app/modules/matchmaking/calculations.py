# app/modules/matchmaking/calculations.py

# A simplified algorithmic approach to compute Ashtakoot matching points.
# In a full astrology engine, these use extensive lookup tables for all 27 nakshatras.

ZODIAC_SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
]

NAKSHATRAS = [
    "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra",
    "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni", "Uttara Phalguni",
    "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha", "Jyeshtha",
    "Mula", "Purva Ashadha", "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
    "Purva Bhadrapada", "Uttara Bhadrapada", "Revati",
]

# Nadi: 0 = Aadi, 1 = Madhya, 2 = Antya
# Nakshatras repeat their Nadi sequentially (0, 1, 2, 2, 1, 0...)
NADI_MAP = [0, 1, 2, 2, 1, 0, 0, 1, 2, 2, 1, 0, 0, 1, 2, 2, 1, 0, 0, 1, 2, 2, 1, 0, 0, 1, 2]

# Gana: 0 = Deva, 1 = Manushya, 2 = Rakshasa
GANA_MAP = [0, 1, 2, 1, 0, 1, 0, 0, 2, 2, 1, 1, 0, 2, 0, 2, 0, 2, 2, 1, 1, 0, 2, 2, 1, 1, 0]

def get_sign_index(sign: str) -> int:
    try:
        return ZODIAC_SIGNS.index(sign)
    except ValueError:
        return 0

def get_nakshatra_index(nakshatra: str) -> int:
    try:
        return NAKSHATRAS.index(nakshatra)
    except ValueError:
        return 0

def compute_ashtakoot(p1_sign: str, p1_nak: str, p2_sign: str, p2_nak: str) -> dict:
    # 1. Varna (Max 1) - Based on sign element
    varna = 1.0 if p1_sign == p2_sign else 0.5
    
    # 2. Vashya (Max 2) - Based on sign types
    vashya = 2.0 if get_sign_index(p1_sign) % 4 == get_sign_index(p2_sign) % 4 else 1.0

    # 3. Tara (Max 3) - Distance between Nakshatras
    idx1 = get_nakshatra_index(p1_nak)
    idx2 = get_nakshatra_index(p2_nak)
    dist = abs(idx1 - idx2) % 9
    tara = 3.0 if dist in (0, 1, 2, 4, 6, 8) else 1.5

    # 4. Yoni (Max 4) - Animal compatibility
    yoni = 4.0 if (idx1 % 14) == (idx2 % 14) else 2.0

    # 5. Graha Maitri (Max 5) - Lord friendship
    graha_maitri = 5.0 if get_sign_index(p1_sign) % 3 == get_sign_index(p2_sign) % 3 else 3.0

    # 6. Gana (Max 6) - Temperament
    g1 = GANA_MAP[idx1]
    g2 = GANA_MAP[idx2]
    gana = 6.0 if g1 == g2 else (0.0 if (g1 == 2 or g2 == 2) else 3.0)

    # 7. Bhakoot (Max 7) - Distance between signs
    s1 = get_sign_index(p1_sign)
    s2 = get_sign_index(p2_sign)
    s_dist = abs(s1 - s2)
    bhakoot = 0.0 if s_dist in (1, 5, 7) else 7.0

    # 8. Nadi (Max 8) - Genetic compatibility
    n1 = NADI_MAP[idx1]
    n2 = NADI_MAP[idx2]
    nadi = 0.0 if n1 == n2 else 8.0

    total = varna + vashya + tara + yoni + graha_maitri + gana + bhakoot + nadi

    return {
        "varna": varna,
        "vashya": vashya,
        "tara": tara,
        "yoni": yoni,
        "graha_maitri": graha_maitri,
        "gana": gana,
        "bhakoot": bhakoot,
        "nadi": nadi,
        "total": total
    }
