import '../../core/constants/game_constants.dart';

class ScoreCalculator {
  static int calculatePoints(int attemptNumber) {
    if (attemptNumber < 1 || attemptNumber > GameConstants.maxAttempts) {
      return GameConstants.pointsForFailure;
    }
    return GameConstants.pointsPerAttempt[attemptNumber - 1];
  }
}
