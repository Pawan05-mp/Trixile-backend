"""Favorite request / response schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel
from app.schemas.place import PlaceBrief


class FavoriteCreate(BaseModel):
    place_id: UUID


class FavoriteRead(BaseModel):
    id: UUID
    user_id: UUID
    place_id: UUID
    created_at: datetime

    model_config = {"from_attributes": True}


class FavoriteWithPlace(BaseModel):
    id: UUID
    place: PlaceBrief
    created_at: datetime

    model_config = {"from_attributes": True}
