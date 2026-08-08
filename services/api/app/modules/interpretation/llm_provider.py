"""
LLM Provider Abstraction Layer
Provides a unified interface for different LLM providers with fallback support.
"""
import json
import time
from abc import ABC, abstractmethod
from typing import AsyncGenerator, Optional

import redis.asyncio as redis
from fastapi import HTTPException
from google import genai
from google.api_core.exceptions import GoogleAPICallError, GoogleAPIError
from google.generativeai import types as genai_types

from app.config import settings

# Rate limiting constants
RATE_LIMIT = 40  # 40 requests per minute as requested
RATE_LIMIT_WINDOW = 60  # 60 seconds


class LLMProvider(ABC):
    """Abstract base class for LLM providers."""

    @abstractmethod
    async def generate_stream(
        self,
        system_prompt: str,
        user_message: str,
        temperature: float = 0.4,
        max_tokens: int = 1500,
    ) -> AsyncGenerator[str, None]:
        """Generate and stream LLM response."""
        pass


class GeminiProvider(LLMProvider):
    """Google Gemini provider implementation."""

    def __init__(self, model_name: str, api_key: str):
        genai.configure(api_key=api_key)
        self.model_name = model_name
        self.model = genai.GenerativeModel(
            model_name=model_name,
            generation_config={"temperature": 0.2, "max_output_tokens": 600},
        )

    async def generate_stream(
        self,
        system_prompt: str,
        user_message: str,
        temperature: float = 0.4,
        max_tokens: int = 1500,
    ) -> AsyncGenerator[str, None]:
        """Generate and stream response from Google Gemini."""
        full_prompt = f"{system_prompt}\n\n{user_message}"
        try:
            response = await self.model.generate_content_async(
                full_prompt,
                stream=True,
                generation_config=genai_types.GenerationConfig(
                    temperature=temperature,
                    max_output_tokens=max_tokens,
                ),
            )
            async for chunk in response:
                if chunk.text:
                    yield chunk.text
        except (GoogleAPICallError, GoogleAPIError) as e:
            # Check if this is a billing/quota error
            if "quota" in str(e).lower() or "billing" in str(e).lower() or "credit" in str(e).lower():
                raise BillingError("Google Gemini API billing error")
            raise


class NVIDIAProvider(LLMProvider):
    """NVIDIA Nemotron provider implementation."""

    def __init__(self, model_name: str, api_key: str):
        self.model_name = model_name
        self.api_key = api_key
        self.base_url = "https://integrate.api.nvidia.com/v1"

    async def generate_stream(
        self,
        system_prompt: str,
        user_message: str,
        temperature: float = 0.4,
        max_tokens: int = 1500,
    ) -> AsyncGenerator[str, None]:
        """Generate and stream response from NVIDIA Nemotron."""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
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
        
        # Import httpx only when needed
        import httpx
        
        async with httpx.AsyncClient() as client:
            async with client.stream("POST", f"{self.base_url}/chat/completions", json=payload, headers=headers) as response:
                if response.status_code != 200:
                    error_data = await response.json()
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"NVIDIA API error: {error_data.get('message', 'Unknown error')}",
                    )
                
                async for chunk in response.aiter_bytes():
                    if chunk:
                        # Parse Server-Sent Events
                        for line in chunk.decode().split("\n"):
                            if line.startswith("data: ") and line.strip() != "data: [DONE]":
                                try:
                                    data = json.loads(line[6:])
                                    if "choices" in data and len(data["choices"]) > 0:
                                        content = data["choices"][0].get("delta", {}).get("content", "")
                                        if content:
                                            yield content
                                except json.JSONDecodeError:
                                    continue


class BillingError(Exception):
    """Raised when API billing/quota issues occur."""
    pass


class RateLimiter:
    """Rate limiter using Redis for distributed rate limiting."""

    def __init__(self, redis_url: str):
        self.redis = redis.from_url(redis_url)

    async def check_rate_limit(self, key: str, limit: int = RATE_LIMIT, window: int = RATE_LIMIT_WINDOW) -> bool:
        """Check if the rate limit has been exceeded."""
        current = await self.redis.get(key)
        if current and int(current) >= limit:
            return False
        
        pipe = self.redis.pipeline()
        pipe.incr(key)
        pipe.expire(key, window)
        await pipe.execute()
        return True

    async def get_remaining(self, key: str) -> int:
        """Get remaining requests in the current window."""
        current = await self.redis.get(key)
        return RATE_LIMIT - int(current or 0)


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
            async def generate_stream(
                self,
                system_prompt: str,
                user_message: str,
                temperature: float = 0.4,
                max_tokens: int = 1500,
            ) -> AsyncGenerator[str, None]:
                # Check rate limit first
                user_key = f"llm:rate_limit:{user_message[:50]}"  # Simple key based on prompt
                if not await self.rate_limiter.check_rate_limit(user_key):
                    raise HTTPException(
                        status_code=429,
                        detail=f"Rate limit exceeded. Maximum {RATE_LIMIT} requests per minute.",
                    )
                
                try:
                    # Try primary provider first
                    async for chunk in primary_provider.generate_stream(
                        system_prompt, user_message, temperature, max_tokens
                    ):
                        yield chunk
                except BillingError:
                    # Fallback to NVIDIA if primary fails due to billing
                    if settings.LLM_FALLBACK_PROVIDER == "nvidia" and settings.NVIDIA_API_KEY:
                        fallback_provider = NVIDIAProvider(
                            model_name=settings.NVIDIA_MODEL_NAME or "nvidia/nemotron-3-ultra-550b-instruct",
                            api_key=settings.NVIDIA_API_KEY,
                        )
                        async for chunk in fallback_provider.generate_stream(
                            system_prompt, user_message, temperature, max_tokens
                        ):
                            yield chunk
                    else:
                        raise HTTPException(
                            status_code=503,
                            detail="Primary API failed and no fallback provider configured.",
                        )
                except Exception as e:
                    raise HTTPException(
                        status_code=500,
                        detail=f"LLM generation failed: {str(e)}",
                    )
        
        fallback_provider = FallbackProvider()
        fallback_provider.rate_limiter = self.rate_limiter
        return fallback_provider