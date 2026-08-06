# Astrology Engine Documentation (Deterministic Swiss Ephemeris)

Welcome to the documentation for **Grahvani's Astrology Calculation Engine**. This domain subsystem computes exact mathematical planetary longitudes, divisional charts (D1, D9), and dasha periods deterministically.

---

## 📂 Astrology Documents Index

- 🧮 **[Calculation Engine](CALCULATION_ENGINE.md)** — Planetary position algorithms, house cusps, Ayanamsa selections.
- 🌌 **[Swiss Ephemeris Integration](SWISS_EPHEMERIS.md)** — `pyswisseph` Python C-extension wrapper, Ephemeris data files (`swefiles`).
- 📍 **[Data Validation & Timezones](DATA_VALIDATION.md)** — Coordinates validation, historical timezone resolution (IANA `tzdata`).
- 📊 **[Chart Generation Pipeline](CHART_GENERATION.md)** — Rasi (D1), Navamsa (D9), and Vimshottari Dasha calculations.
- 🔄 **[Astrology Workflow](ASTROLOGY_WORKFLOW.md)** — End-to-end execution path from birth details to immutable chart snapshot.
- 📜 **[Licensing Requirements](LICENSING.md)** — Swiss Ephemeris AGPL vs. Professional Commercial License compliance.

---

## 🏛️ Calculation Engine Architecture

```mermaid
flowchart LR
    Input["Birth Date, Local Time, Lat/Long"] --> TimeZone["1. Resolve Historical UTC Offset (tzdata)"]
    TimeZone --> JulianDay["2. Convert Local Time to Julian Day (UT)"]
    JulianDay --> SwissEph["3. Call pyswisseph C-Library (swe_calc_ut)"]
    SwissEph --> Longitudes["4. Raw Tropical Longitudes & Ayanamsa Subtraction"]
    Longitudes --> SiderealDegrees["5. Sidereal Zodiac Longitudes (0°-360°)"]
    SiderealDegrees --> ChartFacts["6. Construct Immutable Chart Facts JSON"]
```
