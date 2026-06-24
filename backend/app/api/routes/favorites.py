"""Favorites routes — add, remove, list (authenticated)."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.repositories.favorite_repository import FavoriteRepository
from app.schemas.favorite import FavoriteCreate, FavoriteRead, FavoriteWithPlace
from app.schemas.place import PaginatedResponse

router = APIRouter(tags=["favorites"])


@router.post("/{place_id}", response_model=FavoriteRead, status_code=status.HTTP_201_CREATED)
async def add_favorite(
    place_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = FavoriteRepository(db)
    fav = await repo.add(user_id=user.id, place_id=place_id)
    return fav


@router.delete("/{place_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite(
    place_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = FavoriteRepository(db)
    removed = await repo.remove(place_id=place_id, user_id=user.id)
    if not removed:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Favorite not found")



@router.get("", response_model=PaginatedResponse)
async def list_favorites(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = FavoriteRepository(db)
    items, total = await repo.list_for_user(user_id=user.id, page=page, page_size=page_size)
    return PaginatedResponse(
        items=[FavoriteWithPlace.model_validate(f) for f in items],
        total=total,
        page=page,
        page_size=page_size,
    )
