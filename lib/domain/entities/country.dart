/// Domain entity representing a country.
class Country {
  final String name;
  final String isoCode;

  const Country({required this.name, required this.isoCode});

  String get flagUrl => 'http://flagcdn.com/w320/${isoCode.toLowerCase()}.png';
}
