import 'country.dart';

class Question {
  final Country correctCountry;
  final List<Country> options;

  const Question({
    required this.correctCountry,
    required this.options,
  });

  @override
  String toString() =>
      'Question(correct: ${correctCountry.name}, options: ${options.length})';
}
