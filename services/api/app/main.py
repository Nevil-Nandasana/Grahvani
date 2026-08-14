import os
from contextlib import asynccontextmanager
from datetime import timezone

from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

import sentry_sdk
from app.config import settings
from app.core.exceptions import add_exception_handlers
from app.core.middleware import add_middleware
from app.core.logging import setup_logging
from app.modules.billing.router import router as billing_router
from app.modules.birth_chart.router import router as birth_chart_router
from app.modules.identity.router import router as identity_router
from app.modules.interpretation.router import router as interpretation_router
from app.modules.matchmaking.router import router as matchmaking_router
from app.modules.notifications.router import router as notifications_router
from app.modules.transits.router import router as transits_router
from app.tasks.transit_monitor import daily_transit_monitor_task as check_daily_transits_task

@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler = None
    try:
        from app.db.session import init_db_pool
        await init_db_pool()
    except Exception as e:
        logger.warning(f"Database initialization warning: {e}")

    try:
        scheduler = AsyncIOScheduler()
        scheduler.add_job(
            check_daily_transits_task.send,
            CronTrigger(hour=0, minute=30, timezone=timezone.utc),
            id="daily_transit_check",
            replace_existing=True
        )
        scheduler.start()
    except Exception as e:
        logger.warning(f"APScheduler background task initialization skipped: {e}")
    
    yield

    if scheduler and scheduler.running:
        try:
            scheduler.shutdown()
        except Exception:
            pass

# Initialize centralized logging
logger = setup_logging()

# Initialize Sentry for exception tracking
if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        traces_sample_rate=1.0,
        environment=settings.APP_ENV,
    )
    logger.info("Sentry initialized for exception tracking")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.PROJECT_VERSION,
    description=settings.PROJECT_DESCRIPTION,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
    lifespan=lifespan,
)

# Add middleware & exception handlers
add_middleware(app)
add_exception_handlers(app)

# Root route & convenience redirects
@app.get("/", include_in_schema=False)
async def root():
    return RedirectResponse(url="/api/docs")

@app.get("/docs", include_in_schema=False)
async def docs_redirect():
    return RedirectResponse(url="/api/docs")

@app.get("/redoc", include_in_schema=False)
async def redoc_redirect():
    return RedirectResponse(url="/api/redoc")

# Health Check
@app.get("/health")
async def health_check():
    return {"status": "ok", "service": settings.PROJECT_NAME}

# Include API routers
app.include_router(identity_router, prefix="/api/v1")
app.include_router(birth_chart_router, prefix="/api/v1")
app.include_router(interpretation_router, prefix="/api/v1")
app.include_router(billing_router, prefix="/api/v1")
app.include_router(notifications_router, prefix="/api/v1")
app.include_router(transits_router, prefix="/api/v1")
app.include_router(matchmaking_router, prefix="/api/v1")

# Mount static files if directory exists
if os.path.exists(settings.STATIC_FILES_DIRECTORY):
    app.mount(
        "/static",
        StaticFiles(directory=settings.STATIC_FILES_DIRECTORY),
        name="static",
    )