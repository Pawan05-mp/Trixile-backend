"""Tests for Places endpoints."""

import uuid
from unittest.mock import AsyncMock, patch

from app.models.place import Place


def create_mock_place():
    place_id = uuid.uuid4()
    place = Place(
        id=place_id,
        name="Mock Cafe",
        category="cafe",
        area="White Town",
        rating=4.5,
        reviews=120,
        budget_level="$$",
        latitude=11.93,
        longitude=79.83,
        thumbnail_url="http://example.com/thumb.jpg",
        date_score=8.5,
        romantic_score=9.0,
    )
    return place


@patch("app.api.routes.places.PlaceRepository")
def test_list_places(mock_repo_class, client):
    # Mock Repository instance and its list_all method
    mock_repo = AsyncMock()
    mock_place = create_mock_place()
    mock_repo.list_all.return_value = ([mock_place], 1)
    mock_repo_class.return_value = mock_repo

    response = client.get("/places?page=1&page_size=20")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["items"][0]["name"] == "Mock Cafe"
    assert data["items"][0]["id"] == str(mock_place.id)


@patch("app.api.routes.places.PlaceRepository")
def test_get_place_detail(mock_repo_class, client):
    mock_repo = AsyncMock()
    mock_place = create_mock_place()
    mock_repo.get_by_id.return_value = mock_place
    mock_repo_class.return_value = mock_repo

    response = client.get(f"/places/{mock_place.id}")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Mock Cafe"
    assert data["id"] == str(mock_place.id)
    assert data["date_score"] == 8.5


@patch("app.api.routes.places.PlaceRepository")
def test_get_place_not_found(mock_repo_class, client):
    mock_repo = AsyncMock()
    mock_repo.get_by_id.return_value = None
    mock_repo_class.return_value = mock_repo

    random_id = uuid.uuid4()
    response = client.get(f"/places/{random_id}")
    assert response.status_code == 404
    assert response.json()["detail"] == "Place not found"


@patch("app.api.routes.places.PlaceRepository")
def test_search_places(mock_repo_class, client):
    mock_repo = AsyncMock()
    mock_place = create_mock_place()
    mock_repo.search.return_value = ([mock_place], 1)
    mock_repo_class.return_value = mock_repo

    response = client.get("/places/search?q=Mock")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["items"][0]["name"] == "Mock Cafe"


@patch("app.api.routes.places.PlaceRepository")
def test_nearby_places(mock_repo_class, client):
    mock_repo = AsyncMock()
    mock_place = create_mock_place()
    # Repository find_nearby returns list of (Place, distance)
    mock_repo.find_nearby.return_value = [(mock_place, 0.45)]
    mock_repo_class.return_value = mock_repo

    response = client.get("/places/nearby?lat=11.93&lng=79.83&distance_km=5.0")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["name"] == "Mock Cafe"
    assert data[0]["distance_km"] == 0.45
