class Country {
  final String name;
  final String isoCode;

  const Country({
    required this.name,
    required this.isoCode,
  });

  String get flagUrl => 'http://flagcdn.com/w320/$isoCode.png';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          isoCode == other.isoCode;

  @override
  int get hashCode => name.hashCode ^ isoCode.hashCode;

  @override
  String toString() => 'Country(name: $name, isoCode: $isoCode)';
}
