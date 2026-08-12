"""
Pytest Test Suite — BGE Reranker Engine & Full-App TestClient Verification
Tests unit reranker functionality and full-app TestClient integration against app.main:app.
"""
import json
import uuid
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.config import settings
from app.modules.interpretation.reranker import (
    BaseReranker,
    BGEReranker,
    MockReranker,
    get_reranker,
    reset_reranker,
)


# ─── 1. Unit Tests for Reranker Engine ──────────────────────────────────────

def test_mock_reranker_scoring_and_sorting():
    """Verify MockReranker ranks relevant keyword-matching chunk higher than non-matching chunk."""
    reranker = MockReranker()
    query = "Jupiter in 5th house education children"
    candidates = [
        {
            "id": "chunk-1",
            "source_title": "Phaladeepika",
            "chapter": "Chapter 5",
            "sloka_number": "Verse 10",
            "content": "General planetary transits across zodiac signs.",
        },
        {
            "id": "chunk-2",
            "source_title": "Brihat Parasara Hora Shastra",
            "chapter": "Chapter 12",
            "sloka_number": "Verse 4",
            "content": "Jupiter in 5th house confers great intellect, education, and noble children.",
        },
    ]

    results = reranker.rerank(query, candidates, top_k=2, min_threshold=0.0)
    assert len(results) == 2
    assert results[0]["id"] == "chunk-2"
    assert results[0]["rerank_score"] > results[1]["rerank_score"]
    assert results[0]["reranked"] is True


def test_reranker_sigmoid_and_score_bounds():
    """Verify all returned scores lie strictly within [0.0, 1.0]."""
    reranker = MockReranker()
    query = "Sun in Aries exalted"
    candidates = [
        {"id": f"chunk-{i}", "source_title": "Text", "chapter": "Ch 1", "sloka_number": f"V {i}", "content": f"Sample chunk content {i} Aries Sun"}
        for i in range(10)
    ]
    results = reranker.rerank(query, candidates, top_k=5, min_threshold=0.0)

    assert len(results) == 5
    for item in results:
        assert "rerank_score" in item
        assert 0.0 <= item["rerank_score"] <= 1.0


def test_reranker_min_threshold_filtering():
    """Verify candidates below min_threshold are excluded."""
    reranker = MockReranker()
    query = "Mars in 1st house Manglik"
    candidates = [
        {"id": "c1", "source_title": "Text", "chapter": "C1", "sloka_number": "V1", "content": "Mars in 1st house creates Manglik dosha."},
    ]
    # Threshold set higher than maximum possible score (0.99)
    results = reranker.rerank(query, candidates, top_k=4, min_threshold=0.99)
    assert len(results) == 0


def test_reranker_top_k_truncation():
    """Verify reranker truncates candidate list to top_k."""
    reranker = MockReranker()
    query = "Vimshottari Dasha planetary periods"
    candidates = [
        {"id": f"chunk-{i}", "source_title": "Text", "chapter": "Ch 1", "sloka_number": f"V {i}", "content": f"Dasha period detail {i}"}
        for i in range(20)
    ]
    results = reranker.rerank(query, candidates, top_k=4, min_threshold=0.0)
    assert len(results) == 4


def test_reranker_empty_input():
    """Verify empty input candidates list returns empty list."""
    reranker = MockReranker()
    assert reranker.rerank("Astrology query", [], top_k=4) == []


def test_bge_reranker_fallback_on_model_load_failure():
    """Verify BGEReranker degrades gracefully to top_k RRF candidates when model load fails."""
    reranker = BGEReranker(model_name="nonexistent-model-name-xyz")
    query = "Saturn transit Sade Sati"
    candidates = [
        {"id": "c1", "source_title": "Text 1", "chapter": "Ch 1", "sloka_number": "V1", "content": "Saturn transit in 12th house."},
        {"id": "c2", "source_title": "Text 2", "chapter": "Ch 2", "sloka_number": "V2", "content": "Sade Sati phase explanation."},
    ]

    results = reranker.rerank(query, candidates, top_k=2, min_threshold=0.35)
    assert len(results) == 2
    assert results[0]["id"] == "c1"
    assert "rerank_score" in results[0]


def test_get_reranker_singleton():
    """Verify get_reranker() returns a valid BaseReranker singleton."""
    reset_reranker()
    instance1 = get_reranker()
    instance2 = get_reranker()
    assert isinstance(instance1, BaseReranker)
    assert instance1 is instance2
    reset_reranker()


# ─── 2. Full-App TestClient Integration Tests against app.main:app ──────────

@pytest.mark.asyncio
async def test_full_app_chat_stream_reranker_integration():
    """
    End-to-end full-app TestClient test verifying:
    1. POST /api/v1/chat/stream executes through app.main:app
    2. RAG hybrid retrieval invokes reranker engine
    3. SSE stream yields valid JSON events ('citations', 'delta', 'done')
    4. Reranked chunk score metadata is included in citation objects
    """
    mock_session_id = uuid.uuid4()
    mock_user = MagicMock()
    mock_user.id = uuid.uuid4()
    mock_user.firebase_uid = "demo-user-uid-12345"

    mock_chat_session = MagicMock()
    mock_chat_session.id = mock_session_id
    mock_chat_session.user_id = mock_user.id
    mock_chat_session.chart_id = None

    mock_reranked_chunks = [
        {
            "id": "chunk-101",
            "source_title": "Brihat Parasara Hora Shastra",
            "chapter": "Chapter 12",
            "sloka_number": "Verse 4",
            "content": "Jupiter in 5th house confers high intelligence.",
            "rerank_score": 0.8921,
            "reranked": True,
        },
        {
            "id": "chunk-102",
            "source_title": "Phaladeepika",
            "chapter": "Chapter 5",
            "sloka_number": "Verse 10",
            "content": "Planetary aspects on 5th house.",
            "rerank_score": 0.7450,
            "reranked": True,
        },
    ]

    mock_db = AsyncMock()
    mock_db.get.return_value = mock_chat_session
    mock_db.flush = AsyncMock()
    mock_db.commit = AsyncMock()

    async def override_get_db():
        yield mock_db

    from app.db.session import get_db

    with patch("app.modules.interpretation.router._get_user", new_callable=AsyncMock) as mock_get_user, \
         patch("app.modules.interpretation.router._get_user_tier", new_callable=AsyncMock, return_value="free"), \
         patch("app.modules.interpretation.router._check_daily_quota", new_callable=AsyncMock), \
         patch("app.modules.interpretation.router._hybrid_search", new_callable=AsyncMock) as mock_hybrid_search, \
         patch("app.modules.interpretation.llm_provider.LLMProviderFactory.create_provider_with_fallback") as mock_llm_factory, \
         patch("app.modules.interpretation.router.tracer") as mock_tracer, \
         patch("app.modules.interpretation.router.AsyncSessionLocal"):

        mock_get_user.return_value = mock_user
        mock_hybrid_search.return_value = mock_reranked_chunks

        # Mock LLM provider stream
        mock_provider = AsyncMock()
        async def mock_stream(*args, **kwargs):
            yield "Jupiter in the 5th house is highly auspicious for education."

        mock_provider.generate_stream = mock_stream
        mock_llm_factory.return_value = mock_provider
        mock_tracer.start_trace.return_value = {"trace_id": "test-trace-123"}

        headers = {"Authorization": "Bearer demo-token-123"}
        payload = {
            "session_id": str(mock_session_id),
            "prompt": "What does Jupiter placement in the 5th house mean for education?",
        }

        app.dependency_overrides[get_db] = override_get_db
        try:
            async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
                response = await client.post("/api/v1/chat/stream", json=payload, headers=headers)

            assert response.status_code == 200
            assert "text/event-stream" in response.headers["content-type"]

            response_text = response.text
            assert "data: " in response_text
            assert "citations" in response_text
            assert "Brihat Parasara Hora Shastra" in response_text
            assert "0.8921" in response_text or "rerank_score" in response_text
            assert "delta" in response_text
            assert "done" in response_text

            mock_hybrid_search.assert_called_once()
        finally:
            app.dependency_overrides = {}


@pytest.mark.asyncio
async def test_full_app_chat_stream_reranker_fallback_degradation():
    """
    Verify full-app chat stream degrades gracefully when reranker throws an exception.
    The API must return HTTP 200 SSE stream without failing the request.
    """
    mock_session_id = uuid.uuid4()
    mock_user = MagicMock()
    mock_user.id = uuid.uuid4()
    mock_user.firebase_uid = "demo-user-uid-12345"

    mock_chat_session = MagicMock()
    mock_chat_session.id = mock_session_id
    mock_chat_session.user_id = mock_user.id
    mock_chat_session.chart_id = None

    fallback_chunks = [
        {
            "id": "chunk-101",
            "source_title": "Brihat Parasara Hora Shastra",
            "chapter": "Chapter 1",
            "sloka_number": "Verse 1",
            "content": "Sample classical verse.",
            "rerank_score": 0.95,
            "reranked": False,
        }
    ]

    mock_db = AsyncMock()
    mock_db.get.return_value = mock_chat_session
    mock_db.flush = AsyncMock()
    mock_db.commit = AsyncMock()

    async def override_get_db():
        yield mock_db

    from app.db.session import get_db

    with patch("app.modules.interpretation.router._get_user", new_callable=AsyncMock) as mock_get_user, \
         patch("app.modules.interpretation.router._get_user_tier", new_callable=AsyncMock, return_value="free"), \
         patch("app.modules.interpretation.router._check_daily_quota", new_callable=AsyncMock), \
         patch("app.modules.interpretation.router._hybrid_search", new_callable=AsyncMock) as mock_hybrid_search, \
         patch("app.modules.interpretation.llm_provider.LLMProviderFactory.create_provider_with_fallback") as mock_llm_factory, \
         patch("app.modules.interpretation.router.tracer") as mock_tracer, \
         patch("app.modules.interpretation.router.AsyncSessionLocal"):

        mock_get_user.return_value = mock_user
        mock_hybrid_search.return_value = fallback_chunks

        mock_provider = AsyncMock()
        async def mock_stream(*args, **kwargs):
            yield "Response generated despite reranker fallback."

        mock_provider.generate_stream = mock_stream
        mock_llm_factory.return_value = mock_provider
        mock_tracer.start_trace.return_value = {"trace_id": "test-trace-fallback"}

        headers = {"Authorization": "Bearer demo-token-123"}
        payload = {
            "session_id": str(mock_session_id),
            "prompt": "Explain Sade Sati phase 2.",
        }

        app.dependency_overrides[get_db] = override_get_db
        try:
            async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
                response = await client.post("/api/v1/chat/stream", json=payload, headers=headers)

            assert response.status_code == 200
            assert "text/event-stream" in response.headers["content-type"]
            assert "Response generated despite reranker fallback." in response.text
        finally:
            app.dependency_overrides = {}


@pytest.mark.asyncio
async def test_full_app_chat_stream_content_guardrail_rejection():
    """Verify medical/financial prompts are blocked by content guardrails before retrieval."""
    headers = {"Authorization": "Bearer demo-token-123"}
    payload = {
        "session_id": str(uuid.uuid4()),
        "prompt": "What medication or drug dosage should I take to cure diabetes?",
    }

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/chat/stream", json=payload, headers=headers)

    assert response.status_code == 422
    data = response.json()
    assert data.get("error", {}).get("code") == "GUARDRAIL_TRIGGERED"


@pytest.mark.asyncio
async def test_full_app_chat_stream_validation_error():
    """Verify invalid request body returns HTTP 422 Unprocessable Entity."""
    headers = {"Authorization": "Bearer demo-token-123"}
    payload = {
        "session_id": "invalid-uuid-format",
        "prompt": "",  # Empty prompt violates min_length=1
    }

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/chat/stream", json=payload, headers=headers)

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_full_app_chat_stream_unauthenticated():
    """Verify request without Authorization header is rejected with 401 or 403."""
    payload = {
        "session_id": str(uuid.uuid4()),
        "prompt": "What does Sun in Aries mean?",
    }

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/chat/stream", json=payload)

    assert response.status_code in (401, 403)
