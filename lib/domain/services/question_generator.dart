import 'dart:math';
import '../../core/constants/game_constants.dart';
import '../entities/country.dart';
import '../entities/question.dart';

class QuestionGenerator {
  final Random _random;

  QuestionGenerator({Random? random}) : _random = random ?? Random();

  Question generate(List<Country> allCountries, Set<String> playedIsoCodes) {
    // Filter out already-played countries
    var available = allCountries.where((c) => !playedIsoCodes.contains(c.isoCode)).toList();

    // Reset pool if fewer than optionsCount countries remain
    if (available.length < GameConstants.optionsCount) {
      available = List.from(allCountries);
      playedIsoCodes.clear();
    }

    // Pick correct answer
    final correct = available[_random.nextInt(available.length)];

    // Pick 3 distractors (distinct from correct and each other)
    final distractors = <Country>[];
    final pool = available.where((c) => c.isoCode != correct.isoCode).toList()..shuffle(_random);

    for (final country in pool) {
      if (distractors.length >= GameConstants.optionsCount - 1) break;
      if (!distractors.any((d) => d.name == country.name)) {
        distractors.add(country);
      }
    }

    // Combine and shuffle options
    final options = [correct, ...distractors]..shuffle(_random);

    return Question(correctCountry: correct, options: options);
  }
}
