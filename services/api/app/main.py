"""
Grahvani API — FastAPI Application Entry Point
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.core.exceptions import register_exception_handlers
from app.core.middleware import RequestIDMiddleware
from app.db.session import close_db_pool, init_db_pool
from app.modules.billing.router import router as billing_router
from app.modules.birth_chart.router import router as chart_router
from app.modules.identity.router import router as identity_router
from app.modules.interpretation.router import router as interpretation_router
from app.modules.notifications.router import router as notifications_router
from app.modules.transits.router import router as transit_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application startup and shutdown lifecycle hooks.
    Initializes the async PostgreSQL connection pool and closes it cleanly on shutdown.
    """
    # Startup
    await init_db_pool()
    yield
    # Shutdown
    await close_db_pool()


app = FastAPI(
    title="Grahvani API",
    description=(
        "Production-grade Vedic astrology API combining deterministic Swiss Ephemeris "
        "calculation with evidence-grounded RAG AI interpretation."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# ─── Middleware ──────────────────────────────────────────────────────────────
app.add_middleware(RequestIDMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Exception Handlers ───────────────────────────────────────────────────────
register_exception_handlers(app)

# ─── Domain Routers ───────────────────────────────────────────────────────────
app.include_router(identity_router,        prefix="/api/v1", tags=["Auth & Profiles"])
app.include_router(chart_router,           prefix="/api/v1", tags=["Birth Charts"])
app.include_router(interpretation_router,  prefix="/api/v1", tags=["Grounded AI Chat"])
app.include_router(billing_router,         prefix="/api/v1", tags=["Billing & Entitlements"])
app.include_router(notifications_router,   prefix="/api/v1", tags=["Push Notifications"])
app.include_router(transit_router,         prefix="/api/v1", tags=["Planetary Transits"])


@app.get("/health", tags=["Health"])
async def health_check():
    """Simple liveness probe endpoint for AWS App Runner and load balancers."""
    return {"status": "ok", "version": app.version}
