"""Database hardening schema updates.

Revision ID: 0002_hardening
Revises: 0001_initial_schema
Create Date: 2026-06-11 19:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '0002_hardening'
down_revision: Union[str, None] = '0001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── Add updated_at columns ────────────────────────────────
    op.add_column(
        'users',
        sa.Column(
            'updated_at', 
            sa.DateTime(timezone=True), 
            nullable=False, 
            server_default=sa.text('now()')
        )
    )
    op.add_column(
        'places',
        sa.Column(
            'updated_at', 
            sa.DateTime(timezone=True), 
            nullable=False, 
            server_default=sa.text('now()')
        )
    )
    op.add_column(
        'favorites',
        sa.Column(
            'updated_at', 
            sa.DateTime(timezone=True), 
            nullable=False, 
            server_default=sa.text('now()')
        )
    )

    # ── Create Indexes ────────────────────────────────────────
    # Places budget_level index
    op.create_index(
        'idx_places_budget_level', 
        'places', 
        ['budget_level'], 
        unique=False
    )
    # Favorites user_id and place_id indexes
    op.create_index(
        'idx_favorites_user_id', 
        'favorites', 
        ['user_id'], 
        unique=False
    )
    op.create_index(
        'idx_favorites_place_id', 
        'favorites', 
        ['place_id'], 
        unique=False
    )


def downgrade() -> None:
    # ── Drop Indexes ──────────────────────────────────────────
    op.drop_index('idx_favorites_place_id', table_name='favorites')
    op.drop_index('idx_favorites_user_id', table_name='favorites')
    op.drop_index('idx_places_budget_level', table_name='places')

    # ── Drop updated_at columns ───────────────────────────────
    op.drop_column('favorites', 'updated_at')
    op.drop_column('places', 'updated_at')
    op.drop_column('users', 'updated_at')
