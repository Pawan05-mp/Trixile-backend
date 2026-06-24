class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;

  const AnalyticsEvent(this.name, [this.properties = const {}]);
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  bool _enabled = true;

  void enable() => _enabled = true;
  void disable() => _enabled = false;

  void logEvent(String name, [Map<String, dynamic> properties = const {}]) {
    if (!_enabled) return;
    // In production, send to analytics service
    // For now, debug print (to be removed in production)
  }

  void logScreenView(String screenName) {
    logEvent('screen_view', {'screen': screenName});
  }

  void logRecommendationView(String placeId, String placeName, double score) {
    logEvent('recommendation_view', {
      'place_id': placeId,
      'place_name': placeName,
      'score': score,
    });
  }

  void logSearch(String query) {
    logEvent('search', {'query': query});
  }

  void logFavorite(String placeId, bool added) {
    logEvent('favorite', {'place_id': placeId, 'added': added});
  }

  void logNavigate(String placeId) {
    logEvent('navigate', {'place_id': placeId});
  }

  void logOccasionSwitch(String occasion) {
    logEvent('occasion_switch', {'occasion': occasion});
  }
}

final analyticsService = AnalyticsService();
