"""
Unit tests for Ashtakvarga Service (BAV and SAV calculations)
"""

import pytest
from app.modules.birth_chart.ashtakvarga_service import (
    calculate_ashtakvarga,
    BAV_RULES,
)


def test_ashtakvarga_sav_total_sum():
    """Verify that total Samudaya Ashtakvarga (SAV) points sum to exactly 337 across all 12 signs."""
    # Test chart positions: Aries Lagna, Sun in Aries, Moon in Cancer, Mars in Capricorn, etc.
    planet_signs = {
        "Sun": 0,       # Aries
        "Moon": 3,      # Cancer
        "Mars": 9,      # Capricorn
        "Mercury": 0,   # Aries
        "Jupiter": 8,   # Sagittarius
        "Venus": 11,    # Pisces
        "Saturn": 6,    # Libra
    }
    lagna_sign = 0      # Aries

    result = calculate_ashtakvarga(planet_signs, lagna_sign)

    assert "bav" in result
    assert "sav" in result
    assert len(result["sav"]) == 12
    assert result["total_points"] == 337
    assert sum(result["sav"]) == 337


def test_bav_point_bounds():
    """Verify that each planet's BAV point count in any sign is bounded between 0 and 8."""
    planet_signs = {
        "Sun": 4,       # Leo
        "Moon": 1,      # Taurus
        "Mars": 0,      # Aries
        "Mercury": 5,   # Virgo
        "Jupiter": 3,   # Cancer
        "Venus": 6,     # Libra
        "Saturn": 10,   # Aquarius
    }
    lagna_sign = 8      # Sagittarius

    result = calculate_ashtakvarga(planet_signs, lagna_sign)

    for planet, points in result["bav"].items():
        assert len(points) == 12
        for p in points:
            assert 0 <= p <= 8


def test_house_sav_mapping():
    """Verify house assignment relative to Lagna sign."""
    planet_signs = {
        "Sun": 0, "Moon": 0, "Mars": 0, "Mercury": 0,
        "Jupiter": 0, "Venus": 0, "Saturn": 0
    }
    lagna_sign = 3  # Cancer (House 1 = Cancer, House 2 = Leo, ...)

    result = calculate_ashtakvarga(planet_signs, lagna_sign)
    house_sav = result["house_sav"]

    assert len(house_sav) == 12
    assert house_sav[0]["house"] == 1
    assert house_sav[0]["sign"] == "Cancer"
    assert house_sav[0]["sign_index"] == 3
    assert house_sav[1]["house"] == 2
    assert house_sav[1]["sign"] == "Leo"
    assert house_sav[1]["sign_index"] == 4
