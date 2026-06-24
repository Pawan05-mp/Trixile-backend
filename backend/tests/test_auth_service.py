"""Unit tests for AuthService."""

import uuid
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from sqlalchemy.ext.asyncio import AsyncSession
from app.services.auth_service import AuthService
from app.models.user import User


@pytest.mark.asyncio
@patch("app.services.auth_service.hash_password")
async def test_auth_service_register(mock_hash_password):
    """Verify registration hashes the password and persists the user."""
    mock_hash_password.return_value = "hashed_pw"
    mock_db = AsyncMock(spec=AsyncSession)

    user = await AuthService.register(
        db=mock_db,
        email="register@example.com",
        password="plain_password",
        name="Register User"
    )

    assert user.email == "register@example.com"
    assert user.password_hash == "hashed_pw"
    assert user.name == "Register User"
    assert mock_db.add.called
    assert mock_db.flush.called
    assert mock_db.refresh.called


@pytest.mark.asyncio
@patch("app.services.auth_service.verify_password")
@patch("app.services.auth_service.create_access_token")
async def test_auth_service_authenticate_user_success(mock_create_token, mock_verify):
    """Verify authenticate_user returns token with correct credentials."""
    mock_verify.return_value = True
    mock_create_token.return_value = "generated_jwt_token"

    mock_db = AsyncMock(spec=AsyncSession)
    mock_result = MagicMock()
    user_id = uuid.uuid4()
    user = User(id=user_id, email="auth@example.com", password_hash="hashed_pw")
    mock_result.scalar_one_or_none.return_value = user
    mock_db.execute.return_value = mock_result

    token = await AuthService.authenticate_user(
        db=mock_db,
        email="auth@example.com",
        password="plain_password"
    )

    assert token == "generated_jwt_token"
    mock_verify.assert_called_once_with("plain_password", "hashed_pw")
    mock_create_token.assert_called_once_with(data={"sub": str(user_id)})


@pytest.mark.asyncio
@patch("app.services.auth_service.verify_password")
async def test_auth_service_authenticate_user_not_found(mock_verify):
    """Verify authenticate_user returns None if user does not exist."""
    mock_db = AsyncMock(spec=AsyncSession)
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_db.execute.return_value = mock_result

    token = await AuthService.authenticate_user(
        db=mock_db,
        email="nonexistent@example.com",
        password="password"
    )

    assert token is None
    assert not mock_verify.called


@pytest.mark.asyncio
@patch("app.services.auth_service.verify_password")
async def test_auth_service_authenticate_user_wrong_password(mock_verify):
    """Verify authenticate_user returns None if password is incorrect."""
    mock_verify.return_value = False
    mock_db = AsyncMock(spec=AsyncSession)
    mock_result = MagicMock()
    user = User(id=uuid.uuid4(), email="auth@example.com", password_hash="hashed_pw")
    mock_result.scalar_one_or_none.return_value = user
    mock_db.execute.return_value = mock_result

    token = await AuthService.authenticate_user(
        db=mock_db,
        email="auth@example.com",
        password="wrong_password"
    )

    assert token is None
    mock_verify.assert_called_once_with("wrong_password", "hashed_pw")


@pytest.mark.asyncio
async def test_auth_service_get_user_by_id():
    """Verify get_user_by_id executes query and returns correct user."""
    mock_db = AsyncMock(spec=AsyncSession)
    mock_result = MagicMock()
    user_id = uuid.uuid4()
    user = User(id=user_id, email="id@example.com")
    mock_result.scalar_one_or_none.return_value = user
    mock_db.execute.return_value = mock_result

    result = await AuthService.get_user_by_id(db=mock_db, user_id=user_id)

    assert result == user
    assert mock_db.execute.called
