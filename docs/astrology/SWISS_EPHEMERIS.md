# Swiss Ephemeris Integration Specification

## Purpose
This document specifies how Grahvani integrates the Swiss Ephemeris library (`pyswisseph`) to calculate planetary positions. It covers the required ephemeris data files, the initialization sequence, and the exact Python API calls required to fetch high-precision data.

## Scope
Applies to the core backend calculation service module and the Docker image build process (which must include the ephemeris data files).

---

## 1. What is Swiss Ephemeris?

The Swiss Ephemeris is the world standard for high-precision astronomical calculations in astrological software. It is a C library developed by Astrodienst AG, based on the NASA JPL Horizons system. Grahvani uses the `pyswisseph` Python wrapper to interface with this C library.

**Note**: For licensing obligations regarding commercial use of this library, see [LICENSING.md](LICENSING.md).

---

## 2. Ephemeris Data Files

To achieve NASA-level precision (error < 0.001 arcseconds), the Swiss Ephemeris requires proprietary data files (`.se1`). 

- **Location**: The files must be mounted or baked into the Docker container at `/app/ephe_data`.
- **Files Required**:
  - `seas_18.se1` (Asteroids, 1800-2399 AD)
  - `semo_18.se1` (Moon, 1800-2399 AD)
  - `sepl_18.se1` (Main planets, 1800-2399 AD)
- **Fallback**: If the data files are missing, `pyswisseph` falls back to the built-in Moshier algorithms, which have an unacceptable error margin (up to 3 arcminutes). **The backend must fail to start if the data files are missing.**

---

## 3. Initialization and State Management

`pyswisseph` is a C extension with global state. It is not thread-safe for writing configuration, but it is thread-safe for reading calculations once configured. We configure it once at FastAPI application startup.

```python
# app/modules/birth_chart/services/ephemeris.py
import swisseph as swe
import os

EPHE_PATH = os.getenv("EPHEMERIS_DATA_PATH", "/app/ephe_data")

def initialize_ephemeris():
    """Run once on startup."""
    if not os.path.exists(f"{EPHE_PATH}/sepl_18.se1"):
        raise RuntimeError("CRITICAL: Swiss Ephemeris data files not found!")
        
    swe.set_ephe_path(EPHE_PATH)
    # Set global sidereal mode to Lahiri
    swe.set_sid_mode(swe.SIDM_LAHIRI)
```

---

## 4. Calculating Planetary Positions

The core calculation requires converting the UTC birth time to a Julian Day number, then querying the C library for each planet.

```python
def calculate_planet_position(julian_day_ut: float, planet_id: int) -> dict:
    """
    Calculates the exact position of a planet for a given Julian Day.
    planet_id: swisseph constant (e.g. swe.SUN)
    """
    # Calculate tropical position with high precision + speed
    flags = swe.FLG_SWIEPH | swe.FLG_SPEED
    results, return_flags = swe.calc_ut(julian_day_ut, planet_id, flags)
    
    tropical_long = results[0]  # Exact tropical degree (0-359.999)
    latitude = results[1]       # Ecliptic latitude
    distance = results[2]       # Distance in AU
    speed = results[3]          # Degree travel per day
    
    # Calculate Ayanamsha for this exact moment in time
    ayanamsa = swe.get_ayanamsa_ut(julian_day_ut)
    
    # Convert Tropical to Sidereal (Vedic)
    sidereal_long = (tropical_long - ayanamsa) % 360.0
    
    return {
        "tropical_longitude": tropical_long,
        "sidereal_longitude": sidereal_long,
        "speed": speed,
        "is_retrograde": speed < 0,
        "ayanamsa": ayanamsa,
    }
```

---

## 5. Rationale

**Why manual Tropical-to-Sidereal conversion?** 
`pyswisseph` *can* return sidereal positions directly by adding the `swe.FLG_SIDEREAL` flag. However, performing the calculation manually (by subtracting `swe.get_ayanamsa_ut`) makes the exact Ayanamsha value explicit in the returned JSON structure. This makes debugging much easier if a user reports a discrepancy between Grahvani and another astrology app, as we can instantly see the exact Ayanamsha value applied.

---

## 6. Related Documents

- [CALCULATION_ENGINE.md](CALCULATION_ENGINE.md) -- The mathematical foundation for the engine
- [LICENSING.md](LICENSING.md) -- Commercial licensing plan for the Swiss Ephemeris
- [infrastructure/DOCKER.md](../infrastructure/DOCKER.md) -- How the `.se1` data files are baked into the container
