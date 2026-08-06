# Compliance, Legal Disclaimers, and Regulatory Standards

## Purpose
This document specifies all compliance obligations that Grahvani must meet, including legal disclaimers displayed to users, data protection regulatory obligations, app store review policy requirements, and content moderation standards. It serves as the authoritative compliance checklist for product, legal, and engineering teams.

## Scope
Applies to all user-facing content, API responses, onboarding flows, and marketing materials for Grahvani across all platforms (iOS, Android, Web).

---

## 1. Mandatory Legal Disclaimer

All astrological AI responses delivered by Grahvani must display the following mandatory disclaimer. It is embedded in the system prompt so the AI never omits it, and it is displayed as a persistent footer in the chat UI.

**Standard Disclaimer Text:**
> **Disclaimer**: Grahvani provides astrological insights for personal self-reflection, educational, and entertainment purposes only. Astrological output does not constitute professional medical, psychological, legal, financial, or other regulated advice. For important life decisions, always consult a qualified professional.

**Where it must appear:**
- First AI chat response in every new chat session
- PDF chart export footer (every page)
- App Store / Play Store listing description
- Terms of Service (Section 3: Nature of Services)
- Onboarding screen (pre-consent flow)

---

## 2. Indian Digital Personal Data Protection (DPDP) Act Compliance

Grahvani operates as a **Data Fiduciary** under the Indian DPDP Act 2023, collecting and processing personal data (birth date, time, location, name) for astrological calculation purposes.

### 2.1 Data Collection Obligations

| Obligation | Implementation |
| :--- | :--- |
| **Purpose Limitation** | Birth data is collected solely for chart calculation and AI interpretation. It is never shared with third parties for advertising. |
| **Consent Notice** | A clear consent screen is presented before any data is saved, explaining exactly what data is collected and why (see [DATA_PRIVACY.md](DATA_PRIVACY.md)). |
| **Data Minimisation** | Grahvani collects only what is needed: name, birth date, time, city. No social graphs, contacts, or location tracking. |
| **Right to Erasure** | `DELETE /api/v1/users/me` initiates a permanent 30-day scheduled purge of all personal data. |
| **Right to Portability** | `GET /api/v1/users/me/export` returns a JSON export of all profiles, charts, and chat history. |
| **Breach Notification** | Security incidents affecting personal data must be reported to the Data Protection Board of India within 72 hours. |

### 2.2 Data Localisation
All production data is stored within **AWS Mumbai (`ap-south-1`)** to satisfy Indian data localisation expectations for personally sensitive data.

---

## 3. App Store Compliance Requirements

### 3.1 Apple App Store (iOS)
- **Guideline 1.4.3**: App must not enable, encourage, or facilitate illegal activity. Astrological content is categorised as entertainment under Guideline 4.3.
- **Guideline 3.1.1**: In-App Purchases must use Apple IAP for digital content. Physical goods are exempt; Razorpay is used for web-only subscription fallback.
- **Privacy Nutrition Label**: Must accurately declare data types collected (Name, Birth Date, Location -- linked to user identity, for app functionality).

### 3.2 Google Play Store (Android)
- **Families Policy**: Grahvani is rated **Teen (13+)** and must not contain content incompatible with this rating.
- **Financial Features Policy**: App must display appropriate disclaimers whenever astrological content could be interpreted as financial guidance.
- **Data Safety Form**: Declares collection of Personal Info (Name), Location (Birth Location), and App Activity (Chat History), used for core app functionality, not shared with third parties.

---

## 4. AI Content Policy Compliance

### 4.1 Prohibited AI Output Categories
The guardrail system (see [ai/GUARDRAILS.md](../ai/GUARDRAILS.md)) enforces hard blocks on the following categories:

| Prohibited Category | Example Prompt | Guardrail Response |
| :--- | :--- | :--- |
| Medical diagnosis/prognosis | "Will my illness worsen this year?" | Health disclaimer + refusal |
| Longevity/death predictions | "When will I die based on my chart?" | Health disclaimer + refusal |
| Financial investment advice | "Should I invest in property based on my Jupiter?" | Financial disclaimer + refusal |
| Legal outcome predictions | "Will I win my court case?" | Legal disclaimer + refusal |
| Religious/caste discrimination | Any content profiling based on birth + caste | Hard block, no response |
| Crisis/suicide content | Any expression of self-harm intent | Crisis helpline response, alert |

### 4.2 Crisis Response Protocol
If user input matches crisis keywords (suicidal ideation, self-harm), the AI response is immediately replaced with:
> "I'm not able to provide astrological guidance on this. If you're going through a difficult time, please reach out to iCall India at 9152987821 or Vandrevala Foundation at 1860-2662-345. You're not alone."

---

## 5. Swiss Ephemeris Commercial License

The Swiss Ephemeris C-library (Astrodienst AG) is dual-licensed. Grahvani must acquire the **Professional Commercial License** before any revenue-generating launch (see [astrology/LICENSING.md](../astrology/LICENSING.md)).

---

## 6. Future Improvements

- **GDPR Readiness** (Phase 3 -- Global Expansion): Add EU DPO appointment, Cookie Consent banner for web, and Article 15-17 data subject request automation.
- **ISO 27001 Preparation**: As the user base grows, initiate an ISO 27001 information security management audit.
- **Responsible AI Disclosure**: Publish a public AI Transparency Statement describing model capabilities, limitations, and content policy.

---

## 7. Related Documents

- [DATA_PRIVACY.md](DATA_PRIVACY.md) -- DPDP consent implementation details
- [ENCRYPTION.md](ENCRYPTION.md) -- Data encryption at rest and in transit
- [SECRETS.md](SECRETS.md) -- Secrets management policy
- [ai/GUARDRAILS.md](../ai/GUARDRAILS.md) -- AI content guardrail implementation
- [astrology/LICENSING.md](../astrology/LICENSING.md) -- Swiss Ephemeris commercial license
