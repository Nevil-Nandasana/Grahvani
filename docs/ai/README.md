# AI & GenAI Documentation (Grounded RAG Interpretation Engine)

Welcome to the AI systems documentation for **Grahvani**. Grahvani uses an **evidence-grounded Retrieval-Augmented Generation (RAG)** architecture to explain astrological charts using verified classical texts without mathematical hallucination.

---

## 📂 AI Documents Index

- 🏗️ **[AI Architecture](AI_ARCHITECTURE.md)** — End-to-end interpretation pipeline, provider abstraction layer, zero-AI-math policy.
- 🔍 **[RAG Implementation](RAG.md)** — `pgvector` hybrid search, Reciprocal Rank Fusion (RRF), source citation engine.
- ✍️ **[Prompt Engineering](PROMPT_ENGINEERING.md)** — System prompt templates, versioning, variable context insertion.
- 🎯 **[Model Selection](MODEL_SELECTION.md)** — Primary model (Gemini 1.5 Flash), fallback strategy, token cost budgeting.
- 📚 **[Knowledge Base](KNOWLEDGE_BASE.md)** — Document ingestion pipeline, PDF parsing, text chunking, embedding generation.
- 🛡️ **[Guardrails & Safety](GUARDRAILS.md)** — Input validation, safety policies (no medical/legal advice), groundedness checks.
- 👁️ **[Observability](OBSERVABILITY.md)** — Langfuse trace logging, token accounting, latency metrics.
- 📊 **[Evaluation Framework](EVALUATION.md)** — Golden question evaluation dataset, citation accuracy metrics.
- 🤖 **[Future Agentic AI](FUTURE_AGENTIC_AI.md)** — LangGraph workflows for offline editorial content management.

---

## 🏛️ AI RAG Interpretation Architecture

```mermaid
flowchart TD
    UserQ["User Question + Birth Chart ID"] --> FetchFacts["1. Fetch Validated Birth Chart Facts"]
    UserQ --> HybridSearch["2. Vector + Full-Text Search on pgvector"]
    
    HybridSearch --> SourceChunks["3. Retrieved Top-K Classical Literature Chunks"]
    FetchFacts --> PromptAssembly["4. Assemble Grounded Context Prompt"]
    SourceChunks --> PromptAssembly
    
    PromptAssembly --> SafetyCheck["5. Evaluate Input Guardrails & Topic Policy"]
    SafetyCheck -->|Pass| GeminiAPI["6. Call Google Gemini 1.5 Flash API"]
    SafetyCheck -->|Fail Policy| FallbackResp["Return Policy Disclaimer"]
    
    GeminiAPI --> CitationCheck["7. Validate Output Citations & Groundedness"]
    CitationCheck -->|Valid| StreamOutput["8. Stream Tokens to User via SSE"]
```
