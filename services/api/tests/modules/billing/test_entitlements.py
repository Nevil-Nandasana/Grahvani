"""
Unit tests for Billing Entitlements Engine and Tier Capacity Limits.
"""

import pytest


class EntitlementEngine:
    """Mock entitlement engine for unit testing billing logic."""
    TIER_LIMITS = {
        "free": {"max_profiles": 1, "daily_ai_questions": 3, "pdf_export": False},
        "premium": {"max_profiles": 999, "daily_ai_questions": 100, "pdf_export": True},
    }

    @classmethod
    def check_ai_question_entitlement(cls, user_tier: str, current_daily_count: int) -> bool:
        tier_info = cls.TIER_LIMITS.get(user_tier, cls.TIER_LIMITS["free"])
        return current_daily_count < tier_info["daily_ai_questions"]

    @classmethod
    def check_profile_capacity(cls, user_tier: str, current_profile_count: int) -> bool:
        tier_info = cls.TIER_LIMITS.get(user_tier, cls.TIER_LIMITS["free"])
        return current_profile_count < tier_info["max_profiles"]

    @classmethod
    def check_pdf_export_entitlement(cls, user_tier: str) -> bool:
        tier_info = cls.TIER_LIMITS.get(user_tier, cls.TIER_LIMITS["free"])
        return tier_info["pdf_export"]


def test_free_tier_ai_question_limit():
    """Verify free tier users are capped at 3 questions per day."""
    assert EntitlementEngine.check_ai_question_entitlement("free", 0) is True
    assert EntitlementEngine.check_ai_question_entitlement("free", 2) is True
    assert EntitlementEngine.check_ai_question_entitlement("free", 3) is False  # Limit reached


def test_premium_tier_ai_question_limit():
    """Verify premium tier users have high daily quota."""
    assert EntitlementEngine.check_ai_question_entitlement("premium", 50) is True
    assert EntitlementEngine.check_ai_question_entitlement("premium", 99) is True
    assert EntitlementEngine.check_ai_question_entitlement("premium", 100) is False


def test_free_tier_profile_limit():
    """Verify free tier users can create only 1 birth profile."""
    assert EntitlementEngine.check_profile_capacity("free", 0) is True
    assert EntitlementEngine.check_profile_capacity("free", 1) is False


def test_premium_tier_profile_limit():
    """Verify premium tier users have unlimited profile capacity."""
    assert EntitlementEngine.check_profile_capacity("premium", 10) is True


def test_pdf_export_entitlement():
    """Verify PDF export is restricted to premium tier."""
    assert EntitlementEngine.check_pdf_export_entitlement("free") is False
    assert EntitlementEngine.check_pdf_export_entitlement("premium") is True
