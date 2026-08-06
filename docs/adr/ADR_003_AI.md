# ADR-003: Grounded RAG Generation vs Fine-Tuning LLMs

> [[ADR Index](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/adr/README.md) | [AI Architecture](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/ai/AI_ARCHITECTURE.md) | [RAG Specs](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/ai/RAG.md) | [Guardrails](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/ai/GUARDRAILS.md)]

---

## Metadata
- **Status**: Accepted
- **Date**: 2026-08-01
- **Deciders**: AI Engineering Lead, Product Manager
- **Technical Story**: Choosing between Retrieval-Augmented Generation (RAG) and Custom Fine-Tuning for delivering accurate Vedic astrological interpretations without hallucinations.

---

## Context & Problem Statement

Commercial LLMs tend to generate hallucinated or contradictory astrological interpretations when asked open-ended questions about complex planetary placements. Standard base models lack strict grounding in authentic classical texts (such as *Brihat Parashara Hora Shastra*). We need an AI strategy that ensures 100% adherence to verified planetary facts and classical texts.

---

## Options Considered

### Option 1: Fine-Tuning Open Source LLMs (e.g. Llama-3-8B / Mistral)
Fine-tune an open-source model on a dataset of astrology slokas and interpretations.

- **Pros**: In-house model ownership; offline execution potential.
- **Cons**: Fine-tuning bakes knowledge into model weights but does NOT eliminate hallucinations; updates to source texts require costly re-training runs; high GPU hosting costs.

---

### Option 2: Pure Prompt Engineering with Base LLM
Rely entirely on system prompts sent to Gemini Flash without external text retrieval.

- **Pros**: Extremely fast to build.
- **Cons**: High rate of factual errors; inability to cite specific classical slokas; model invents non-existent planetary rules.

---

### Option 3: Grounded Retrieval-Augmented Generation (RAG) with Gemini Flash — **ACCEPTED**
Use a deterministic ephemeris calculation layer to compute exact chart facts, a `pgvector` RAG pipeline to retrieve relevant classical text slokas, and **Google Gemini Flash** as an instruction-aligned interpretation generator.

- **Pros**:
  - **Zero Hallucination Guarantee on Facts**: LLM receives computed planetary facts as immutable context.
  - **Verifiable Citations**: LLM is instructed to reference exact sloka numbers and text titles retrieved from the vector store.
  - **Low Latency & Cost**: Gemini Flash provides high speed and low cost per token compared to fine-tuned GPU clusters.
  - **Dynamic Knowledge Updates**: Adding or updating classical texts only requires updating document chunks in PostgreSQL, with zero model re-training.
- **Cons**: Context window overhead when passing multiple retrieved sloka chunks.

---

## Decision Outcome

**Chosen Option**: **Option 3: Grounded RAG with Gemini Flash**.

### Positive Consequences
- Interpretations carry transparent source citations ([Brihat Parashara Hora Shastra, Saravali]).
- Rapid knowledge base updates without fine-tuning pipelines.

---

## Re-evaluation Trigger
- Re-evaluate if open-source edge models running locally on mobile devices achieve comparable reasoning capabilities without server API dependency.
