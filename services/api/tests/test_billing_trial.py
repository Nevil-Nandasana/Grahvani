"""
Pytest Test Suite — 7-Day Free Premium Trial Entitlement Flow & Full-App TestClient Verification
Tests trial activation endpoint, anti-abuse protections, trial expiration tier reversion,
and unauthenticated request handling against app.main:app.
"""
import uuid
from datetime import datetime, timezone, timedelta
import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.db.session import get_db
from app.modules.identity.models import User
from app.modules.billing.models import Subscription


class FakeAsyncSession:
    """In-memory AsyncSession simulator for fast full-app TestClient integration testing."""
    def __init__(self, user: User | None = None, subscriptions: list[Subscription] | None = None):
        self.user = user
        self.subscriptions = subscriptions if subscriptions is not None else []

    async def execute(self, statement):
        stmt_str = str(statement).lower()

        class FakeResult:
            def __init__(self, items):
                self._items = items
            def scalar_one_or_none(self):
                return self._items[0] if self._items else None
            def scalars(self):
                items = self._items
                class FakeScalars:
                    def __init__(self, s_items):
                        self._s_items = s_items
                    def all(self):
                        return self._s_items
                return FakeScalars(items)

        if "users" in stmt_str:
            return FakeResult([self.user] if self.user else [])
        elif "subscriptions" in stmt_str:
            active_subs = [s for s in self.subscriptions if s.status == "active"]
            return FakeResult(active_subs)
        return FakeResult([])

    def add(self, obj):
        if isinstance(obj, Subscription):
            self.subscriptions.append(obj)

    async def commit(self):
        pass

    async def flush(self):
        pass


@pytest.mark.asyncio
async def test_trial_activation_success():
    """
    Verify successful 7-day free trial activation:
    1. POST /api/v1/billing/trial/activate returns HTTP 200 with trial_expires_at = now + 7 days
    2. User is_trial_used is set to True and tier updated to premium
    3. GET /api/v1/billing/entitlements reflects premium tier with 100 daily queries limit
    """
    user_id = uuid.uuid4()
    mock_user = User(
        id=user_id,
        firebase_uid="demo-user-uid-12345",
        email="demo@grahvani.ai",
        tier="free",
        is_trial_used=False,
    )
    fake_session = FakeAsyncSession(user=mock_user)

    async def override_get_db():
        yield fake_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        headers = {"Authorization": "Bearer demo-token-123"}
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            # 1. Activate trial
            response = await client.post("/api/v1/billing/trial/activate", headers=headers)
            assert response.status_code == 200, f"Response: {response.text}"
            data = response.json()
            assert data["status"] == "success"
            assert data["is_trial"] is True
            assert "trial_started_at" in data
            assert "trial_expires_at" in data

            # Verify User model state was updated
            assert mock_user.is_trial_used is True
            assert mock_user.tier == "premium"
            assert len(fake_session.subscriptions) == 1
            assert fake_session.subscriptions[0].is_trial is True
            assert fake_session.subscriptions[0].provider == "trial"

            # 2. Check entitlements endpoint reflects premium trial state
            entitlements_resp = await client.get("/api/v1/billing/entitlements", headers=headers)
            assert entitlements_resp.status_code == 200
            ent_data = entitlements_resp.json()
            assert ent_data["tier"] == "premium"
            assert ent_data["is_active"] is True
            assert ent_data["is_trial"] is True
            assert ent_data["daily_queries_limit"] == 100
            assert ent_data["queries_remaining"] == 100
            assert ent_data["trial_eligible"] is False
    finally:
        app.dependency_overrides = {}


@pytest.mark.asyncio
async def test_trial_activation_anti_abuse_duplicate():
    """
    Verify anti-abuse check: attempting a second trial activation returns HTTP 400 Bad Request.
    """
    user_id = uuid.uuid4()
    mock_user = User(
        id=user_id,
        firebase_uid="demo-user-uid-12345",
        email="demo@grahvani.ai",
        tier="premium",
        is_trial_used=True,
    )
    fake_session = FakeAsyncSession(user=mock_user)

    async def override_get_db():
        yield fake_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        headers = {"Authorization": "Bearer demo-token-123"}
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/billing/trial/activate", headers=headers)
            assert response.status_code == 400
            data = response.json()
            assert data["error"]["message"] == "Trial has already been redeemed for this account."
    finally:
        app.dependency_overrides = {}


@pytest.mark.asyncio
async def test_trial_expiration_reversion():
    """
    Verify trial expiration reversion: past trial expiration date reverts user tier to free (3 queries limit).
    """
    user_id = uuid.uuid4()
    mock_user = User(
        id=user_id,
        firebase_uid="demo-user-uid-12345",
        email="demo@grahvani.ai",
        tier="premium",
        is_trial_used=True,
    )
    past_expiration = datetime.now(timezone.utc) - timedelta(hours=2)
    expired_sub = Subscription(
        id=uuid.uuid4(),
        user_id=user_id,
        provider="trial",
        status="active",
        tier="premium",
        expires_at=past_expiration,
        is_trial=True,
    )
    fake_session = FakeAsyncSession(user=mock_user, subscriptions=[expired_sub])

    async def override_get_db():
        yield fake_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        headers = {"Authorization": "Bearer demo-token-123"}
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.get("/api/v1/billing/entitlements", headers=headers)
            assert response.status_code == 200
            data = response.json()
            assert data["tier"] == "free"
            assert data["is_active"] is False
            assert data["daily_queries_limit"] == 3
            assert data["queries_remaining"] == 3
            assert data["is_trial"] is True
            assert mock_user.tier == "free"
    finally:
        app.dependency_overrides = {}


@pytest.mark.asyncio
async def test_unauthenticated_trial_activation():
    """
    Verify unauthenticated call to trial activation returns HTTP 403 Forbidden.
    """
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/billing/trial/activate")
        assert response.status_code == 403
