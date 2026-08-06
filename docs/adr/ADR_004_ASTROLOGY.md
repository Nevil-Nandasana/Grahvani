# ADR-004: Swiss Ephemeris C-Library (`pyswisseph`) for Planetary Calculations

> [[ADR Index](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/adr/README.md) | [Calculation Engine](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/astrology/CALCULATION_ENGINE.md) | [Swiss Ephemeris Specs](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/astrology/SWISS_EPHEMERIS.md) | [Licensing Specs](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/astrology/LICENSING.md)]

---

## Metadata
- **Status**: Accepted
- **Date**: 2026-08-01
- **Deciders**: Lead Astrological Engineer, Backend Architect
- **Technical Story**: Selecting the astronomical calculation engine for computing exact planetary positions, houses, ayanamsas, and dasha periods in Grahvani.

---

## Context & Problem Statement

Vedic astrology requires extreme astronomical precision (sub-arcsecond accuracy for planetary longitudes, house cusps, and node positions). Calculating planetary positions based on date, time, and coordinates is a deterministic physical problem. We must select an astronomical calculation engine that guarantees commercial precision and strict correctness.

---

## Options Considered

### Option 1: AI / LLM Calculation
Use LLM prompts to estimate or compute planetary positions directly.

- **Pros**: None.
- **Cons**: Catastrophic failure mode; LLMs cannot perform precise floating-point astronomical ephemeris calculations. Completely rejected.

---

### Option 2: Pure Python Approximations (e.g. Simplified Keplerian Orbits)
Implement simplified Python mathematical scripts for planetary motion.

- **Pros**: Pure Python without C-extensions.
- **Cons**: Lacks sub-arcsecond accuracy; fails for historical dates and fast-moving bodies (Moon, Mercury); does not support complex house systems or historical delta-T corrections.

---

### Option 3: Swiss Ephemeris via Python Wrapper (`pyswisseph`) — **ACCEPTED**
Integrate **Swiss Ephemeris** (Astrodienst AG), the global industry standard for astronomical ephemeris computing, through the Python `pyswisseph` wrapper.

- **Pros**:
  - **Sub-Arcsecond Accuracy**: Derived from NASA JPL DE431 ephemeris data.
  - **Comprehensive Ayanamsa Support**: Native support for Lahiri (Chitra Paksha), Raman, Krishnamurti (KP), and Fagan-Bradley ayanamsas.
  - **High Performance**: Executed in compiled C code at sub-millisecond execution speeds per chart.
- **Cons**: Swiss Ephemeris is dual-licensed (AGPL v2 or Professional Commercial License). Grahvani MUST purchase the **Swiss Ephemeris Commercial License** before launch to maintain closed-source status.

---

## Decision Outcome

**Chosen Option**: **Option 3: Swiss Ephemeris via `pyswisseph`**.

### Licensing Compliance Strategy
- Grahvani will procure the official **Swiss Ephemeris Professional Commercial License** from Astrodienst AG prior to public commercial launch ([Licensing Specs](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/astrology/LICENSING.md)).

---

## Re-evaluation Trigger
- Re-evaluate if NASA JPL publishes a newer JPL DE series file required for historical astronomical research beyond the year 5000 CE.
