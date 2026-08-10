"""
Unit tests for Planetary Dignity & Friendship Matrix Service
"""

import pytest
from app.modules.birth_chart.dignity_service import (
    calculate_planetary_dignity,
    calculate_tatkalika_friendship,
    calculate_panchadha_sambandha,
    is_combust,
)


def test_exaltation_detection():
    """Verify deep exaltation calculation for Sun in Aries (10°)."""
    planet_positions = {"Sun": 0, "Moon": 1, "Mars": 9}
    res = calculate_planetary_dignity(
        planet="Sun",
        sign_index=0,       # Aries
        deg_in_sign=10.0,
        sun_longitude=10.0,
        planet_positions=planet_positions
    )

    assert res["dignity_state"] == "Exalted"
    assert res["dignity_score"] == 100.0


def test_debilitation_detection():
    """Verify debilitation for Saturn in Aries (20°)."""
    planet_positions = {"Sun": 4, "Saturn": 0}
    res = calculate_planetary_dignity(
        planet="Saturn",
        sign_index=0,       # Aries
        deg_in_sign=20.0,
        sun_longitude=120.0,
        planet_positions=planet_positions
    )

    assert res["dignity_state"] == "Debilitated"
    assert res["dignity_score"] == 0.0


def test_moolatrikona_detection():
    """Verify Moolatrikona detection for Jupiter in Sagittarius (5°)."""
    planet_positions = {"Sun": 0, "Jupiter": 8}
    res = calculate_planetary_dignity(
        planet="Jupiter",
        sign_index=8,       # Sagittarius
        deg_in_sign=5.0,
        sun_longitude=10.0,
        planet_positions=planet_positions
    )

    assert res["dignity_state"] == "Moolatrikona"
    assert res["dignity_score"] == 85.0


def test_own_sign_detection():
    """Verify own sign detection for Venus in Taurus (20°)."""
    planet_positions = {"Sun": 0, "Venus": 1}
    res = calculate_planetary_dignity(
        planet="Venus",
        sign_index=1,       # Taurus
        deg_in_sign=20.0,
        sun_longitude=10.0,
        planet_positions=planet_positions
    )

    assert res["dignity_state"] == "Own Sign"
    assert res["dignity_score"] == 75.0


def test_tatkalika_friendship():
    """Verify temporal friendship rules (2nd, 3rd, 4th, 10th, 11th, 12th houses = +1)."""
    # Sign 0 (Aries) to Sign 1 (Taurus) -> 2nd house -> Temporal Friend (+1)
    assert calculate_tatkalika_friendship(0, 1) == 1
    # Sign 0 (Aries) to Sign 4 (Leo) -> 5th house -> Temporal Enemy (-1)
    assert calculate_tatkalika_friendship(0, 4) == -1


def test_panchadha_sambandha():
    """Verify compound friendship combinations."""
    assert calculate_panchadha_sambandha(1, 1) == "Adhi Mitra"
    assert calculate_panchadha_sambandha(1, -1) == "Sama"
    assert calculate_panchadha_sambandha(-1, -1) == "Adhi Satru"


def test_combustion_check():
    """Verify combustion calculation when close to Sun."""
    # Mercury at 15° Aries, Sun at 10° Aries -> diff 5° (combust)
    assert is_combust("Mercury", 15.0, 10.0, is_retrograde=False) is True
    # Mercury at 35° Aries, Sun at 10° Aries -> diff 25° (not combust)
    assert is_combust("Mercury", 35.0, 10.0, is_retrograde=False) is False
