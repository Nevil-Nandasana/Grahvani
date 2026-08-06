# Feature Specifications

## Purpose
This document provides the definitive specifications for the core user-facing features of the Grahvani MVP. It acts as the bridge between product requirements and engineering implementation, defining exactly what each feature does, how it behaves, and its boundary limits.

## Scope
Covers the 4 core features of the MVP: Birth Profile Management, Interactive Chart Explorer, Vimshottari Dasha Explorer, and Grounded AI RAG Chat. 

---

## 1. Birth Profile Management

**Objective**: Allow users to securely save and manage the birth details required to calculate an astrological chart.

### 1.1 Requirements
- **Data Points Collected**: Full Name, Date of Birth (YYYY-MM-DD), Time of Birth (HH:MM), Birth City (autocomplete).
- **Location Resolution**: The Birth City input MUST autocomplete against the Google Places API to guarantee valid latitude, longitude, and IANA timezone ID resolution. Manual coordinate entry is prohibited to prevent user error.
- **Capacity limits**: 
  - Free Tier: Max 1 profile.
  - Premium Tier: Unlimited profiles.
- **Privacy**: The user's own primary profile cannot be deleted unless the entire account is deleted (DPDP Act requirement).

### 1.2 User Flow
1. User taps "Add Profile" on the home dashboard.
2. User fills out the 4-step form.
3. On submit, the app POSTs to `/api/v1/profiles`.
4. The backend stores the data and synchronously triggers a Dramatiq background task to pre-calculate the Swiss Ephemeris `chart_facts_json`.
5. The UI returns to the dashboard, displaying a loading skeleton until the calculation is complete.

---

## 2. Interactive Chart Explorer

**Objective**: Render the calculated astrological data into a visually stunning, interactable North Indian diamond chart.

### 2.1 Requirements
- **Rendering**: Must use Flutter `CustomPainter` to draw the diamond grid natively (no web views or static images). This ensures crisp rendering on high-DPI displays.
- **Data Display**: 
  - Zodiac sign number (1-12) in the corner of each house.
  - Planet abbreviations (Su, Mo, Ma, Me, Ju, Ve, Sa, Ra, Ke, Asc) in their respective houses.
  - Retrograde indicators (an underscore or specific color) for retrograde planets.
- **Interactivity**: Tapping a house must highlight it and open a bottom sheet detailing the exact degrees of the planets in that house, their nakshatra (constellation), and dignity (exalted/debilitated).
- **Supported Charts**: D1 (Rasi/Birth) and D9 (Navamsa) for all users. D10, D12, D60 for Premium users.

---

## 3. Vimshottari Dasha Explorer

**Objective**: Display the user's planetary timeline (Dasha), showing which planetary periods they are currently experiencing.

### 3.1 Requirements
- **Calculation Basis**: Must be calculated based on the precise degree of the Moon at birth using the Lahiri Ayanamsha (360-day year standard).
- **Timeline UI**: Rendered as a vertical scrolling list.
- **Current Indicator**: The UI must automatically scroll to and highlight the Dasha period encompassing `DateTime.now()`.
- **Depth Limit**:
  - Free Tier: Maha Dasha only (major periods spanning years).
  - Premium Tier: Expandable accordions for Antar Dasha (sub-periods) and Pratyantar Dasha (sub-sub-periods).

---

## 4. Grounded AI RAG Chat

**Objective**: The core differentiator of Grahvani -- allow users to ask natural language questions about their chart and receive answers grounded entirely in classical texts.

### 4.1 Requirements
- **Input Limit**: User questions are capped at 500 characters.
- **Streaming UI**: The response must stream token-by-token (SSE) into a chat bubble to minimize perceived latency.
- **Citations**: 
  - The response MUST include source citations.
  - Citations are rendered as interactive "chips" above or within the chat bubble (e.g., `[BPHS Ch 12]`).
  - Tapping a citation chip opens a modal displaying the original Sanskrit shloka (if available) and the English translation chunk used by the LLM.
- **History**: The chat interface must display the last 7 days of conversation history (Free tier) or 12 months (Premium).
- **Guardrail Enforcement**: If a user asks a medical or financial question, the UI must gracefully display the guardrail rejection message without crashing or showing a raw API error.

---

## 5. Rationale

The specification of a **native `CustomPainter`** for the chart instead of an HTML canvas/webview is a critical product decision. Webviews introduce scroll jank, scaling artifacts on iOS Retina displays, and make the tap-to-inspect interactivity feel sluggish. The native implementation requires more initial engineering but delivers the "premium, state-of-the-art" feel demanded by the brand.

---

## 6. Related Documents

- [product/MVP.md](MVP.md) -- Scope boundaries for the initial release
- [product/PREMIUM_FEATURES.md](PREMIUM_FEATURES.md) -- Details on the Free vs Premium breakdown
- [astrology/CALCULATION_ENGINE.md](../astrology/CALCULATION_ENGINE.md) -- How the backend calculates the chart data displayed by the UI
- [api/STREAMING.md](../api/STREAMING.md) -- The SSE technical spec for the AI Chat feature
