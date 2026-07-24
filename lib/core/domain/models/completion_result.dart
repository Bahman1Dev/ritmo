enum CompletionResult {
  full('FULL'),
  light('LIGHT'),
  minimal('MINIMAL'),
  partial('PARTIAL'),
  skipped('SKIPPED');

  const CompletionResult(this.dbValue);
  final String dbValue;

  static CompletionResult fromDb(String? v) => switch (v) {
        'FULL' || 'COMPLETED' => CompletionResult.full,
        'LIGHT'   => CompletionResult.light,
        'MINIMAL' => CompletionResult.minimal,
        'PARTIAL' => CompletionResult.partial,
        'SKIPPED' => CompletionResult.skipped,
        _ => CompletionResult.full,
      };

  /// Weight in daily rhythm calculation.
  double rhythmWeight([double? partialRatio]) => switch (this) {
        CompletionResult.full    => 1.0,
        CompletionResult.light   => 0.7,
        CompletionResult.minimal => 0.3,
        CompletionResult.partial => (partialRatio ?? 0.5).clamp(0.1, 0.9),
        CompletionResult.skipped => 0.0,
      };

  bool get keepsStreak => this != CompletionResult.skipped;
  bool get advancesProgression => this == CompletionResult.full;
}
