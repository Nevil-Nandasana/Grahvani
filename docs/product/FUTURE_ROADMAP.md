# Future Product Roadmap

## Purpose
This document describes Grahvani's post-MVP product evolution -- the planned features, growth initiatives, and platform expansions across Phases 2-4. It is a living document updated quarterly as market feedback and analytics data arrive.

## Scope
Covers all planned features not included in the MVP. See [MVP.md](MVP.md) for the exact MVP scope boundary.

---

## 1. Phase 2 -- Production Hardening and Premium Depth (3-6 months post-launch)

**Goal**: Retain and deepen engagement with the MVP user base. Reduce churn by adding premium chart depth.

| Feature | Why | Engineering Notes |
| :--- | :--- | :--- |
| **D10 / D12 / D60 Divisional Charts** | Most-requested premium feature; completes the Vedic chart experience | Backend already calculates; Flutter `CustomPainter` widget needed |
| **Antar Dasha and Pratyantar Dasha** | Deeper predictive timeline is the #1 astrologer offering | Data in `chart_facts_json`; timeline UI component needed |
| **PDF Chart Export** | Download and share feature; premium upsell driver | WeasyPrint backend task; S3 storage |
| **Push Notifications (Dasha Changes)** | Re-engagement driver: notify when Maha/Antar Dasha changes | Firebase Cloud Messaging + Dramatiq scheduled task |
| **Web App (Flutter Web build)** | Expand to non-mobile users; Razorpay web checkout | `flutter build web`; CDN hosting on S3 + CloudFront |
| **Sade Sati Tracker** | High-demand Saturn transit feature for Indian users | Periodic ephemeris check; notification when Saturn enters Moon sign |

---

## 2. Phase 3 -- Growth and Globalisation (6-18 months)

**Goal**: Grow to 100K+ active users across India and international diaspora markets.

| Feature | Why | Engineering Notes |
| :--- | :--- | :--- |
| **Multi-Language Support (Hindi, Tamil, Telugu, Marathi)** | 80%+ of Indian users are more comfortable in their mother tongue | LLM translation at response time (OD-003); corpus in English + translated UI strings |
| **Voice AI Consultation** | Real-time voice-to-voice astrological Q&A | WebRTC audio stream; Whisper STT + TTS |
| **Synastry (Compatibility Charts)** | Partner/relationship chart comparison | Requires multi-profile selection UI; double chart rendering |
| **Multi-Profile Comparison** | Family member chart overlays | Profile picker; chart diff renderer |
| **International Payment Integration** | Serve UK, US, Australia diaspora | Stripe or Paddle for USD/GBP/EUR |
| **Yearly Varshaphal (Solar Return) Chart** | Annual predictive chart highly valued in Vedic tradition | Annual ephemeris calculation at birthday |
| **Western Astrology (Tropical Zodiac)** | Serve users wanting Tropical zodiac & Western chart wheel views | Ephemeris calculation with `AYANAMSA = 0`; Placidus/Koch house cusps & 360° wheel `CustomPainter` |
| **Horary Astrology (Prashna)** | Instantaneous Q&A chart calculation for specific user questions | Time & place chart generator; KP 1–249 seed number input & Horary RAG prompt pipeline |

---

## 3. Phase 4 -- Marketplace and Platform (18+ months)

**Goal**: Become the platform for Vedic astrology, not just an app.

| Feature | Why | Engineering Notes |
| :--- | :--- | :--- |
| **Verified Human Astrologer Marketplace** | High-margin service for users wanting live consultation | Video calling integration; astrologer verification workflow; payout system |
| **Astrologer Tools (Pro Dashboard)** | Enable professional astrologers to use Grahvani for client management | Multi-client profile management; detailed chart reports |
| **Community Forums** | User engagement flywheel; lower CAC via organic growth | Discourse integration or custom forum |
| **API Access (Developer Tier)** | B2B revenue stream: other apps paying for ephemeris + RAG API | API key management; usage-based billing |
| **Muhurta (Auspicious Timing)** | Find optimal timing for events (weddings, business starts) | Planetary dignity calculation; calendar integration |
| **Numerology & Tarot Reading Suite** | Broaden divination offerings for lifestyle & daily guidance users | Pythagorean & Chaldean numerology calculations; 78-card Tarot draw state machine + LLM interpretations |
| **On-Device LLM Local Inference** | Provide offline AI consultation fallback when network is unavailable | Quantized 1B–3B local SLM runtime (e.g., Llama-3.2-1B / ExecuTorch) integrated via mobile native FFI bindings |

---

## 4. Roadmap Scope Status

> [!NOTE]
> All previously deprioritized features (**Western Astrology**, **Horary/Prashna**, **Numerology & Tarot**, and **On-Device LLM Local Inference**) have been formally integrated into the Phase 3 and Phase 4 active development roadmaps.

---

## 5. Rationale

The phase structure follows a **expand-then-deepen** growth model:
- Phase 1 (MVP): Prove the core value loop works.
- Phase 2: Add depth for power users to reduce churn.
- Phase 3: Acquire users beyond the English-speaking early adopter base.
- Phase 4: Build defensible moat through network effects (marketplace, platform).

---

## 6. Related Documents

- [MVP.md](MVP.md) -- Current MVP scope
- [FEATURE_SPECIFICATIONS.md](FEATURE_SPECIFICATIONS.md) -- Detailed specs for features
- [DEVELOPMENT_ROADMAP.md](../DEVELOPMENT_ROADMAP.md) -- Phase timeline and milestone tracking
- [OPEN_DECISIONS.md](../OPEN_DECISIONS.md) -- Unresolved decisions affecting roadmap items
