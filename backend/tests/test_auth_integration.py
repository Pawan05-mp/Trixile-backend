"""Integration and authentication tests for registration, login, and protected routes."""

import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from app.models.user import User
from app.core.security import create_access_token


@pytest.mark.asyncio
@patch("app.api.routes.auth.AuthService")
async def test_register_user_success(mock_auth_service, client):
    """Register a new user successfully."""
    new_user_id = uuid.uuid4()
    mock_user = User(
        id=new_user_id,
        email="test_new@example.com",
        name="New User",
        password_hash="hashedpassword123",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    mock_auth_service.register = AsyncMock(return_value=mock_user)

    response = client.post(
        "/auth/register",
        json={"email": "test_new@example.com", "password": "mypassword123", "name": "New User"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test_new@example.com"
    assert data["name"] == "New User"
    assert "id" in data


@pytest.mark.asyncio
@patch("app.api.routes.auth.AuthService")
async def test_login_user_success(mock_auth_service, client):
    """Authenticate and get a valid JWT token."""
    mock_auth_service.authenticate_user = AsyncMock(return_value="mocked_jwt_token_string")

    response = client.post(
        "/auth/login",
        data={"username": "test@example.com", "password": "correctpassword"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["access_token"] == "mocked_jwt_token_string"
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
@patch("app.api.routes.auth.AuthService")
async def test_login_user_failure(mock_auth_service, client):
    """Verify login failure returns 401."""
    mock_auth_service.authenticate_user = AsyncMock(return_value=None)

    response = client.post(
        "/auth/login",
        data={"username": "test@example.com", "password": "wrongpassword"}
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid credentials"


@pytest.mark.asyncio
async def test_protected_routes_unauthorized_missing_token(client):
    """Protected endpoints require a token, else return 401."""
    response = client.get("/favorites")
    assert response.status_code == 401
    assert response.json()["detail"] == "Not authenticated"


@pytest.mark.asyncio
async def test_protected_routes_unauthorized_invalid_token(client):
    """Protected endpoints reject invalid token format, return 401."""
    response = client.get("/favorites", headers={"Authorization": "Bearer invalidtoken123"})
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid token"


@pytest.mark.asyncio
@patch("app.api.dependencies.AuthService")
async def test_protected_routes_unauthorized_user_not_found(mock_auth_service, client):
    """Token is valid but the user is not in the database, return 401."""
    token = create_access_token({"sub": str(uuid.uuid4())})
    mock_auth_service.get_user_by_id = AsyncMock(return_value=None)

    response = client.get("/favorites", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 401
    assert response.json()["detail"] == "User not found"


@pytest.mark.asyncio
@patch("app.api.dependencies.AuthService")
@patch("app.api.routes.favorites.FavoriteRepository")
async def test_protected_routes_authorized_success(mock_fav_repo_class, mock_auth_service, client):
    """Valid token and user allows request to proceed."""
    user_id = uuid.uuid4()
    mock_user = User(
        id=user_id,
        email="test_auth@example.com",
        name="Auth User",
        password_hash="fakehash"
    )
    token = create_access_token({"sub": str(user_id)})
    mock_auth_service.get_user_by_id = AsyncMock(return_value=mock_user)

    mock_repo = AsyncMock()
    mock_repo.list_for_user.return_value = ([], 0)
    mock_fav_repo_class.return_value = mock_repo

    response = client.get("/favorites", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 0
    assert data["items"] == []

