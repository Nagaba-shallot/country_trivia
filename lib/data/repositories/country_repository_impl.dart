import '../../core/errors/failures.dart';
import '../../domain/entities/country.dart';
import '../../domain/repositories/country_repository.dart';
import '../datasources/country_api_service.dart';
import '../datasources/country_local_data_source.dart';

class CountryRepositoryImpl implements CountryRepository {
  final CountryApiService _apiService;
  final CountryLocalDataSource _localDataSource;

  CountryRepositoryImpl({
    required CountryApiService apiService,
    required CountryLocalDataSource localDataSource,
  })  : _apiService = apiService,
        _localDataSource = localDataSource;

  @override
  Future<List<Country>> getCountries() async {
    try {
      final dtos = await _apiService.fetchAllCountries();
      return dtos.map((dto) => dto.toDomain()).toList();
    } on ServerFailure {
      final dtos = await _localDataSource.getCountriesFromAsset();
      return dtos.map((dto) => dto.toDomain()).toList();
    }
  }
}
