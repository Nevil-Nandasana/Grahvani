# Model Selection and Token Economics Specification

## Purpose
This document specifies the LLM provider evaluation criteria, current selection rationale, and token budget economics for Grahvani's AI interpretation layer. The model choice is treated as a **configurable deployment parameter**, not a hardcoded product constant.

## Scope
Applies to the `interpretation` backend module which orchestrates all LLM inference calls. Does not affect the calculation engine (which is deterministic and uses no LLM).

> **Status**: The specific LLM model version is under active evaluation (see [OPEN_DECISIONS.md](../OPEN_DECISIONS.md)). The provider may change based on cost, quality, and reliability results from the evaluation phase. All code references the model via `settings.LLM_MODEL_NAME` environment variable, not a hardcoded string.

---

## 1. LLM Provider Evaluation Matrix

| Provider | Model(s) Evaluated | Context Window | Input Cost (per 1M tokens) | Output Cost (per 1M tokens) | TTFB (typical) | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Google AI / Vertex AI** | Gemini 1.5 Flash, Gemini 2.0 Flash | 1M / 1M | $0.075 / $0.10 | $0.30 / $0.40 | ~600-900 ms | Current primary candidate |
| **Anthropic** | Claude 3.5 Haiku | 200K | $0.80 | $4.00 | ~700 ms | Higher cost; strong instruction following |
| **OpenAI** | GPT-4o-mini | 128K | $0.15 | $0.60 | ~600 ms | Mature API; wide ecosystem |
| **Mistral AI** | Mistral 8x7B | 32K | $0.04 | $0.24 | ~500 ms | Lowest cost; accuracy validation needed |

**Current Primary Candidate**: A Google Gemini Flash-series model is the current default due to:
- Largest context window (handles extensive chart facts + retrieved chunks comfortably).
- Lowest cost per token among frontier models.
- Native Google Cloud integration with Vertex AI for IAM-controlled API access.
- Streaming SSE response support with low TTFB.

The specific model version (e.g., 1.5 Flash vs. 2.0 Flash) is resolved at deployment time via `settings.LLM_MODEL_NAME`.

---

## 2. LLM Provider Abstraction

The integration layer uses a provider abstraction to allow model switching without modifying business logic:

```python
# app/modules/interpretation/llm_provider.py
from abc import ABC, abstractmethod
from typing import AsyncGenerator

class LLMProvider(ABC):
    """Abstract base for LLM providers. Swap implementations without touching business logic."""

    @abstractmethod
    async def generate_stream(
        self,
        system_prompt: str,
        user_message: str,
        temperature: float,
        max_tokens: int,
    ) -> AsyncGenerator[str, None]:
        """Yields tokens as they arrive from the LLM."""
        ...

class GeminiProvider(LLMProvider):
    """Google Gemini provider via google-generativeai SDK."""

    def __init__(self, model_name: str, api_key: str):
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel(
            model_name=model_name,                 # e.g., 'gemini-1.5-flash' or 'gemini-2.0-flash'
            generation_config={"temperature": 0.2, "max_output_tokens": 600},
        )

    async def generate_stream(self, system_prompt, user_message, temperature, max_tokens):
        full_prompt = f"{system_prompt}\n\n{user_message}"
        response = await self.model.generate_content_async(full_prompt, stream=True)
        async for chunk in response:
            if chunk.text:
                yield chunk.text


# Factory: select provider from config at startup
def create_llm_provider(settings) -> LLMProvider:
    if settings.LLM_PROVIDER == "google":
        return GeminiProvider(
            model_name=settings.LLM_MODEL_NAME,   # e.g. "gemini-2.0-flash"
            api_key=settings.GEMINI_API_KEY,
        )
    raise ValueError(f"Unknown LLM provider: {settings.LLM_PROVIDER}")
```

---

## 3. Token Budget Per Request

| Prompt Component | Token Budget |
| :--- | :--- |
| System Prompt + Policy Rules | ~400 tokens |
| Verified Chart Facts (D1, D9, Dasha) | ~350 tokens |
| Retrieved Classical Chunks (Top-4 x 128 tokens avg) | ~512 tokens |
| Conversation History (last 3 turns) | ~300 tokens |
| User Question | ~50-100 tokens |
| **Total Max Prompt Input** | **~1,700 tokens** |
| **Max Generated Response Output** | **600 tokens** |
| **Max Total Per Request** | **~2,300 tokens** |

**Estimated Cost Per Request** (at Gemini 2.0 Flash pricing):
- Input: 1,700 tokens x $0.10/1M = $0.00017
- Output: 600 tokens x $0.40/1M = $0.00024
- **Total per chat question: ~$0.0004 (~0.04 paise per question)**

**Monthly Cost at Scale** (1 million AI questions/month):
- 1M x $0.0004 = **$400/month** in LLM API costs.

---

## 4. Cost Control Mechanisms

| Mechanism | Implementation |
| :--- | :--- |
| **Free tier rate limiting** | 3 questions/day hard limit enforced server-side |
| **Premium tier rate limiting** | 60 questions/hour sliding window (Redis) |
| **Max output tokens** | Hard-coded `max_output_tokens=600` in provider config |
| **Chunk retrieval limit** | Top-4 chunks maximum (prevents large context stuffing) |
| **Response caching** | Identical `(question, chart_id)` tuples cached in Redis for 1 hour (uncommon but possible) |

---

## 5. Rationale for Provider Abstraction

Hard-coding the LLM model name in business logic creates maintenance debt:
- Model versions are deprecated periodically (e.g., Gemini 1.0 Pro was deprecated 6 months after release).
- Better pricing or quality from a different provider could emerge post-launch.
- The abstraction layer costs nothing in performance and makes future model upgrades zero-code changes.

---

## 6. Future Improvements

- **Multi-Provider Fallback**: If the primary provider returns HTTP 503, automatically retry with a secondary provider (e.g., OpenAI GPT-4o-mini) to achieve 99.9% AI availability.
- **Model A/B Testing**: Route 5% of requests to a candidate model and compare Langfuse groundedness scores before full promotion.
- **Cost Dashboard**: CloudWatch metric tracking per-request LLM token counts and costs by user tier.

---

## 7. Related Documents

- [RAG.md](RAG.md) -- How retrieved chunks are incorporated into the prompt
- [PROMPT_ENGINEERING.md](PROMPT_ENGINEERING.md) -- Complete system prompt template
- [OBSERVABILITY.md](OBSERVABILITY.md) -- Langfuse tracing for LLM calls
- [OPEN_DECISIONS.md](../OPEN_DECISIONS.md) -- Current model selection evaluation status
