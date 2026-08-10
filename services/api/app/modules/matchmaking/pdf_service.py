"""
PDF Generation Service for Matchmaking (Kundali Milan & Synastry) Reports.
Uses WeasyPrint for HTML-to-PDF conversion with Jinja2 templating.
"""

import tempfile
from pathlib import Path
from typing import Dict, Any, List
from uuid import uuid4

from fastapi import HTTPException
from jinja2 import Environment, FileSystemLoader
from weasyprint import HTML

# Directory to store Jinja2 templates
templates_dir = Path(__file__).parent / "templates"
env = Environment(loader=FileSystemLoader(templates_dir))


def _get_template(template_name: str) -> str:
    """Load a Jinja2 template."""
    try:
        return env.get_template(template_name).render()
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to load template: {str(e)}"
        )


async def generate_milan_pdf(
    profile1: Any,
    profile2: Any,
    ashtakoot: Dict[str, Any]
) -> Path:
    """
    Generate a PDF report for Kundali Milan (Ashtakoot compatibility).
    
    Args:
        profile1: First birth profile
        profile2: Second birth profile
        ashtakoot: Ashtakoot compatibility scores
        
    Returns:
        Path to the generated PDF file
    """
    try:
        # Prepare template data
        template_data = {
            "profile1": {
                "name": profile1.name,
                "date_of_birth": profile1.date_of_birth,
                "time_of_birth": profile1.time_of_birth,
                "place_of_birth": profile1.place_of_birth,
                "moon_sign": ashtakoot.get("profile1_moon", "Unknown"),
                "nakshatra": ashtakoot.get("profile1_nakshatra", "Unknown"),
            },
            "profile2": {
                "name": profile2.name,
                "date_of_birth": profile2.date_of_birth,
                "time_of_birth": profile2.time_of_birth,
                "place_of_birth": profile2.place_of_birth,
                "moon_sign": ashtakoot.get("profile2_moon", "Unknown"),
                "nakshatra": ashtakoot.get("profile2_nakshatra", "Unknown"),
            },
            "ashtakoot": ashtakoot.get("ashtakoot", {}),
            "total_score": ashtakoot.get("ashtakoot", {}).get("total", 0),
        }

        # Render HTML from template
        template = env.get_template("milan_report.html")
        html_content = template.render(**template_data)

        # Generate PDF
        pdf_path = Path(tempfile.gettempdir()) / f"milan_{uuid4().hex}.pdf"
        HTML(string=html_content).write_pdf(pdf_path)

        return pdf_path
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"PDF generation failed: {str(e)}"
        )


async def generate_synastry_pdf(
    profile1: Any,
    profile2: Any,
    chart1: Dict[str, Any],
    chart2: Dict[str, Any],
    aspects: List[Dict[str, Any]]
) -> Path:
    """
    Generate a PDF report for Synastry (Dual-Chart) analysis.
    
    Args:
        profile1: First birth profile
        profile2: Second birth profile
        chart1: First birth chart data
        chart2: Second birth chart data
        aspects: List of synastry aspects
        
    Returns:
        Path to the generated PDF file
    """
    try:
        # Prepare template data
        template_data = {
            "profile1": {
                "name": profile1.name,
                "date_of_birth": profile1.date_of_birth,
                "time_of_birth": profile1.time_of_birth,
                "place_of_birth": profile1.place_of_birth,
            },
            "profile2": {
                "name": profile2.name,
                "date_of_birth": profile2.date_of_birth,
                "time_of_birth": profile2.time_of_birth,
                "place_of_birth": profile2.place_of_birth,
            },
            "aspects": aspects,
            "harmonious_count": len([a for a in aspects if a.get("is_harmonious", False)]),
            "tense_count": len([a for a in aspects if not a.get("is_harmonious", True)]),
            "total_aspects": len(aspects),
        }

        # Render HTML from template
        template = env.get_template("synastry_report.html")
        html_content = template.render(**template_data)

        # Generate PDF
        pdf_path = Path(tempfile.gettempdir()) / f"synastry_{uuid4().hex}.pdf"
        HTML(string=html_content).write_pdf(pdf_path)

        return pdf_path
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"PDF generation failed: {str(e)}"
        )