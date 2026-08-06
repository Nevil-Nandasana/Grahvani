# FastAPI Modular Monolith Architecture

> [[Backend Index](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/README.md) | [Modules Guide](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/MODULES.md) | [API Design](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/API_DESIGN.md) | [Error Handling](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/ERROR_HANDLING.md)]

---

## 1. Modular Monolith Architecture Overview

The **Grahvani** backend is designed as a single-repository **FastAPI Modular Monolith** written in **Python 3.12+**. Rather than splitting early code into microservices, the application is organized into explicit domain modules (`identity`, `birth_chart`, `astrology_content`, `interpretation`, `billing`) contained within a single application process.

### Architecture Goals
- **High Concurrency**: Built entirely using Python `async` / `await` coroutines for non-blocking I/O operations (PostgreSQL queries via asyncpg, Redis operations via redis-py async, HTTP calls via httpx).
- **Strict Module Boundaries**: Domain logic is isolated; cross-module data exchange occurs via explicit Python service methods, avoiding inter-module database joins.
- **Fast Startup & Low Overhead**: Runs efficiently inside containerized AWS App Runner services.

---

## 2. Codebase & Directory Layout

```text
services/api/
├── alembic/                  # Alembic database migration revisions
├── app/
│   ├── main.py               # FastAPI application instantiation & lifespan
│   ├── config.py             # Pydantic BaseSettings environment config
│   ├── dependencies.py       # Shared FastAPI dependencies (DB, Redis, HTTP)
│   │
│   ├── core/                 # Shared cross-cutting concerns
│   │   ├── exceptions.py     # Custom exception classes & global handlers
│   │   ├── middleware.py     # Request ID, CORS, and logging middleware
│   │   └── security.py       # Firebase JWT verification & RBAC checks
│   │
│   ├── modules/              # Isolated Domain Modules
│   │   ├── identity/         # User profiles, auth sessions, DPDP deletion
│   │   ├── birth_chart/      # Chart calculation requests & snapshot management
│   │   ├── interpretation/   # Grounded RAG retrieval & Gemini Flash AI chat
│   │   └── billing/          # Razorpay, Play Store, and App Store entitlements
│   │
│   └── tasks/                # Dramatiq background task workers
│       ├── worker.py         # Worker entrypoint
│       └── ephemeris.py      # Swiss Ephemeris background jobs
│
├── tests/                    # Pytest test suite (unit, integration, fixtures)
├── pyproject.toml            # Poetry dependency specification
└── Dockerfile                # Multi-stage production container build
```

---

## 3. APIRouter Modularity & Mounting

Main application routing is aggregated cleanly using FastAPI `APIRouter` instances defined in each domain module:

```python
# Location: services/api/app/main.py
from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.modules.identity.router import router as identity_router
from app.modules.birth_chart.router import router as chart_router
from app.modules.interpretation.router import router as chat_router
from app.modules.billing.router import router as billing_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize DB pools, Redis connections, HTTP clients
    await init_db_pool()
    await init_redis_client()
    yield
    # Shutdown: Close connections cleanly
    await close_db_pool()
    await close_redis_client()

app = FastAPI(
    title="Grahvani API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Include Domain Module Routers under /api/v1
app.include_router(identity_router, prefix="/api/v1/auth", tags=["Auth & Profiles"])
app.include_router(chart_router, prefix="/api/v1/charts", tags=["Birth Charts"])
app.include_router(chat_router, prefix="/api/v1/chat", tags=["Grounded AI Chat"])
app.include_router(billing_router, prefix="/api/v1/billing", tags=["Billing & Entitlements"])
```

---

## 4. Pydantic v2 Request & Response Validation

All API input parameters and output responses are validated using **Pydantic v2** models, ensuring strict data types and automatic OpenAPI schema generation:

```python
# Example Pydantic Model in app/modules/birth_chart/schemas.py
from pydantic import BaseModel, Field, field_validator
from datetime import date, time

class CreateProfileRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, example="Aditya Sharma")
    date_of_birth: date = Field(..., example="1992-08-15")
    time_of_birth: time = Field(..., example="14:30:00")
    latitude: float = Field(..., ge=-90.0, le=90.0, example=28.6139)
    longitude: float = Field(..., ge=-180.0, le=180.0, example=77.2090)
    timezone: str = Field(default="Asia/Kolkata", example="Asia/Kolkata")

    @field_validator("name")
    def sanitize_name(cls, v: str) -> str:
        return v.strip()
```

---

## 5. Global Exception Handling & Middleware Stack

Grahvani registers global exception handlers to convert unhandled domain errors or validation failures into consistent JSON response envelopes ([Error Handling](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/ERROR_HANDLING.md)):

```python
@app.exception_handler(DomainException)
async def domain_exception_handler(request: Request, exc: DomainException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": {
                "code": exc.code,
                "message": exc.message,
                "details": exc.details
            }
        }
    )
```

---

## 6. Related Documents

- [Backend Overview](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/README.md) — Comprehensive backend domain overview.
- [Backend Modules](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/MODULES.md) — Detailed breakdown of domain module interfaces.
- [API Design](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/API_DESIGN.md) — RESTful standards and HTTP status codes.
- [Error Handling](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/ERROR_HANDLING.md) — Exception hierarchy and standard error responses.
