"""
Adversarial & Edge-Case Test Suite for BGE Reranker Engine
Tests edge cases, invalid inputs, extreme parameters, fallback degradation, and resilience.
"""
import pytest
from unittest.mock import MagicMock, patch

from app.config import settings
from app.modules.interpretation.reranker import (
    BaseReranker,
    BGEReranker,
    MockReranker,
    get_reranker,
    reset_reranker,
)


class TestMockRerankerAdversarial:
    """Adversarial edge-case tests for MockReranker."""

    def setup_method(self):
        self.reranker = MockReranker()
        self.sample_cand = {
            "id": "c1",
            "source_title": "Text",
            "chapter": "Ch 1",
            "sloka_number": "V1",
            "content": "Jupiter in 5th house brings wisdom.",
        }

    def test_empty_candidate_list(self):
        assert self.reranker.rerank("Jupiter in 5th house", [], top_k=4) == []

    def test_single_candidate(self):
        res = self.reranker.rerank("Jupiter", [self.sample_cand], top_k=4)
        assert len(res) == 1
        assert res[0]["id"] == "c1"

    def test_candidate_empty_text(self):
        cand_empty = dict(self.sample_cand)
        cand_empty["content"] = ""
        res = self.reranker.rerank("Jupiter", [cand_empty], top_k=4, min_threshold=0.0)
        assert len(res) == 1
        assert res[0]["rerank_score"] >= 0.0

    def test_candidate_missing_content_key(self):
        cand_no_content = {"id": "c_no_content", "source_title": "Text"}
        res = self.reranker.rerank("Jupiter", [cand_no_content], top_k=4, min_threshold=0.0)
        assert len(res) == 1
        assert res[0]["rerank_score"] >= 0.0

    def test_empty_query_string(self):
        res = self.reranker.rerank("", [self.sample_cand], top_k=4)
        assert len(res) == 1

    def test_whitespace_query_string(self):
        res = self.reranker.rerank("   \t\n  ", [self.sample_cand], top_k=4)
        assert len(res) == 1

    def test_huge_query_string(self):
        huge_query = "Jupiter " * 15000  # 120k chars
        res = self.reranker.rerank(huge_query, [self.sample_cand], top_k=4)
        assert len(res) == 1

    def test_extreme_top_k_zero(self):
        res = self.reranker.rerank("Jupiter", [self.sample_cand], top_k=0)
        assert res == []

    def test_extreme_top_k_negative(self):
        cands = [self.sample_cand, {"id": "c2", "content": "Saturn in 1st house"}]
        res = self.reranker.rerank("Jupiter", cands, top_k=-1)
        # Note: top_k=-1 in Python slicing `[: -1]` drops the last candidate
        assert isinstance(res, list)

    def test_extreme_top_k_huge(self):
        cands = [{"id": f"c{i}", "content": f"Content {i}"} for i in range(5)]
        res = self.reranker.rerank("Content", cands, top_k=1000000)
        assert len(res) == 5

    def test_threshold_out_of_bounds_high(self):
        res = self.reranker.rerank("Jupiter", [self.sample_cand], min_threshold=2.0)
        assert res == []

    def test_threshold_out_of_bounds_negative(self):
        res = self.reranker.rerank("Jupiter", [self.sample_cand], min_threshold=-1.0)
        assert len(res) == 1

    def test_null_content_in_candidate(self):
        cand_null_content = {"id": "c_null", "content": None}
        try:
            res = self.reranker.rerank("Jupiter", [cand_null_content])
            # If supported:
            assert isinstance(res, list)
        except AttributeError as e:
            pytest.fail(f"MockReranker raised AttributeError on candidate with content=None: {e}")

    def test_null_query(self):
        try:
            res = self.reranker.rerank(None, [self.sample_cand])
            assert isinstance(res, list)
        except AttributeError as e:
            pytest.fail(f"MockReranker raised AttributeError on query=None: {e}")

    def test_null_candidate_in_list(self):
        try:
            res = self.reranker.rerank("Jupiter", [None])
            assert isinstance(res, list)
        except TypeError as e:
            pytest.fail(f"MockReranker raised TypeError on candidate=[None]: {e}")


class TestBGERerankerAdversarial:
    """Adversarial edge-case tests for BGEReranker in active and fallback states."""

    def test_bge_empty_candidates(self):
        bge = BGEReranker(model_name="nonexistent-model")
        assert bge.rerank("query", [], top_k=4) == []

    def test_bge_model_load_failure_fallback(self):
        bge = BGEReranker(model_name="nonexistent-model")
        cands = [{"id": "c1", "content": "text 1"}, {"id": "c2", "content": "text 2"}]
        res = bge.rerank("query", cands, top_k=2)
        assert len(res) == 2
        assert res[0]["reranked"] is False
        assert res[0]["bge_score"] is None
        assert res[0]["rerank_score"] == 1.0
        assert res[1]["rerank_score"] == 0.95

    def test_bge_inference_exception_graceful_degradation(self):
        bge = BGEReranker(model_name="dummy-model")
        bge._model = MagicMock()
        bge._mode = "sentence_transformers"
        bge._initialized = True
        # Simulate neural model inference exception (CUDA OOM or tensor shape error)
        bge._model.predict.side_effect = RuntimeError("CUDA out of memory during cross-encoder inference")

        cands = [
            {"id": "c1", "content": "content 1"},
            {"id": "c2", "content": "content 2"},
        ]

        res = bge.rerank("query", cands, top_k=2)
        assert len(res) == 2
        assert res[0]["reranked"] is False
        assert res[0]["rerank_score"] == 1.0
        assert res[1]["rerank_score"] == 0.95

    def test_bge_active_model_null_content(self):
        bge = BGEReranker(model_name="dummy-model")
        bge._model = MagicMock()
        bge._mode = "sentence_transformers"
        bge._initialized = True
        bge._model.predict.return_value = [0.8]

        cands_null = [{"id": "c1", "content": None}]
        # Should gracefully convert None to "" or handle in try block
        res = bge.rerank("query", cands_null, top_k=1)
        assert len(res) >= 0

    def test_bge_null_candidate_in_list_fallback_crash(self):
        bge = BGEReranker(model_name="nonexistent-model")
        try:
            res = bge.rerank("query", [None], top_k=1)
            assert isinstance(res, list)
        except TypeError as e:
            pytest.fail(f"BGEReranker fallback path crashed with TypeError when candidate is None: {e}")


class TestRerankerFactoryAdversarial:
    """Tests for get_reranker singleton factory with non-standard configs."""

    def test_get_reranker_invalid_type_config(self):
        reset_reranker()
        with patch.object(settings, "RERANKER_TYPE", "invalid_type_xyz"), \
             patch.object(settings, "RERANKER_ENABLED", True), \
             patch.object(settings, "APP_ENV", "production"):
            r = get_reranker()
            assert isinstance(r, BGEReranker)
        reset_reranker()

    def test_get_reranker_disabled_config(self):
        reset_reranker()
        with patch.object(settings, "RERANKER_ENABLED", False):
            r = get_reranker()
            assert isinstance(r, MockReranker)
        reset_reranker()
