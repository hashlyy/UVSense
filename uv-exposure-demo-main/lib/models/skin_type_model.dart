enum SkinType { I, II, III, IV, V, VI }

class SkinTypeModel {
  final int geneticScore;
  final int reactionScore;
  final int pigmentationScore;
  final int habitsScore;
  final int totalScore;
  final SkinType skinType;

  SkinTypeModel({
    required this.geneticScore,
    required this.reactionScore,
    required this.pigmentationScore,
    required this.habitsScore,
    required this.totalScore,
    required this.skinType,
  });

  static SkinType getSkinTypeFromScore(int score) {
    if (score <= 10) return SkinType.I;
    if (score <= 18) return SkinType.II;
    if (score <= 26) return SkinType.III;
    if (score <= 34) return SkinType.IV;
    if (score <= 42) return SkinType.V;
    return SkinType.VI;
  }

  @override
  String toString() {
    return 'SkinTypeModel(score: $totalScore, type: ${skinType.name})';
  }
}
