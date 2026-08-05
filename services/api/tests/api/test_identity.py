"""
Pytest Integration Tests — Identity API Endpoints
"""
import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch

from app.main import app


@pytest.mark.asyncio
async def test_health_check():
    """Health endpoint should return 200 without auth."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_unauthenticated_profile_creation_returns_401():
    """Creating a profile without auth token should return 401/403."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post("/api/v1/profiles", json={
            "name": "Test User",
            "date_of_birth": "1990-01-01",
            "time_of_birth": "12:00:00",
            "place_name": "Mumbai",
            "latitude": 19.07,
            "longitude": 72.87,
        })
    assert response.status_code in (401, 403)
