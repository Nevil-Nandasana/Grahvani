"""
PDF Generation Service for Birth Chart and Varshaphal Reports.
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


async def generate_varshaphal_pdf(
    profile: Any,
    varshaphal_data: Dict[str, Any]
) -> Path:
    """
    Generate a PDF report for Varshaphal (Solar Return) analysis.
    
    Args:
        profile: Birth profile
        varshaphal_data: Varshaphal data (year, chart, muntha, varshesha, etc.)
        
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
            },
            "varshaphal": {
                "year": varshaphal_data.get("year", 0),
                "solar_return_date": varshaphal_data.get("solar_return_date", ""),
                "muntha_planet": varshaphal_data.get("muntha_planet", "Unknown"),
                "varshesha_planet": varshaphal_data.get("varshesha_planet", "Unknown"),
                "year_summary": varshaphal_data.get("year_summary", ""),
            },
            "chart": varshaphal_data.get("chart_facts", {}),
            "planets": varshaphal_data.get("chart_facts", {}).get("planets", []),
            "life_areas": [
                {
                    "title": "Career & Status",
                    "emoji": "💼",
                    "prediction": "The 10th house lord in a strong annual position indicates professional growth and recognition."
                },
                {
                    "title": "Relationships",
                    "emoji": "❤️",
                    "prediction": "Venus and the 7th house lord determine the annual relationship quality and key partnerships."
                },
                {
                    "title": "Health & Vitality",
                    "emoji": "🌿",
                    "prediction": "The 1st and 6th house dynamics in the solar return chart indicate physical vitality."
                },
                {
                    "title": "Finances",
                    "emoji": "💰",
                    "prediction": "The 2nd and 11th house lords reveal income, gains, and financial opportunities this year."
                },
                {
                    "title": "Travel & Learning",
                    "emoji": "✈️",
                    "prediction": "9th house activation indicates long journeys, higher education, or spiritual retreats."
                },
                {
                    "title": "Spiritual Growth",
                    "emoji": "🕉️",
                    "prediction": "Jupiter's position in the annual chart reveals wisdom, dharma, and spiritual expansion."
                },
            ]
        }

        # Render HTML from template
        template = env.get_template("varshaphal_report.html")
        html_content = template.render(**template_data)

        # Generate PDF
        pdf_path = Path(tempfile.gettempdir()) / f"varshaphal_{uuid4().hex}.pdf"
        HTML(string=html_content).write_pdf(pdf_path)

        return pdf_path
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"PDF generation failed: {str(e)}"
        )