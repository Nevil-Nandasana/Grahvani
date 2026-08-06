# Frontend Documentation (Flutter Mobile Application)

Welcome to the documentation for the **Grahvani** mobile application built using **Flutter**. The app targets both **Android** and **iOS** from a single shared Dart codebase.

---

## 📂 Frontend Documents Index

- 🏗️ **[Flutter Architecture](FLUTTER_ARCHITECTURE.md)** — Feature-first clean architecture layout, layer separation (`presentation`, `domain`, `data`), dependency injection with Riverpod.
- 🎨 **[UI Components & Design System](UI_COMPONENTS.md)** — Material 3 / Cupertino styling tokens, color palette, custom birth chart rendering widgets, typography.
- ⚡ **[State Management](STATE_MANAGEMENT.md)** — Riverpod providers, notifier lifecycles, `AsyncValue` data states, user session state.
- 🗺️ **[Navigation & Routing](NAVIGATION.md)** — `go_router` configuration, authenticated route guards, deep links, tab bar navigation.
- 💾 **[Offline Storage & Caching](OFFLINE_STORAGE.md)** — Drift SQLite database, local encrypted secure storage, offline chart caching.

---

## 🏛️ High-Level Clean Architecture Layers

```mermaid
graph TD
    subgraph PresentationLayer["Presentation Layer (UI & State)"]
        UIWidgets["Flutter Widgets<br/>(Material 3 / Cupertino)"]
        Notifiers["Riverpod Notifiers<br/>(AsyncValue State)"]
    end

    subgraph DomainLayer["Domain Layer (Business Logic)"]
        Entities["Domain Models / Entities<br/>(BirthProfile, BirthChart)"]
        UseCases["Use Cases / Repositories Interfaces"]
    end

    subgraph DataLayer["Data Layer (Infrastructure)"]
        RepoImpl["Repository Implementations"]
        APIClient["Dio REST & SSE Client"]
        LocalDB["Drift SQLite DB"]
        SecureStorage["Flutter Secure Storage"]
    end

    UIWidgets --> Notifiers
    Notifiers --> UseCases
    UseCases --> Entities
    RepoImpl ..|> UseCases
    RepoImpl --> APIClient
    RepoImpl --> LocalDB
    RepoImpl --> SecureStorage
```
