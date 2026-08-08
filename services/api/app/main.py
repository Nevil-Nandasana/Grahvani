import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.core.exceptions import add_exception_handlers
from app.core.middleware import add_middleware
from app.modules.billing import router as billing_router
from app.modules.birth_chart import router as birth_chart_router
from app.modules.identity import router as identity_router
from app.modules.interpretation import router as interpretation_router
from app.modules.notifications import router as notifications_router
from app.modules.transits import router as transits_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.PROJECT_VERSION,
    description=settings.PROJECT_DESCRIPTION,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
)

# Add middleware
add_middleware(app)

# Add exception handlers
add_exception_handlers(app)

# Include API routers
app.include_router(identity_router, prefix="/api/v1")
app.include_router(birth_chart_router, prefix="/api/v1")
app.include_router(interpretation_router, prefix="/api/v1")
app.include_router(billing_router, prefix="/api/v1")
app.include_router(notifications_router, prefix="/api/v1")
app.include_router(transits_router, prefix="/api/v1")

# Mount static files if directory exists
if os.path.exists(settings.STATIC_FILES_DIRECTORY):
    app.mount(
        "/static",
        StaticFiles(directory=settings.STATIC_FILES_DIRECTORY),
        name="static",
    )