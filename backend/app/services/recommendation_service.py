"""Recommendation engine with weighted scoring per occasion.

Adapted to match the existing Supabase schema (no PostGIS,
no budget_level, no JSONB tag columns).
"""

from __future__ import annotations

import math

from sqlalchemy import Float, case, cast, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.place import Place


# ── Weight definitions ───────────────────────────────────────

OCCASION_WEIGHTS: dict[str, dict[str, float]] = {
    "date": {
        "date_score": 0.40,
        "romantic_score": 0.20,
        "conversation_score": 0.15,
        "quality_score": 0.15,
        "popularity_score": 0.10,
    },
    "friends": {
        "friends_score": 0.40,
        "social_score": 0.20,
        "activity_score": 0.20,
        "quality_score": 0.10,
        "popularity_score": 0.10,
    },
    "solo": {
        "solo_score": 0.40,
        "comfort_score": 0.20,
        "quiet_score": 0.20,
        "quality_score": 0.10,
        "popularity_score": 0.10,
    },
    "family": {
        "friends_score": 0.25,
        "social_score": 0.20,
        "activity_score": 0.20,
        "comfort_score": 0.15,
        "quality_score": 0.10,
        "popularity_score": 0.10,
    },
}


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in km between two lat/lng pairs."""
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _build_score_expression(occasion: str):
    """Build a SQLAlchemy expression for the weighted composite score."""
    weights = OCCASION_WEIGHTS.get(occasion, OCCASION_WEIGHTS["date"])
    terms = []
    for col_name, weight in weights.items():
        col = getattr(Place, col_name)
        terms.append(
            cast(case((col.is_(None), 0.0), else_=col), Float) * weight
        )
    expr = terms[0]
    for t in terms[1:]:
        expr = expr + t
    return expr.label("computed_score")


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
        """
        score_expr = _build_score_expression(occasion)

        q = select(Place, score_expr)

        # ── Distance bounding-box pre-filter in SQL ────────
        if lat is not None and lng is not None and distance_km is not None:
            lat_delta = math.degrees(distance_km / 111.0)
            lng_delta = math.degrees(distance_km / (111.0 * math.cos(math.radians(lat))))
            q = q.where(
                Place.latitude.is_not(None),
                Place.longitude.is_not(None),
                Place.latitude.between(lat - lat_delta, lat + lat_delta),
                Place.longitude.between(lng - lng_delta, lng + lng_delta),
            )

        q = q.order_by(score_expr.desc()).limit(limit)

        result = await self.db.execute(q)
        rows = result.all()

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

            # Add distance_km when a reference point was provided
            if lat is not None and lng is not None and place.latitude is not None and place.longitude is not None:
                d["distance_km"] = round(_haversine_km(lat, lng, place.latitude, place.longitude), 4)

            out.append(d)
        return out
