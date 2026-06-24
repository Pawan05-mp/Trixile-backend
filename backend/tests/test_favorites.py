"""Tests for Favorites endpoints."""

import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest
from app.api.dependencies import get_current_user
from app.main import app
from app.models.user import User
from app.models.favorite import Favorite
from app.models.place import Place


def create_mock_user():
    return User(
        id=uuid.uuid4(),
        email="testuser@example.com",
        name="Test User",
        password_hash="fakehash"
    )


def setup_auth_override(mock_user):
    app.dependency_overrides[get_current_user] = lambda: mock_user


def teardown_auth_override():
    if get_current_user in app.dependency_overrides:
        del app.dependency_overrides[get_current_user]


@patch("app.api.routes.favorites.FavoriteRepository")
def test_add_favorite(mock_repo_class, client):
    mock_user = create_mock_user()
    setup_auth_override(mock_user)
    
    place_id = uuid.uuid4()
    mock_repo = AsyncMock()
    mock_favorite = Favorite(
        id=uuid.uuid4(),
        user_id=mock_user.id,
        place_id=place_id,
        created_at=datetime.now(timezone.utc)
    )
    mock_repo.add.return_value = mock_favorite
    mock_repo_class.return_value = mock_repo

    try:
        response = client.post(f"/favorites/{place_id}")
        assert response.status_code == 201
        data = response.json()
        assert data["place_id"] == str(place_id)
        assert data["user_id"] == str(mock_user.id)
    finally:
        teardown_auth_override()


@patch("app.api.routes.favorites.FavoriteRepository")
def test_remove_favorite(mock_repo_class, client):
    mock_user = create_mock_user()
    setup_auth_override(mock_user)
    
    place_id = uuid.uuid4()
    mock_repo = AsyncMock()
    mock_repo.remove.return_value = True
    mock_repo_class.return_value = mock_repo

    try:
        response = client.delete(f"/favorites/{place_id}")
        assert response.status_code == 204
    finally:
        teardown_auth_override()


@patch("app.api.routes.favorites.FavoriteRepository")
def test_list_favorites(mock_repo_class, client):
    mock_user = create_mock_user()
    setup_auth_override(mock_user)
    
    mock_repo = AsyncMock()
    place_id = uuid.uuid4()
    mock_place = Place(
        id=place_id,
        name="Fav Place",
        category="cafe",
        area="White Town",
        rating=4.2,
        budget_level="$$"
    )
    mock_favorite = Favorite(
        id=uuid.uuid4(),
        user_id=mock_user.id,
        place_id=place_id,
        created_at=datetime.now(timezone.utc),
        place=mock_place
    )
    mock_repo.list_for_user.return_value = ([mock_favorite], 1)
    mock_repo_class.return_value = mock_repo

    try:
        response = client.get("/favorites?page=1&page_size=20")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["items"][0]["place"]["name"] == "Fav Place"
    finally:
        teardown_auth_override()
