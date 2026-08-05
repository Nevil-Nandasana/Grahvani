"""
Dramatiq Task — Swiss Ephemeris Birth Chart Calculation
Executed asynchronously by the Dramatiq worker container.
"""
import asyncio
import uuid
from datetime import datetime, timezone

import dramatiq

from app.db.session import AsyncSessionLocal
from app.modules.birth_chart.ephemeris_service import calculate_chart
from app.modules.birth_chart.models import BirthChart
from app.modules.identity.models import BirthProfile


@dramatiq.actor(queue_name="ephemeris", max_retries=3, time_limit=240_000)
def calculate_birth_chart_task(chart_id: str) -> None:
    """
    Background Dramatiq task that:
    1. Loads birth profile from PostgreSQL.
    2. Calculates planetary positions using Swiss Ephemeris (pyswisseph).
    3. Stores the immutable chart_facts_json snapshot in PostgreSQL.
    4. Updates chart status to 'complete' or 'error'.
    """
    asyncio.run(_calculate_birth_chart_async(chart_id))


async def _calculate_birth_chart_async(chart_id: str) -> None:
    async with AsyncSessionLocal() as db:
        chart = await db.get(BirthChart, uuid.UUID(chart_id))
        if not chart:
            return

        # Mark as calculating
        chart.status = "calculating"
        await db.commit()

        try:
            profile = await db.get(BirthProfile, chart.profile_id)
            if not profile:
                raise ValueError("Birth profile not found for chart calculation.")

            # Parse birth date and time
            dob = profile.date_of_birth.split("-")  # YYYY-MM-DD
            tob = profile.time_of_birth.split(":")  # HH:MM:SS

            # Execute Swiss Ephemeris calculation
            chart_facts = calculate_chart(
                year=int(dob[0]),
                month=int(dob[1]),
                day=int(dob[2]),
                hour=int(tob[0]),
                minute=int(tob[1]),
                second=int(tob[2]) if len(tob) > 2 else 0,
                latitude=profile.latitude,
                longitude=profile.longitude,
                ayanamsa=chart.ayanamsa,
                house_system="P",  # Placidus
            )

            chart.chart_facts_json = chart_facts
            chart.status = "complete"
            chart.calculated_at = datetime.now(timezone.utc)

        except Exception as e:
            chart.status = "error"
            chart.error_message = str(e)

        await db.commit()
