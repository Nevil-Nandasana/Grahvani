"""
Birth Chart Module — API Router
Routes: /charts
"""
import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.core.security import CurrentUser
from app.db.session import get_db
from app.modules.birth_chart.models import BirthChart
from app.modules.identity.models import BirthProfile, User
from app.tasks.ephemeris import calculate_birth_chart_task

router = APIRouter()


@router.post("/charts/calculate", status_code=status.HTTP_202_ACCEPTED)
async def trigger_chart_calculation(
    body: dict,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """
    Enqueue an asynchronous Swiss Ephemeris calculation job for a given birth profile.
    Returns HTTP 202 Accepted immediately. Client polls /charts/{id}/status.
    """
    profile_id = body.get("profile_id")
    ayanamsa = body.get("ayanamsa", "lahiri")
    house_system = body.get("house_system", "placidus")

    # Verify profile exists and belongs to user
    firebase_uid = current_user.get("uid")
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundError("User")

    profile = await db.get(BirthProfile, uuid.UUID(profile_id))
    if not profile or profile.user_id != user.id:
        raise NotFoundError("Birth Profile")

    # Create chart record in pending state
    chart = BirthChart(
        profile_id=profile.id,
        status="pending",
        ayanamsa=ayanamsa,
        house_system=house_system,
    )
    db.add(chart)
    await db.flush()

    # Enqueue background Dramatiq task
    calculate_birth_chart_task.send(str(chart.id))

    return {
        "success": True,
        "data": {
            "chart_id": str(chart.id),
            "status": "pending",
            "poll_url": f"/api/v1/charts/{chart.id}/status",
        },
    }


@router.get("/charts/{chart_id}", status_code=status.HTTP_200_OK)
async def get_chart(
    chart_id: uuid.UUID,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Retrieve a completed birth chart facts snapshot."""
    chart = await db.get(BirthChart, chart_id)
    if not chart:
        raise NotFoundError("Birth Chart")

    return {"success": True, "data": {
        "chart_id": str(chart.id),
        "status": chart.status,
        "ayanamsa": chart.ayanamsa,
        "chart_facts": chart.chart_facts_json,
        "calculated_at": chart.calculated_at.isoformat() if chart.calculated_at else None,
    }}


@router.get("/charts/{chart_id}/status", status_code=status.HTTP_200_OK)
async def get_chart_status(
    chart_id: uuid.UUID,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Poll endpoint for background chart calculation job status."""
    chart = await db.get(BirthChart, chart_id)
    if not chart:
        raise NotFoundError("Birth Chart")
    return {"success": True, "data": {"chart_id": str(chart.id), "status": chart.status}}
