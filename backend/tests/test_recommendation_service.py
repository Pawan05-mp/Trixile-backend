"""Unit tests for recommendation scoring service weights."""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.services.recommendation_service import (
    OCCASION_WEIGHTS,
    _build_score_expression,
    RecommendationService,
)
from app.models.place import Place


def test_occasion_weights_keys():
    """All three occasion types must be defined."""
    assert "date" in OCCASION_WEIGHTS
    assert "friends" in OCCASION_WEIGHTS
    assert "solo" in OCCASION_WEIGHTS


def test_date_weights_sum_to_one():
    weights = OCCASION_WEIGHTS["date"]
    assert abs(sum(weights.values()) - 1.0) < 1e-6


def test_friends_weights_sum_to_one():
    weights = OCCASION_WEIGHTS["friends"]
    assert abs(sum(weights.values()) - 1.0) < 1e-6


def test_solo_weights_sum_to_one():
    weights = OCCASION_WEIGHTS["solo"]
    assert abs(sum(weights.values()) - 1.0) < 1e-6


def test_date_weights_values():
    w = OCCASION_WEIGHTS["date"]
    assert w["date_score"] == 0.40
    assert w["romantic_score"] == 0.20
    assert w["conversation_score"] == 0.15
    assert w["quality_score"] == 0.15
    assert w["popularity_score"] == 0.10


def test_friends_weights_values():
    w = OCCASION_WEIGHTS["friends"]
    assert w["friends_score"] == 0.40
    assert w["social_score"] == 0.20
    assert w["activity_score"] == 0.20
    assert w["quality_score"] == 0.10
    assert w["popularity_score"] == 0.10


def test_solo_weights_values():
    w = OCCASION_WEIGHTS["solo"]
    assert w["solo_score"] == 0.40
    assert w["comfort_score"] == 0.20
    assert w["quiet_score"] == 0.20
    assert w["quality_score"] == 0.10
    assert w["popularity_score"] == 0.10


def test_build_score_expression_returns_labelled_expression():
    expr = _build_score_expression("date")
    # The expression should be labelled "computed_score"
    assert expr.key == "computed_score"


def test_build_score_expression_fallback_to_date():
    """Unknown occasion should default to date weights."""
    expr = _build_score_expression("nonexistent_occasion")
    assert expr.key == "computed_score"


@pytest.mark.asyncio
async def test_recommendation_service_recommend():
    """Test that recommend() builds and executes a query."""
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place = Place(
        id="e963b6f2-bb0a-4fb4-9cbe-cd3376ae753f",
        name="Beachside Bistro",
        category="cafe",
        area="White Town",
        rating=4.5,
        reviews=200,
        budget_level="$$",
        date_score=9.0,
        romantic_score=8.5,
        conversation_score=7.0,
        quality_score=8.0,
        popularity_score=7.5,
        occasion_tags=["date"],
        atmosphere_tags=["romantic"],
    )

    mock_result.all.return_value = [(place, 8.75)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="date", limit=20)

    assert isinstance(results, list)
    assert len(results) == 1
    assert results[0]["name"] == "Beachside Bistro"
    assert results[0]["computed_score"] == 8.75
