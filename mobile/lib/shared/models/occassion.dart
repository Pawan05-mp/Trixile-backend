enum Occasion {
  date('date', 'Date'),
  friends('friends', 'Friends'),
  family('family', 'Family'),
  solo('solo', 'Solo');

  final String apiValue;
  final String displayName;

  const Occasion(this.apiValue, this.displayName);

  static Occasion fromApi(String value) {
    return Occasion.values.firstWhere(
      (o) => o.apiValue == value,
      orElse: () => Occasion.date,
    );
  }
}
