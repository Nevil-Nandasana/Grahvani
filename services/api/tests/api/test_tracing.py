"""
Unit tests for Langfuse AI Tracing, RAG spans, LLM generation logging, and User Feedback scoring.
"""
import pytest
from unittest.mock import MagicMock, patch

from app.core.tracing import LangfuseTracer


def test_tracer_noop_mode_when_keys_missing():
    """Tracer should run in No-Op mode without errors when Langfuse keys are absent."""
    with patch("app.core.tracing.settings.LANGFUSE_PUBLIC_KEY", ""), \
         patch("app.core.tracing.settings.LANGFUSE_SECRET_KEY", ""):
        
        tracer = LangfuseTracer()
        tracer.client = None

        trace_info = tracer.start_trace(user_id="u123", session_id="s456", tier="free")
        assert trace_info["trace_id"] is not None
        assert trace_info["trace_obj"] is None

        # Safe execution of spans in No-Op mode
        tracer.record_rag_span(
            trace_info=trace_info,
            query="What is my dasha?",
            chunks=[{"source_title": "BPHS", "chapter": "12", "sloka_number": "4"}],
            duration_ms=45.2,
        )

        tracer.record_llm_generation(
            trace_info=trace_info,
            model_name="gemini-2.0-flash",
            system_prompt="sys",
            user_message="user",
            completion="reading output",
            ttft_ms=320.0,
            total_duration_ms=1200.0,
            input_tokens=150,
            output_tokens=40,
        )

        tracer.score_message(
            trace_id=trace_info["trace_id"],
            name="user_feedback",
            value=1.0,
            comment="Great reading",
        )


def test_tracer_active_mode_recording():
    """Tracer should invoke Langfuse client methods when active."""
    mock_client = MagicMock()
    mock_trace = MagicMock()
    mock_span = MagicMock()
    mock_generation = MagicMock()

    mock_client.trace.return_value = mock_trace
    mock_trace.span.return_value = mock_span
    mock_trace.generation.return_value = mock_generation

    tracer = LangfuseTracer()
    tracer.client = mock_client

    trace_info = tracer.start_trace(user_id="u999", session_id="s888", tier="premium", tags=["test"])
    assert trace_info["trace_obj"] == mock_trace
    mock_client.trace.assert_called_once()

    tracer.record_rag_span(
        trace_info=trace_info,
        query="Jupiter placement",
        chunks=[{"source_title": "BPHS", "chapter": "5", "sloka_number": "10"}],
        duration_ms=30.0,
    )
    mock_trace.span.assert_called_once()
    mock_span.end.assert_called_once()

    tracer.record_llm_generation(
        trace_info=trace_info,
        model_name="gemini-2.0-flash",
        system_prompt="system text",
        user_message="user text",
        completion="completion text",
        ttft_ms=250.0,
        total_duration_ms=800.0,
        input_tokens=100,
        output_tokens=50,
    )
    mock_trace.generation.assert_called_once()
    mock_generation.end.assert_called_once()

    tracer.score_message(
        trace_id=trace_info["trace_id"],
        name="user_feedback",
        value=-1.0,
        comment="Hallucinated placement",
    )
    mock_client.score.assert_called_once_with(
        trace_id=trace_info["trace_id"],
        name="user_feedback",
        value=-1.0,
        comment="Hallucinated placement",
    )
    mock_client.flush.assert_called_once()
