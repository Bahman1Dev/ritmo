/// Represents the current life context of the user.
enum LifeContext {
  /// Normal daily context
  normal,

  /// Travel context
  travel,

  /// Sick context
  sick,

  /// Exam context
  exam,

  /// Busy context
  busy,

  /// Worship context
  worship,
}

/// Represents daily behavior configuration based on life context.
class DailyBehavior {
  /// Creates a [DailyBehavior] instance.
  DailyBehavior({
    required this.context,
    required this.behavior,
    this.activeWorshipSeasonTitle,
  });

  /// Active life context.
  final LifeContext context;

  /// Behavior mode ('NORMAL', 'SILENCE_ALL', 'ESSENTIAL_ONLY').
  final String behavior;

  /// Active worship season title if any (e.g. "Ramadan").
  final String? activeWorshipSeasonTitle;
}
