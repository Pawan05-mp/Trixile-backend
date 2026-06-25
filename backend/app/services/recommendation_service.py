"""Recommendation engine with weighted scoring per occasion.

Each occasion has a centralised weight configuration. The score
expression is built dynamically using func.coalesce() to prevent
NULL columns from crashing the query.

For the ``family`` occasion the base weighted score is augmented
with two computed bonuses that are evaluated in Python after the
DB fetch (avoiding a complex SQL CASE expression in the ORDER BY):

  - Category bonus  +1.0 for family-friendly venue types
  - Cost bonus      +0.5 for cheap venues, +0.3 for moderately priced venues

These bonuses are added to ``computed_score`` and exposed as
``family_category_bonus`` / ``family_budget_bonus`` for transparency.
"""

from __future__ import annotations

import math

from sqlalchemy import Float, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.place import Place


# ── Weight definitions ───────────────────────────────────────
# Each entry maps a DB column name → its weight.
# Weights for a single occasion must sum to 1.0 (± rounding).

OCCASION_WEIGHTS: dict[str, dict[str, float]] = {
    "date": {
        "date_score": 0.25,
        "romantic_score": 0.20,
        "conversation_score": 0.15,
        "scenic_score": 0.10,
        "photo_score": 0.10,
        "comfort_score": 0.05,
        "quality_score": 0.10,
        "popularity_score": 0.05,
    },
    "friends": {
        "friends_score": 0.25,
        "social_score": 0.20,
        "activity_score": 0.15,
        "stimulation_score": 0.10,
        "photo_score": 0.05,
        "quality_score": 0.15,
        "popularity_score": 0.10,
    },
    "family": {
        "comfort_score": 0.25,
        "quality_score": 0.15,
        "nature_score": 0.15,
        "scenic_score": 0.10,
        "quiet_score": 0.10,
        "popularity_score": 0.10,
        "activity_score": 0.10,
        "social_score": 0.05,
    },
    "solo": {
        "solo_score": 0.25,
        "quiet_score": 0.20,
        "nature_score": 0.15,
        "comfort_score": 0.15,
        "scenic_score": 0.10,
        "quality_score": 0.10,
        "popularity_score": 0.05,
    },
}

# ── Family bonus configuration ───────────────────────────────

FAMILY_CATEGORY_BONUS = 1.0
FAMILY_CATEGORY_BONUS_SET: frozenset[str] = frozenset({
    "Park", "Beach", "Zoo", "Botanical Garden",
    "Museum", "Theme Park", "Lake", "Playground",
})

FAMILY_COST_BONUS_THRESHOLDS: list[tuple[float, float]] = [
    (500, 0.5),    # average_cost < 500 → budget tier → +0.5
    (1500, 0.3),   # 500 <= average_cost < 1500 → moderate tier → +0.3
]


def _family_category_bonus(category: str | None) -> float:
    """Return the category bonus for a family-occasion place."""
    if category and category in FAMILY_CATEGORY_BONUS_SET:
        return FAMILY_CATEGORY_BONUS
    return 0.0


def _family_cost_bonus(average_cost: float | None) -> float:
    """Return a cost-based bonus for family-occasion places.

    Converts ``average_cost`` into tiers and assigns a bonus:
      - < 500   → +0.50
      - < 1500  → +0.30
      - ≥ 1500  →  0.00
    """
    if average_cost is None:
        return 0.0
    for threshold, bonus in FAMILY_COST_BONUS_THRESHOLDS:
        if average_cost < threshold:
            return bonus
    return 0.0


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in km between two lat/lng pairs."""
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlng / 2) ** 2
    )
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _build_score_expression(occasion: str):
    """Build a SQLAlchemy expression for the weighted composite score.

    Uses ``func.coalesce()`` on every column so that NULL values are
    treated as 0.0 instead of crashing the query.

    For ``family``, bonuses are applied in Python post-fetch (see
    ``RecommendationService.recommend``), so the SQL expression only
    covers the base weighted sum.
    """
    weights = OCCASION_WEIGHTS.get(occasion, OCCASION_WEIGHTS["date"])
    score_expr = sum(
        func.coalesce(getattr(Place, column), 0) * weight
        for column, weight in weights.items()
    )
    return score_expr.label("computed_score")


class RecommendationService:
    """Async recommendation service."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def recommend(
        self,
        *,
        occasion: str = "date",
        lat: float | None = None,
        lng: float | None = None,
        distance_km: float | None = None,
        budget: str | None = None,
        limit: int = 20,
    ) -> list[dict]:
        """Return top-scored places for the given occasion.

        Optionally filters by distance (approximate haversine bounding box).

        For the ``family`` occasion, category and budget bonuses are
        added to the base weighted score in Python after the DB fetch.
        The DB query still orders by the base weighted score so the
        bonus logic stays in one place and doesn't leak into SQL.
        """
        score_expr = _build_score_expression(occasion)

        q = select(Place, score_expr)

        # ── Distance bounding-box pre-filter in SQL ────────
        if lat is not None and lng is not None and distance_km is not None:
            lat_delta = math.degrees(distance_km / 111.0)
            lng_delta = math.degrees(
                distance_km / (111.0 * math.cos(math.radians(lat)))
            )
            q = q.where(
                Place.latitude.is_not(None),
                Place.longitude.is_not(None),
                Place.latitude.between(lat - lat_delta, lat + lat_delta),
                Place.longitude.between(lng - lng_delta, lng + lng_delta),
            )

        q = q.order_by(score_expr.desc()).limit(limit)

        result = await self.db.execute(q)
        rows = result.all()

        is_family = occasion == "family"

        out: list[dict] = []
        for place, computed in rows:
            d = {
                "id": str(place.id),
                "name": place.name,
                "category": place.category,
                "area": place.area,
                "rating": place.rating,
                "reviews": place.reviews,
                "latitude": place.latitude,
                "longitude": place.longitude,
                "date_score": place.date_score,
                "friends_score": place.friends_score,
                "solo_score": place.solo_score,
                "romantic_score": place.romantic_score,
                "conversation_score": place.conversation_score,
                "quiet_score": place.quiet_score,
                "scenic_score": place.scenic_score,
                "social_score": place.social_score,
                "activity_score": place.activity_score,
                "comfort_score": place.comfort_score,
                "nature_score": place.nature_score,
                "stimulation_score": place.stimulation_score,
                "photo_score": place.photo_score,
                "quality_score": place.quality_score,
                "popularity_score": place.popularity_score,
                "google_maps_url": place.google_maps_url,
                "thumbnail_url": place.image_path,  # map image_path -> thumbnail_url for Flutter
                "opening_time": str(place.opening_time) if place.opening_time else None,
                "closing_time": str(place.closing_time) if place.closing_time else None,
                "computed_score": round(float(computed or 0), 4),
            }

            # ── Family bonuses ─────────────────────────────
            if is_family:
                cat_bonus = _family_category_bonus(place.category)
                cost_bonus = _family_cost_bonus(place.average_cost)
                total_bonus = cat_bonus + cost_bonus
                d["computed_score"] = round(d["computed_score"] + total_bonus, 4)
                d["family_category_bonus"] = cat_bonus
                d["family_cost_bonus"] = cost_bonus

            # Add distance_km when a reference point was provided
            if (
                lat is not None
                and lng is not None
                and place.latitude is not None
                and place.longitude is not None
            ):
                d["distance_km"] = round(
                    _haversine_km(lat, lng, place.latitude, place.longitude), 4
                )

            out.append(d)

        # Re-sort after bonuses so family results are correctly ranked
        if is_family:
            out.sort(key=lambda x: x["computed_score"], reverse=True)

        return out
