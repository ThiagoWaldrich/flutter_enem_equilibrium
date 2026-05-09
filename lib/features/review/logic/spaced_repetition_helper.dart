class SpacedRepetitionHelper {
  static int getNextInterval(int qualityScore) {
    switch (qualityScore) {
      case 1: return 1;   // Muito difícil
      case 2: return 2;   // Difícil
      case 3: return 7;   // Bom
      case 4: return 14;  // Muito bom
      default: return 7;
    }
  }

  static double calculateMastery(double currentMastery, int qualityScore) {
    const sessionWeight = 0.3;
    const historyWeight = 0.7;
    final sessionMastery = qualityScore / 4.0;
    return (sessionMastery * sessionWeight + currentMastery * historyWeight).clamp(0.0, 1.0);
  }
}