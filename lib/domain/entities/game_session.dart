import 'question.dart';

enum RoundState {
  inProgress,
  answeredCorrectly,
  revealed,
}

class GameSession {
  final int score;
  final Question? currentQuestion;
  final int attemptsLeft;
  final RoundState roundState;

  const GameSession({
    this.score = 0,
    this.currentQuestion,
    this.attemptsLeft = 3,
    this.roundState = RoundState.inProgress,
  });

  GameSession copyWith({
    int? score,
    Question? currentQuestion,
    int? attemptsLeft,
    RoundState? roundState,
  }) {
    return GameSession(
      score: score ?? this.score,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
      roundState: roundState ?? this.roundState,
    );
  }

  @override
  String toString() =>
      'GameSession(score: $score, attemptsLeft: $attemptsLeft, state: $roundState)';
}
