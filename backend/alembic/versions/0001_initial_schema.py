"""Initial schema with users, places, favorites and postgis.

Revision ID: 0001_initial_schema
Revises: 
Create Date: 2026-06-11 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from geoalchemy2 import Geography

# revision identifiers, used by Alembic.
revision: str = '0001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── Enable PostGIS ──────────────────────────────────────────
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")

    # ── Table: users ─────────────────────────────────────────────
    op.create_table(
        'users',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('password_hash', sa.String(length=255), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_users_email', 'users', ['email'], unique=True)

    # ── Table: places ────────────────────────────────────────────
    op.create_table(
        'places',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('name', sa.String(length=500), nullable=False),
        sa.Column('category', sa.String(length=255), nullable=True),
        sa.Column('area', sa.String(length=255), nullable=True),
        sa.Column('rating', sa.Float(), nullable=True),
        sa.Column('reviews', sa.Integer(), nullable=True),
        sa.Column('budget_level', sa.String(length=50), nullable=True),
        sa.Column('latitude', sa.Float(), nullable=True),
        sa.Column('longitude', sa.Float(), nullable=True),
        sa.Column(
            'location',
            Geography(
                geometry_type='POINT',
                srid=4326,
                spatial_index=False,
                from_text='ST_GeogFromText',
                name='geography',
                nullable=True
            ),
            nullable=True
        ),
        sa.Column('date_score', sa.Float(), nullable=True),
        sa.Column('friends_score', sa.Float(), nullable=True),
        sa.Column('solo_score', sa.Float(), nullable=True),
        sa.Column('romantic_score', sa.Float(), nullable=True),
        sa.Column('conversation_score', sa.Float(), nullable=True),
        sa.Column('quiet_score', sa.Float(), nullable=True),
        sa.Column('scenic_score', sa.Float(), nullable=True),
        sa.Column('social_score', sa.Float(), nullable=True),
        sa.Column('activity_score', sa.Float(), nullable=True),
        sa.Column('comfort_score', sa.Float(), nullable=True),
        sa.Column('nature_score', sa.Float(), nullable=True),
        sa.Column('stimulation_score', sa.Float(), nullable=True),
        sa.Column('photo_score', sa.Float(), nullable=True),
        sa.Column('quality_score', sa.Float(), nullable=True),
        sa.Column('popularity_score', sa.Float(), nullable=True),
        sa.Column('recommendation_score', sa.Float(), nullable=True),
        sa.Column('occasion_tags', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('atmosphere_tags', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('best_visit_time', sa.String(length=255), nullable=True),
        sa.Column('opening_time', sa.String(length=50), nullable=True),
        sa.Column('closing_time', sa.String(length=50), nullable=True),
        sa.Column('google_maps_url', sa.Text(), nullable=True),
        sa.Column('thumbnail_url', sa.Text(), nullable=True),
        sa.Column('detail_url', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )

    # Indexes on places
    op.create_index('idx_places_name', 'places', ['name'], unique=False)
    op.create_index('idx_places_category', 'places', ['category'], unique=False)
    op.create_index('idx_places_area', 'places', ['area'], unique=False)
    op.create_index('idx_places_category_area', 'places', ['category', 'area'], unique=False)
    op.create_index('idx_places_date_score', 'places', ['date_score'], unique=False)
    op.create_index('idx_places_friends_score', 'places', ['friends_score'], unique=False)
    op.create_index('idx_places_solo_score', 'places', ['solo_score'], unique=False)

    # PostGIS GIST index on location geography column
    op.execute(
        "CREATE INDEX idx_places_location ON places USING gist (location)"
    )

    # ── Table: favorites ─────────────────────────────────────────
    op.create_table(
        'favorites',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('place_id', sa.UUID(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['place_id'], ['places.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'place_id', name='uq_user_place')
    )


def downgrade() -> None:
    op.drop_table('favorites')
    # Geography indexes must be dropped if dropping the table is not clean, 
    # but dropping the table automatically drops its indexes.
    op.drop_table('places')
    op.drop_index('idx_users_email', table_name='users')
    op.drop_table('users')
    op.execute("DROP EXTENSION IF EXISTS postgis")
