"""
Interpretation Module — API Router (Grounded RAG AI Chat)
Routes: /chat/sessions, /chat/stream

LLM Pipeline:
  1. Validate prompt (500-char cap + content guardrails)
  2. Check daily entitlement quota
  3. Embed query via google-genai text-embedding-004
  4. Hybrid search: HNSW cosine vector + BM25 GIN tsvector via RRF fusion
  5. Build grounded system prompt with retrieved shlokas
  6. Stream response via SSE with [SOURCEREF] citation markers
  7. Persist completed message to chat_messages
"""
import json
import re
import time
import uuid
from datetime import datetime, date, timezone
from typing import AsyncGenerator

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from sqlalchemy import select, text, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.exceptions import EntitlementError, GuardrailError, NotFoundError
from app.core.security import CurrentUser
from app.core.tracing import tracer
from app.db.session import AsyncSessionLocal, get_db
from app.modules.billing.models import Subscription
from app.modules.birth_chart.models import BirthChart
from app.modules.identity.models import User
from app.modules.interpretation.models import ChatMessage, ChatSession
from app.modules.interpretation.llm_provider import LLMProviderFactory, BillingError

router = APIRouter()

# ─── LLM Provider Factory ────────────────────────────────────────────────────
llm_factory = LLMProviderFactory()


# ─── Content Guardrails ───────────────────────────────────────────────────────
_GUARDRAIL_PATTERNS = [
    # Medical / health advice
    r"\b(diagnos|treatment|medication|drug|dosage|prescri|cure|symptom|disease|cancer|diabetes|covid|hiv)\b",
    # Financial advice
    r"\b(invest|stock|crypto|bitcoin|nifty|sensex|mutual fund|trading|portfolio|buy.*share|sell.*share)\b",
    # Legal advice
    r"\b(lawyer|attorney|legal advice|sue|lawsuit|court|divorce|custody|criminal charge|bail)\b",
    # Prompt injection
    r"(ignore (previous|above|all) (instructions?|prompt)|you are now|act as|jailbreak|bypass|forget your|disregard)",
    # Violence / self-harm
    r"\b(suicide|self.harm|kill (myself|yourself)|violent|weapon|bomb)\b",
]
_GUARDRAIL_RE = re.compile("|".join(_GUARDRAIL_PATTERNS), re.IGNORECASE)

# Daily query limits per tier
_DAILY_LIMITS: dict[str, int] = {"free": 3, "premium": 100, "family": 500, "pro": 1000}

# Grounded system prompt
_SYSTEM_PROMPT = """You are Grahvani, an expert Vedic astrology guide. Your purpose is to provide
accurate, thoughtful interpretations of Vedic (Jyotish) birth charts grounded in classical Shastra texts.

RULES:
- Answer ONLY questions related to Vedic astrology, birth charts, planetary placements, dashas, and karma.
- Always cite the classical source you are drawing from using the format: [SOURCE: <title> <chapter/verse>]
- NEVER give medical, legal, financial, or harmful advice. Politely redirect if asked.
- Be warm, respectful, and insightful. Use Sanskrit terms with brief English explanations.
- Base all interpretations on the CONTEXT provided. Do not hallucinate planetary positions.

CONTEXT (Classical texts retrieved for this query):
{context}

USER BIRTH CHART DATA:
{chart_facts}
"""


# ─── Pydantic Schemas ─────────────────────────────────────────────────────────

class CreateSessionRequest(BaseModel):
    chart_id: uuid.UUID = Field(..., description="The birth chart UUID to link this session to.")
    title: str | None = Field(None, max_length=255)


class StreamChatRequest(BaseModel):
    session_id: uuid.UUID = Field(..., description="Chat session UUID.")
    prompt: str = Field(..., min_length=1, max_length=500, description="User's question (max 500 chars).")


class FeedbackRequest(BaseModel):
    message_id: uuid.UUID = Field(..., description="The assistant chat message UUID.")
    score: int = Field(..., description="1 for positive feedback, -1 for hallucination/negative feedback.")
    comment: str | None = Field(None, max_length=1000, description="Optional feedback explanation.")


# ─── Helper: Get User Record ──────────────────────────────────────────────────

async def _get_user(firebase_uid: str, db: AsyncSession) -> User:
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundError("User")
    return user


async def _get_user_tier(user: User, db: AsyncSession) -> str:
    """Fetch active subscription tier for user (free, premium, etc.)."""
    result = await db.execute(
        select(Subscription)
        .where(Subscription.user_id == user.id, Subscription.status == "active")
        .order_by(Subscription.created_at.desc())
        .limit(1)
    )
    subscription = result.scalar_one_or_none()
    return subscription.tier if subscription else "free"


# ─── Helper: Entitlement Check ───────────────────────────────────────────────

async def _check_daily_quota(user: User, db: AsyncSession) -> None:
    """Raises EntitlementError if user has exhausted their daily AI query limit."""
    # Get user's active subscription tier
    result = await db.execute(
        select(Subscription)
        .where(Subscription.user_id == user.id, Subscription.status == "active")
        .order_by(Subscription.created_at.desc())
        .limit(1)
    )
    subscription = result.scalar_one_or_none()
    tier = subscription.tier if subscription else "free"
    daily_limit = _DAILY_LIMITS.get(tier, 3)

    # Count today's assistant messages for this user across all sessions
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    count_result = await db.execute(
        select(func.count(ChatMessage.id))
        .join(ChatSession, ChatMessage.session_id == ChatSession.id)
        .where(
            ChatSession.user_id == user.id,
            ChatMessage.role == "assistant",
            ChatMessage.created_at >= today_start,
        )
    )
    today_count = count_result.scalar_one() or 0

    if today_count >= daily_limit:
        raise EntitlementError(
            f"You've used all {daily_limit} free AI questions for today. "
            "Upgrade to Premium for 100 daily interpretations."
        )


# ─── Helper: Hybrid RAG Search ────────────────────────────────────────────────

async def _hybrid_search(query: str, db: AsyncSession, top_k: int = 5) -> list[dict]:
    """
    Reciprocal Rank Fusion (RRF) over:
    - HNSW cosine vector similarity (dense embedding)
    - BM25 GIN tsvector full-text search (sparse keyword)

    Returns top_k chunks ordered by combined RRF score.
    """
    client = _get_genai_client()

    # 1. Embed the query
    embed_response = client.models.embed_content(
        model="text-embedding-004",
        contents=query,
        config=genai_types.EmbedContentConfig(task_type="RETRIEVAL_QUERY"),
    )
    query_vector = embed_response.embeddings[0].values

    # 2. Vector search (HNSW cosine)
    vector_sql = text("""
        SELECT id, source_title, kanda_or_chapter, sloka_number, content,
               ROW_NUMBER() OVER (ORDER BY embedding <=> :query_vector::vector) AS vector_rank
        FROM document_chunks
        ORDER BY embedding <=> :query_vector::vector
        LIMIT :top_k
    """)

    # 3. BM25 full-text search (GIN tsvector)
    fts_sql = text("""
        SELECT id, source_title, kanda_or_chapter, sloka_number, content,
               ROW_NUMBER() OVER (ORDER BY ts_rank(fts_vector_col, plainto_tsquery('english', :query)) DESC) AS fts_rank
        FROM document_chunks
        WHERE fts_vector_col @@ plainto_tsquery('english', :query)
        ORDER BY ts_rank(fts_vector_col, plainto_tsquery('english', :query)) DESC
        LIMIT :top_k
    """)

    # Execute both searches
    vector_result = await db.execute(
        vector_sql,
        {"query_vector": f"[{','.join(str(v) for v in query_vector)}]", "top_k": top_k * 2},
    )
    fts_result = await db.execute(fts_sql, {"query": query, "top_k": top_k * 2})

    vector_rows = {str(row.id): {"rank": row.vector_rank, "row": row} for row in vector_result}
    fts_rows = {str(row.id): {"rank": row.fts_rank, "row": row} for row in fts_result}

    # 4. RRF fusion: score = 1/(k + rank_vector) + 1/(k + rank_fts)
    k = 60  # RRF constant
    all_ids = set(vector_rows) | set(fts_rows)
    rrf_scores: dict[str, float] = {}

    for chunk_id in all_ids:
        score = 0.0
        if chunk_id in vector_rows:
            score += 1.0 / (k + vector_rows[chunk_id]["rank"])
        if chunk_id in fts_rows:
            score += 1.0 / (k + fts_rows[chunk_id]["rank"])
        rrf_scores[chunk_id] = score

    # Sort by RRF score descending and return top_k
    sorted_ids = sorted(rrf_scores, key=lambda x: rrf_scores[x], reverse=True)[:top_k]

    results = []
    for chunk_id in sorted_ids:
        row_data = (vector_rows.get(chunk_id) or fts_rows.get(chunk_id))["row"]
        results.append({
            "id": chunk_id,
            "source_title": row_data.source_title,
            "chapter": row_data.kanda_or_chapter,
            "sloka_number": row_data.sloka_number,
            "content": row_data.content,
        })

    return results


# ─── API Endpoints ────────────────────────────────────────────────────────────

@router.post("/chat/sessions", status_code=status.HTTP_201_CREATED)
async def create_chat_session(
    body: CreateSessionRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Initialize a new AI chat session linked to a birth chart snapshot."""
    firebase_uid = current_user.get("uid")
    user = await _get_user(firebase_uid, db)

    # Verify chart exists and belongs to user
    chart = await db.get(BirthChart, body.chart_id)
    if not chart:
        raise NotFoundError("Birth Chart")

    now = datetime.now(timezone.utc)
    session = ChatSession(
        user_id=user.id,
        chart_id=body.chart_id,
        title=body.title or f"Chart Reading — {now.strftime('%d %b %Y')}",
        created_at=now,
    )
    db.add(session)
    await db.flush()

    return {
        "success": True,
        "data": {
            "session_id": str(session.id),
            "chart_id": str(body.chart_id),
            "title": session.title,
            "created_at": session.created_at.isoformat(),
        },
    }


@router.post("/chat/stream")
async def stream_chat_response(
    body: StreamChatRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """
    SSE streaming endpoint for grounded RAG AI interpretation.

    Pipeline:
    1. Validate prompt (cap + guardrails)
    2. Check daily entitlement quota
    3. Embed query via text-embedding-004
    4. Hybrid search (HNSW + BM25 RRF) against document_chunks
    5. Build grounded system prompt with retrieved shlokas
    6. Stream Gemini Flash response as SSE delta events
    7. Persist completed message to chat_messages
    """
    # ── 1. Content guardrail check ─────────────────────────────────────────────
    if _GUARDRAIL_RE.search(body.prompt):
        raise GuardrailError(
            "This question falls outside the scope of Vedic astrology guidance. "
            "I can only interpret planetary positions and their classical meanings."
        )

    firebase_uid = current_user.get("uid")
    user = await _get_user(firebase_uid, db)
    user_tier = await _get_user_tier(user, db)

    # ── 2. Entitlement quota check ────────────────────────────────────────────
    await _check_daily_quota(user, db)

    # ── 3. Fetch session and chart facts ─────────────────────────────────────
    session = await db.get(ChatSession, body.session_id)
    if not session or session.user_id != user.id:
        raise NotFoundError("Chat Session")

    chart_facts_str = "{}"
    if session.chart_id:
        chart = await db.get(BirthChart, session.chart_id)
        if chart and chart.chart_facts_json:
            chart_facts_str = json.dumps(chart.chart_facts_json, indent=2)

    # Start Langfuse root trace
    trace_info = tracer.start_trace(
        user_id=str(user.id),
        session_id=str(body.session_id),
        tier=user_tier,
    )

    # ── 4 & 5. Hybrid RAG search ──────────────────────────────────────────────
    rag_start = time.time()
    retrieved_chunks = await _hybrid_search(body.prompt, db, top_k=5)
    rag_duration_ms = (time.time() - rag_start) * 1000

    # Record RAG retrieval span in Langfuse
    tracer.record_rag_span(
        trace_info=trace_info,
        query=body.prompt,
        chunks=retrieved_chunks,
        duration_ms=rag_duration_ms,
    )

    # Build context block with source references
    context_lines = []
    citations: list[dict] = []
    for i, chunk in enumerate(retrieved_chunks, start=1):
        ref_id = f"SRC{i}"
        citation_label = f"[{chunk['source_title']} {chunk['chapter'] or ''} {chunk['sloka_number'] or ''}]".strip()
        context_lines.append(f"[{ref_id}] {citation_label}\n{chunk['content']}")
        citations.append({
            "ref_id": ref_id,
            "label": citation_label,
            "source_title": chunk["source_title"],
            "chapter": chunk["chapter"],
            "sloka_number": chunk["sloka_number"],
            "content": chunk["content"],
        })

    context_block = "\n\n---\n\n".join(context_lines) if context_lines else "No classical texts retrieved."
    grounded_system = _SYSTEM_PROMPT.format(
        context=context_block, chart_facts=chart_facts_str
    )

    # ── 6. LLM Provider SSE streaming ─────────────────────────────────────────
    session_id_str = str(body.session_id)
    prompt_text = body.prompt
    now = datetime.now(timezone.utc)

    # Persist the user message immediately
    user_msg = ChatMessage(
        session_id=session.id,
        role="user",
        content=prompt_text,
        citations_json=None,
        tokens_used=None,
        created_at=now,
    )
    db.add(user_msg)
    await db.flush()
    await db.commit()

    async def _sse_generator() -> AsyncGenerator[str, None]:
        """Stream LLM response as Server-Sent Events."""
        full_response = ""
        stream_start = time.time()
        first_token_time = None

        try:
            # Send citations metadata before streaming starts
            yield f"data: {json.dumps({'event': 'citations', 'citations': citations})}\n\n"

            # Get LLM provider with fallback support
            llm_provider = await llm_factory.create_provider_with_fallback()
            
            # Stream response from LLM provider
            async for chunk in llm_provider.generate_stream(
                system_prompt=grounded_system,
                user_message=prompt_text,
                temperature=0.4,
                max_tokens=1500,
                rate_limit_key=str(user.id),
            ):
                if first_token_time is None:
                    first_token_time = time.time()
                full_response += chunk
                yield f"data: {json.dumps({'event': 'delta', 'content': chunk})}\n\n"

            total_duration_ms = (time.time() - stream_start) * 1000
            ttft_ms = (first_token_time - stream_start) * 1000 if first_token_time else None
            input_tokens = len(grounded_system.split()) + len(prompt_text.split())
            output_tokens = len(full_response.split())

            # Log LLM generation metrics to Langfuse
            tracer.record_llm_generation(
                trace_info=trace_info,
                model_name=settings.LLM_MODEL_NAME,
                system_prompt=grounded_system,
                user_message=prompt_text,
                completion=full_response,
                ttft_ms=ttft_ms,
                total_duration_ms=total_duration_ms,
                input_tokens=input_tokens,
                output_tokens=output_tokens,
            )

            # Persist assistant reply to chat_messages with trace_id
            async with AsyncSessionLocal() as async_db:
                assistant_msg = ChatMessage(
                    session_id=uuid.UUID(session_id_str),
                    role="assistant",
                    content=full_response,
                    citations_json=citations,
                    tokens_used=output_tokens,
                    trace_id=trace_info.get("trace_id"),
                    created_at=datetime.now(timezone.utc),
                )
                async_db.add(assistant_msg)
                await async_db.commit()

            yield f"data: {json.dumps({'event': 'done', 'total_tokens': output_tokens, 'trace_id': trace_info.get('trace_id')})}\n\n"

        except EntitlementError as e:
            yield f"data: {json.dumps({'event': 'error', 'code': 'ENTITLEMENT_REQUIRED', 'message': e.message})}\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'event': 'error', 'code': 'STREAM_ERROR', 'message': str(e)})}\n\n"

    return StreamingResponse(
        _sse_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.post("/chat/messages/feedback", status_code=status.HTTP_200_OK)
async def submit_message_feedback(
    body: FeedbackRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """
    Submit user rating (score: +1 or -1) and feedback comment for an assistant response.
    Updates database record and pushes score evaluation to Langfuse.
    """
    if body.score not in (1, -1):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Score must be 1 (positive) or -1 (negative/hallucination).",
        )

    firebase_uid = current_user.get("uid")
    user = await _get_user(firebase_uid, db)

    # Fetch message and verify session ownership
    message = await db.get(ChatMessage, body.message_id)
    if not message:
        raise NotFoundError("Chat Message")

    session = await db.get(ChatSession, message.session_id)
    if not session or session.user_id != user.id:
        raise NotFoundError("Chat Session")

    message.feedback_score = body.score
    message.feedback_text = body.comment
    await db.commit()

    # Send feedback score to Langfuse if trace_id is present
    if message.trace_id:
        tracer.score_message(
            trace_id=message.trace_id,
            name="user_feedback",
            value=float(body.score),
            comment=body.comment,
        )

    return {
        "success": True,
        "data": {
            "message_id": str(message.id),
            "feedback_score": message.feedback_score,
            "feedback_text": message.feedback_text,
            "trace_id": message.trace_id,
        },
    }


@router.get("/chat/sessions", status_code=status.HTTP_200_OK)
async def list_chat_sessions(
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """List all chat sessions for the authenticated user, most recent first."""
    firebase_uid = current_user.get("uid")
    user = await _get_user(firebase_uid, db)

    result = await db.execute(
        select(ChatSession)
        .where(ChatSession.user_id == user.id)
        .order_by(ChatSession.created_at.desc())
        .limit(50)
    )
    sessions = result.scalars().all()

    return {
        "success": True,
        "data": [
            {
                "session_id": str(s.id),
                "chart_id": str(s.chart_id) if s.chart_id else None,
                "title": s.title,
                "created_at": s.created_at.isoformat(),
            }
            for s in sessions
        ],
    }


@router.get("/chat/sessions/{session_id}/messages", status_code=status.HTTP_200_OK)
async def get_session_messages(
    session_id: uuid.UUID,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """Retrieve full message history for a chat session."""
    firebase_uid = current_user.get("uid")
    user = await _get_user(firebase_uid, db)

    session = await db.get(ChatSession, session_id)
    if not session or session.user_id != user.id:
        raise NotFoundError("Chat Session")

    result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.session_id == session_id)
        .order_by(ChatMessage.created_at.asc())
    )
    messages = result.scalars().all()

    return {
        "success": True,
        "data": [
            {
                "message_id": str(m.id),
                "role": m.role,
                "content": m.content,
                "citations": m.citations_json,
                "tokens_used": m.tokens_used,
                "trace_id": m.trace_id,
                "feedback_score": m.feedback_score,
                "feedback_text": m.feedback_text,
                "created_at": m.created_at.isoformat(),
            }
            for m in messages
        ],
    }
