# Swiss Ephemeris Licensing Requirements

## Purpose
This document describes the licensing obligations for the Swiss Ephemeris library used in Grahvani's calculation engine, the action plan for acquiring a commercial license, and the operational risk profile of the current development-phase license.

## Scope
Applies to any deployment of Grahvani that uses `pyswisseph` (the Python wrapper for the Swiss Ephemeris C-library) for astronomical calculations.

---

## 1. Swiss Ephemeris Dual-License Overview

The Swiss Ephemeris software library is copyrighted by **Astrodienst AG** (Zurich, Switzerland). It is dual-licensed:

| License | Type | Requirement | Suitable For |
| :--- | :--- | :--- | :--- |
| **AGPL v3 (Open Source)** | Free to use | Full backend source code must be publicly released (including all modules using Swiss Ephemeris, even over network) | Open-source projects |
| **Professional Commercial License** | Paid, one-time fee | No source code disclosure required | Commercial SaaS, closed-source products |

**Grahvani uses the AGPL v3 license during development only.** As a revenue-generating commercial SaaS platform with closed-source code, Grahvani must acquire the **Professional Commercial License** before any public launch or monetization.

---

## 2. AGPL v3 Compliance During Development

During the pre-commercial development phase, the AGPL v3 license is in effect. This means:

- **The source code is not currently published** -- this is a license violation risk during development if Grahvani is accessed over a network by any external party (even beta testers).
- **Immediate Action Required**: All non-team external beta testing must either:
  - Operate under a signed NDA with an AGPL license exception, OR
  - Trigger immediate acquisition of the commercial license.

---

## 3. Commercial License Acquisition Plan

| Step | Action | Responsible | Target Date |
| :--- | :--- | :--- | :--- |
| 1 | Contact Astrodienst AG licensing team at `licensing@astro.com` | Founder / Legal | Before first external beta |
| 2 | Obtain price quotation for SaaS commercial license | Founder | Pre-MVP |
| 3 | Review and execute license agreement | Legal counsel | Pre-MVP |
| 4 | Store license certificate in Google Drive (Legal folder) | Operations | Post-execution |
| 5 | Add license reference to system documentation and app footer | Engineering | Post-execution |

**Approximate License Cost**: Astrodienst AG typically charges a one-time license fee in the CHF 2,000-8,000 range depending on usage scale and distribution type. Contact them for an exact quote.

---

## 4. Alternative: OpenEphemeris / Astropy

If the commercial license fee is prohibitive or licensing terms are unfavorable, a contingency calculation engine using **Astropy** (BSD licensed, fully open-source) or the **Jean Meeus algorithms** (public domain) is documented in the engineering backlog:

| Alternative | License | Accuracy vs. Swiss Ephemeris | Implementation Effort |
| :--- | :--- | :--- | :--- |
| **Astropy** | BSD-3 | High for solar system bodies; no native Ayanamsha | 3-4 weeks to port |
| **Jean Meeus algorithms** | Public domain | Moderate (~1 arcminute accuracy) | 6-8 weeks to implement |
| **flatlib (Python)** | LGPL | Good; built on Swiss Ephemeris (same license problem) | Not viable |

**Recommendation**: Proceed with Swiss Ephemeris commercial license. Astropy is the fallback only if commercial terms are unacceptable.

---

## 5. Rationale

Swiss Ephemeris is the industry standard for precision astronomical calculations, used by professional astrology software worldwide including Jagannatha Hora, Kala, and Astro.com. Its accuracy (< 1 arcsecond deviation from NASA JPL Horizons) is essential for Grahvani's "accuracy-first" brand promise. No open-source alternative matches its precision and Ayanamsha support quality.

---

## 6. Trade-offs

| Choice | Pro | Con |
| :--- | :--- | :--- |
| Swiss Ephemeris (Commercial License) | Industry-standard precision, full Ayanamsha support, active maintenance | One-time license fee; contractual obligations |
| Astropy (BSD) | Free, modern Python, active community | No native Vedic ayanamsha support; requires custom implementation |

---

## 7. Future Improvements

- **Annual Compliance Review**: Confirm license validity at each product anniversary to ensure coverage for expanded user tiers.
- **Ephemeris Version Pinning**: Pin `pyswisseph` to a tested version in `pyproject.toml` and document it in `chart_facts_json.snapshot_version` for reproducibility.

---

## 8. Related Documents

- [CALCULATION_ENGINE.md](CALCULATION_ENGINE.md) -- How Swiss Ephemeris is integrated in the calculation pipeline
- [SWISS_EPHEMERIS.md](SWISS_EPHEMERIS.md) -- Technical integration details and pyswisseph usage
- [COMPLIANCE.md](../security/COMPLIANCE.md) -- Overall compliance obligations
- [OPEN_DECISIONS.md](../OPEN_DECISIONS.md) -- Open decision OD-004 on timezone database
