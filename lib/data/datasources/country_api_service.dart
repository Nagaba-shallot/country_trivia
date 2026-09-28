import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/errors/failures.dart';
import '../../core/constants/api_constants.dart';
import '../models/country_dto.dart';

class CountryApiService {
  final http.Client _client;

  CountryApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<CountryDto>> fetchAllCountries() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/all?fields=name,cca2');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
        return jsonList
            .map((json) => CountryDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerFailure('Failed to fetch countries: ${response.statusCode}');
      }
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Network error: $e');
    }
  }
}
