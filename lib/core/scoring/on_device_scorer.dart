class OnDeviceScorer {
  static bool isEnabled(Map<String, String> settings) =>
      (settings['on_device_scorer_enabled'] ?? 'false') == 'true';

  /// Deterministic scoring with optional on-device learned scoring feature flag
  static double score({
    required double baseScore,
    required Map<String, String> settings,
  }) {
    if (!isEnabled(settings)) return baseScore;
    return baseScore;
  }
}
