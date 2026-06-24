"""Data-access layer for places — matching DB schema without PostGIS."""

from __future__ import annotations

import math
from uuid import UUID

from sqlalchemy import func, select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.place import Place


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Approximate great-circle distance in km between two lat/lng pairs."""
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


class PlaceRepository:
    """Thin async repository wrapping Place queries."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_id(self, place_id: UUID) -> Place | None:
        result = await self.db.execute(select(Place).where(Place.id == place_id))
        return result.scalar_one_or_none()

    async def list_all(self, *, page: int = 1, page_size: int = 20) -> tuple[list[Place], int]:
        count_q = select(func.count()).select_from(Place)
        total = (await self.db.execute(count_q)).scalar() or 0

        q = (
            select(Place)
            .order_by(Place.name)
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        rows = (await self.db.execute(q)).scalars().all()
        return list(rows), total

    async def search(
        self,
        *,
        q: str | None = None,
        name: str | None = None,
        category: str | None = None,
        area: str | None = None,
        tag: str | None = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[Place], int]:
        query = select(Place)
        filters = []

        if q:
            q_val = f"%{q}%"
            filters.append(
                or_(
                    Place.name.ilike(q_val),
                    Place.category.ilike(q_val),
                    Place.area.ilike(q_val),
                )
            )

        if name:
            filters.append(Place.name.ilike(f"%{name}%"))
        if category:
            filters.append(Place.category.ilike(f"%{category}%"))
        if area:
            filters.append(Place.area.ilike(f"%{area}%"))

        if filters:
            query = query.where(*filters)

        count_q = select(func.count()).select_from(query.subquery())
        total = (await self.db.execute(count_q)).scalar() or 0

        query = query.order_by(Place.name).offset((page - 1) * page_size).limit(page_size)
        rows = (await self.db.execute(query)).scalars().all()
        return list(rows), total

    async def find_nearby(
        self,
        lat: float,
        lng: float,
        distance_km: float = 5.0,
        limit: int = 20,
    ) -> list[tuple[Place, float]]:
        """Return places within *distance_km* of the given lat/lng using an
        approximate bounding-box pre-filter, then precise haversine in Python.
        """
        # Approximate bounding box (~1° lat ≈ 111 km, ~1° lng ≈ 111*cos(lat) km)
        lat_delta = math.degrees(distance_km / 111.0)
        lng_delta = math.degrees(distance_km / (111.0 * math.cos(math.radians(lat))))

        q = (
            select(Place)
            .where(Place.latitude.is_not(None))
            .where(Place.longitude.is_not(None))
            .where(Place.latitude.between(lat - lat_delta, lat + lat_delta))
            .where(Place.longitude.between(lng - lng_delta, lng + lng_delta))
            .limit(limit * 3)  # over-fetch to account for bounding box inaccuracy
        )
        rows = (await self.db.execute(q)).scalars().all()

        result: list[tuple[Place, float]] = []
        for place in rows:
            if place.latitude is None or place.longitude is None:
                continue
            dist = _haversine_km(lat, lng, place.latitude, place.longitude)
            if dist <= distance_km:
                result.append((place, round(dist, 4)))

        result.sort(key=lambda x: x[1])
        return result[:limit]
