import 'occassion.dart';
/// Parses budget_level coming from the backend, which stores it as a
/// String on a 1–6 scale (e.g. "1".."6"), while older mock data used
/// a plain int. Falls back to 2 if missing/unparseable.
int _parseBudgetLevel(dynamic value) {
  if (value == null) return 2;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  return 2;
}

class Place {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String? categoryName;

  final String dnaCategory;

  final String area;
  final int budgetLevel;
  final double qualityScore;
  final double popularityIndex;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;

  final String? imagePath;

  final List<String> tags;
  final bool indoor;
  final String? phoneNumber;
  final String? websiteUrl;

  // New API response fields
  final double score;
  final Occasion? occasion;
  final double distanceKm;
  final List<String> reasons;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    this.categoryName,
    this.dnaCategory = 'restaurant',
    required this.area,
    required this.budgetLevel,
    required this.qualityScore,
    required this.popularityIndex,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    this.imagePath,
    required this.tags,
    required this.indoor,
    this.phoneNumber,
    this.websiteUrl,
    this.score = 0.0,
    this.occasion,
    this.distanceKm = 0.0,
    this.reasons = const [],
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Place',
      description: json['description'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String?,
      dnaCategory: json['dnaCategory'] as String? ?? 'restaurant',
      area: json['area'] as String? ?? 'Chennai Core',
      budgetLevel: _parseBudgetLevel(json['budgetLevel'] ?? json['budget_level']),
      qualityScore: (json['qualityScore'] as num? ?? 0.8).toDouble(),
      popularityIndex: (json['popularityIndex'] as num? ?? 0.5).toDouble(),
      latitude: (json['latitude'] as num? ?? 13.0603).toDouble(),
      longitude: (json['longitude'] as num? ?? 80.2415).toDouble(),
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imagePath: json['imagePath'] as String? ?? json['image_path'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      indoor: json['indoor'] as bool? ?? true,
      phoneNumber: json['phoneNumber'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      score: (json['score'] as num? ?? 0.0).toDouble(),
      occasion: json['occasion'] != null
          ? Occasion.fromApi(json['occasion'] as String)
          : null,
      distanceKm: (json['distance_km'] as num? ?? 0.0).toDouble(),
      reasons:
          (json['reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  factory Place.fromRecommendationJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Place',
      description: json['description'] as String? ?? '',
      categoryId: json['category'] as String? ?? '',
      categoryName: json['category'] as String?,
      dnaCategory: json['category'] as String? ?? 'restaurant',
      area: json['area'] as String? ?? 'Chennai Core',
      budgetLevel: _parseBudgetLevel(json['budget_level']),
      qualityScore: (json['score'] as num? ?? 0.8).toDouble(),
      popularityIndex: 0.5,
      latitude: (json['latitude'] as num? ?? 13.0603).toDouble(),
      longitude: (json['longitude'] as num? ?? 80.2415).toDouble(),
      imageUrls: json['thumbnail_url'] != null
          ? [json['thumbnail_url'] as String]
          : [],
      imagePath: json['thumbnail_url'] as String?,
      tags: [],
      indoor: true,
      score: (json['score'] as num? ?? 0.0).toDouble(),
      occasion: json['occasion'] != null
          ? Occasion.fromApi(json['occasion'] as String)
          : null,
      distanceKm: (json['distance_km'] as num? ?? 0.0).toDouble(),
      reasons:
          (json['reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Builds a [Place] from the backend's lightweight `PlaceBrief` schema
  /// (id, name, category, area, rating, budget_level, latitude, longitude,
  /// thumbnail_url) — used by the favorites list and place search/nearby.
  factory Place.fromBriefJson(Map<String, dynamic> json) {
    final rating = (json['rating'] as num?)?.toDouble() ?? 4.0;
    return Place(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Place',
      description: '',
      categoryId: json['category'] as String? ?? '',
      categoryName: json['category'] as String?,
      dnaCategory: json['category'] as String? ?? 'restaurant',
      area: json['area'] as String? ?? 'Pondicherry',
      budgetLevel: _parseBudgetLevel(json['budget_level']),
      qualityScore: (rating / 5).clamp(0, 1),
      popularityIndex: 0.5,
      latitude: (json['latitude'] as num? ?? 11.9416).toDouble(),
      longitude: (json['longitude'] as num? ?? 79.8083).toDouble(),
      imageUrls: json['thumbnail_url'] != null ? [json['thumbnail_url'] as String] : [],
      imagePath: json['thumbnail_url'] as String?,
      tags: const [],
      indoor: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'dnaCategory': dnaCategory,
      'area': area,
      'budgetLevel': budgetLevel,
      'qualityScore': qualityScore,
      'popularityIndex': popularityIndex,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'imagePath': imagePath,
      'tags': tags,
      'indoor': indoor,
      'phoneNumber': phoneNumber,
      'websiteUrl': websiteUrl,
      'score': score,
      'distance_km': distanceKm,
      'reasons': reasons,
    };
  }

  String get budgetIndicator => '₹' * budgetLevel.clamp(1, 4);
  double get starRating => qualityScore * 5;

  bool get hasNetworkImage =>
      imagePath != null && imagePath!.startsWith('http');

  String? get displayImageUrl {
    if (hasNetworkImage) return imagePath;
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return null;
  }
}
