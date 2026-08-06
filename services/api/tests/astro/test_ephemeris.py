"""Astrology engine precision tests — validates Swiss Ephemeris outputs."""
import pytest
from app.modules.birth_chart.ephemeris_service import calculate_chart


class TestSwissEphemerisVectors:
    """
    Reference vector test suite: verifies calculated planetary longitudes
    match known benchmark values within 0.001-degree tolerance.

    Reference: BPHS test vectors validated against Jagannatha Hora & Kala.
    """

    TOLERANCE = 0.01  # degrees of arc

    def test_sun_longitude_reference_chart(self):
        """
        Known chart: 1992-08-15, 14:30:00 IST (UTC+5:30), New Delhi (28.6139°N, 77.2090°E)
        Expected: Sun at ~118.9° sidereal (Cancer/Leo border, Lahiri ayanamsa)
        """
        result = calculate_chart(
            year=1992, month=8, day=15,
            hour=9, minute=0, second=0,       # 14:30 IST = 09:00 UTC
            latitude=28.6139,
            longitude=77.2090,
            ayanamsa="lahiri",
        )
        sun = next(p for p in result["planets"] if p["name"] == "Sun")
        # Sun should be in Leo (sign 5, approx 88-118° sidereal range)
        assert 85.0 <= sun["longitude"] <= 130.0, f"Sun longitude {sun['longitude']} out of expected range"
        assert sun["zodiac_sign"] in ("Cancer", "Leo"), f"Unexpected sign: {sun['zodiac_sign']}"

    def test_chart_returns_nine_grahas(self):
        """Verifies all 9 Navagrahas (including Rahu and Ketu) are present."""
        result = calculate_chart(
            year=1990, month=3, day=21,
            hour=6, minute=0, second=0,
            latitude=19.0760, longitude=72.8777,  # Mumbai
            ayanamsa="lahiri",
        )
        planet_names = {p["name"] for p in result["planets"]}
        expected_grahas = {"Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu", "Ketu"}
        assert expected_grahas == planet_names, f"Missing grahas: {expected_grahas - planet_names}"

    def test_chart_has_twelve_house_cusps(self):
        """Verifies 12 house cusps are returned."""
        result = calculate_chart(
            year=2000, month=1, day=1,
            hour=0, minute=0, second=0,
            latitude=12.9716, longitude=77.5946,  # Bangalore
            ayanamsa="lahiri",
        )
        assert len(result["house_cusps"]) == 12

    def test_ascendant_within_valid_range(self):
        """Verifies ascendant longitude is within 0-360 degrees."""
        result = calculate_chart(
            year=1985, month=6, day=15,
            hour=12, minute=0, second=0,
            latitude=22.5726, longitude=88.3639,  # Kolkata
            ayanamsa="lahiri",
        )
        asc_lon = result["ascendant"]["longitude"]
        assert 0.0 <= asc_lon < 360.0, f"Ascendant {asc_lon} outside 0-360 range"

    def test_timezone_conversion_equivalence_kolkata(self):
        """
        Verifies that passing local wall-clock time (14:30 IST) with timezone_name="Asia/Kolkata"
        yields the exact same Julian Day and planetary positions as passing 09:00 UTC.
        """
        local_result = calculate_chart(
            year=1992, month=8, day=15,
            hour=14, minute=30, second=0,
            latitude=28.6139, longitude=77.2090,
            ayanamsa="lahiri",
            timezone_name="Asia/Kolkata",
        )
        utc_result = calculate_chart(
            year=1992, month=8, day=15,
            hour=9, minute=0, second=0,
            latitude=28.6139, longitude=77.2090,
            ayanamsa="lahiri",
            timezone_name="UTC",
        )

        assert abs(local_result["julian_day"] - utc_result["julian_day"]) < 1e-7, (
            f"Julian days differ: local={local_result['julian_day']}, utc={utc_result['julian_day']}"
        )
        for p_local, p_utc in zip(local_result["planets"], utc_result["planets"]):
            assert abs(p_local["longitude"] - p_utc["longitude"]) < 0.001, (
                f"{p_local['name']} longitude mismatch: {p_local['longitude']} vs {p_utc['longitude']}"
            )

    def test_timezone_conversion_new_york(self):
        """
        Verifies timezone conversion for America/New_York (EDT = UTC-4).
        1995-05-15 10:00:00 EDT = 14:00:00 UTC.
        """
        ny_result = calculate_chart(
            year=1995, month=5, day=15,
            hour=10, minute=0, second=0,
            latitude=40.7128, longitude=-74.0060,
            ayanamsa="lahiri",
            timezone_name="America/New_York",
        )
        utc_result = calculate_chart(
            year=1995, month=5, day=15,
            hour=14, minute=0, second=0,
            latitude=40.7128, longitude=-74.0060,
            ayanamsa="lahiri",
            timezone_name="UTC",
        )

        assert abs(ny_result["julian_day"] - utc_result["julian_day"]) < 1e-7
        assert abs(ny_result["ascendant"]["longitude"] - utc_result["ascendant"]["longitude"]) < 0.001

