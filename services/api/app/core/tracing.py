"""
Grahvani — Langfuse AI Observability & Tracing Module
Handles trace initialization, RAG retrieval spans, LLM generation logging,
token cost tracking, and user feedback scoring with safe No-Op fallback.
"""
import logging
import time
import uuid
from typing import Any, Dict, List, Optional

from app.config import settings

logger = logging.getLogger(__name__)

_langfuse_client: Optional[Any] = None
_client_initialized: bool = False


def get_langfuse_client() -> Optional[Any]:
    """Get or initialize singleton Langfuse client safely."""
    global _langfuse_client, _client_initialized

    if _client_initialized:
        return _langfuse_client

    _client_initialized = True

    if not settings.LANGFUSE_PUBLIC_KEY or not settings.LANGFUSE_SECRET_KEY:
        logger.info("Langfuse credentials missing. Tracing will run in No-Op mode.")
        _langfuse_client = None
        return None

    try:
        from langfuse import Langfuse
        _langfuse_client = Langfuse(
            public_key=settings.LANGFUSE_PUBLIC_KEY,
            secret_key=settings.LANGFUSE_SECRET_KEY,
            host=settings.LANGFUSE_HOST or "https://cloud.langfuse.com",
        )
        logger.info("Langfuse client successfully initialized.")
    except Exception as e:
        logger.warning(f"Failed to initialize Langfuse client: {e}. Falling back to No-Op mode.")
        _langfuse_client = None

    return _langfuse_client


class LangfuseTracer:
    """Wrapper class for AI pipeline tracing and cost metrics."""

    def __init__(self):
        self.client = get_langfuse_client()

    def start_trace(
        self,
        user_id: str,
        session_id: str,
        tier: str = "free",
        tags: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Start a new root trace for a user chat session query."""
        trace_id = str(uuid.uuid4())
        all_tags = [f"tier:{tier}"] + (tags or [])

        trace_obj = None
        if self.client:
            try:
                trace_obj = self.client.trace(
                    id=trace_id,
                    name="chat_interaction",
                    user_id=user_id,
                    session_id=session_id,
                    tags=all_tags,
                )
            except Exception as e:
                logger.warning(f"Langfuse start_trace error: {e}")

        return {
            "trace_id": trace_id,
            "trace_obj": trace_obj,
            "start_time": time.time(),
        }

    def record_rag_span(
        self,
        trace_info: Dict[str, Any],
        query: str,
        chunks: List[Dict[str, Any]],
        duration_ms: float,
    ) -> None:
        """Record RAG retrieval span inside trace."""
        trace_obj = trace_info.get("trace_obj")
        if not trace_obj:
            return

        try:
            span = trace_obj.span(
                name="rag_hybrid_search",
                input={"query": query, "top_k": len(chunks)},
                output={
                    "retrieved_count": len(chunks),
                    "shlokas": [
                        {
                            "source": c.get("source_title"),
                            "chapter": c.get("chapter"),
                            "sloka": c.get("sloka_number"),
                        }
                        for c in chunks
                    ],
                },
                metadata={"duration_ms": duration_ms},
            )
            span.end()
        except Exception as e:
            logger.warning(f"Langfuse record_rag_span error: {e}")

    def record_llm_generation(
        self,
        trace_info: Dict[str, Any],
        model_name: str,
        system_prompt: str,
        user_message: str,
        completion: str,
        ttft_ms: Optional[float],
        total_duration_ms: float,
        input_tokens: int,
        output_tokens: int,
    ) -> None:
        """Record LLM generation span with token usage and latency metrics."""
        trace_obj = trace_info.get("trace_obj")
        if not trace_obj:
            return

        try:
            generation = trace_obj.generation(
                name="llm_streaming_completion",
                model=model_name,
                input=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                output=completion,
                usage={
                    "input": input_tokens,
                    "output": output_tokens,
                    "unit": "TOKENS",
                },
                metadata={
                    "ttft_ms": ttft_ms,
                    "total_duration_ms": total_duration_ms,
                },
            )
            generation.end()
        except Exception as e:
            logger.warning(f"Langfuse record_llm_generation error: {e}")

    def score_message(
        self,
        trace_id: Optional[str],
        name: str = "user_feedback",
        value: float = 1.0,
        comment: Optional[str] = None,
    ) -> None:
        """Post a feedback score (+1 or -1) to Langfuse linked to trace_id."""
        if not self.client or not trace_id:
            return

        try:
            self.client.score(
                trace_id=trace_id,
                name=name,
                value=value,
                comment=comment,
            )
            self.client.flush()
        except Exception as e:
            logger.warning(f"Langfuse score_message error: {e}")


# Singleton instance
tracer = LangfuseTracer()
