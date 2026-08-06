# Integration Testing Specification

## Purpose
This document defines the integration testing strategy for the Grahvani backend. Integration tests verify that the FastAPI application interacts correctly with its external dependencies: the PostgreSQL database, the Redis cache, and the Dramatiq task queue.

## Scope
Applies to tests running in the `tests/integration/` directory. These tests are executed via `pytest` during the CI pipeline and require a running Docker infrastructure (database and cache).

---

## 1. Test Infrastructure (Testcontainers)

To guarantee clean, deterministic environments across local developer machines and CI runners, Grahvani uses the `testcontainers-python` library. This automatically spins up ephemeral Docker containers for PostgreSQL and Redis before the test suite runs and destroys them afterward.

```python
# tests/integration/conftest.py
import pytest
from testcontainers.postgres import PostgresContainer
from testcontainers.redis import RedisContainer
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.db.base import Base

@pytest.fixture(scope="session")
def postgres_container():
    with PostgresContainer("postgres:16-alpine", driver="asyncpg") as postgres:
        yield postgres

@pytest.fixture(scope="session")
async def db_engine(postgres_container):
    engine = create_async_engine(postgres_container.get_connection_url())
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture(scope="function")
async def db_session(db_engine):
    """Provides a fresh database session for each test, rolling back afterward."""
    connection = await db_engine.connect()
    transaction = await connection.begin()
    session_maker = async_sessionmaker(bind=connection)
    session = session_maker()
    
    yield session
    
    await session.close()
    await transaction.rollback()
    await connection.close()
```

---

## 2. API Integration Testing (FastAPI TestClient)

Integration tests hit the actual FastAPI routes using `httpx.AsyncClient`, verifying request parsing, database inserts, and standard HTTP response envelopes.

```python
# tests/integration/test_profiles_api.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_create_profile_route_inserts_into_db(auth_headers, db_session):
    # Dependency override to inject the test database session
    app.dependency_overrides[get_db_session] = lambda: db_session

    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.post(
            "/api/v1/profiles",
            json={
                "full_name": "Test User",
                "birth_date": "1995-10-24",
                "birth_time": "14:30:00",
                "latitude": 22.3072,
                "longitude": 73.1812,
                "timezone_id": "Asia/Kolkata"
            },
            headers=auth_headers
        )
    
    assert response.status_code == 201
    
    data = response.json()["data"]
    assert data["full_name"] == "Test User"
    
    # Verify the profile actually exists in the test DB
    from app.models.profile import BirthProfile
    profile_in_db = await db_session.get(BirthProfile, data["id"])
    assert profile_in_db is not None
```

---

## 3. Webhook Integration Testing

Payment webhooks (Google Play, Apple IAP, Razorpay) are critical infrastructure. Integration tests must verify that incoming webhooks correctly update the `subscriptions` table.

```python
# tests/integration/test_apple_webhooks.py
@pytest.mark.asyncio
async def test_apple_renewal_webhook_updates_subscription(db_session, test_user_id):
    # 1. Seed a cancelled/expired subscription in the DB
    await seed_expired_subscription(db_session, test_user_id)
    
    # 2. Simulate Apple Server-to-Server Notification (V2) payload
    webhook_payload = generate_signed_apple_jwt(
        notification_type="DID_RENEW",
        original_transaction_id="1000000123"
    )
    
    # 3. Post to webhook endpoint
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.post("/api/v1/webhooks/apple", data=webhook_payload)
        
    assert response.status_code == 200
    
    # 4. Verify DB state changed to Active
    sub = await get_subscription(db_session, test_user_id)
    assert sub.status == "active"
```

---

## 4. Background Task Integration (Dramatiq)

To test Dramatiq background tasks (like PDF chart generation), we configure Dramatiq to use an inline, synchronous broker during testing. This allows the task to execute immediately within the test process, rather than requiring a separate worker container.

```python
# tests/integration/conftest.py
import dramatiq
from dramatiq.brokers.stub import StubBroker

@pytest.fixture(autouse=True)
def stub_broker():
    broker = StubBroker()
    broker.emit_after("process_boot")
    dramatiq.set_broker(broker)
    yield broker
    broker.flush_all()
```

---

## 5. Rationale

Using `testcontainers` guarantees that if a test passes locally, it will pass in CI, eliminating "it works on my machine" issues caused by lingering DB state or mismatched PostgreSQL versions. Using transaction rollbacks per-function ensures test isolation without the massive overhead of dropping and recreating the schema for every test.

---

## 6. Related Documents

- [testing/TESTING_STRATEGY.md](TESTING_STRATEGY.md) -- Overall test pyramid
- [testing/UNIT_TESTS.md](UNIT_TESTS.md) -- For fast, isolated business logic testing
- [testing/E2E_TESTS.md](E2E_TESTS.md) -- Mobile integration testing via Maestro
