"""
Vimshottari Dasha Reference Test Suite
Validates the dasha engine against known astrological benchmarks.

Reference chart used throughout:
  - Birth: 1992-08-15, 09:00:00 UTC (= 14:30 IST)
  - Location: New Delhi (28.6139°N, 77.2090°E)
  - Ayanamsa: Lahiri

This chart is also used in test_ephemeris.py for planetary vectors.
Moon is in Purva Ashadha nakshatra (lord: Venus) for this chart.
"""
import pytest
from app.modules.birth_chart.ephemeris_service import (
    VIMSHOTTARI_SEQUENCE,
    VIMSHOTTARI_TOTAL_YEARS,
    VIMSHOTTARI_YEARS,
    _NAKSHATRA_LORDS,
    _NAKSHATRA_SPAN,
    _jd_to_date,
    calculate_chart,
    calculate_vimshottari_dasha,
)

# ─── Shared Fixtures ──────────────────────────────────────────────────────────

_REFERENCE_CHART = dict(
    year=1992, month=8, day=15,
    hour=9, minute=0, second=0,       # 14:30 IST = 09:00 UTC
    latitude=28.6139, longitude=77.2090,
    ayanamsa="lahiri",
)


@pytest.fixture(scope="module")
def reference_chart_result():
    """Full chart result for the reference birth data (cached across tests)."""
    return calculate_chart(**_REFERENCE_CHART)


@pytest.fixture(scope="module")
def reference_dasha(reference_chart_result):
    """Vimshottari dasha data extracted from the reference chart result."""
    return reference_chart_result["vimshottari_dasha"]


# ─── Structural Tests ─────────────────────────────────────────────────────────

class TestDashaStructure:
    """Verify the shape and completeness of dasha output."""

    def test_dasha_present_in_chart_facts(self, reference_chart_result):
        """chart_facts_json must include vimshottari_dasha key."""
        assert "vimshottari_dasha" in reference_chart_result

    def test_dasha_has_required_top_level_keys(self, reference_dasha):
        required = {"birth_nakshatra", "birth_nakshatra_lord", "dasha_balance_at_birth", "maha_dashas"}
        assert required.issubset(set(reference_dasha.keys()))

    def test_nine_maha_dashas_returned(self, reference_dasha):
        """Exactly 9 Maha Dasha periods must be present."""
        assert len(reference_dasha["maha_dashas"]) == 9

    def test_each_maha_has_nine_antar_dashas(self, reference_dasha):
        """Each Maha Dasha must contain exactly 9 Antar Dasha sub-periods."""
        for maha in reference_dasha["maha_dashas"]:
            assert len(maha["antar_dashas"]) == 9, (
                f"Maha {maha['planet']} has {len(maha['antar_dashas'])} antar dashas, expected 9"
            )

    def test_each_antar_has_nine_pratyantar_dashas(self, reference_dasha):
        """Each Antar Dasha must contain exactly 9 Pratyantar Dasha sub-sub-periods."""
        for maha in reference_dasha["maha_dashas"]:
            for antar in maha["antar_dashas"]:
                assert len(antar["pratyantar_dashas"]) == 9, (
                    f"Antar {antar['planet']} in Maha {maha['planet']} "
                    f"has {len(antar['pratyantar_dashas'])} pratyantar dashas, expected 9"
                )

    def test_all_maha_planets_are_valid(self, reference_dasha):
        """Every Maha Dasha planet must be one of the 9 Vimshottari planets."""
        valid_planets = set(VIMSHOTTARI_SEQUENCE)
        for maha in reference_dasha["maha_dashas"]:
            assert maha["planet"] in valid_planets, f"Invalid Maha planet: {maha['planet']}"

    def test_maha_planets_cover_full_sequence(self, reference_dasha):
        """All 9 planets must appear across the 9 Maha Dasha periods (each exactly once)."""
        planets = [m["planet"] for m in reference_dasha["maha_dashas"]]
        assert set(planets) == set(VIMSHOTTARI_SEQUENCE), (
            f"Not all planets covered. Missing: {set(VIMSHOTTARI_SEQUENCE) - set(planets)}"
        )

    def test_dates_are_iso_format(self, reference_dasha):
        """All start/end dates must be valid ISO-8601 YYYY-MM-DD strings."""
        import re
        pattern = re.compile(r"^\d{4}-\d{2}-\d{2}$")
        for maha in reference_dasha["maha_dashas"]:
            assert pattern.match(maha["start_date"]), f"Bad start date: {maha['start_date']}"
            assert pattern.match(maha["end_date"]), f"Bad end date: {maha['end_date']}"

    def test_maha_start_equals_previous_end(self, reference_dasha):
        """Each Maha Dasha must start on the day the previous one ended (no gaps)."""
        mahas = reference_dasha["maha_dashas"]
        for i in range(1, len(mahas)):
            assert mahas[i]["start_date"] == mahas[i - 1]["end_date"], (
                f"Gap between Maha {mahas[i-1]['planet']} end ({mahas[i-1]['end_date']}) "
                f"and Maha {mahas[i]['planet']} start ({mahas[i]['start_date']})"
            )

    def test_first_maha_starts_on_birth_date(self, reference_dasha):
        """The first Maha Dasha must start on the birth date."""
        assert reference_dasha["maha_dashas"][0]["start_date"] == "1992-08-15"


# ─── Arithmetic Consistency Tests ─────────────────────────────────────────────

class TestDashaArithmetic:
    """Verify the mathematical correctness of dasha period durations."""

    TOLERANCE_DAYS = 2  # ± 2 days tolerance for floating-point accumulation

    def test_nine_full_maha_dashas_sum_to_120_years(self):
        """
        For a birth at nakshatra start (0% elapsed), 9 Maha Dashas must total 120 years.
        We use Moon longitude = 0.0 (start of Ashwini, lord=Ketu, balance=7 full years).
        """
        import swisseph as swe
        # Julian Day for a reference birth — use Jan 1, 2000, 12:00 UTC (J2000.0)
        birth_jd = swe.julday(2000, 1, 1, 12.0)
        # Moon at exactly 0.0° = start of Ashwini nakshatra → full Ketu balance
        dasha = calculate_vimshottari_dasha(moon_longitude=0.0, birth_jd=birth_jd)
        total_years = sum(m["duration_years"] for m in dasha["maha_dashas"])
        assert abs(total_years - 120.0) < 0.01, f"Total dasha years = {total_years}, expected 120.0"

    def test_antar_dashas_sum_to_maha_duration(self, reference_dasha):
        """Antar Dasha durations must sum exactly to their containing Maha Dasha duration."""
        for maha in reference_dasha["maha_dashas"]:
            antar_total = sum(a["duration_years"] for a in maha["antar_dashas"])
            assert abs(antar_total - maha["duration_years"]) < 1e-4, (
                f"Maha {maha['planet']}: antar sum={antar_total:.6f}, "
                f"maha_duration={maha['duration_years']:.6f}"
            )

    def test_pratyantar_dashas_sum_to_antar_duration(self, reference_dasha):
        """Pratyantar Dasha durations must sum exactly to their Antar Dasha duration."""
        for maha in reference_dasha["maha_dashas"]:
            for antar in maha["antar_dashas"]:
                prat_total = sum(p["duration_years"] for p in antar["pratyantar_dashas"])
                assert abs(prat_total - antar["duration_years"]) < 1e-6, (
                    f"Antar {antar['planet']} in Maha {maha['planet']}: "
                    f"pratyantar sum={prat_total:.8f}, antar={antar['duration_years']:.8f}"
                )

    def test_maha_dasha_durations_are_positive(self, reference_dasha):
        """Every Maha Dasha duration must be a positive number."""
        for maha in reference_dasha["maha_dashas"]:
            assert maha["duration_years"] > 0, f"Non-positive Maha duration: {maha}"

    def test_balance_is_within_lord_total_years(self, reference_dasha):
        """
        The dasha balance at birth must be between 0 (exclusive) and
        the total years for the birth nakshatra lord (inclusive).
        """
        balance = reference_dasha["dasha_balance_at_birth"]
        lord_years = VIMSHOTTARI_YEARS[balance["planet"]]
        assert 0 < balance["years_remaining"] <= lord_years, (
            f"Balance {balance['years_remaining']} out of range (0, {lord_years}] "
            f"for planet {balance['planet']}"
        )

    def test_first_maha_duration_equals_balance(self, reference_dasha):
        """The first Maha Dasha duration must equal the balance at birth."""
        balance_years = reference_dasha["dasha_balance_at_birth"]["years_remaining"]
        first_maha_years = reference_dasha["maha_dashas"][0]["duration_years"]
        assert abs(first_maha_years - balance_years) < 1e-4, (
            f"First Maha duration {first_maha_years} ≠ balance {balance_years}"
        )


# ─── Nakshatra Lord Tests ─────────────────────────────────────────────────────

class TestNakshatraLords:
    """Verify nakshatra lord lookups are correct for known positions."""

    def test_ashwini_lord_is_ketu(self):
        """Ashwini (0.0° – 13.33°) lord must be Ketu."""
        assert _NAKSHATRA_LORDS[0] == "Ketu"

    def test_bharani_lord_is_venus(self):
        """Bharani (13.33° – 26.67°) lord must be Venus."""
        assert _NAKSHATRA_LORDS[1] == "Venus"

    def test_revati_lord_is_mercury(self):
        """Revati (346.67° – 360°) lord must be Mercury (last nakshatra, index 26)."""
        assert _NAKSHATRA_LORDS[26] == "Mercury"

    def test_27_nakshatra_lords_defined(self):
        """Exactly 27 nakshatra lords must be defined."""
        assert len(_NAKSHATRA_LORDS) == 27

    def test_lords_cycle_correctly(self):
        """Nakshatra lords must cycle: Ketu, Venus, Sun, Moon, Mars, Rahu, Jupiter, Saturn, Mercury × 3."""
        expected_cycle = ["Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury"]
        for i in range(27):
            expected = expected_cycle[i % 9]
            actual = _NAKSHATRA_LORDS[i]
            assert actual == expected, f"Nakshatra {i}: expected {expected}, got {actual}"

    def test_vimshottari_years_sum_to_120(self):
        """All Vimshottari Maha Dasha years must sum to 120."""
        assert sum(VIMSHOTTARI_YEARS.values()) == 120

    def test_vimshottari_sequence_has_nine_planets(self):
        """The Vimshottari sequence must contain exactly 9 planets."""
        assert len(VIMSHOTTARI_SEQUENCE) == 9
        assert len(set(VIMSHOTTARI_SEQUENCE)) == 9  # No duplicates


# ─── Reference Chart Validation ───────────────────────────────────────────────

class TestReferenceChartDasha:
    """
    Validate specific dasha values for the 1992-08-15 New Delhi reference chart.

    The Moon for this chart is in Sagittarius (Dhanus), in Purva Ashadha nakshatra.
    Purva Ashadha's lord is Venus (index 19 in nakshatra list → lord index 19 % 9 = 1 = Venus).
    So the birth lord is Venus and the first Maha Dasha is Venus.
    """

    def test_birth_nakshatra_lord_is_venus(self, reference_dasha):
        """Reference chart: Moon in Purva Ashadha → Venus is the birth nakshatra lord."""
        assert reference_dasha["birth_nakshatra_lord"] == "Venus", (
            f"Expected Venus, got {reference_dasha['birth_nakshatra_lord']}"
        )

    def test_first_maha_dasha_planet_is_venus(self, reference_dasha):
        """Reference chart: First (partial) Maha Dasha must be Venus."""
        assert reference_dasha["maha_dashas"][0]["planet"] == "Venus"

    def test_second_maha_dasha_planet_is_sun(self, reference_dasha):
        """After Venus Maha, next must be Sun (sequential Vimshottari order)."""
        assert reference_dasha["maha_dashas"][1]["planet"] == "Sun"

    def test_venus_maha_ends_before_2013(self, reference_dasha):
        """
        Venus Maha starts Aug 1992 with a partial balance (< 20 years remaining).
        It must end before 2013-08-15 (which would be 21 full years from birth).
        """
        venus_maha = reference_dasha["maha_dashas"][0]
        assert venus_maha["planet"] == "Venus"
        end_year = int(venus_maha["end_date"][:4])
        assert end_year <= 2013, f"Venus Maha ended in {end_year}, expected ≤ 2013"

    def test_balance_is_positive_fraction_of_20(self, reference_dasha):
        """Venus balance must be a fraction of the full 20-year Venus period."""
        balance = reference_dasha["dasha_balance_at_birth"]["years_remaining"]
        assert 0 < balance < 20, f"Venus balance {balance} not in (0, 20)"

    def test_birth_nakshatra_is_purva_ashadha(self, reference_dasha):
        """Reference chart: Moon nakshatra should be Purva Ashadha."""
        assert reference_dasha["birth_nakshatra"] == "Purva Ashadha", (
            f"Expected 'Purva Ashadha', got '{reference_dasha['birth_nakshatra']}'"
        )
