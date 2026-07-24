class CompletionOutcome {
  const CompletionOutcome({
    required this.didWrite,
    this.streakDelta = 0,
    this.unlockedAchievements = const [],
    this.sideEffects = const [],
    this.undoToken,
    this.errorMessage,
  });

  final bool didWrite;
  final int streakDelta;
  final List<String> unlockedAchievements;
  final List<String> sideEffects;
  final String? undoToken;
  final String? errorMessage;

  factory CompletionOutcome.failure(String message) =>
      CompletionOutcome(didWrite: false, errorMessage: message);

  factory CompletionOutcome.success({
    int streakDelta = 0,
    List<String> unlockedAchievements = const [],
    List<String> sideEffects = const [],
    String? undoToken,
  }) =>
      CompletionOutcome(
        didWrite: true,
        streakDelta: streakDelta,
        unlockedAchievements: unlockedAchievements,
        sideEffects: sideEffects,
        undoToken: undoToken,
      );
}
