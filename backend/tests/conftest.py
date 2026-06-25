"""Pytest conftest configuration and global fixtures."""

import os
import sys
from unittest.mock import MagicMock

# Set testing environment variables
os.environ["TESTING"] = "1"
os.environ["POSTGRES_DB"] = "test_placesdb"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession

# Add backend to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app
from app.db.session import get_db


@pytest.fixture
def mock_db():
    """Mock database session."""
    session = MagicMock(spec=AsyncSession)
    return session


@pytest.fixture
def client(mock_db):
    """FastAPI test client with database override."""
    def _get_db_override():
        yield mock_db

    app.dependency_overrides[get_db] = _get_db_override
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
