import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/errors/failures.dart';
import '../models/country_dto.dart';

class CountryLocalDataSource {
  const CountryLocalDataSource();

  Future<List<CountryDto>> getCountriesFromAsset() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/countries.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => CountryDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheFailure('Failed to load countries from asset: $e');
    }
  }
}
