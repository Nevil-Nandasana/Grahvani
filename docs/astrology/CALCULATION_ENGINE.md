# Calculation Engine Specification

## Purpose
This document defines the mathematical foundation, coordinate systems, and astrological constants used by the Grahvani calculation engine. It ensures deterministic, highly accurate chart generation that aligns with standard Indian Vedic astrological practice.

## Scope
Applies to the core backend calculation service module that interfaces with the Swiss Ephemeris wrapper.

---

## 1. Mathematical Foundation & Coordinate Systems

Vedic astrology uses the **Sidereal Zodiac** (Nirayana), unlike Western astrology which uses the Tropical Zodiac (Sayana). Grahvani computes all planetary positions in the Sidereal system.

### 1.1 The Ayanamsha 
The difference between the Tropical and Sidereal systems is the Precession of the Equinoxes, quantified by a value called the **Ayanamsha**. 
Grahvani standardizes exclusively on the **Lahiri (Chitra Paksha) Ayanamsha** ($SE\_SIDM\_LAHIRI = 1$).

### 1.2 Ayanamsha Subtraction Formula
The core calculation performed by the engine for every body is:
$$\text{Longitude}_{\text{Sidereal}} = (\text{Longitude}_{\text{Tropical}} - \text{Ayanamsa}_{\text{Lahiri}}) \pmod{360^\circ}$$

---

## 2. Calculated Astronomical Bodies

The engine deterministically computes 10 primary points for every chart. The output is a floating-point degree representing the exact position on the $360^\circ$ ecliptic plane.

| Body / Point | Swiss Ephemeris ID | Notes |
| :--- | :--- | :--- |
| **Sun** | `SE_SUN` (0) | |
| **Moon** | `SE_MOON` (1) | Exact degree is critical for Vimshottari Dasha calculation. |
| **Mars** | `SE_MARS` (4) | |
| **Mercury** | `SE_MERCURY` (2) | |
| **Jupiter** | `SE_JUPITER` (5) | |
| **Venus** | `SE_VENUS` (3) | |
| **Saturn** | `SE_SATURN` (6) | |
| **Rahu** | `SE_MEAN_NODE` (10) | North Lunar Node. Grahvani uses the **Mean Node** calculation, which is standard in Lahiri/Vedic practice. |
| **Ketu** | N/A (Derived) | South Lunar Node. Calculated as: $(\text{Rahu} + 180^\circ) \pmod{360^\circ}$. |
| **Ascendant** | `SE_ASC` | Also called Lagna. Calculated based on the precise latitude and longitude of the birth city. |

---

## 3. Zodiac Signs & Degreewise Subdivision

Once the $360^\circ$ sidereal longitude is calculated, it must be mapped to one of the 12 Zodiac signs (Rashis). Each sign occupies exactly $30^\circ$.

### 3.1 Sign Mapping Formulas
To find the sign index ($0 = \text{Aries}, 1 = \text{Taurus}, \dots, 11 = \text{Pisces}$):
$$\text{Sign Index} = \left\lfloor \frac{\text{Longitude}_{\text{Sidereal}}}{30} \right\rfloor$$

To find the exact degree *within* that sign (used for UI display, e.g., "14° Scorpio"):
$$\text{Sign Degree} = \text{Longitude}_{\text{Sidereal}} \pmod{30^\circ}$$

---

## 4. Nakshatra (Constellation) Calculation

Vedic astrology further subdivides the ecliptic into 27 Nakshatras, each spanning $13^\circ 20'$ ($13.333^\circ$).

### 4.1 Nakshatra Formulas
To find the Nakshatra index ($0 = \text{Ashwini}, \dots, 26 = \text{Revati}$):
$$\text{Nakshatra Index} = \left\lfloor \frac{\text{Longitude}_{\text{Sidereal}}}{13.333333} \right\rfloor$$

To find the Pada (quarter) of the Nakshatra ($1, 2, 3, \text{ or } 4$):
$$\text{Pada} = \left\lfloor \left( \frac{\text{Longitude}_{\text{Sidereal}}}{3.333333} \right) \pmod{4} \right\rfloor + 1$$

---

## 5. Rationale

Standardizing exclusively on the **Lahiri Ayanamsha** and **Mean Nodes** prevents user confusion and simplifies the AI prompting pipeline. Giving users the option to select from 15 different Ayanamshas or True Nodes leads to conflicting chart generation and breaks the deterministic validation tests. Lahiri is the official Ayanamsha adopted by the Government of India and is expected by 95%+ of the target market.

---

## 6. Related Documents

- [SWISS_EPHEMERIS.md](SWISS_EPHEMERIS.md) -- Detailed C-library integration
- [DATA_VALIDATION.md](DATA_VALIDATION.md) -- Timezone and coordinate inputs required for these calculations
- [testing/UNIT_TESTS.md](../testing/UNIT_TESTS.md) -- The reference test vectors that validate these mathematical formulas
