"""Data-access layer for favorites."""

from __future__ import annotations

from uuid import UUID

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.favorite import Favorite


class FavoriteRepository:
    """Thin async repository wrapping Favorite queries."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def add(self, user_id: UUID, place_id: UUID) -> Favorite:
        fav = Favorite(user_id=user_id, place_id=place_id)
        self.db.add(fav)
        await self.db.flush()
        await self.db.refresh(fav)
        return fav

    async def remove(self, place_id: UUID, user_id: UUID) -> bool:
        result = await self.db.execute(
            delete(Favorite).where(Favorite.place_id == place_id, Favorite.user_id == user_id)
        )
        return result.rowcount > 0


    async def list_for_user(
        self, user_id: UUID, *, page: int = 1, page_size: int = 20
    ) -> tuple[list[Favorite], int]:
        count_q = select(func.count()).select_from(Favorite).where(Favorite.user_id == user_id)
        total = (await self.db.execute(count_q)).scalar() or 0

        q = (
            select(Favorite)
            .options(selectinload(Favorite.place))
            .where(Favorite.user_id == user_id)
            .order_by(Favorite.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        rows = (await self.db.execute(q)).scalars().all()
        return list(rows), total
