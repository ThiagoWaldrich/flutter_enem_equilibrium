// lib/features/review/logic/spaced_repetition_helper.dart
class SpacedRepetitionHelper {
  const SpacedRepetitionHelper._();

  static const Map<int, int> _intervals = {
    1: 1,
    2: 2,
    3: 7,
    4: 14,
  };

  static int getNextIntervalInDays(int qualityScore) {
    return _intervals[qualityScore] ?? 7;
  }

  static double calculateNewMastery(double currentMastery, int qualityScore) {
    const sessionWeight = 0.3;
    const historyWeight = 0.7;
    final sessionMastery = (qualityScore - 1) / 3.0;
    return (sessionMastery * sessionWeight + currentMastery * historyWeight)
        .clamp(0.0, 1.0);
  }

  static bool isOverdue(DateTime nextReviewDate) {
    return DateTime.now().isAfter(nextReviewDate);
  }
}