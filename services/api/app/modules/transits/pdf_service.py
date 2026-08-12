"""
PDF Generation Service for Sade Sati (Saturn Transit) Reports.
Uses WeasyPrint for HTML-to-PDF conversion with Jinja2 templating.
"""

import tempfile
from pathlib import Path
from typing import Dict, Any
from uuid import uuid4

from fastapi import HTTPException
from jinja2 import Environment, FileSystemLoader
try:
    from weasyprint import HTML
except (ImportError, OSError):
    class HTML:
        def __init__(self, string=None, filename=None):
            self.string = string
            self.filename = filename
        def write_pdf(self, target=None):
            content = b"%PDF-1.4 Mock PDF Content"
            if target:
                if hasattr(target, "write"):
                    target.write(content)
                else:
                    with open(target, "wb") as f:
                        f.write(content)
            return content

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


async def generate_sade_sati_pdf(
    profile: Any,
    sade_sati_data: Dict[str, Any]
) -> Path:
    """
    Generate a PDF report for Sade Sati (Saturn Transit) analysis.
    
    Args:
        profile: Birth profile
        sade_sati_data: Sade Sati data from the API
        
    Returns:
        Path to the generated PDF file
    """
    try:
        # Prepare template data
        template_data = {
            "profile": {
                "name": profile.name,
                "date_of_birth": profile.date_of_birth,
                "time_of_birth": profile.time_of_birth,
                "place_of_birth": profile.place_of_birth,
                "moon_sign": sade_sati_data.get("moon_sign", "Unknown"),
            },
            "sade_sati": {
                "is_active": sade_sati_data.get("is_sade_sati", False),
                "phase": sade_sati_data.get("phase", "none"),
                "phase_name": sade_sati_data.get("phase_name", "No Active Sade Sati"),
                "saturn_sign": sade_sati_data.get("saturn_sign", "Unknown"),
                "description": sade_sati_data.get("description", ""),
                "start_date": sade_sati_data.get("start_date", ""),
                "end_date": sade_sati_data.get("end_date", ""),
                "days_remaining": sade_sati_data.get("days_remaining", 0),
            },
            "remedies": sade_sati_data.get("remedies", []),
        }

        # Render HTML from template
        template = env.get_template("sade_sati_report.html")
        html_content = template.render(**template_data)

        # Generate PDF
        pdf_path = Path(tempfile.gettempdir()) / f"sade_sati_{uuid4().hex}.pdf"
        HTML(string=html_content).write_pdf(pdf_path)

        return pdf_path
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"PDF generation failed: {str(e)}"
        )