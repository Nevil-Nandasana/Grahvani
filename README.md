# Grahvani

**Production-grade, cross-platform Vedic astrology SaaS application** combining deterministic Swiss Ephemeris calculation accuracy with an evidence-grounded RAG AI interpretation layer.

---

## Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Mobile Client** | Flutter (Android + iOS), Riverpod, go_router, Drift SQLite |
| **API Backend** | Python 3.12, FastAPI, SQLAlchemy 2.0 async, Pydantic v2 |
| **Astrology Engine** | Swiss Ephemeris via `pyswisseph` (Lahiri Ayanamsa) |
| **AI / RAG** | Google Gemini Flash + `text-embedding-004` + `pgvector` |
| **Task Queue** | Dramatiq + Redis 7 |
| **Database** | PostgreSQL 16 + `pgvector` 0.6+ |
| **Cloud** | AWS App Runner, RDS, S3, Secrets Manager |

---

## Project Structure

```
grahvani/
├── apps/
│   └── mobile/           # Flutter mobile client (Android + iOS)
├── services/
│   └── api/              # FastAPI modular monolith backend
│       ├── app/
│       │   ├── main.py
│       │   ├── config.py
│       │   ├── core/     # Security, middleware, exceptions
│       │   ├── modules/  # identity, birth_chart, interpretation, billing
│       │   └── tasks/    # Dramatiq background workers
│       └── alembic/      # Database migrations
├── docs/                 # Full project technical documentation (84 files)
├── FeatTracking/         # Feature tracking backlog & project rules
├── docker-compose.yml
├── .env.example
└── .gitignore
```

---

## Local Development Quickstart

### Prerequisites
- Docker Desktop installed and running
- Python 3.12+ and [Poetry](https://python-poetry.org/docs/)
- Flutter SDK 3.x
- Git

### 1. Clone & Configure Environment

```bash
git clone <your-repo-url>
cd grahvani
cp .env.example .env
# Edit .env with your Firebase, Gemini API Key, and Razorpay credentials
```

### 2. Start Infrastructure Containers

```bash
docker compose up db redis -d
```

### 3. Set Up Backend API

```bash
cd services/api
poetry install
poetry run alembic upgrade head          # Apply all DB migrations
poetry run uvicorn app.main:app --reload # Start API with hot-reload
```

API available at: `http://localhost:8000`
Swagger UI docs: `http://localhost:8000/docs`

### 4. Start Background Worker

```bash
cd services/api
poetry run dramatiq app.tasks.worker --processes 2 --threads 4
```

### 5. Set Up & Run Flutter Mobile App

```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## Running Tests

```bash
# Backend unit + integration tests with coverage
cd services/api
poetry run pytest --cov=app --cov-report=term-missing

# Astrology engine precision vectors (must be 100% pass)
poetry run pytest tests/astro/

# Flutter unit & widget tests
cd apps/mobile
flutter test
```

---

## Documentation

All technical documentation is in `docs/`. Start with [docs/README.md](docs/README.md).

- [Project Overview](docs/PROJECT_OVERVIEW.md)
- [System Architecture](docs/SYSTEM_ARCHITECTURE.md)
- [API Endpoints](docs/api/ENDPOINTS.md)
- [Feature Tracking](FeatTracking/FEATURE_TRACKING.md)
- [Project Rules](FeatTracking/PROJECT_RULES.md)
