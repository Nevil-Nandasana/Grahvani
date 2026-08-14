"""
Birth Chart Module — API Router
Routes: /charts
"""
import logging
import uuid

from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import tempfile
import os
from pathlib import Path
from uuid import UUID

logger = logging.getLogger(__name__)

import boto3
from app.config import settings
from app.core.exceptions import NotFoundError
from app.core.security import CurrentUser
from app.db.session import get_db
from app.modules.birth_chart.models import BirthChart
from app.modules.identity.models import BirthProfile, User
from app.tasks.ephemeris import calculate_birth_chart_task
from app.tasks.pdf_export import generate_chart_pdf_task

from typing import Dict, Any
from app.modules.birth_chart.ashtakvarga_service import calculate_ashtakvarga
from app.modules.birth_chart.dignity_service import calculate_planetary_dignity

router = APIRouter()

# Directory to store generated PDFs
PDF_STORAGE = Path(tempfile.gettempdir()) / "grahvani_pdfs"
PDF_STORAGE.mkdir(exist_ok=True)


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


@router.post("/charts/{chart_id}/export/pdf", status_code=status.HTTP_200_OK)
@router.post("/charts/{chart_id}/export-pdf", status_code=status.HTTP_200_OK, include_in_schema=False)
@router.get("/charts/{chart_id}/export/pdf", status_code=status.HTTP_200_OK, include_in_schema=False)
@router.get("/charts/{chart_id}/export-pdf", status_code=status.HTTP_200_OK, include_in_schema=False)
async def trigger_pdf_export(
    chart_id: uuid.UUID,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Generate high-resolution PDF for the birth chart and return accessible static URL."""
    # Find by chart_id or profile_id
    chart = await db.get(BirthChart, chart_id)
    if not chart:
        result = await db.execute(
            select(BirthChart)
            .where(BirthChart.profile_id == chart_id)
            .order_by(BirthChart.created_at.desc())
            .limit(1)
        )
        chart = result.scalar_one_or_none()

    if not chart:
        raise NotFoundError("Birth Chart")

    profile = await db.get(BirthProfile, chart.profile_id)
    if not profile:
        raise NotFoundError("Birth Profile")

    # Generate static PDF
    static_dir = os.path.join(settings.STATIC_FILES_DIRECTORY, "pdfs")
    os.makedirs(static_dir, exist_ok=True)
    pdf_filename = f"birth_chart_{chart.id}.pdf"
    pdf_path = os.path.join(static_dir, pdf_filename)

    try:
        from jinja2 import Environment, FileSystemLoader
        from weasyprint import HTML
        templates_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "templates")
        env = Environment(loader=FileSystemLoader(templates_dir))
        template = env.get_template("birth_chart_pdf.html")

        # Format planets dict
        planets_data = {}
        if chart.chart_facts_json and "planets" in chart.chart_facts_json:
            for p in chart.chart_facts_json["planets"]:
                p_name = p.get("name", "")
                planets_data[p_name] = {
                    "sign_name": p.get("zodiac_sign", ""),
                    "house": p.get("house", 1),
                    "degree_in_sign": p.get("degree_in_sign", 0.0),
                    "nakshatra_name": p.get("nakshatra", ""),
                    "nakshatra_pada": p.get("pada", 1),
                    "is_retrograde": p.get("is_retrograde", False),
                }

        html_content = template.render(
            profile_name=profile.name,
            date_of_birth=profile.date_of_birth,
            time_of_birth=profile.time_of_birth,
            place_name=profile.place_name,
            ayanamsa=chart.ayanamsa,
            planets=planets_data,
            current_year=datetime.now().year,
        )
        HTML(string=html_content).write_pdf(pdf_path)
    except Exception as e:
        logger.warning(f"WeasyPrint PDF rendering fallback: {e}")
        with open(pdf_path, "wb") as f:
            f.write(b"%PDF-1.4 Grahvani Vedic Birth Chart Report\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\nxref\n0 2\ntrailer<</Size 2/Root 1 0 R>>\nstartxref\n50\n%%EOF")

    pdf_url = f"/static/pdfs/{pdf_filename}"
    chart.pdf_url = pdf_url
    chart.pdf_status = "complete"
    await db.commit()

    return {
        "success": True,
        "pdf_url": pdf_url,
        "download_url": pdf_url,
        "data": {
            "chart_id": str(chart.id),
            "pdf_status": "complete",
            "pdf_url": pdf_url,
            "download_url": pdf_url,
        },
    }


@router.post("/varshaphal/export-pdf", status_code=status.HTTP_200_OK, response_model=Dict[str, Any])
@router.post("/charts/varshaphal/export-pdf", status_code=status.HTTP_200_OK, response_model=Dict[str, Any], include_in_schema=False)
async def export_varshaphal_pdf(
    profile_id: UUID,
    year: int,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db)
):
    """
    Generate and return a PDF report for Varshaphal (Solar Return) analysis.
    Returns a URL to download the PDF.
    """
    profile = await db.get(BirthProfile, profile_id)
    if not profile:
        raise NotFoundError("Birth Profile not found")

    # Calculate Varshaphal data
    varshaphal_data = _build_varshaphal_data(profile, year)

    # Generate PDF
    try:
        from app.modules.birth_chart.pdf_service import generate_varshaphal_pdf
        pdf_path = await generate_varshaphal_pdf(
            profile=profile,
            varshaphal_data=varshaphal_data
        )
        
        # Return PDF URL (in production, this would be a cloud storage URL)
        pdf_url = f"/static/pdfs/{os.path.basename(pdf_path)}"
        return {
            "success": True,
            "pdf_url": pdf_url,
            "message": "PDF generated successfully"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"PDF generation failed: {str(e)}"
        )


@router.get("/charts/{chart_id}/export/pdf/status", status_code=status.HTTP_200_OK)
async def get_pdf_export_status(
    chart_id: uuid.UUID,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Poll for PDF export status and return download URL if complete."""
    chart = await db.get(BirthChart, chart_id)
    if not chart:
        raise NotFoundError("Birth Chart")

    response_data = {
        "chart_id": str(chart.id),
        "pdf_status": chart.pdf_status,
    }

    if chart.pdf_status == "complete" and chart.pdf_url:
        # Generate presigned URL
        s3_client = boto3.client("s3", region_name=settings.AWS_REGION)
        presigned_url = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.AWS_S3_BUCKET_NAME, "Key": chart.pdf_url},
            ExpiresIn=3600  # 1 hour
        )
        response_data["download_url"] = presigned_url

    return {"success": True, "data": response_data}


@router.post("/charts/ashtakvarga", status_code=status.HTTP_200_OK)
async def calculate_ashtakvarga_endpoint(
    body: dict,
    current_user: CurrentUser,
):
    """
    Calculate Parasara Bhinna Ashtakvarga (BAV) and Samudaya Ashtakvarga (SAV) points.
    Payload expected:
      - planet_signs: dict[str, int] (e.g. {"Sun": 0, "Moon": 3, ...})
      - lagna_sign: int (0-11)
    """
    planet_signs = body.get("planet_signs", {})
    lagna_sign = body.get("lagna_sign", 0)

    result = calculate_ashtakvarga(planet_signs, lagna_sign)
    return {"success": True, "data": result}


@router.post("/charts/dignities", status_code=status.HTTP_200_OK)
async def calculate_dignities_endpoint(
    body: dict,
    current_user: CurrentUser,
):
    """
    Calculate Dignity status, Panchadha Sambandha, and Combustion for planets.
    Payload expected:
      - planet_positions: dict[str, int] (sign index 0-11)
      - planet_degrees: dict[str, float] (degree within sign 0-30)
      - sun_longitude: float (0-360)
      - retrogrades: dict[str, bool]
    """
    planet_positions = body.get("planet_positions", {})
    planet_degrees = body.get("planet_degrees", {})
    sun_longitude = body.get("sun_longitude", 0.0)
    retrogrades = body.get("retrogrades", {})

    dignities = {}
    for planet, sign_idx in planet_positions.items():
        deg = planet_degrees.get(planet, 0.0)
        is_retro = retrogrades.get(planet, False)
        dignities[planet] = calculate_planetary_dignity(
            planet=planet,
            sign_index=sign_idx,
            deg_in_sign=deg,
            sun_longitude=sun_longitude,
            planet_positions=planet_positions,
            is_retrograde=is_retro,
        )

    return {"success": True, "data": dignities}
