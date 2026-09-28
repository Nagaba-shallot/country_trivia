import '../../domain/entities/country.dart';

class CountryDto {
  final String commonName;
  final String cca2;

  const CountryDto({
    required this.commonName,
    required this.cca2,
  });

  factory CountryDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>?;
    final commonName = name?['common'] as String? ?? '';
    final cca2 = json['cca2'] as String? ?? '';

    return CountryDto(
      commonName: commonName,
      cca2: cca2,
    );
  }

  Country toDomain() {
    return Country(
      name: commonName,
      isoCode: cca2.toLowerCase(),
    );
  }
}
