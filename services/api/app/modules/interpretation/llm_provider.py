"""
LLM Provider Abstraction Layer
Provides a unified interface for different LLM providers with fallback support and Redis rate limiting.
"""
import json
import logging
from abc import ABC, abstractmethod
from typing import AsyncGenerator, Optional

import redis.asyncio as redis
from fastapi import HTTPException
from google import genai
from google.api_core.exceptions import GoogleAPICallError, GoogleAPIError

from app.config import settings

logger = logging.getLogger(__name__)

# Rate limiting constants
RATE_LIMIT = 40  # 40 requests per minute
RATE_LIMIT_WINDOW = 60  # 60 seconds


class BillingError(Exception):
    """Raised when API billing/quota/credit issues occur."""
    pass


class LLMProvider(ABC):
    """Abstract base class for LLM providers."""

    @abstractmethod
    async def generate_stream(
        self,
        system_prompt: str,
        user_message: str,
        temperature: float = 0.4,
        max_tokens: int = 1500,
        rate_limit_key: Optional[str] = None,
    ) -> AsyncGenerator[str, None]:
        """Generate and stream LLM response."""
        pass


class GeminiProvider(LLMProvider):
    """Google Gemini provider implementation supporting multi-key rotation and SDK fallbacks."""

    def __init__(self, model_name: str, api_key: str | list[str]):
        self.model_name = model_name
        if isinstance(api_key, str):
            # Parse comma-separated keys if provided
            self.api_keys = [k.strip() for k in api_key.split(",") if k.strip()]
        else:
            self.api_keys = [k.strip() for k in api_key if k.strip()]

        if not self.api_keys:
            self.api_keys = [""]

        self._clients = []
        self._legacy_models = []
        self._use_new_sdk = True
        self._current_index = 0

        for key in self.api_keys:
            try:
                # Modern google-genai SDK (v1.0+)
                client = genai.Client(api_key=key)
                self._clients.append(client)
            except (AttributeError, TypeError):
                # Legacy google.generativeai fallback
                import google.generativeai as legacy_genai
                legacy_genai.configure(api_key=key)
                model = legacy_genai.GenerativeModel(model_name=model_name)
                self._legacy_models.append(model)
                self._use_new_sdk = False

    def _get_next_index(self) -> int:
        """Get current key index and advance for round-robin rotation."""
        idx = self._current_index
        self._current_index = (self._current_index + 1) % len(self.api_keys)
        return idx

    async def generate_stream(
        self,
        system_prompt: str,
        user_message: str,
        temperature: float = 0.4,
        max_tokens: int = 1500,
        rate_limit_key: Optional[str] = None,
    ) -> AsyncGenerator[str, None]:
        """Generate and stream response from Google Gemini with multi-key failover."""
        full_prompt = f"{system_prompt}\n\n{user_message}"
        num_keys = len(self.api_keys)
        start_idx = self._get_next_index()
        last_exception = None

        for attempt in range(num_keys):
            key_idx = (start_idx + attempt) % num_keys
            try:
                if self._use_new_sdk:
                    from google.genai import types
                    client = self._clients[key_idx]
                    response = await client.aio.models.generate_content_stream(
                        model=self.model_name,
                        contents=full_prompt,
                        config=types.GenerateContentConfig(
                            temperature=temperature,
                            max_output_tokens=max_tokens,
                        ),
                    )
                    async for chunk in response:
                        if chunk.text:
                            yield chunk.text
                    return  # Success
                else:
                    model = self._legacy_models[key_idx]
                    response = await model.generate_content_async(
                        full_prompt,
                        stream=True,
                        generation_config={
                            "temperature": temperature,
                            "max_output_tokens": max_tokens,
                        },
                    )
                    async for chunk in response:
                        if chunk.text:
                            yield chunk.text
                    return  # Success
            except (GoogleAPICallError, GoogleAPIError, Exception) as e:
                last_exception = e
                err_msg = str(e).lower()
                if "quota" in err_msg or "billing" in err_msg or "credit" in err_msg or "429" in err_msg or "exceeded" in err_msg:
                    logger.warning(
                        f"Gemini API Key index {key_idx} quota/billing error: {e}. Trying next key..."
                    )
                    continue
                if settings.APP_ENV == "development":
                    logger.warning(f"Gemini API error ({e}). Using local Vedic AI fallback in development.")
                    break
                raise

        # If in development or keys exhausted, provide classical Vedic response
        if settings.APP_ENV == "development" or not any(self.api_keys):
            fallback_response = (
                "Namaste! 🙏 Based on your classical Vedic birth chart (Kundali):\n\n"
                "✨ **Planetary Insights & Guidance:**\n"
                f"Regarding your inquiry ('{user_message}'), classical Shastras such as *Brihat Parashara Hora Shastra* "
                "teach that the planetary placements, their dignity, and the prevailing Vimshottari Dasha guide the flow of karma.\n\n"
                "🪐 **Astrological Perspective:**\n"
                "• **Lagnesha (Ascendant Lord)** establishes physical vitality, foundational purpose, and personal resilience.\n"
                "• **Moon (Chandra)** and its Nakshatra govern mental peace, intuition, and emotional clarity.\n"
                "• **Jupiter (Guru)** bestows wisdom, righteous action (Dharma), and spiritual expansion.\n\n"
                "🌿 **Recommended Remedies & Practices:**\n"
                "1. Maintain disciplined morning meditation and offer water to the rising Sun (*Surya Arghya*).\n"
                "2. Recite the Maha Mrityunjaya Mantra or Gayatri Mantra 108 times during your prevailing dasha.\n"
                "3. Cultivate sattvic deeds and dana (charity) aligned with the day of your ruling planet.\n\n"
                "May the planetary deities bestow wisdom, peace, and prosperity upon your journey. [Brihat Parashara Hora Shastra Ch. 12]"
            )
            import asyncio
            for word in fallback_response.split(" "):
                yield word + " "
                await asyncio.sleep(0.02)
            return

        # All keys failed
        logger.error("All Gemini API keys in pool failed or exhausted quota.")
        raise BillingError(f"All Google Gemini API keys exhausted: {last_exception}") from last_exception


class NVIDIAProvider(LLMProvider):
    """NVIDIA Nemotron provider implementation supporting multi-key failover."""

    def __init__(self, model_name: str, api_key: str | list[str]):
        self.model_name = model_name
        if isinstance(api_key, str):
            self.api_keys = [k.strip() for k in api_key.split(",") if k.strip()]
        else:
            self.api_keys = [k.strip() for k in api_key if k.strip()]

        if not self.api_keys:
            self.api_keys = [""]

        self.base_url = "https://integrate.api.nvidia.com/v1"
        self._current_index = 0

    def _get_next_index(self) -> int:
        """Get current key index and advance for round-robin rotation."""
        idx = self._current_index
        self._current_index = (self._current_index + 1) % len(self.api_keys)
        return idx

    async def generate_stream(
        self,
        system_prompt: str,
        user_message: str,
        temperature: float = 0.4,
        max_tokens: int = 1500,
        rate_limit_key: Optional[str] = None,
    ) -> AsyncGenerator[str, None]:
        """Generate and stream response from NVIDIA Nemotron with multi-key failover."""
        import httpx

        num_keys = len(self.api_keys)
        start_idx = self._get_next_index()
        last_exception = None

        for attempt in range(num_keys):
            key_idx = (start_idx + attempt) % num_keys
            key = self.api_keys[key_idx]

            headers = {
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json",
            }

            payload = {
                "model": self.model_name,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                "temperature": temperature,
                "max_tokens": max_tokens,
                "stream": True,
            }

            try:
                async with httpx.AsyncClient() as client:
                    async with client.stream("POST", f"{self.base_url}/chat/completions", json=payload, headers=headers) as response:
                        if response.status_code != 200:
                            error_body = await response.aread()
                            error_text = error_body.decode("utf-8", errors="ignore")
                            if response.status_code in (402, 429) or "quota" in error_text.lower() or "billing" in error_text.lower():
                                logger.warning(f"NVIDIA API Key index {key_idx} rate/billing error ({response.status_code}). Trying next key...")
                                last_exception = BillingError(f"NVIDIA API rate/billing error ({response.status_code}): {error_text}")
                                continue
                            raise HTTPException(
                                status_code=response.status_code,
                                detail=f"NVIDIA API error ({response.status_code}): {error_text}",
                            )

                        # Use aiter_lines to safely parse SSE lines across chunk boundaries
                        async for line in response.aiter_lines():
                            if line.startswith("data: ") and line.strip() != "data: [DONE]":
                                try:
                                    data = json.loads(line[6:])
                                    if "choices" in data and len(data) > 0:
                                        content = data["choices"][0].get("delta", {}).get("content", "")
                                        if content:
                                            yield content
                                except json.JSONDecodeError:
                                    continue
                        return  # Success
            except BillingError:
                continue
            except HTTPException:
                raise
            except Exception as e:
                logger.warning(f"NVIDIA API Key index {key_idx} exception: {e}")
                last_exception = e
                continue

        # All NVIDIA keys failed
        logger.error("All NVIDIA API keys in pool failed or exhausted quota.")
        raise BillingError(f"All NVIDIA API keys exhausted: {last_exception}") from last_exception


class RateLimiter:
    """Rate limiter using Redis for distributed rate limiting."""

    def __init__(self, redis_url: str):
        self.redis = redis.from_url(redis_url)

    async def check_rate_limit(self, key: str, limit: int = RATE_LIMIT, window: int = RATE_LIMIT_WINDOW) -> bool:
        """Check if the rate limit has been exceeded atomically without resetting TTL."""
        try:
            count = await self.redis.incr(key)
            if count == 1:
                await self.redis.expire(key, window)
            return count <= limit
        except Exception as e:
            logger.warning(f"Redis rate limiter failed: {e}. Bypassing rate limit check.")
            return True

    async def get_remaining(self, key: str, limit: int = RATE_LIMIT) -> int:
        """Get remaining requests in the current window."""
        try:
            current = await self.redis.get(key)
            used = int(current or 0)
            return max(0, limit - used)
        except Exception:
            return limit


class LLMProviderFactory:
    """Factory for creating LLM providers with fallback support."""

    def __init__(self):
        self.rate_limiter = RateLimiter(settings.REDIS_URL)

    async def create_provider(self) -> LLMProvider:
        """Create the primary LLM provider based on configuration."""
        if settings.LLM_PROVIDER == "google":
            return GeminiProvider(
                model_name=settings.LLM_MODEL_NAME or "gemini-2.0-flash",
                api_key=settings.GEMINI_API_KEY,
            )
        elif settings.LLM_PROVIDER == "nvidia":
            return NVIDIAProvider(
                model_name=settings.NVIDIA_MODEL_NAME or "nvidia/nemotron-3-ultra-550b-instruct",
                api_key=settings.NVIDIA_API_KEY,
            )
        else:
            raise ValueError(f"Unknown LLM provider: {settings.LLM_PROVIDER}")

    async def create_provider_with_fallback(self) -> LLMProvider:
        """Create provider with automatic fallback when primary fails."""
        primary_provider = await self.create_provider()

        class FallbackProvider(LLMProvider):
            def __init__(self, primary: LLMProvider, rate_limiter: RateLimiter):
                self.primary_provider = primary
                self.rate_limiter = rate_limiter

            async def generate_stream(
                self,
                system_prompt: str,
                user_message: str,
                temperature: float = 0.4,
                max_tokens: int = 1500,
                rate_limit_key: Optional[str] = None,
            ) -> AsyncGenerator[str, None]:
                # Check rate limit first
                key = f"llm:rate_limit:{rate_limit_key if rate_limit_key else 'global'}"
                if not await self.rate_limiter.check_rate_limit(key):
                    raise HTTPException(
                        status_code=429,
                        detail=f"Rate limit exceeded. Maximum {RATE_LIMIT} requests per minute.",
                    )

                has_yielded = False
                try:
                    async for chunk in self.primary_provider.generate_stream(
                        system_prompt, user_message, temperature, max_tokens, rate_limit_key
                    ):
                        has_yielded = True
                        yield chunk
                except (BillingError, Exception) as e:
                    # Trigger fallback if BillingError occurs or if primary failed before yielding any output
                    if isinstance(e, BillingError) or not has_yielded:
                        if settings.LLM_FALLBACK_PROVIDER == "nvidia" and settings.NVIDIA_API_KEY:
                            logger.info("Primary provider failed due to quota/error. Switching to NVIDIA fallback provider.")
                            fallback_provider = NVIDIAProvider(
                                model_name=settings.NVIDIA_MODEL_NAME or "nvidia/nemotron-3-ultra-550b-instruct",
                                api_key=settings.NVIDIA_API_KEY,
                            )
                            async for chunk in fallback_provider.generate_stream(
                                system_prompt, user_message, temperature, max_tokens, rate_limit_key
                            ):
                                yield chunk
                            return
                        else:
                            raise HTTPException(
                                status_code=503,
                                detail="Primary API failed and no fallback provider configured.",
                            )

                    if isinstance(e, HTTPException):
                        raise e
                    raise HTTPException(
                        status_code=500,
                        detail=f"LLM generation failed: {str(e)}",
                    )

        return FallbackProvider(primary_provider, self.rate_limiter)