class AppConstants {
  AppConstants._();

  // App General
  static const String appName = 'Place Discovery';

  // API Endpoints
  // NOTE: the FastAPI backend (see backend/app/main.py) mounts every
  // router at the root — `/auth`, `/places`, `/favorites` — with no
  // `/api` prefix, so the trailing `/api` previously here caused every
  // request (login, register, etc.) to 404. Fixed by pointing straight
  // at the service root. If your deployed Cloud Run service actually
  // sits behind a reverse proxy that adds `/api`, restore the suffix.
  static const String baseUrl =
      'https://trixile-backend.onrender.com';
  static const int apiTimeoutMs = 120000;

  // Supabase OAuth (Google/Facebook). Must exactly match a URL registered
  // under Supabase Dashboard -> Authentication -> URL Configuration ->
  // Redirect URLs, and the matching scheme/host must be registered in
  // android/app/src/main/AndroidManifest.xml and ios/Runner/Info.plist.
  // See SOCIAL_LOGIN_SETUP.md.
  static const String supabaseRedirectUrl = 'io.trixile.app://login-callback';

  // Coordinate Reference (Pondicherry Center Fallback)
  static const double defaultLat = 11.9416;
  static const double defaultLng = 79.8083;

  // Storage Boxes
  static const String settingsBox = 'app_settings_box';
  static const String favoritesBox = 'favorites_places_box';
  static const String cacheBox = 'places_cache_box';
  static const String recentBox = 'recent_recommendations_box';

  // Cache TTL
  static const Duration cacheTtl = Duration(minutes: 5);
  static const Duration recentMaxAge = Duration(hours: 24);
  static const int recentMaxCount = 20;

  // Storage Keys
  static const String keyFirstInstall = 'is_first_install';
  static const String keyPreferredBudget = 'preferred_budget_limit';
  static const String keyMaxDistance = 'max_search_distance_km';
  static const String keyOfflineMode = 'enable_offline_mode';
  static const String keyDarkMode = 'enable_dark_mode';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyNotifications = 'enable_notifications';
}
