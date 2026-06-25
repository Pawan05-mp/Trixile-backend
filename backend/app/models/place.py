"""Place model matching the existing Supabase schema."""

import uuid
from datetime import datetime, time, timezone

from sqlalchemy import (
    Float, Integer, String, DateTime, Text, Time, Index,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Place(Base):
    __tablename__ = "places"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )

    # ── Basic info ───────────────────────────────────────────
    name: Mapped[str] = mapped_column(Text, nullable=False, index=True)
    category: Mapped[str | None] = mapped_column(Text, nullable=True, index=True)
    area: Mapped[str | None] = mapped_column(Text, nullable=True, index=True)

    rating: Mapped[float | None] = mapped_column(Float, nullable=True)
    reviews: Mapped[int | None] = mapped_column(Integer, nullable=True)
    average_cost: Mapped[float | None] = mapped_column(Float, nullable=True)
    budget_level: Mapped[str | None] = mapped_column(String(50), nullable=True)  # 'budget' | 'moderate' | 'upscale'

    # ── Location ─────────────────────────────────────────────
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)

    # ── Occasion scores ──────────────────────────────────────
    date_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    friends_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    solo_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)

    # ── Atmosphere scores ────────────────────────────────────
    romantic_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    conversation_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    quiet_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    scenic_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    social_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    activity_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    comfort_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)

    # ── Extra scores ─────────────────────────────────────────
    nature_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    stimulation_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    photo_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)

    # ── Quality / meta scores ────────────────────────────────
    quality_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    popularity_score: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)

    # ── Timings (match DB `time without time zone`) ──────────
    opening_time: Mapped[time | None] = mapped_column(Time(timezone=False), nullable=True)
    closing_time: Mapped[time | None] = mapped_column(Time(timezone=False), nullable=True)

    # ── Links / media ────────────────────────────────────────
    google_maps_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_path: Mapped[str | None] = mapped_column(Text, nullable=True)

    # ── Timestamps ───────────────────────────────────────────
    created_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    favorites = relationship("Favorite", back_populates="place", cascade="all, delete-orphan")

    # ── Indexes ──────────────────────────────────────────────
    __table_args__ = (
        Index("idx_places_date_score", "date_score"),
        Index("idx_places_friends_score", "friends_score"),
        Index("idx_places_solo_score", "solo_score"),
    )
