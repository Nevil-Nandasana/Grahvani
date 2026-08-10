"""
Birth Chart Module — API Router
Routes: /charts
"""
import uuid

from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import tempfile
import os
from pathlib import Path
from uuid import UUID

import boto3
from app.config import settings
from app.core.exceptions import NotFoundError
from app.core.security import CurrentUser
from app.db.session import get_db
from app.modules.birth_chart.models import BirthChart
from app.modules.identity.models import BirthProfile, User
from app.tasks.ephemeris import calculate_birth_chart_task
from app.tasks.pdf_export import generate_chart_pdf_task

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


@router.post("/charts/{chart_id}/export/pdf", status_code=status.HTTP_202_ACCEPTED)
async def trigger_pdf_export(
    chart_id: uuid.UUID,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Trigger background job to generate a high-resolution PDF for the birth chart."""
    chart = await db.get(BirthChart, chart_id)
    if not chart or chart.status != "complete":
        raise NotFoundError("Birth Chart (must be fully calculated first)")

    # Verify user ownership
    profile = await db.get(BirthProfile, chart.profile_id)
    user = await db.execute(select(User).where(User.firebase_uid == current_user.get("uid")))
    user = user.scalar_one_or_none()
    if not user or profile.user_id != user.id:
        raise NotFoundError("Birth Chart")

    chart.pdf_status = "pending"
    await db.commit()

    # Enqueue background task
    generate_chart_pdf_task.send(str(chart.id))

    return {
        "success": True,
        "data": {
            "chart_id": str(chart.id),
            "pdf_status": "pending",
            "poll_url": f"/api/v1/charts/{chart.id}/export/pdf/status",
        },
    }


@router.post("/varshaphal/export-pdf", status_code=status.HTTP_200_OK, response_model=Dict[str, Any])
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
