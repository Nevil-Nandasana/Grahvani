from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any
from uuid import UUID
import tempfile
import os
from pathlib import Path

from app.db.session import get_db
from app.core.security import CurrentUser
from app.core.exceptions import NotFoundError
from app.modules.identity.models import BirthProfile
from app.modules.birth_chart.ephemeris_service import calculate_chart
from app.modules.matchmaking.schemas import MatchmakingRequest
from app.modules.matchmaking.calculations import compute_ashtakoot

router = APIRouter()

# Directory to store generated PDFs
PDF_STORAGE = Path(tempfile.gettempdir()) / "grahvani_pdfs"
PDF_STORAGE.mkdir(exist_ok=True)

@router.post("/charts/synastry/export-pdf", status_code=status.HTTP_200_OK, response_model=Dict[str, Any])
async def export_synastry_pdf(
    request: MatchmakingRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db)
):
    """
    Generate and return a PDF report for Synastry (Dual-Chart) analysis.
    Returns a URL to download the PDF.
    """
    profile1 = await db.get(BirthProfile, request.profile1_id)
    profile2 = await db.get(BirthProfile, request.profile2_id)

    if not profile1 or not profile2:
        raise NotFoundError("One or both Birth Profiles not found")

    # Get charts for both profiles
    def _get_chart_data(profile):
        dob = profile.date_of_birth.split("-")
        tob = profile.time_of_birth.split(":")
        chart = calculate_chart(
            year=int(dob[0]),
            month=int(dob[1]),
            day=int(dob[2]),
            hour=int(tob[0]),
            minute=int(tob[1]),
            second=int(tob[2]) if len(tob) > 2 else 0,
            latitude=profile.latitude,
            longitude=profile.longitude,
            timezone_name=profile.timezone
        )
        return chart

    chart1 = _get_chart_data(profile1)
    chart2 = _get_chart_data(profile2)

    # Compute synastry aspects
    aspects = compute_synastry_aspects(chart1, chart2)

    # Generate PDF
    try:
        from app.modules.matchmaking.pdf_service import generate_synastry_pdf
        pdf_path = await generate_synastry_pdf(
            profile1=profile1,
            profile2=profile2,
            chart1=chart1,
            chart2=chart2,
            aspects=aspects
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


@router.post("/charts/milan/export-pdf", status_code=status.HTTP_200_OK, response_model=Dict[str, Any])
async def export_milan_pdf(
    request: MatchmakingRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db)
):
    """
    Generate and return a PDF report for Kundali Milan (Ashtakoot compatibility).
    Returns a URL to download the PDF.
    """
    profile1 = await db.get(BirthProfile, request.profile1_id)
    profile2 = await db.get(BirthProfile, request.profile2_id)

    if not profile1 or not profile2:
        raise NotFoundError("One or both Birth Profiles not found")

    def _get_moon_data(profile):
        dob = profile.date_of_birth.split("-")
        tob = profile.time_of_birth.split(":")
        chart = calculate_chart(
            year=int(dob[0]),
            month=int(dob[1]),
            day=int(dob[2]),
            hour=int(tob[0]),
            minute=int(tob[1]),
            second=int(tob[2]) if len(tob) > 2 else 0,
            latitude=profile.latitude,
            longitude=profile.longitude,
            timezone_name=profile.timezone
        )
        moon = next(p for p in chart["planets"] if p["name"] == "Moon")
        return moon

    moon1 = _get_moon_data(profile1)
    moon2 = _get_moon_data(profile2)

    ashtakoot = compute_ashtakoot(
        moon1["zodiac_sign"], moon1["nakshatra"],
        moon2["zodiac_sign"], moon2["nakshatra"]
    )

    # Generate PDF
    try:
        from app.modules.matchmaking.pdf_service import generate_milan_pdf
        pdf_path = await generate_milan_pdf(
            profile1=profile1,
            profile2=profile2,
            ashtakoot=ashtakoot
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


@router.post("/charts/milan", status_code=status.HTTP_200_OK)
async def compute_milan(
    request: MatchmakingRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db)
):
    profile1 = await db.get(BirthProfile, request.profile1_id)
    profile2 = await db.get(BirthProfile, request.profile2_id)

    if not profile1 or not profile2:
        raise NotFoundError("One or both Birth Profiles not found")

    def _get_moon_data(profile):
        dob = profile.date_of_birth.split("-")
        tob = profile.time_of_birth.split(":")
        chart = calculate_chart(
            year=int(dob[0]),
            month=int(dob[1]),
            day=int(dob[2]),
            hour=int(tob[0]),
            minute=int(tob[1]),
            second=int(tob[2]) if len(tob) > 2 else 0,
            latitude=profile.latitude,
            longitude=profile.longitude,
            timezone_name=profile.timezone
        )
        moon = next(p for p in chart["planets"] if p["name"] == "Moon")
        return moon

    moon1 = _get_moon_data(profile1)
    moon2 = _get_moon_data(profile2)

    ashtakoot = compute_ashtakoot(
        moon1["zodiac_sign"], moon1["nakshatra"],
        moon2["zodiac_sign"], moon2["nakshatra"]
    )

    return {
        "success": True,
        "data": {
            "profile1_id": str(profile1.id),
            "profile2_id": str(profile2.id),
            "profile1_moon": moon1["zodiac_sign"],
            "profile1_nakshatra": moon1["nakshatra"],
            "profile2_moon": moon2["zodiac_sign"],
            "profile2_nakshatra": moon2["nakshatra"],
            "ashtakoot": ashtakoot
        }
    }
