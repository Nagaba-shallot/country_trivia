import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../models/country_dto.dart';

class CountryApiService {
  final http.Client client;

  CountryApiService({required this.client});

  Future<List<CountryDto>> fetchAllCountries() async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.allCountriesEndpoint}',
    );

    http.Response response;
    try {
      response = await client.get(uri);
    } catch (e) {
      throw ServerFailure('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw ServerFailure(
        'Failed to fetch countries: HTTP ${response.statusCode}',
      );
    }

    try {
      final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
      return jsonList
          .map((json) => CountryDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to parse countries response: $e');
    }
  }
}
