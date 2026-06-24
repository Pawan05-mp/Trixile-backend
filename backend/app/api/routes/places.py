"""Place routes — list, detail, search, nearby."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.repositories.place_repository import PlaceRepository
from app.schemas.place import PlaceBrief, PlaceRead, PaginatedResponse, PlaceNearbyRead

router = APIRouter(tags=["places"])


@router.get("", response_model=PaginatedResponse)
async def list_places(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    repo = PlaceRepository(db)
    items, total = await repo.list_all(page=page, page_size=page_size)
    return PaginatedResponse(
        items=[PlaceBrief.model_validate(p) for p in items],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/search", response_model=PaginatedResponse)
async def search_places(
    q: str | None = None,
    name: str | None = None,
    category: str | None = None,
    area: str | None = None,
    tag: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    repo = PlaceRepository(db)
    items, total = await repo.search(
        q=q, name=name, category=category, area=area, tag=tag,
        page=page, page_size=page_size,
    )
    return PaginatedResponse(
        items=[PlaceBrief.model_validate(p) for p in items],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/nearby", response_model=list[PlaceNearbyRead])
async def nearby_places(
    lat: float = Query(...),
    lng: float = Query(...),
    distance_km: float = Query(5.0, ge=0.1, le=50.0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    repo = PlaceRepository(db)
    items = await repo.find_nearby(lat=lat, lng=lng, distance_km=distance_km, limit=limit)
    return [
        PlaceNearbyRead(
            id=p.id,
            name=p.name,
            category=p.category,
            area=p.area,
            rating=p.rating,
            latitude=p.latitude,
            longitude=p.longitude,
            thumbnail_url=p.image_path,
            distance_km=round(dist, 4)
        )
        for p, dist in items
    ]


@router.get("/{place_id}", response_model=PlaceRead)
async def get_place(place_id: UUID, db: AsyncSession = Depends(get_db)):
    repo = PlaceRepository(db)
    place = await repo.get_by_id(place_id)
    if place is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Place not found")
    return PlaceRead.model_validate(place)
