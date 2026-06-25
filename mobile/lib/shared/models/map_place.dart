class MapPlace {
  final String id;
  final String name;
  final String category;
  final double lat;
  final double lng;
  final double rating;
  final String? imageUrl;
  final String color;

  const MapPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.rating = 0.0,
    this.imageUrl,
    this.color = '#76D11B',
  });
}
