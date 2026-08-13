"""
Unit tests for LLM Provider abstraction, Rate Limiting (40 RPM), and NVIDIA Fallback logic.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi import HTTPException

from app.modules.interpretation.llm_provider import (
    BillingError,
    GeminiProvider,
    LLMProviderFactory,
    NVIDIAProvider,
    RateLimiter,
    RATE_LIMIT,
)


@pytest.mark.asyncio
async def test_rate_limiter_allows_under_limit():
    """Rate limiter should allow requests within the 40 RPM limit."""
    mock_redis = AsyncMock()
    mock_redis.incr.return_value = 1

    limiter = RateLimiter("redis://localhost:6379/0")
    limiter.redis = mock_redis

    allowed = await limiter.check_rate_limit("test_user_key")
    assert allowed is True
    mock_redis.incr.assert_called_once_with("test_user_key")
    mock_redis.expire.assert_called_once_with("test_user_key", 60)


@pytest.mark.asyncio
async def test_rate_limiter_blocks_over_limit():
    """Rate limiter should block request #41 within 60s."""
    mock_redis = AsyncMock()
    mock_redis.incr.return_value = 41

    limiter = RateLimiter("redis://localhost:6379/0")
    limiter.redis = mock_redis

    allowed = await limiter.check_rate_limit("test_user_key")
    assert allowed is False
    # expire should not be called again on request 41
    mock_redis.expire.assert_not_called()


@pytest.mark.asyncio
async def test_rate_limiter_does_not_reset_ttl_on_subsequent_requests():
    """Rate limiter should set TTL only when count is 1 (first request in window)."""
    mock_redis = AsyncMock()
    mock_redis.incr.return_value = 5

    limiter = RateLimiter("redis://localhost:6379/0")
    limiter.redis = mock_redis

    allowed = await limiter.check_rate_limit("test_user_key")
    assert allowed is True
    mock_redis.expire.assert_not_called()


@pytest.mark.asyncio
async def test_fallback_provider_switches_to_nvidia_on_billing_error():
    """When primary provider raises BillingError, FallbackProvider should switch to NVIDIA."""
    mock_primary = AsyncMock()

    async def mock_primary_stream(*args, **kwargs):
        raise BillingError("Google Gemini API quota exceeded")
        yield  # make it a generator

    mock_primary.generate_stream = mock_primary_stream

    mock_rate_limiter = AsyncMock()
    mock_rate_limiter.check_rate_limit.return_value = True

    factory = LLMProviderFactory()
    factory.create_provider = AsyncMock(return_value=mock_primary)
    factory.rate_limiter = mock_rate_limiter

    fallback_provider = await factory.create_provider_with_fallback()

    mock_nvidia_chunks = ["Hello ", "from ", "NVIDIA!"]

    async def mock_nvidia_stream(*args, **kwargs):
        for chunk in mock_nvidia_chunks:
            yield chunk

    with patch("app.modules.interpretation.llm_provider.settings.NVIDIA_API_KEY", "test-nvidia-key"), \
         patch.object(NVIDIAProvider, "generate_stream", side_effect=mock_nvidia_stream):
        chunks = []
        async for chunk in fallback_provider.generate_stream("sys", "user", rate_limit_key="user_123"):
            chunks.append(chunk)

        assert chunks == ["Hello ", "from ", "NVIDIA!"]


@pytest.mark.asyncio
async def test_fallback_provider_raises_429_when_rate_limit_exceeded():
    """FallbackProvider should raise 429 when rate limit is exceeded."""
    mock_primary = AsyncMock()
    mock_rate_limiter = AsyncMock()
    mock_rate_limiter.check_rate_limit.return_value = False

    factory = LLMProviderFactory()
    factory.create_provider = AsyncMock(return_value=mock_primary)
    factory.rate_limiter = mock_rate_limiter

    fallback_provider = await factory.create_provider_with_fallback()

    with pytest.raises(HTTPException) as exc_info:
        async for _ in fallback_provider.generate_stream("sys", "user", rate_limit_key="user_123"):
            pass

    assert exc_info.value.status_code == 429
    assert "Rate limit exceeded" in exc_info.value.detail


@pytest.mark.asyncio
async def test_gemini_provider_multi_key_parsing_and_rotation():
    """GeminiProvider should parse comma-separated keys and rotate across them."""
    provider = GeminiProvider(
        model_name="gemini-2.0-flash",
        api_key="key_1, key_2, key_3",
    )
    assert provider.api_keys == ["key_1", "key_2", "key_3"]
    assert len(provider._clients) == 3


@pytest.mark.asyncio
async def test_nvidia_provider_multi_key_parsing_and_rotation():
    """NVIDIAProvider should parse comma-separated keys and rotate across them."""
    provider = NVIDIAProvider(
        model_name="nvidia/nemotron-3-ultra-550b-instruct",
        api_key="nv_key_1, nv_key_2",
    )
    assert provider.api_keys == ["nv_key_1", "nv_key_2"]


