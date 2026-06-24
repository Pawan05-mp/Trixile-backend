"""Unit tests for security utilities: password hashing and JWT."""

import time
import pytest
from unittest.mock import patch
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    decode_access_token,
)


def test_hash_password_returns_string():
    hashed = hash_password("mypassword")
    assert isinstance(hashed, str)
    assert len(hashed) > 0


def test_hash_is_not_plaintext():
    hashed = hash_password("mypassword")
    assert hashed != "mypassword"


def test_verify_password_correct():
    hashed = hash_password("correct_password")
    assert verify_password("correct_password", hashed) is True


def test_verify_password_incorrect():
    hashed = hash_password("correct_password")
    assert verify_password("wrong_password", hashed) is False


def test_create_access_token_returns_string():
    token = create_access_token({"sub": "user-id-123"})
    assert isinstance(token, str)
    assert len(token) > 0


def test_decode_access_token_valid():
    token = create_access_token({"sub": "user-id-123"})
    payload = decode_access_token(token)
    assert payload is not None
    assert payload["sub"] == "user-id-123"


def test_decode_access_token_invalid():
    result = decode_access_token("invalid.token.string")
    assert result is None


def test_decode_access_token_empty():
    result = decode_access_token("")
    assert result is None


def test_access_token_has_exp():
    token = create_access_token({"sub": "user-id-999"})
    payload = decode_access_token(token)
    assert "exp" in payload


def test_decode_expired_token():
    """Token with negative expiry should be invalid."""
    from datetime import timedelta
    token = create_access_token({"sub": "expired-user"}, expires_delta=timedelta(seconds=-1))
    result = decode_access_token(token)
    assert result is None
