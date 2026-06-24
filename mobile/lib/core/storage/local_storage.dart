import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../app/constants/app_constants.dart';

class LocalStorage {
  late final Box<dynamic> _settingsBox;
  late final Box<dynamic> _cacheBox;
  late final Box<dynamic> _favoritesBox;
  late final Box<dynamic> _recentBox;

  bool _initialized = false;

  bool get isReady => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      _settingsBox = await Hive.openBox<dynamic>(AppConstants.settingsBox);

      _cacheBox = await Hive.openBox<dynamic>(AppConstants.cacheBox);

      _favoritesBox = await Hive.openBox<dynamic>(AppConstants.favoritesBox);

      _recentBox = await Hive.openBox<dynamic>(AppConstants.recentBox);

      _initialized = true;
    } catch (_) {
      // Initialization failed; all methods check _initialized before operating
    }
  }

  // ==========================================================
  // Preferences
  // ==========================================================

  Future<void> saveBudgetPreference(int budgetLimit) async {
    if (!_initialized) return;

    await _settingsBox.put(AppConstants.keyPreferredBudget, budgetLimit);
  }

  int getPreferredBudget() {
    if (!_initialized) return 4;

    return _settingsBox.get(AppConstants.keyPreferredBudget, defaultValue: 4)
        as int;
  }

  Future<void> saveDistancePreference(double kilometers) async {
    if (!_initialized) return;

    await _settingsBox.put(AppConstants.keyMaxDistance, kilometers);
  }

  double getDistancePreference() {
    if (!_initialized) return 10.0;

    return (_settingsBox.get(AppConstants.keyMaxDistance, defaultValue: 10.0)
            as num)
        .toDouble();
  }

  Future<void> saveFirstInstallFlag(bool isFirstInstall) async {
    if (!_initialized) return;

    await _settingsBox.put(AppConstants.keyFirstInstall, isFirstInstall);
  }

  bool isFirstInstall() {
    if (!_initialized) return true;

    return _settingsBox.get(AppConstants.keyFirstInstall, defaultValue: true)
        as bool;
  }

  Future<void> saveDarkModePreference(bool isDarkMode) async {
    if (!_initialized) return;

    await _settingsBox.put(AppConstants.keyDarkMode, isDarkMode);
  }

  bool getDarkModePreference() {
    if (!_initialized) return false;

    return _settingsBox.get(AppConstants.keyDarkMode, defaultValue: false)
        as bool;
  }

  Future<void> saveUserName(String name) async {
    if (!_initialized) return;
    await _settingsBox.put(AppConstants.keyUserName, name);
  }

  String? getUserName() {
    if (!_initialized) return null;
    return _settingsBox.get(AppConstants.keyUserName) as String?;
  }

  Future<void> saveUserEmail(String email) async {
    if (!_initialized) return;
    await _settingsBox.put(AppConstants.keyUserEmail, email);
  }

  String? getUserEmail() {
    if (!_initialized) return null;
    return _settingsBox.get(AppConstants.keyUserEmail) as String?;
  }

  Future<void> saveNotificationPreference(bool enabled) async {
    if (!_initialized) return;
    await _settingsBox.put(AppConstants.keyNotifications, enabled);
  }

  bool getNotificationPreference() {
    if (!_initialized) return true;
    return _settingsBox.get(AppConstants.keyNotifications, defaultValue: true)
        as bool;
  }

  // ==========================================================
  // Cache
  // ==========================================================

  Future<void> cachePlaces(
    String queryKey,
    List<Map<String, dynamic>> places,
  ) async {
    if (!_initialized) return;

    await _cacheBox.put(queryKey, {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': places,
    });
  }

  Future<List<Map<String, dynamic>>?> getCachedPlaces(String queryKey) async {
    if (!_initialized) return null;

    final dynamic cached = _cacheBox.get(queryKey);

    if (cached == null) {
      return null;
    }

    try {
      final timestamp = cached['timestamp'] as int;

      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (age > AppConstants.cacheTtl.inMilliseconds) {
        await _cacheBox.delete(queryKey);
        return null;
      }

      final List<dynamic> data = cached['data'] as List<dynamic>;

      return data
          .map(
            (item) => Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
          )
          .toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAllCache() async {
    if (!_initialized) return;

    await _cacheBox.clear();
  }

  // ==========================================================
  // Favorites
  // ==========================================================

  Future<void> addFavorite(
    String placeId,
    Map<String, dynamic> placeJson,
  ) async {
    if (!_initialized) return;

    await _favoritesBox.put(placeId, placeJson);
  }

  Future<void> removeFavorite(String placeId) async {
    if (!_initialized) return;

    await _favoritesBox.delete(placeId);
  }

  Future<void> toggleFavorite(
    String placeId,
    Map<String, dynamic> placeJson,
  ) async {
    if (!_initialized) return;

    if (_favoritesBox.containsKey(placeId)) {
      await removeFavorite(placeId);
    } else {
      await addFavorite(placeId, placeJson);
    }
  }

  bool isFavorite(String placeId) {
    if (!_initialized) return false;

    return _favoritesBox.containsKey(placeId);
  }

  List<Map<String, dynamic>> getSavedFavorites() {
    if (!_initialized) return [];

    try {
      return _favoritesBox.values
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==========================================================
  // Recent Recommendations
  // ==========================================================

  Future<void> addRecentRecommendation(Map<String, dynamic> placeJson) async {
    if (!_initialized) return;

    final id = placeJson['id'] as String? ?? '';
    if (id.isEmpty) return;

    // Remove duplicate if exists
    if (_recentBox.containsKey(id)) {
      await _recentBox.delete(id);
    }

    await _recentBox.put(id, {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': placeJson,
    });

    // Enforce max count
    if (_recentBox.length > AppConstants.recentMaxCount) {
      final entries = _recentBox.toMap().entries.toList()
        ..sort(
          (a, b) => ((b.value as Map)['timestamp'] as int).compareTo(
            (a.value as Map)['timestamp'] as int,
          ),
        );
      final toRemove = entries.skip(AppConstants.recentMaxCount);
      for (final e in toRemove) {
        await _recentBox.delete(e.key);
      }
    }
  }

  List<Map<String, dynamic>> getRecentRecommendations() {
    if (!_initialized) return [];

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entries = _recentBox.toMap().entries.toList()
        ..sort(
          (a, b) => ((b.value as Map)['timestamp'] as int).compareTo(
            (a.value as Map)['timestamp'] as int,
          ),
        );

      return entries
          .where((e) {
            final age = now - ((e.value as Map)['timestamp'] as int);
            return age < AppConstants.recentMaxAge.inMilliseconds;
          })
          .map(
            (e) => Map<String, dynamic>.from((e.value as Map)['data'] as Map),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearRecentRecommendations() async {
    if (!_initialized) return;
    await _recentBox.clear();
  }

  // ==========================================================
  // Cleanup
  // ==========================================================

  Future<void> dispose() async {
    if (!_initialized) return;

    await _settingsBox.close();
    await _cacheBox.close();
    await _favoritesBox.close();
    await _recentBox.close();

    _initialized = false;
  }
}
