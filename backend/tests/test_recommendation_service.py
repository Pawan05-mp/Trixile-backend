"""Unit tests for recommendation scoring service weights and logic."""

import pytest
from unittest.mock import AsyncMock, MagicMock
from app.services.recommendation_service import (
    OCCASION_WEIGHTS,
    FAMILY_CATEGORY_BONUS,
    FAMILY_CATEGORY_BONUS_SET,
    FAMILY_BUDGET_BONUS,
    _build_score_expression,
    _family_category_bonus,
    _family_budget_bonus,
    RecommendationService,
)
from app.models.place import Place


# ── Weight integrity tests ───────────────────────────────────

def test_all_occasions_defined():
    assert set(OCCASION_WEIGHTS.keys()) == {"date", "friends", "family", "solo"}


@pytest.mark.parametrize("occasion", ["date", "friends", "family", "solo"])
def test_occasion_weights_sum_to_one(occasion):
    weights = OCCASION_WEIGHTS[occasion]
    assert abs(sum(weights.values()) - 1.0) < 1e-6


def test_date_weights_values():
    w = OCCASION_WEIGHTS["date"]
    assert w["date_score"] == 0.25
    assert w["romantic_score"] == 0.20
    assert w["conversation_score"] == 0.15
    assert w["scenic_score"] == 0.10
    assert w["photo_score"] == 0.10
    assert w["comfort_score"] == 0.05
    assert w["quality_score"] == 0.10
    assert w["popularity_score"] == 0.05


def test_friends_weights_values():
    w = OCCASION_WEIGHTS["friends"]
    assert w["friends_score"] == 0.25
    assert w["social_score"] == 0.20
    assert w["activity_score"] == 0.15
    assert w["stimulation_score"] == 0.10
    assert w["photo_score"] == 0.05
    assert w["quality_score"] == 0.15
    assert w["popularity_score"] == 0.10


def test_family_weights_values():
    """Verify the derived family score formula weights."""
    w = OCCASION_WEIGHTS["family"]
    assert w["comfort_score"] == 0.25
    assert w["quality_score"] == 0.15
    assert w["nature_score"] == 0.15
    assert w["scenic_score"] == 0.10
    assert w["quiet_score"] == 0.10
    assert w["popularity_score"] == 0.10
    assert w["activity_score"] == 0.10
    assert w["social_score"] == 0.05


def test_solo_weights_values():
    w = OCCASION_WEIGHTS["solo"]
    assert w["solo_score"] == 0.25
    assert w["quiet_score"] == 0.20
    assert w["nature_score"] == 0.15
    assert w["comfort_score"] == 0.15
    assert w["scenic_score"] == 0.10
    assert w["quality_score"] == 0.10
    assert w["popularity_score"] == 0.05


# ── Family bonus unit tests ──────────────────────────────────

@pytest.mark.parametrize("category", [
    "Park", "Beach", "Zoo", "Botanical Garden",
    "Museum", "Theme Park", "Lake", "Playground",
])
def test_family_category_bonus_eligible_categories(category):
    assert _family_category_bonus(category) == FAMILY_CATEGORY_BONUS


@pytest.mark.parametrize("category", ["Cafe", "Restaurant", "Bar", "Hotel", None])
def test_family_category_bonus_ineligible_categories(category):
    assert _family_category_bonus(category) == 0.0


def test_family_budget_bonus_budget():
    assert _family_budget_bonus("budget") == FAMILY_BUDGET_BONUS["budget"]


def test_family_budget_bonus_moderate():
    assert _family_budget_bonus("moderate") == FAMILY_BUDGET_BONUS["moderate"]


def test_family_budget_bonus_upscale():
    assert _family_budget_bonus("upscale") == 0.0


def test_family_budget_bonus_none():
    assert _family_budget_bonus(None) == 0.0


def test_family_budget_bonus_case_insensitive():
    assert _family_budget_bonus("Budget") == FAMILY_BUDGET_BONUS["budget"]
    assert _family_budget_bonus("MODERATE") == FAMILY_BUDGET_BONUS["moderate"]


# ── Expression builder tests ─────────────────────────────────

def test_build_score_expression_returns_labelled_expression():
    expr = _build_score_expression("date")
    assert expr.key == "computed_score"


def test_build_score_expression_fallback_to_date():
    expr = _build_score_expression("nonexistent_occasion")
    assert expr.key == "computed_score"


# ── recommend() tests ────────────────────────────────────────

@pytest.mark.asyncio
async def test_recommend_date():
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place = Place(
        id="e963b6f2-bb0a-4fb4-9cbe-cd3376ae753f",
        name="Date Spot Cafe",
        category="cafe",
        area="White Town",
        rating=4.5,
        reviews=200,
        date_score=9.0,
        romantic_score=8.5,
        conversation_score=7.0,
        scenic_score=6.0,
        photo_score=8.0,
        comfort_score=7.0,
        quality_score=8.0,
        popularity_score=7.5,
    )

    mock_result.all.return_value = [(place, 8.75)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="date", limit=20)

    assert isinstance(results, list)
    assert len(results) == 1
    assert results[0]["name"] == "Date Spot Cafe"
    assert results[0]["computed_score"] == 8.75


@pytest.mark.asyncio
async def test_recommend_friends():
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place = Place(
        id="a1b2c3d4-1111-1111-1111-000000000001",
        name="Hangout Hub",
        category="cafe",
        area="White Town",
        rating=4.0,
        reviews=100,
        friends_score=9.0,
        social_score=8.0,
        activity_score=7.0,
        stimulation_score=6.0,
        photo_score=5.0,
        quality_score=8.0,
        popularity_score=7.0,
    )

    mock_result.all.return_value = [(place, 8.25)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="friends", limit=20)

    assert len(results) == 1
    assert results[0]["name"] == "Hangout Hub"


@pytest.mark.asyncio
async def test_recommend_family_base_score():
    """Family result without bonuses returns the raw computed score."""
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place = Place(
        id="b2c3d4e5-1111-1111-1111-000000000001",
        name="Generic Venue",
        category="Cafe",
        area="Green Area",
        rating=4.8,
        reviews=300,
        comfort_score=9.0,
        quality_score=8.0,
        activity_score=7.0,
        scenic_score=6.0,
        nature_score=8.0,
        quiet_score=7.0,
        popularity_score=7.5,
        social_score=6.5,
        budget_level="upscale",
    )

    mock_result.all.return_value = [(place, 7.875)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="family", limit=20)

    assert len(results) == 1
    assert results[0]["name"] == "Generic Venue"
    assert results[0]["computed_score"] == 7.875
    assert results[0]["family_category_bonus"] == 0.0
    assert results[0]["family_budget_bonus"] == 0.0


@pytest.mark.asyncio
async def test_recommend_family_category_bonus_applied():
    """Park category triggers +1.0 category bonus."""
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place = Place(
        id="b2c3d4e5-1111-1111-1111-000000000002",
        name="Family Park",
        category="Park",
        area="Green Area",
        rating=4.8,
        reviews=300,
        comfort_score=9.0,
        quality_score=8.0,
        activity_score=7.0,
        scenic_score=6.0,
        nature_score=8.0,
        quiet_score=7.0,
        popularity_score=7.5,
        social_score=6.5,
        budget_level=None,
    )

    mock_result.all.return_value = [(place, 7.875)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="family", limit=20)

    assert results[0]["family_category_bonus"] == 1.0
    assert results[0]["family_budget_bonus"] == 0.0
    assert results[0]["computed_score"] == round(7.875 + 1.0, 4)


@pytest.mark.asyncio
async def test_recommend_family_budget_bonus_applied():
    """Budget-level 'budget' triggers +0.5 bonus."""
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place = Place(
        id="b2c3d4e5-1111-1111-1111-000000000003",
        name="Cheap Park",
        category="Park",
        area="Green Area",
        rating=4.5,
        reviews=150,
        comfort_score=8.0,
        quality_score=7.0,
        activity_score=6.0,
        scenic_score=5.0,
        nature_score=7.0,
        quiet_score=6.0,
        popularity_score=6.5,
        social_score=5.5,
        budget_level="budget",
    )

    mock_result.all.return_value = [(place, 6.75)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="family", limit=20)

    assert results[0]["family_category_bonus"] == 1.0
    assert results[0]["family_budget_bonus"] == 0.5
    assert results[0]["computed_score"] == round(6.75 + 1.0 + 0.5, 4)


@pytest.mark.asyncio
async def test_recommend_family_moderate_budget_bonus():
    """Budget-level 'moderate' triggers +0.3 bonus."""
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place = Place(
        id="b2c3d4e5-1111-1111-1111-000000000004",
        name="Mid-range Beach",
        category="Beach",
        area="Coast",
        rating=4.6,
        reviews=200,
        comfort_score=8.5,
        quality_score=7.5,
        activity_score=7.0,
        scenic_score=9.0,
        nature_score=8.0,
        quiet_score=6.0,
        popularity_score=7.0,
        social_score=6.0,
        budget_level="moderate",
    )

    mock_result.all.return_value = [(place, 7.55)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="family", limit=20)

    assert results[0]["family_category_bonus"] == 1.0
    assert results[0]["family_budget_bonus"] == 0.3
    assert results[0]["computed_score"] == round(7.55 + 1.0 + 0.3, 4)


@pytest.mark.asyncio
async def test_recommend_family_bonuses_not_on_other_occasions():
    """Non-family occasions must not include bonus keys."""
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place = Place(
        id="c3d4e5f6-1111-1111-1111-000000000001",
        name="Park Cafe",
        category="Park",
        area="Old Town",
        rating=4.0,
        reviews=80,
        date_score=8.0,
        romantic_score=7.0,
        conversation_score=6.0,
        scenic_score=7.0,
        photo_score=5.0,
        comfort_score=7.0,
        quality_score=8.0,
        popularity_score=6.0,
    )

    mock_result.all.return_value = [(place, 7.3)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="date", limit=20)

    assert "family_category_bonus" not in results[0]
    assert "family_budget_bonus" not in results[0]


@pytest.mark.asyncio
async def test_recommend_family_re_sorted_by_total_score():
    """After bonuses, results must be ordered by final computed_score desc."""
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place_a = Place(
        id="aaaaaaaa-0000-0000-0000-000000000001",
        name="Plain Venue",
        category="Cafe",
        budget_level="upscale",
        comfort_score=9.0, quality_score=9.0,
    )
    place_b = Place(
        id="bbbbbbbb-0000-0000-0000-000000000001",
        name="Family Park Budget",
        category="Park",
        budget_level="budget",
        comfort_score=7.0, quality_score=7.0,
    )

    # DB returns place_a first (higher base), place_b second
    mock_result.all.return_value = [(place_a, 8.0), (place_b, 6.0)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="family", limit=20)

    # place_b total = 6.0 + 1.0 + 0.5 = 7.5; place_a total = 8.0
    # place_a should still be first
    assert results[0]["name"] == "Plain Venue"
    assert results[0]["computed_score"] == 8.0
    assert results[1]["name"] == "Family Park Budget"
    assert results[1]["computed_score"] == 7.5


@pytest.mark.asyncio
async def test_recommend_solo():
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place = Place(
        id="c3d4e5f6-1111-1111-1111-000000000002",
        name="Quiet Corner",
        category="cafe",
        area="Old Town",
        rating=4.2,
        reviews=80,
        solo_score=9.0,
        quiet_score=8.0,
        nature_score=7.0,
        comfort_score=8.0,
        scenic_score=6.0,
        quality_score=7.0,
        popularity_score=5.0,
    )

    mock_result.all.return_value = [(place, 8.65)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="solo", limit=20)

    assert len(results) == 1
    assert results[0]["name"] == "Quiet Corner"


@pytest.mark.asyncio
async def test_empty_database_returns_empty_list():
    mock_db = AsyncMock()
    mock_result = MagicMock()
    mock_result.all.return_value = []
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="date", limit=20)

    assert results == []


@pytest.mark.asyncio
async def test_null_scores_do_not_crash():
    """When all score columns are NULL the query must still succeed."""
    mock_db = AsyncMock()
    mock_result = MagicMock()

    place = Place(
        id="00000000-0000-0000-0000-000000000001",
        name="Null Place",
        category="other",
        area="Nowhere",
        rating=3.0,
        reviews=0,
        date_score=None,
        romantic_score=None,
        conversation_score=None,
        scenic_score=None,
        photo_score=None,
        comfort_score=None,
        quality_score=None,
        popularity_score=None,
        friends_score=None,
        social_score=None,
        activity_score=None,
        stimulation_score=None,
        solo_score=None,
        quiet_score=None,
        nature_score=None,
    )

    mock_result.all.return_value = [(place, 0.0)]
    mock_db.execute = AsyncMock(return_value=mock_result)

    svc = RecommendationService(mock_db)
    results = await svc.recommend(occasion="date", limit=20)

    assert len(results) == 1
    assert results[0]["computed_score"] == 0.0
