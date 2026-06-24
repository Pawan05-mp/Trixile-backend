"""Unit tests for PlaceRepository and FavoriteRepository."""

import uuid
import pytest
from unittest.mock import AsyncMock, MagicMock
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.place_repository import PlaceRepository
from app.repositories.favorite_repository import FavoriteRepository
from app.models.place import Place
from app.models.favorite import Favorite


@pytest.mark.asyncio
async def test_place_repository_get_by_id():
    """Verify get_by_id executes expected query and returns place."""
    mock_db = AsyncMock(spec=AsyncSession)
    mock_result = MagicMock()
    place = Place(id=uuid.uuid4(), name="Test Cafe")
    mock_result.scalar_one_or_none.return_value = place
    mock_db.execute.return_value = mock_result

    repo = PlaceRepository(mock_db)
    result = await repo.get_by_id(place.id)

    assert result == place
    assert mock_db.execute.called


@pytest.mark.asyncio
async def test_place_repository_list_all():
    """Verify list_all returns items and total count."""
    mock_db = AsyncMock(spec=AsyncSession)
    mock_count_result = MagicMock()
    mock_count_result.scalar.return_value = 5
    mock_rows_result = MagicMock()
    places = [Place(id=uuid.uuid4(), name="Cafe A"), Place(id=uuid.uuid4(), name="Cafe B")]
    mock_rows_result.scalars().all.return_value = places

    # Mock execute returns count first, then rows
    mock_db.execute.side_effect = [mock_count_result, mock_rows_result]

    repo = PlaceRepository(mock_db)
    items, total = await repo.list_all(page=1, page_size=2)

    assert total == 5
    assert len(items) == 2
    assert items[0].name == "Cafe A"


@pytest.mark.asyncio
async def test_place_repository_search_all_filters():
    """Verify search handles multiple filters and query parameters."""
    mock_db = AsyncMock(spec=AsyncSession)
    mock_count_result = MagicMock()
    mock_count_result.scalar.return_value = 1
    mock_rows_result = MagicMock()
    places = [Place(id=uuid.uuid4(), name="Searched Cafe")]
    mock_rows_result.scalars().all.return_value = places

    mock_db.execute.side_effect = [mock_count_result, mock_rows_result]

    repo = PlaceRepository(mock_db)
    items, total = await repo.search(
        q="heritage",
        name="cafe",
        category="cafe",
        area="heritage town",
        tag="date",
        page=1,
        page_size=20
    )

    assert total == 1
    assert len(items) == 1
    assert items[0].name == "Searched Cafe"


@pytest.mark.asyncio
async def test_place_repository_find_nearby():
    """Verify find_nearby executes spatial queries with geography parameters."""
    mock_db = AsyncMock(spec=AsyncSession)
    mock_result = MagicMock()
    place = Place(id=uuid.uuid4(), name="Nearby Cafe")
    mock_result.all.return_value = [(place, 1.25)]
    mock_db.execute.return_value = mock_result

    repo = PlaceRepository(mock_db)
    results = await repo.find_nearby(lat=11.93, lng=79.83, distance_km=5.0)

    assert len(results) == 1
    assert results[0][0] == place
    assert results[0][1] == 1.25


@pytest.mark.asyncio
async def test_favorite_repository_add():
    """Verify favorite addition adds and flushes entity."""
    mock_db = AsyncMock(spec=AsyncSession)
    user_id = uuid.uuid4()
    place_id = uuid.uuid4()

    repo = FavoriteRepository(mock_db)
    fav = await repo.add(user_id=user_id, place_id=place_id)

    assert fav.user_id == user_id
    assert fav.place_id == place_id
    assert mock_db.add.called
    assert mock_db.flush.called
    assert mock_db.refresh.called


@pytest.mark.asyncio
async def test_favorite_repository_remove():
    """Verify remove returns correct success boolean based on row count."""
    mock_db = AsyncMock(spec=AsyncSession)
    mock_result = MagicMock()
    mock_result.rowcount = 1
    mock_db.execute.return_value = mock_result

    repo = FavoriteRepository(mock_db)
    success = await repo.remove(place_id=uuid.uuid4(), user_id=uuid.uuid4())
    assert success is True

    mock_result.rowcount = 0
    success = await repo.remove(place_id=uuid.uuid4(), user_id=uuid.uuid4())
    assert success is False


@pytest.mark.asyncio
async def test_favorite_repository_list_for_user():
    """Verify list_for_user retrieves total count and paginated list."""
    mock_db = AsyncMock(spec=AsyncSession)
    mock_count_result = MagicMock()
    mock_count_result.scalar.return_value = 10
    mock_rows_result = MagicMock()
    favs = [Favorite(user_id=uuid.uuid4(), place_id=uuid.uuid4())]
    mock_rows_result.scalars().all.return_value = favs

    mock_db.execute.side_effect = [mock_count_result, mock_rows_result]

    repo = FavoriteRepository(mock_db)
    items, total = await repo.list_for_user(user_id=uuid.uuid4(), page=1, page_size=5)

    assert total == 10
    assert len(items) == 1
    assert mock_db.execute.call_count == 2
