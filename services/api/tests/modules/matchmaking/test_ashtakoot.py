import pytest
from app.modules.matchmaking.calculations import compute_ashtakoot

def test_compute_ashtakoot_same_nakshatra():
    """Test matching the exact same nakshatra. Nadi dosha should trigger (0 pts)."""
    result = compute_ashtakoot("Cancer", "Pushya", "Cancer", "Pushya")
    
    assert result["varna"] == 1.0
    assert result["vashya"] == 2.0
    assert result["nadi"] == 0.0  # Nadi dosha
    assert result["total"] < 36.0

def test_compute_ashtakoot_general():
    """Test a general match between two different signs and nakshatras."""
    result = compute_ashtakoot("Aries", "Ashwini", "Taurus", "Rohini")
    
    assert "total" in result
    assert result["total"] > 0
    assert result["total"] <= 36.0
    
    # Aries vs Taurus -> distance 1, Bhakoot should be 0.0
    assert result["bhakoot"] == 0.0
