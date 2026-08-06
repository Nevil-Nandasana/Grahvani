# Flutter Architecture Specification

## 1. Overview & Clean Architecture Principles
The **Grahvani** mobile frontend is constructed using **Flutter 3.19+** and **Dart 3.3+**. The application enforces a **feature-first, layered clean architecture** pattern to ensure maximum testability, maintainability, and clean separation of concerns.

---

## 2. Directory & Folder Layout

```text
apps/mobile/lib/
│
├── main.dart                      # Application entry point, ProviderScope initialization
├── app.dart                       # MaterialApp.router, theme configuration
│
├── core/                          # Global shared infrastructure & UI components
│   ├── constants/                 # App colors, dimensions, typography, API URLs
│   ├── network/                   # Dio HTTP client, SSE client, interceptors
│   ├── storage/                   # Drift database instance, FlutterSecureStorage
│   ├── theme/                     # Material 3 light/dark color schemes & text themes
│   ├── utils/                     # Date formatters, coordinate helpers
│   └── widgets/                   # Reusable buttons, text fields, loading indicators
│
└── features/                      # Feature-oriented domain modules
    ├── auth/                      # Firebase Auth, login screen, phone OTP screen
    │   ├── data/                  # AuthRepositoryImpl, Firebase SDK integration
    │   ├── domain/                # AuthUser entity, AuthRepository interface
    │   └── presentation/          # LoginScreen, AuthNotifier, OTPVerificationWidget
    │
    ├── profile/                   # Birth profile management (Self, Family)
    │   ├── data/                  # ProfileRepositoryImpl, Drift ProfileDao
    │   ├── domain/                # BirthProfile model
    │   └── presentation/          # ProfileListScreen, ProfileFormScreen
    │
    ├── chart/                     # Birth chart display & planetary facts
    │   ├── data/                  # ChartRepositoryImpl, ChartRemoteDataSource
    │   ├── domain/                # BirthChart, PlanetaryPosition, DashaPeriod models
    │   └── presentation/          # ChartOverviewScreen, D1ChartPainter, DashaTimeline
    │
    ├── chat/                      # AI Astrological RAG Chat
    │   ├── data/                  # ChatRepositoryImpl, SSEStreamDataSource
    │   ├── domain/                # ChatMessage, ChatSession models
    │   └── presentation/          # ChatScreen, MessageBubble, StreamingTextWidget
    │
    └── subscriptions/             # In-App Purchases & Premium Entitlements
        ├── data/                  # BillingRepositoryImpl, InAppPurchase SDK
        ├── domain/                # UserEntitlement, SubscriptionPlan models
        └── presentation/          # PaywallScreen, EntitlementGuardWidget
```

---

## 3. Layer Communication Rules

1. **Presentation Layer (`features/*/presentation/`)**:
   - Contains Flutter UI widgets and Riverpod `Notifier` / `AsyncNotifier` classes.
   - Responsible for rendering UI states (`loading`, `data`, `error`) using Riverpod `AsyncValue`.
   - **Rule**: Presentation widgets must NEVER import data layer classes (e.g., `Dio`, `Drift`). They communicate exclusively with domain repository interfaces via Riverpod providers.

2. **Domain Layer (`features/*/domain/`)**:
   - Contains immutable pure Dart data classes (entities) and abstract repository interfaces.
   - **Rule**: Domain code must have zero dependencies on Flutter UI frameworks or third-party data libraries.

3. **Data Layer (`features/*/data/`)**:
   - Implements abstract repository interfaces defined in the domain layer.
   - Coordinates remote HTTP API calls (via `Dio`) and local cache persistence (via `Drift` / `FlutterSecureStorage`).

---

## 4. Key Flutter Dependencies

| Package | Version | Purpose |
| :--- | :--- | :--- |
| `flutter_riverpod` | `^2.5.1` | Compile-safe reactive state management & DI. |
| `riverpod_annotation` | `^2.3.5` | Code generation for providers (`@riverpod`). |
| `go_router` | `^13.2.0` | Declarative routing & deep link handling. |
| `dio` | `^5.4.1` | Feature-rich HTTP client with interceptors for JWT injection. |
| `drift` | `^2.16.0` | Type-safe SQLite ORM for offline chart caching. |
| `flutter_secure_storage` | `^9.0.0` | Encrypted storage for sensitive JWT tokens. |
| `firebase_auth` | `^4.17.8` | Mobile identity authentication (Google, Apple, OTP). |
| `in_app_purchase` | `^3.1.13` | Official Flutter plugin for Google Play & Apple App Store IAP. |
