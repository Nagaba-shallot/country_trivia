class Country {
  final String name;
  final String isoCode;

  const Country({
    required this.name,
    required this.isoCode,
  });

  String get flagUrl => 'http://flagcdn.com/w320/${isoCode.toLowerCase()}.png';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          isoCode == other.isoCode;

  @override
  int get hashCode => isoCode.hashCode;

  @override
  String toString() => 'Country(name: $name, isoCode: $isoCode)';
}
