"""
Transits Module — API endpoints for planetary transits, Sade Sati status, and transit alerts.
"""
from fastapi import APIRouter

router = APIRouter(prefix="/transits", tags=["Transits & Transit Alerts"])

# Import all routers
from .router import router as transit_router

# Include transit router
router.include_router(transit_router)