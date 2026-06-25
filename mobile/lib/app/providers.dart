import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/auth_service.dart';
import '../core/api/favorites_service.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../core/location/location_service.dart';
import '../core/network/connectivity_service.dart';
import '../shared/models/place.dart';
import '../shared/models/occassion.dart';

// Singleton Providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService(ref.read(apiClientProvider));
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('localStorageProvider must be overridden in main()');
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

// ── Auth state ─────────────────────────────────────────────
// True once a token has been restored/attached to the ApiClient.
// Flipped by AuthService callers on login/register/logout; also
// restored once at startup in main.dart.
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

// App Settings Providers
final budgetPreferenceProvider = StateProvider<int>((ref) {
  final local = ref.read(localStorageProvider);
  return local.getPreferredBudget();
});

final maxDistanceProvider = StateProvider<double>((ref) {
  final local = ref.read(localStorageProvider);
  return local.getDistancePreference();
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final local = ref.read(localStorageProvider);
  return local.getDarkModePreference() ? ThemeMode.dark : ThemeMode.light;
});

// Location
const _defaultLat = 11.9416;
const _defaultLng = 79.8083;

enum LocationStatus { denied, deniedForever, serviceDisabled, ok }

class OfflineException implements Exception {
  final String message;
  const OfflineException(this.message);
  @override
  String toString() => message;
}

class LocationResult {
  final double lat;
  final double lng;
  final LocationStatus status;
  const LocationResult(this.lat, this.lng, this.status);
}

final userLocationProvider = FutureProvider<LocationResult>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  final position = await locationService.getCurrentLocation();
  if (position == null) {
    final status = await locationService.getLocationStatus();
    return LocationResult(_defaultLat, _defaultLng, status);
  }
  return LocationResult(
    position.latitude,
    position.longitude,
    LocationStatus.ok,
  );
});

// Occasion selection
final selectedOccasionProvider = StateProvider<Occasion>(
  (ref) => Occasion.date,
);

// Location permission status (for UI)
final locationPermissionProvider = Provider<AsyncValue<LocationStatus>>((ref) {
  final locationAsync = ref.watch(userLocationProvider);
  return locationAsync.whenData((l) => l.status);
});

// Build cache key
String _cacheKey(Occasion occasion, double lat, double lng, int budget) {
  return 'recs:${occasion.apiValue}:${lat.toStringAsFixed(2)}:${lng.toStringAsFixed(2)}:$budget';
}

// Recommendations from backend API with caching & offline fallback
final recommendationsProvider = FutureProvider<List<Place>>((ref) async {
  final api = ref.read(apiClientProvider);
  final storage = ref.read(localStorageProvider);
  final occasion = ref.watch(selectedOccasionProvider);
  final locationAsync = ref.watch(userLocationProvider);
  final budgetLimit = ref.watch(budgetPreferenceProvider);

  final location = locationAsync.value ??
      const LocationResult(_defaultLat, _defaultLng, LocationStatus.ok);
  final cacheKey = _cacheKey(occasion, location.lat, location.lng, budgetLimit);

  try {
    final response = await api.get<List<dynamic>>(
      '/places/recommendations',
      queryParameters: {
        'occasion': occasion.apiValue,
        'lat': location.lat,
        'lng': location.lng,
        'limit': 20,
        // NOTE: the backend's `budget` filter is an exact string match
        // against its internal 1–6 budget_level scale (not the same
        // scale as our 1–4 local budget preference), so it isn't sent
        // here to avoid accidentally filtering out every result.
      },
    );

    final data = (response.data ?? []).cast<Map<String, dynamic>>();
    final places =
        data.map((json) => Place.fromRecommendationJson(json)).toList();

    await storage.cachePlaces(cacheKey, data);

    return places;
  } catch (e, st) {
    debugPrint('❌ recommendationsProvider error: $e');
    debugPrint('❌ recommendationsProvider stack: $st');
    if (e is DioException) {
      debugPrint('❌ DioException type: ${e.type}');
      debugPrint('❌ DioException status: ${e.response?.statusCode}');
      debugPrint('❌ DioException body: ${e.response?.data}');
    }
    final cached = await storage.getCachedPlaces(cacheKey);
    if (cached != null) {
      debugPrint('📦 Using ${cached.length} cached recommendations');
      return cached.map((j) => Place.fromRecommendationJson(j)).toList();
    }
    debugPrint('⚠️ No cached recommendations available — returning empty');
    return [];
  }
});

// Recent recommendations provider
final recentRecommendationsProvider = Provider<List<Place>>((ref) {
  final storage = ref.read(localStorageProvider);
  final recentJson = storage.getRecentRecommendations();
  return recentJson.map((j) => Place.fromRecommendationJson(j)).toList();
});

// Saved/favorite places — backed by the real backend, with the local
// Hive cache as an offline fallback. Call `ref.invalidate(savedPlacesProvider)`
// after adding/removing a favorite to refresh this.
final savedPlacesProvider = FutureProvider<List<Place>>((ref) async {
  final favoritesService = ref.read(favoritesServiceProvider);
  final storage = ref.read(localStorageProvider);
  try {
    final places = await favoritesService.list();
    return places;
  } catch (_) {
    // Offline / not authenticated yet — fall back to whatever was
    // last saved locally.
    final cached = storage.getSavedFavorites();
    return cached.map(Place.fromJson).toList();
  }
});

// Connectivity stream provider
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.read(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
