"""Recommendation route."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.schemas.place import RecommendedPlace
from app.services.recommendation_service import RecommendationService

router = APIRouter(tags=["recommendations"])


@router.get("/recommendations", response_model=list[RecommendedPlace], response_model_exclude_none=True)
async def get_recommendations(
    occasion: str = Query("date", pattern="^(date|friends|solo|family)$"),
    lat: float | None = Query(None),
    lng: float | None = Query(None),
    distance_km: float | None = Query(None, ge=1, le=20),
    budget: str | None = Query(None),
    limit: int = Query(20, ge=1, le=100),
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
