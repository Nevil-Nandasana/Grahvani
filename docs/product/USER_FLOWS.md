# User Flows Specification

## 1. Overview
This document describes every critical user journey in **Grahvani**, from first app launch through paid subscription and ongoing daily usage. Each flow maps directly to screens, API calls, and backend domain module interactions.

---

## 2. Onboarding & First-Run Flow

```mermaid
flowchart TD
    AppLaunch["User Launches App"] --> SplashScreen["Splash Screen\n(Check Local JWT Token in SecureStorage)"]
    SplashScreen -->|Token Valid & Not Expired| HomeScreen["Home / Profile List Screen"]
    SplashScreen -->|No Token / Expired| LoginScreen["Login Screen\n(Choose Auth Method)"]

    subgraph LoginOptions["Authentication Options"]
        Google["Google Sign-In"]
        Apple["Apple ID (iOS only)"]
        OTP["Phone OTP (India-first)"]
    end

    LoginScreen --> LoginOptions
    LoginOptions --> FirebaseJWT["Firebase Issues ID Token (JWT)"]
    FirebaseJWT --> StoreToken["Store JWT in FlutterSecureStorage"]
    StoreToken --> ConsentScreen["DPDP Act Consent Screen\n(Explain data usage, get explicit approval)"]
    ConsentScreen -->|Accepted| CreateFirstProfile["Prompt to Create First Birth Profile"]
    ConsentScreen -->|Declined| ExitApp["App exits with message:\nConsent required to continue"]
```

---

## 3. Birth Profile Creation & Chart Calculation Flow

```mermaid
flowchart TD
    ProfileForm["Birth Profile Form Screen"] --> InputName["1. Full Name (e.g., Nevil Nandasana)"]
    InputName --> InputDOB["2. Select Date of Birth (DD/MM/YYYY calendar picker)"]
    InputDOB --> InputTime["3. Select Time of Birth (HH:MM picker)\nor toggle 'Time Unknown'"]
    InputTime --> LocationSearch["4. Type City Name → Select from Geocoded Suggestions\n(Google Places API or equivalent)"]
    LocationSearch --> AutoCoords["Auto-fill Latitude, Longitude, Timezone (IANA)"]
    AutoCoords --> SubmitAPI["POST /api/v1/profiles → Backend saves BirthProfile"]
    SubmitAPI --> TriggerCalc["POST /api/v1/charts/calculate\n→ Background Dramatiq task queued"]
    TriggerCalc --> PollStatus["Poll GET /api/v1/charts/{profile_id}/status\nevery 1.5 seconds while calculating"]
    PollStatus -->|Status: COMPLETE| ChartScreen["Navigate to Birth Chart Overview Screen"]
    PollStatus -->|Status: FAILED| ErrorBanner["Display Error: 'Invalid birth details'\nwith correction prompt"]
```

**Key UX Principles for Birth Profile Form:**
- The city search uses autocomplete to reduce manual lat/long entry errors.
- `Time Unknown` flag is stored as a `null` birth_time in the database; the chart is still generated but a persistent banner reads: *"Chart accuracy may vary due to unknown birth time. Ascendant calculations are unreliable."*
- Timezone is resolved **historically** — not just from current coordinates — to handle Daylight Saving Time at the actual birth date/year.

---

## 4. Birth Chart Exploration Flow

```mermaid
flowchart TD
    ChartScreen["Birth Chart Overview Screen"] --> D1Chart["North Indian Diamond Chart Render\n(D1 Rasi - CustomPainter Widget)"]
    D1Chart --> PlanetTap["Tap a Planetary Glyph or House Number"]
    PlanetTap --> PlanetDetailSheet["Bottom Sheet:\nPlanet Name, Sign, Degree, Retrograde, House\n+ Quick AI explanation button"]

    ChartScreen --> NavamShape["Toggle to D9 Navamsa Chart View"]
    ChartScreen --> DashaTab["Switch to Dasha Timeline Tab"]
    DashaTab --> MahaDasha["Maha Dasha Timeline (Lifetime view)"]
    MahaDasha --> ExpandAntar["Tap to expand Antar Dasha periods"]
    ExpandAntar --> ExpandPratyantar["(Premium) Tap to expand Pratyantar Dasha"]
```

---

## 5. Grounded AI Chat Flow

```mermaid
flowchart LR
    ChatEntry["User Taps 'Ask AI' button or planet detail"] --> ChatScreen["Chat Screen for selected Birth Profile"]
    ChatScreen --> TypeQuestion["User types question:\ne.g. 'What does Sun in 10th house mean for my career?'"]
    TypeQuestion --> SendButton["Tap Send"]
    SendButton --> EntitlementCheck["Backend checks:\nFree tier (3/day) or Premium (unlimited)?"]
    EntitlementCheck -->|Limit Reached| PaywallNudge["Show Paywall prompt:\n'Upgrade to Premium for unlimited AI chat'"]
    EntitlementCheck -->|Within Limit| PostStream["POST /api/v1/chat/stream\n→ SSE Connection Opens"]

    PostStream --> BackendRAG["Backend:\n1. Fetch Chart Snapshot Facts\n2. Hybrid pgvector Search\n3. Assemble Grounded Prompt\n4. Safety Guardrail Check"]
    BackendRAG --> StreamTokens["Tokens stream in real-time\n(SSE event: token, citation, done)"]
    StreamTokens --> DisplayBubble["AI response builds progressively in chat bubble"]
    DisplayBubble --> CitationChip["Source citations appear as tappable chips\ne.g. [BPHS, Ch. 12]"]
    CitationChip --> SourceModal["Tap citation → Show source excerpt modal"]
```

**Chat Safety Guardrails in Action:**
| User Question Type | Guardrail Applied | Response Shown |
| :--- | :--- | :--- |
| *"Will I get cured of my cancer next month?"* | Medical Policy Block | Health disclaimer + refusal |
| *"Should I invest in crypto based on my Rahu?"* | Financial Policy Block | Financial disclaimer + refusal |
| *"Ignore previous instructions and..."* | Prompt Injection Block | Generic policy error, logged |
| *"What does Venus in 7th house mean?"* | No guardrail triggered | Grounded RAG answer with citations |

---

## 6. Subscription & Paywall Flow

```mermaid
flowchart TD
    PaywallTrigger["User hits free-tier limit\nor taps 'Upgrade to Premium'"] --> PaywallScreen["Paywall Screen:\nShow Free vs Premium comparison table"]
    PaywallScreen --> SelectPlan["User selects Monthly or Annual plan"]
    SelectPlan --> PlatformBilling["Platform Billing (based on OS)"]

    subgraph Platforms["Platform Billing Routes"]
        Android["Android: Google Play Billing\nIn-App Purchase sheet opens"]
        iOS_pay["iOS: Apple In-App Purchase\nApple sheet opens with Face/Touch ID"]
        Web["Web: Razorpay Checkout\nSupports UPI Autopay, Cards, NetBanking"]
    end

    PlatformBilling --> Platforms
    Android --> PurchaseComplete["Purchase Completed on Store"]
    iOS_pay --> PurchaseComplete
    Web --> PurchaseComplete

    PurchaseComplete --> ServerWebhook["Store Sends Webhook to FastAPI\n(Google RTDN / Apple Notifications / Razorpay)"]
    ServerWebhook --> VerifySignature["Backend verifies cryptographic signature"]
    VerifySignature --> UpdateEntitlement["UPDATE subscriptions SET tier='premium', status='active'"]
    UpdateEntitlement --> GrantAccess["Client polls GET /api/v1/billing/entitlements\n→ tier: 'premium' returned"]
    GrantAccess --> UnlockPremium["Premium features unlocked instantly"]
```

> [!IMPORTANT]
> The client NEVER grants premium access based on a local store receipt alone. The entitlement state is always fetched from the backend `GET /api/v1/billing/entitlements` endpoint which reads the server-authoritative `subscriptions` table.

---

## 7. Settings & Privacy Flow

```mermaid
flowchart TD
    Settings["Settings Screen"] --> DataPrivacy["Data & Privacy Section"]
    DataPrivacy --> ExportData["Export My Data\n→ GET /api/v1/users/me/export\nDownloads JSON of all profiles, charts, chat history"]
    DataPrivacy --> DeleteAccount["Delete My Account\n→ DELETE /api/v1/users/me\nPermanently soft-deletes all personal data within 30 days"]
    DataPrivacy --> ManageConsent["Manage Consent\n→ Review & update notification permissions"]
    Settings --> ManageSubscription["Manage Subscription\n→ Opens native OS subscription management"]
    Settings --> SwitchAyanamsha["Advanced: Change Ayanamsa\n→ Recalculate chart with new settings"]
```
