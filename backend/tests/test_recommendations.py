"""Tests for the /places/recommendations endpoint."""

from unittest.mock import AsyncMock, patch


@patch("app.api.routes.recommendations.RecommendationService")
def test_get_recommendations_date(mock_service_class, client):
    mock_service = AsyncMock()
    mock_rec = {
        "id": "e963b6f2-bb0a-4fb4-9cbe-cd3376ae753f",
        "name": "Date Spot Cafe",
        "category": "cafe",
        "area": "Heritage Town",
        "rating": 4.6,
        "reviews": 105,
        "latitude": 11.932,
        "longitude": 79.829,
        "date_score": 9.0,
        "romantic_score": 9.5,
        "conversation_score": 8.0,
        "quiet_score": 7.0,
        "scenic_score": 6.0,
        "social_score": 8.0,
        "activity_score": 5.0,
        "comfort_score": 9.0,
        "nature_score": 4.0,
        "stimulation_score": 6.0,
        "photo_score": 8.5,
        "quality_score": 8.5,
        "popularity_score": 8.0,
        "google_maps_url": "http://maps.google.com",
        "thumbnail_url": "http://example.com/date.jpg",
        "computed_score": 9.1234,
    }

    mock_service.recommend.return_value = [mock_rec]
    mock_service_class.return_value = mock_service

    response = client.get("/places/recommendations?occasion=date&lat=11.93&lng=79.83&distance_km=5.0")
    assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"

    data = response.json()
    assert len(data) == 1
    assert data[0]["name"] == "Date Spot Cafe"
    assert data[0]["computed_score"] == 9.1234
    assert data[0]["rating"] == 4.6


@patch("app.api.routes.recommendations.RecommendationService")
def test_get_recommendations_valid_occasions(mock_service_class, client):
    """All four occasion values must be accepted by the API validation."""
    mock_service = AsyncMock()
    mock_service.recommend.return_value = []
    mock_service_class.return_value = mock_service

    for occ in ("date", "friends", "family", "solo"):
        response = client.get(f"/places/recommendations?occasion={occ}")
        assert response.status_code == 200, f"{occ} returned {response.status_code}: {response.text}"
