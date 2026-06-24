"""Unit tests for import script utility functions and data validation."""

import uuid
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
import pandas as pd
from scripts.import_places import (
    parse_tags,
    to_float,
    to_int,
    validate_row,
    import_data,
    process_batch
)


def test_parse_tags_nan():
    assert parse_tags(None) == []
    assert parse_tags(pd.NA) == []


def test_parse_tags_list():
    assert parse_tags(["cafe", "romantic", ""]) == ["cafe", "romantic"]


def test_parse_tags_string():
    assert parse_tags("cafe, romantic, quiet") == ["cafe", "romantic", "quiet"]
    assert parse_tags("  cafe  ") == ["cafe"]


def test_parse_tags_other_types():
    assert parse_tags(123) == []


def test_to_float_valid():
    assert to_float("4.5") == 4.5
    assert to_float(4) == 4.0
    assert to_float(None) is None


def test_to_float_invalid():
    assert to_float("invalid") is None


def test_to_int_valid():
    assert to_int("123") == 123
    assert to_int(4.5) == 4
    assert to_int(None) is None


def test_to_int_invalid():
    assert to_int("invalid") is None


def test_validate_row_valid():
    row = {
        "name": "Cafe Des Arts",
        "lat": 11.93,
        "lng": 79.83,
        "rating": 4.5,
        "reviews": 120
    }
    errors = validate_row(1, row)
    assert len(errors) == 0


def test_validate_row_invalid():
    row = {
        "name": "",
        "lat": 100.0,  # Out of range [-90, 90]
        "lng": -200.0, # Out of range [-180, 180]
        "rating": 6.0,  # Out of range [0, 5]
        "reviews": -5   # Negative
    }
    errors = validate_row(1, row)
    assert len(errors) == 5
    assert "Name is required" in errors[0]
    assert "Latitude" in errors[1]
    assert "Longitude" in errors[2]
    assert "Rating" in errors[3]
    assert "Reviews" in errors[4]


@pytest.mark.asyncio
@patch("scripts.import_places.pd.read_excel")
@patch("scripts.import_places.async_session_factory")
async def test_import_data_success(mock_session_factory, mock_read_excel):
    """Test standard import_data execution mock flow."""
    mock_df = MagicMock()
    mock_df.__len__.return_value = 1
    mock_df.iterrows.return_value = [
        (0, MagicMock(to_dict=lambda: {
            "id": "e963b6f2-bb0a-4fb4-9cbe-cd3376ae753f",
            "name": "Mock Place",
            "lat": 11.93,
            "lng": 79.83,
            "rating": 4.5,
            "reviews": 200,
            "category": "restaurant",
            "area": "Heritage Town"
        }))
    ]
    mock_read_excel.return_value = mock_df

    mock_session = MagicMock()
    mock_session.execute = AsyncMock()
    mock_session.commit = AsyncMock()
    
    mock_nested = MagicMock()
    mock_nested.__aenter__ = AsyncMock()
    mock_nested.__aexit__ = AsyncMock(return_value=False)
    mock_session.begin_nested.return_value = mock_nested

    mock_session_factory.return_value.__aenter__.return_value = mock_session
    mock_session_factory.return_value.__aexit__ = AsyncMock()

    with patch("builtins.open", MagicMock()), patch("scripts.import_places.os.path.exists", return_value=True):
        report = await import_data("dummy_path.xlsx", batch_size=10)
        
        assert report["total_records"] == 1
        assert report["successful_records"] == 1
        assert report["failed_records"] == 0
        assert len(report["errors"]) == 0


@pytest.mark.asyncio
async def test_process_batch_failure():
    """Verify batch insert fallback logic when an exception is raised during batch execute."""
    mock_session = MagicMock()
    mock_session.execute = AsyncMock(side_effect=Exception("DB constraint error"))
    
    mock_nested = MagicMock()
    mock_nested.__aenter__ = AsyncMock()
    mock_nested.__aexit__ = AsyncMock(return_value=False)
    mock_session.begin_nested.return_value = mock_nested
    
    batch = [
        {"id": uuid.uuid4(), "name": "Place 1"},
        {"id": uuid.uuid4(), "name": "Place 2"}
    ]
    
    with patch("scripts.import_places.insert_single_record") as mock_insert_single:

        mock_insert_single.side_effect = [True, False]
        
        succeeded, failed, errors = await process_batch(mock_session, batch)
        
        assert succeeded == 1
        assert failed == 1
        assert len(errors) == 1
        assert errors[0]["name"] == "Place 2"
        assert mock_insert_single.call_count == 2
