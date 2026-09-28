import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/errors/failures.dart';
import '../models/country_dto.dart';

class CountryLocalDataSource {
  static const String _assetPath = 'assets/data/countries.json';

  Future<List<CountryDto>> getCountriesFromAsset() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => CountryDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheFailure('Failed to load local countries: $e');
    }
  }
}
