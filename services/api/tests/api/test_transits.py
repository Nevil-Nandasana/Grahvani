"""Backend API unit test — validates Sade Sati Saturn transit calculation endpoint."""
import pytest
from app.modules.birth_chart.ephemeris_service import calculate_chart
from app.tasks.transit_monitor import (
    _calculate_saturn_position,
    _is_saturn_in_sade_sati,
    _get_sade_sati_phase_description,
)


class TestSadeSatiTransitEngine:
    """Test suite for Sade Sati calculation logic and transit phase evaluation."""

    def test_saturn_position_returns_valid_sign(self):
        """Verifies Saturn calculation returns valid zodiac sign and degree."""
        saturn_info = _calculate_saturn_position(2026, 8, 6)
        assert "zodiac_sign" in saturn_info
        assert "longitude" in saturn_info
        assert 0.0 <= saturn_info["longitude"] < 360.0

    def test_sade_sati_first_phase_detection(self):
        """12th house from Moon -> First Phase."""
        # If Moon is Aries and Saturn is Pisces (12th from Aries)
        is_active, phase = _is_saturn_in_sade_sati(moon_sign="Aries", saturn_sign="Pisces")
        assert is_active is True
        assert phase == "first_phase"

    def test_sade_sati_peak_phase_detection(self):
        """Directly over Moon sign -> Peak (Second) Phase."""
        # Moon in Aquarius, Saturn in Aquarius
        is_active, phase = _is_saturn_in_sade_sati(moon_sign="Aquarius", saturn_sign="Aquarius")
        assert is_active is True
        assert phase == "second_phase"

    def test_sade_sati_final_phase_detection(self):
        """2nd house from Moon -> Final (Third) Phase."""
        # Moon in Capricorn, Saturn in Aquarius (2nd from Capricorn)
        is_active, phase = _is_saturn_in_sade_sati(moon_sign="Capricorn", saturn_sign="Aquarius")
        assert is_active is True
        assert phase == "third_phase"

    def test_sade_sati_inactive_detection(self):
        """Saturn in non-Sade Sati house relative to Moon."""
        # Moon in Aries, Saturn in Leo (5th from Aries)
        is_active, phase = _is_saturn_in_sade_sati(moon_sign="Aries", saturn_sign="Leo")
        assert is_active is False
        assert phase is None

    def test_transit_router_schema_validation(self):
        """Verifies SadeSatiResponse and CurrentPositionsResponse pydantic models."""
        from app.modules.transits.router import SadeSatiResponse, CurrentPositionsResponse, PlanetPositionInfo
        
        response = SadeSatiResponse(
            profile_id="123e4567-e89b-12d3-a456-426614174000",
            profile_name="Test User",
            moon_sign="Pisces",
            saturn_sign="Aquarius",
            is_sade_sati_active=True,
            phase="first_phase",
            phase_name="First Phase (12th House from Moon — Rising)",
            description="Saturn is in 12th house from Moon.",
            remedies=["Recite Hanuman Chalisa"],
            checked_at="2026-08-06T12:00:00Z",
        )
        assert response.is_sade_sati_active is True
        assert response.phase == "first_phase"
        assert len(response.remedies) == 1

