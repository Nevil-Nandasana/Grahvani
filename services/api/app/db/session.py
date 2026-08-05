"""
Grahvani — Async Database Session Management
SQLAlchemy 2.0 async engine + session factory.
"""
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import settings

# ─── Async Engine ─────────────────────────────────────────────────────────────
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=20,           # Max persistent connections in pool
    max_overflow=10,        # Additional connections beyond pool_size under load
    pool_timeout=30,        # Seconds to wait for a connection before raising
    pool_recycle=1800,      # Recycle connections every 30 minutes
    pool_pre_ping=True,     # Validate connection liveness before each use
    echo=settings.DEBUG,    # Log SQL queries in development
)

# ─── Session Factory ──────────────────────────────────────────────────────────
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def init_db_pool() -> None:
    """Called during FastAPI lifespan startup to warm up the connection pool."""
    async with engine.begin() as conn:
        await conn.run_sync(lambda c: None)  # Warm connection


async def close_db_pool() -> None:
    """Called during FastAPI lifespan shutdown to close pool cleanly."""
    await engine.dispose()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    FastAPI dependency that yields a database session per HTTP request,
    committing on success and rolling back on exception.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
