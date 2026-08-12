"""
BGE Reranker Service — Post-retrieval Cross-Encoder Scoring Module
Provides deep cross-encoder scoring (BAAI/bge-reranker-large) and mock adapters
with Sigmoid logit normalization, min score thresholding (0.35), and graceful degradation.
"""
import logging
import math
from abc import ABC, abstractmethod
from typing import Any, List, Dict, Optional

from app.config import settings

logger = logging.getLogger(__name__)


class BaseReranker(ABC):
    """Abstract base class for post-retrieval reranking engines."""

    @abstractmethod
    def rerank(
        self,
        query: str,
        candidates: List[Dict[str, Any]],
        top_k: int = 4,
        min_threshold: float = 0.35,
    ) -> List[Dict[str, Any]]:
        """
        Reranks a list of candidate document chunks against user query.

        Args:
            query: User prompt string.
            candidates: List of candidate chunk dictionaries retrieved via RRF.
            top_k: Maximum number of top chunks to return.
            min_threshold: Minimum normalized relevance score cutoff [0.0 - 1.0].

        Returns:
            Filtered and sorted list of candidate chunks with attached 'rerank_score'.
        """
        pass


class BGEReranker(BaseReranker):
    """
    Production Cross-Encoder reranker wrapping BAAI/bge-reranker-large.
    Uses sentence-transformers CrossEncoder or HuggingFace transformers with PyTorch.
    """

    def __init__(
        self,
        model_name: Optional[str] = None,
        device: str = "auto",
        batch_size: int = 16,
        max_length: int = 512,
    ):
        self.model_name = model_name or settings.RERANKER_MODEL_NAME
        self.device = device
        self.batch_size = batch_size
        self.max_length = max_length
        self._model: Any = None
        self._tokenizer: Any = None
        self._mode: str = "none"  # "sentence_transformers" | "transformers" | "none"
        self._initialized: bool = False

    def _load_model(self) -> None:
        if self._initialized:
            return

        try:
            # 1. Try sentence_transformers CrossEncoder
            from sentence_transformers import CrossEncoder
            import torch

            target_device = "cuda" if (self.device == "auto" and torch.cuda.is_available()) else ("cpu" if self.device == "auto" else self.device)
            logger.info(f"Loading BGE CrossEncoder '{self.model_name}' on device '{target_device}'...")
            self._model = CrossEncoder(self.model_name, max_length=self.max_length, device=target_device)
            self._mode = "sentence_transformers"
            logger.info(f"Successfully initialized sentence_transformers CrossEncoder '{self.model_name}'.")
        except (ImportError, ModuleNotFoundError):
            try:
                # 2. Fallback to HuggingFace transformers AutoModelForSequenceClassification
                import torch
                from transformers import AutoModelForSequenceClassification, AutoTokenizer

                target_device = "cuda" if (self.device == "auto" and torch.cuda.is_available()) else ("cpu" if self.device == "auto" else self.device)
                logger.info(f"Loading HF AutoModelForSequenceClassification '{self.model_name}' on device '{target_device}'...")
                self._tokenizer = AutoTokenizer.from_pretrained(self.model_name)
                self._model = AutoModelForSequenceClassification.from_pretrained(self.model_name)
                self._model.to(target_device)
                self._model.eval()
                self._mode = "transformers"
                logger.info(f"Successfully initialized HF transformers BGE model '{self.model_name}'.")
            except Exception as e:
                logger.warning(f"Failed to load production BGE Reranker model '{self.model_name}': {e}. Active degradation mode.")
                self._model = None
                self._mode = "none"
        except Exception as e:
            logger.warning(f"Error initializing BGE CrossEncoder '{self.model_name}': {e}. Active degradation mode.")
            self._model = None
            self._mode = "none"
        finally:
            self._initialized = True

    @staticmethod
    def _sigmoid(val: float) -> float:
        """Applies Sigmoid transformation to convert raw logit into [0.0, 1.0] probability-like score."""
        try:
            return 1.0 / (1.0 + math.exp(-val))
        except OverflowError:
            return 0.0 if val < 0 else 1.0

    def rerank(
        self,
        query: str,
        candidates: List[Dict[str, Any]],
        top_k: int = 4,
        min_threshold: float = 0.35,
    ) -> List[Dict[str, Any]]:
        query = query or ""
        if not candidates:
            return []

        valid_candidates = [c for c in candidates if c is not None and isinstance(c, dict)]
        if not valid_candidates:
            return []

        self._load_model()

        # If model loading failed or unavailable, fallback to top_k RRF candidate ordering
        if not self._model or self._mode == "none":
            logger.warning("BGE model not loaded. Falling back to initial RRF candidate ordering.")
            fallback_list = []
            slice_candidates = valid_candidates[:top_k] if top_k != 0 else []
            for idx, cand in enumerate(slice_candidates):
                c = dict(cand)
                c["rerank_score"] = round(1.0 - (0.05 * idx), 4)
                c["bge_score"] = None
                c["reranked"] = False
                fallback_list.append(c)
            return fallback_list

        try:
            pairs = [[query, cand.get("content") or ""] for cand in valid_candidates]
            scores: List[float] = []

            if self._mode == "sentence_transformers":
                raw_scores = self._model.predict(pairs, batch_size=self.batch_size, show_progress_bar=False)
                scores = [self._sigmoid(float(s)) for s in raw_scores]
            elif self._mode == "transformers":
                import torch
                for i in range(0, len(pairs), self.batch_size):
                    batch_pairs = pairs[i : i + self.batch_size]
                    inputs = self._tokenizer(
                        batch_pairs,
                        padding=True,
                        truncation=True,
                        max_length=self.max_length,
                        return_tensors="pt",
                    ).to(self._model.device)
                    with torch.no_grad():
                        logits = self._model(**inputs).logits.view(-1)
                        batch_logits = logits.cpu().float().tolist()
                        scores.extend([self._sigmoid(l) for l in batch_logits])

            # Attach normalized scores
            scored_candidates = []
            for cand, score in zip(valid_candidates, scores):
                c = dict(cand)
                norm_score = round(float(score), 4)
                c["rerank_score"] = norm_score
                c["bge_score"] = norm_score
                c["reranked"] = True
                scored_candidates.append(c)

            # Sort descending by score
            scored_candidates.sort(key=lambda x: x["rerank_score"], reverse=True)

            # Filter by threshold & take top_k
            filtered = [c for c in scored_candidates if c["rerank_score"] >= min_threshold]
            if top_k == 0:
                return []
            return filtered[:top_k]

        except Exception as e:
            logger.error(f"Execution error during BGE reranking inference: {e}. Gracefully degrading to RRF candidates.", exc_info=True)
            fallback_list = []
            slice_candidates = valid_candidates[:top_k] if top_k != 0 else []
            for idx, cand in enumerate(slice_candidates):
                c = dict(cand)
                c["rerank_score"] = round(1.0 - (0.05 * idx), 4)
                c["bge_score"] = None
                c["reranked"] = False
                fallback_list.append(c)
            return fallback_list


class MockReranker(BaseReranker):
    """
    Deterministic Mock Reranker adapter for dev, test, and CI environments.
    Calculates query token overlap, applies positional score heuristics, normalizes to [0,1],
    filters by min_threshold (0.35), and returns top_k candidates.
    """

    def rerank(
        self,
        query: str,
        candidates: List[Dict[str, Any]],
        top_k: int = 4,
        min_threshold: float = 0.35,
    ) -> List[Dict[str, Any]]:
        query = query or ""
        if not candidates:
            return []

        valid_candidates = [c for c in candidates if c is not None and isinstance(c, dict)]
        if not valid_candidates:
            return []

        query_tokens = set(query.lower().split())
        scored_candidates = []

        for idx, cand in enumerate(valid_candidates):
            c = dict(cand)
            content_text = str(cand.get("content") or "").lower()
            content_tokens = set(content_text.split())

            if not query_tokens:
                overlap_ratio = 0.5
            else:
                matches = query_tokens.intersection(content_tokens)
                overlap_ratio = len(matches) / len(query_tokens)

            # Combine token overlap with position rank score
            # Base score 0.45 + up to 0.50 from overlap - small penalty per position index
            raw_score = 0.45 + (0.50 * overlap_ratio) - (0.01 * idx)
            bounded_score = round(min(1.0, max(0.0, raw_score)), 4)

            c["rerank_score"] = bounded_score
            c["bge_score"] = bounded_score
            c["reranked"] = True
            scored_candidates.append(c)

        # Sort descending by rerank_score
        scored_candidates.sort(key=lambda x: x["rerank_score"], reverse=True)

        # Filter by threshold & take top_k
        filtered = [c for c in scored_candidates if c["rerank_score"] >= min_threshold]
        if top_k == 0:
            return []
        return filtered[:top_k]


# Singleton instance container
_reranker_instance: Optional[BaseReranker] = None


def get_reranker() -> BaseReranker:
    """
    Lazy-loading singleton getter for Reranker instance.
    Selects MockReranker in test/dev/mock mode or BGEReranker in production mode.
    """
    global _reranker_instance
    if _reranker_instance is None:
        reranker_type = settings.RERANKER_TYPE.lower()
        if not settings.RERANKER_ENABLED or reranker_type == "mock" or settings.APP_ENV == "testing":
            logger.info("Initializing MockReranker engine for environment.")
            _reranker_instance = MockReranker()
        else:
            logger.info(f"Initializing production BGEReranker engine with model '{settings.RERANKER_MODEL_NAME}'.")
            _reranker_instance = BGEReranker(model_name=settings.RERANKER_MODEL_NAME)
    return _reranker_instance


def reset_reranker() -> None:
    """Resets global reranker singleton instance (primarily for testing)."""
    global _reranker_instance
    _reranker_instance = None
