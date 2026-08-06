# AI Observability and Tracing Specification

## Purpose
This document specifies how Grahvani monitors, traces, and evaluates the performance of its AI interpretation layer in production. It defines the integration with Langfuse, the key metrics tracked, cost accounting procedures, and hallucination debugging workflows.

## Scope
Applies to the `interpretation` backend module, specifically the `/api/v1/chat/stream` endpoint and the Retrieval-Augmented Generation (RAG) pipeline.

---

## 1. Langfuse Tracing Integration

To ensure full visibility into the AI pipeline, Grahvani uses **Langfuse** as its LLM observability platform. Every user query initiates a nested trace that captures retrieval scores, prompt assembly, and token generation.

### 1.1 Implementation Pattern

```python
# app/modules/interpretation/tracing.py
from langfuse import Langfuse
from langfuse.decorators import observe, langfuse_context
from app.core.config import settings

langfuse_client = Langfuse(
    public_key=settings.LANGFUSE_PUBLIC_KEY,
    secret_key=settings.LANGFUSE_SECRET_KEY,
    host="https://cloud.langfuse.com",
)

@observe(name="chat_interaction")
async def process_chat_query(user_id: str, session_id: str, question: str, chart_id: str):
    """
    Root trace for the entire chat interaction.
    Attaches user and session IDs for cohort analysis in Langfuse.
    """
    langfuse_context.update_current_trace(
        user_id=user_id,
        session_id=session_id,
        tags=["production", "rag_chat"]
    )
    
    # 1. Retrieve chunks (nested span)
    chunks = await retrieve_relevant_chunks(question, chart_id)
    
    # 2. Assemble prompt (nested span)
    prompt = assemble_system_prompt(chunks, chart_id)
    
    # 3. Call LLM (nested span - captures tokens/latency)
    async for token in generate_llm_response(prompt, question):
        yield token
```

---

## 2. Key Monitored Metrics

The AI team monitors the following KPIs on the Langfuse dashboard:

| Metric | Target | Description |
| :--- | :--- | :--- |
| **Time-To-First-Token (TTFT)** | < 1,200 ms (p50) | Crucial for perceived performance in the Flutter UI. |
| **Full Completion Time** | < 8,000 ms (p50) | Total time to stream the complete 600-token answer. |
| **RAG Retrieval Score** | >= 0.65 (min) | The lowest cosine distance score of the top-4 retrieved chunks. Drops below 0.65 trigger a "Low Confidence" alert. |
| **Token Cost per Request** | < $0.001 | Combined input and output token cost calculated dynamically based on the active model pricing. |
| **User Feedback Rate** | > 5% | Percentage of AI responses receiving a thumbs up/down from the user. |

---

## 3. Cost Accounting and Tier Analysis

Langfuse automatically maps token usage to USD costs. We tag traces with the user's subscription tier to monitor gross margins:

```python
langfuse_context.update_current_trace(
    tags=[f"tier:{user_subscription_tier}"]  # 'free' or 'premium'
)
```

**Financial Alerting**: If the average cost per query for Free tier users exceeds $0.001, a Slack alert is fired to the AI lead to investigate prompt bloat or model routing errors.

---

## 4. Hallucination Debugging Workflow

When a user reports a hallucinated or inaccurate astrological reading (or taps "thumbs down" in the app), the support team follows this runbook:

1. Locate the trace in Langfuse using the `session_id` or `user_id`.
2. Inspect the **Input Prompt** span to see the exact context provided to the LLM.
3. Verify the **Retrieved Chunks**:
   - *If the chunks are wrong*: The RAG retrieval step failed (e.g., poor vector search match). Fix requires tuning the embedding model or RRF weights.
   - *If the chunks are correct but the answer is wrong*: The LLM failed to follow the groundedness guardrail. Fix requires system prompt tuning.
4. Clone the trace into the Langfuse **Playground** to experiment with prompt changes against the exact failing input.
5. Add the failing query to the 100-question **Golden Evaluation Dataset** to prevent regression.

---

## 5. Rationale

Standard APM tools (Datadog, New Relic) are insufficient for LLM observability. They measure HTTP latency and SQL query times, but cannot inspect prompt lengths, token costs, or semantic retrieval scores. Langfuse provides a purpose-built tracing layer that integrates seamlessly with FastAPI while keeping trace data isolated from standard application logs.

---

## 6. Future Improvements

- **Automated LLM-as-a-Judge**: Implement an asynchronous cron job that randomly samples 1% of daily traces and uses a larger model (e.g., Claude 3.5 Sonnet) to score them for groundedness, pushing the score back to Langfuse.
- **Prompt Version A/B Testing**: Tag traces with `prompt_version: v2.1` to compare groundedness scores between prompt revisions before full rollout.

---

## 7. Related Documents

- [ai/RAG.md](RAG.md) -- Details on the retrieval process that is being traced
- [ai/GUARDRAILS.md](GUARDRAILS.md) -- Safety policies enforced during generation
- [ai/MODEL_SELECTION.md](MODEL_SELECTION.md) -- Token budgeting and cost estimates
- [infrastructure/MONITORING.md](../infrastructure/MONITORING.md) -- General application observability (CloudWatch/Sentry)
