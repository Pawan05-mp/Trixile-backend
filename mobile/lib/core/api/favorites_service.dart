import 'api_client.dart';
import '../../shared/models/place.dart';

/// Talks to the backend's authenticated /favorites endpoints.
/// Requires the ApiClient to already have a bearer token set
/// (see [ApiClient.setAuthToken]).
class FavoritesService {
  FavoritesService(this._api);

  final ApiClient _api;

  Future<void> add(String placeId) async {
    await _api.post<void>('/favorites/$placeId');
  }

  Future<void> remove(String placeId) async {
    await _api.delete<void>('/favorites/$placeId');
  }

  /// Returns the user's saved places as full [Place] objects
  /// (built from the lightweight PlaceBrief the backend returns).
  Future<List<Place>> list() async {
    final response = await _api.get<Map<String, dynamic>>(
      '/favorites',
      queryParameters: {'page': 1, 'page_size': 100},
    );
    final items = (response.data?['items'] as List<dynamic>? ?? []);
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      final place = map['place'] as Map<String, dynamic>;
      return Place.fromBriefJson(place);
    }).toList();
  }
}
