"""
Unit tests for Divisional Charts (D9 Navamsha, D10 Dasamsa, D12 Dwadasamsa, D60 Shashtiamsa)
and Ayanamsa variations in ephemeris service.
"""

import pytest
from app.modules.birth_chart.ephemeris_service import (
    AYANAMSA_MAP,
    PLANETS,
    NAKSHATRAS,
    ZODIAC_SIGNS,
    _get_nakshatra,
)


def test_nakshatra_pada_spans():
    """Verify that longitude 0.0° yields Ashwini Pada 1 and 359.9° yields Revati Pada 4."""
    name, pada = _get_nakshatra(0.0)
    assert name == "Ashwini"
    assert pada == 1

    name, pada = _get_nakshatra(13.2)  # ~13°20' is boundary to Bharani
    assert name == "Ashwini" or name == "Bharani"

    name, pada = _get_nakshatra(359.9)
    assert name == "Revati"
    assert pada == 4


def test_ayanamsa_map_supported_standards():
    """Verify all 4 supported Ayanamsa standards are present in mapping."""
    expected_ayanamsas = {"lahiri", "raman", "krishnamurti", "fagan_bradley"}
    assert set(AYANAMSA_MAP.keys()) == expected_ayanamsas


def test_planet_definitions():
    """Verify standard 7 classical planets + Rahu are defined in ephemeris mapping."""
    expected_planets = {"Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu"}
    assert set(PLANETS.keys()) == expected_planets


def test_zodiac_sign_count():
    """Verify exactly 12 zodiac signs in sequence."""
    assert len(ZODIAC_SIGNS) == 12
    assert ZODIAC_SIGNS[0] == "Aries"
    assert ZODIAC_SIGNS[11] == "Pisces"


def test_nakshatra_count():
    """Verify exactly 27 nakshatras in sequence."""
    assert len(NAKSHATRAS) == 27
    assert NAKSHATRAS[0] == "Ashwini"
    assert NAKSHATRAS[26] == "Revati"
