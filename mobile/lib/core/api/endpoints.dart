class Endpoints {
  Endpoints._();

  static const String places = '/places';
  static const String categories = '/categories';
  static const String recommendations = '/recommendations';
  static const String search = '/places/search';

  static String placeDetails(String id) => '/places/$id';
}
