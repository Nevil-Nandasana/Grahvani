# AI Architecture Specification

## 1. Zero-AI-Math Principle & Architecture Goal
The core mandate of **Grahvani's** AI architecture is strict separation:
- **No Generative Math**: AI models NEVER calculate planetary longitudes, ascendants, dasha dates, or houses.
- **Fact-Grounded Explanation**: AI generative models operate exclusively as an natural language translation and synthesis engine over:
  1. Immutable chart facts computed by `pyswisseph`.
  2. Curated astrological literature chunks retrieved via RAG.

---

## 2. LLM Provider Abstraction Layer (`LLMProviderAdapter`)
To prevent vendor lock-in, all LLM interactions pass through a unified abstract base class:

```python
from abc import ABC, abstractmethod
from typing import AsyncGenerator

class LLMProviderAdapter(ABC):
    @abstractmethod
    async def generate_stream(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.2,
    ) -> AsyncGenerator[str, None]:
        pass

class GeminiFlashAdapter(LLMProviderAdapter):
    def __init__(self, api_key: str):
        # Initialize Google GenAI SDK client
        ...

    async def generate_stream(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.2,
    ) -> AsyncGenerator[str, None]:
        # Stream response from Gemini 1.5 Flash
        ...
```
