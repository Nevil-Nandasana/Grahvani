# End-to-End (E2E) Testing Specification (Maestro)

## Purpose
This document defines the E2E test strategy for Grahvani's mobile application using **Maestro**, a mobile-native UI testing framework. E2E tests simulate real user journeys on Android emulators and iOS simulators without any test doubles or mocked APIs.

## Scope
Covers critical user journeys: onboarding, birth profile creation, chart generation, AI chat, and premium subscription paywall. Does not replace unit tests; E2E tests verify integration of all layers end-to-end.

---

## 1. Why Maestro

| Tool | Verdict | Reason |
| :--- | :--- | :--- |
| **Maestro** | Selected | YAML-first, no code required for simple flows; excellent Android emulator support; native CI integration |
| Flutter Integration Test | Rejected | Requires code; slow on CI; harder to maintain by non-developers |
| Appium | Rejected | Heavy setup; complex driver management for Flutter widgets |

---

## 2. Maestro Flow Configuration

Maestro test flows are YAML files stored in `tests/e2e/flows/`. They run against a staging backend with seeded test data.

### 2.1 Onboarding Flow (`onboarding_flow.yaml`)

```yaml
appId: com.grahvani.app
---
- launchApp:
    clearState: true        # Fresh install simulation

# Step 1: Login with Google
- tapOn: "Sign in with Google"
- assertVisible: "Grahvani"   # Google sign-in modal opens, then returns

# Step 2: Consent screen
- assertVisible: "We need your consent"
- tapOn: "I Agree and Continue"

# Step 3: Add first birth profile
- assertVisible: "Add Your Birth Profile"
- tapOn: "Full Name"
- inputText: "Test User"
- tapOn: "Date of Birth"
- selectDatePickerValue: "1990-01-15"
- tapOn: "Time of Birth"
- selectTimePickerValue: "06:30"
- tapOn: "Birth City"
- inputText: "Mumbai"
- tapOn: "Mumbai, Maharashtra, India"   # Autocomplete suggestion

# Step 4: Calculate chart
- tapOn: "Calculate My Birth Chart"
- assertVisible: "Calculating..."       # Loading state
- assertVisible: "Scorpio Ascendant"   # Chart result (seeded test vector)
```

### 2.2 AI Chat Flow (`ai_chat_flow.yaml`)

```yaml
appId: com.grahvani.app
---
- launchApp

# Navigate to chart
- tapOn: "Test User"

# Open AI chat
- tapOn: "Ask AI"
- assertVisible: "What would you like to know?"

# Ask a question
- tapOn: "Type your question..."
- inputText: "What does my Sun placement mean?"
- tapOn: "Send"

# Wait for streaming response
- waitForAnimationToEnd:
    timeout: 15000
- assertVisible: "BPHS"    # Citation must appear in response
- assertNotVisible: "error" # No error state
```

### 2.3 Paywall Flow (`paywall_flow.yaml`)

```yaml
appId: com.grahvani.app
---
- launchApp

# Trigger free tier limit
- repeat:
    times: 3
    commands:
      - tapOn: "Ask AI"
      - inputText: "Tell me about my chart"
      - tapOn: "Send"
      - waitForAnimationToEnd:
          timeout: 10000
      - tapOn: "Back"

# 4th question should hit paywall
- tapOn: "Ask AI"
- inputText: "Tell me about my Jupiter"
- tapOn: "Send"
- assertVisible: "Upgrade to Premium"   # Paywall bottom sheet
- assertVisible: "299"                   # Show price
```

---

## 3. CI Integration

```yaml
# .github/workflows/e2e.yml
name: E2E Tests (Maestro)
on:
  push:
    branches: [main, staging]

jobs:
  e2e-android:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 34
          script: |
            flutter build apk --flavor staging
            adb install build/app/outputs/flutter-apk/app-staging-release.apk
            maestro test tests/e2e/flows/ --format junit --output e2e-results.xml
      - uses: actions/upload-artifact@v4
        with:
          name: e2e-results
          path: e2e-results.xml
```

---

## 4. Test Data Strategy

E2E tests run against a **staging backend** with seeded deterministic test data:
- Test user account: `e2e-test@grahvani.app` (Firebase Auth staging project)
- Pre-seeded birth profile: Mumbai, 1990-01-15, 06:30 IST (known to produce Scorpio Ascendant with current Lahiri Ayanamsha)
- Free-tier entitlement starts at 0 questions used (reset by staging seeder before each E2E run)

---

## 5. Rationale

E2E tests are the last line of defence before releases. They validate that the entire stack -- Flutter client, FastAPI backend, PostgreSQL, Swiss Ephemeris, RAG pipeline -- works together correctly for the user journeys that matter most commercially (chart generation, AI chat, paywall).

---

## 6. Trade-offs

| Choice | Pro | Con |
| :--- | :--- | :--- |
| Maestro (YAML) | Simple to write, no Flutter code needed, reads like plain English | Less programmatic power than Flutter Integration Tests |
| Staging backend (real API) | Tests the real integration; catches backend bugs | Test runs are slower; backend staging data management needed |

---

## 7. Future Improvements

- **iOS CI Pipeline**: Add iOS Simulator E2E runs on macOS GitHub runners once Android coverage is stable.
- **Visual Snapshot Testing**: Add Maestro screenshot assertions for chart widget rendering consistency.
- **Parallel Test Execution**: Shard E2E flows across multiple emulators using `maestro cloud` for faster CI feedback.

---

## 8. Related Documents

- [TESTING_STRATEGY.md](TESTING_STRATEGY.md) -- Overall testing philosophy and quality gates
- [INTEGRATION_TESTS.md](INTEGRATION_TESTS.md) -- Backend API integration tests
- [UNIT_TESTS.md](UNIT_TESTS.md) -- Unit testing patterns
