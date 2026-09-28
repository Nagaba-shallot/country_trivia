import '../../domain/entities/country.dart';

class CountryDto {
  final String commonName;
  final String cca2;

  const CountryDto({
    required this.commonName,
    required this.cca2,
  });

  factory CountryDto.fromJson(Map<String, dynamic> json) {
    return CountryDto(
      commonName: json['name'] as String,
      cca2: json['cca2'] as String,
    );
  }

  Country toDomain() {
    return Country(
      name: commonName,
      isoCode: cca2,
    );
  }
}
