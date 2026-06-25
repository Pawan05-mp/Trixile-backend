"""Place request / response schemas matching Supabase schema."""

from __future__ import annotations

from datetime import datetime, time
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class PlaceRead(BaseModel):
    """Full place representation returned by the API."""
    id: UUID
    name: str
    category: str | None = None
    area: str | None = None

    rating: float | None = None
    reviews: int | None = None
    average_cost: float | None = None

    latitude: float | None = None
    longitude: float | None = None

    date_score: float | None = None
    friends_score: float | None = None
    family_score: float | None = None
    solo_score: float | None = None

    romantic_score: float | None = None
    conversation_score: float | None = None
    quiet_score: float | None = None
    scenic_score: float | None = None
    social_score: float | None = None
    activity_score: float | None = None
    comfort_score: float | None = None

    nature_score: float | None = None
    stimulation_score: float | None = None
    photo_score: float | None = None

    quality_score: float | None = None
    popularity_score: float | None = None

    opening_time: time | None = None
    closing_time: time | None = None

    google_maps_url: str | None = None
    thumbnail_url: str | None = Field(None, validation_alias="image_path", serialization_alias="thumbnail_url")

    created_at: datetime | None = None

    model_config = {"from_attributes": True, "populate_by_name": True}


class PlaceBrief(BaseModel):
    """Lightweight place summary for list views."""
    id: UUID
    name: str
    category: str | None = None
    area: str | None = None
    rating: float | None = None
    latitude: float | None = None
    longitude: float | None = None
    thumbnail_url: str | None = Field(None, validation_alias="image_path", serialization_alias="thumbnail_url")

    model_config = {"from_attributes": True, "populate_by_name": True}


class RecommendedPlace(PlaceRead):
    """Place with computed recommendation score attached."""
    computed_score: float = 0.0


class PlaceNearbyRead(PlaceBrief):
    """Place summary with calculated distance attached."""
    distance_km: float


class PlaceSearchParams(BaseModel):
    """Query parameters for search."""
    name: str | None = None
    category: str | None = None
    area: str | None = None
    tag: str | None = None


class RecommendationParams(BaseModel):
    """Query parameters for the recommendation engine."""
    lat: float | None = None
    lng: float | None = None
    occasion: str = "date"
    budget: str | None = None
    distance_km: float | None = None
    limit: int = 20


class NearbyParams(BaseModel):
    """Query parameters for nearby search."""
    lat: float
    lng: float
    distance_km: float = 5.0
    limit: int = 20


class PaginatedResponse(BaseModel):
    """Generic paginated envelope."""
    items: list[Any]
    total: int
    page: int
    page_size: int
