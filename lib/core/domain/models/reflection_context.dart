/// Direction of the user's recent mood trend.
enum MoodTrendDirection { up, flat, down }

/// A compact, read-only summary of the self-reflection signal, passed into
/// `RitmoIntelligenceEngine` so suggestions can soften on low/declining mood.
///
/// Built in `DashboardController` from `ReflectionEngine` output. Kept tiny and
/// nullable on purpose: when null, the intelligence engine behaves exactly as
/// before (backward compatible).
class ReflectionContext {

  const ReflectionContext({
    required this.avgMoodScore,
    required this.moodTrendDirection,
    required this.currentStreak,
    this.reflectionEnergyCorrelation,
  });
  /// Average mood score over the reflection horizon (engine scale, ~1..5).
  final double avgMoodScore;

  final MoodTrendDirection moodTrendDirection;

  final int currentStreak;

  /// Pearson correlation between reflection and energy, if enough samples.
  final double? reflectionEnergyCorrelation;

  /// True when the engine should bias toward a gentler day: low average mood
  /// or a clearly downward trend.
  bool get wantsGentleMode =>
      avgMoodScore < 2.6 || moodTrendDirection == MoodTrendDirection.down;
}
