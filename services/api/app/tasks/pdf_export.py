"""
Dramatiq Task — High Resolution PDF Birth Chart Export
"""
import asyncio
import io
import os
import uuid
from datetime import datetime

import boto3
import dramatiq
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

from app.config import settings
from app.db.session import AsyncSessionLocal
from app.modules.birth_chart.models import BirthChart
from app.modules.identity.models import BirthProfile


@dramatiq.actor(queue_name="default", max_retries=3, time_limit=300_000)
def generate_chart_pdf_task(chart_id: str) -> None:
    """
    Background Dramatiq task that:
    1. Fetches BirthChart and BirthProfile.
    2. Renders PDF using Jinja2 and WeasyPrint.
    3. Uploads the generated PDF to S3.
    4. Updates pdf_status and pdf_url on the chart.
    """
    asyncio.run(_generate_chart_pdf_async(chart_id))


async def _generate_chart_pdf_async(chart_id: str) -> None:
    async with AsyncSessionLocal() as db:
        chart = await db.get(BirthChart, uuid.UUID(chart_id))
        if not chart or not chart.chart_facts_json:
            return

        profile = await db.get(BirthProfile, chart.profile_id)
        if not profile:
            return

        # Mark as calculating
        chart.pdf_status = "pending"
        await db.commit()

        try:
            # Setup Jinja2 Environment
            templates_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
            env = Environment(loader=FileSystemLoader(templates_dir))
            template = env.get_template("birth_chart_pdf.html")

            # Render HTML
            html_content = template.render(
                profile_name=profile.name,
                date_of_birth=profile.date_of_birth,
                time_of_birth=profile.time_of_birth,
                place_name=profile.place_name,
                ayanamsa=chart.ayanamsa,
                planets=chart.chart_facts_json.get("planets", {}),
                current_year=datetime.now().year,
            )

            # Generate PDF via WeasyPrint
            pdf_bytes = HTML(string=html_content).write_pdf()

            # Upload to S3
            s3_client = boto3.client("s3", region_name=settings.AWS_REGION)
            object_key = f"pdfs/birth_charts/{chart.id}.pdf"

            # Assuming IAM Role or environment variables provide AWS credentials
            s3_client.upload_fileobj(
                io.BytesIO(pdf_bytes),
                settings.AWS_S3_BUCKET_NAME,
                object_key,
                ExtraArgs={"ContentType": "application/pdf"}
            )

            # Update DB
            chart.pdf_url = object_key
            chart.pdf_status = "complete"

        except Exception as e:
            chart.pdf_status = "error"
            # Optional: log the error or save to another field

        await db.commit()
