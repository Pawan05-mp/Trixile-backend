"""Recommendation route."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.schemas.place import RecommendedPlace
from app.services.recommendation_service import RecommendationService

router = APIRouter(tags=["recommendations"])


@router.get(
    "/recommendations",
    response_model=list[RecommendedPlace],
    response_model_exclude_none=True,
    summary="Get place recommendations by occasion",
    description=(
        "Returns scored place recommendations for a specific occasion. "
        "Supported occasions: `date`, `friends`, `family`, `solo`. "
        "Results are ordered by `computed_score` descending. "
        "Optionally filter by geographic bounding box via `lat`, `lng`, and `distance_km`."
    ),
)
async def get_recommendations(
    occasion: str = Query(
        "date",
        pattern="^(date|friends|family|solo)$",
        description="Occasion to score places for.",
    ),
    lat: float | None = Query(None, description="Reference latitude for distance filtering."),
    lng: float | None = Query(None, description="Reference longitude for distance filtering."),
    distance_km: float | None = Query(None, ge=1, le=20, description="Maximum distance from reference point (1–20 km)."),
    budget: str | None = Query(None, description="Budget filter (not currently applied at DB level)."),
    limit: int = Query(20, ge=1, le=100, description="Maximum number of results to return."),
    db: AsyncSession = Depends(get_db),
):
    svc = RecommendationService(db)
    results = await svc.recommend(
        occasion=occasion,
        lat=lat,
        lng=lng,
        distance_km=distance_km,
        budget=budget,
        limit=limit,
    )
    return results
