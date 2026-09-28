import '../../domain/entities/country.dart';

/// Data transfer object for a country as returned by the REST Countries API v3.1.
///
/// Example JSON:
/// ```json
/// {
///   "name": { "common": "Germany" },
///   "cca2": "DE"
/// }
/// ```
class CountryDto {
  final String commonName;
  final String cca2;

  const CountryDto({required this.commonName, required this.cca2});

  /// Creates a [CountryDto] from a JSON map.
  ///
  /// Throws a [FormatException] if required fields are missing or invalid.
  factory CountryDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid country JSON: "name" must be an object',
      );
    }

    final commonName = name['common'];
    if (commonName is! String || commonName.isEmpty) {
      throw const FormatException(
        'Invalid country JSON: "name.common" must be a non-empty string',
      );
    }

    final cca2 = json['cca2'];
    if (cca2 is! String || cca2.isEmpty) {
      throw const FormatException(
        'Invalid country JSON: "cca2" must be a non-empty string',
      );
    }

    return CountryDto(commonName: commonName, cca2: cca2);
  }

  /// Maps this DTO to the [Country] domain entity.
  Country toDomain() {
    return Country(name: commonName, isoCode: cca2);
  }
}
