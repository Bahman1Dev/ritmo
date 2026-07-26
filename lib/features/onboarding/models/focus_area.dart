enum FocusArea {
  health('HEALTH', 'سلامتی'),
  sport('SPORT', 'ورزش'),
  study('STUDY', 'درس'),
  work('WORK', 'کار'),
  income('INCOME', 'کسب درآمد'),
  family('FAMILY', 'خانواده'),
  worship('WORSHIP', 'عبادت'),
  sleep('SLEEP', 'خواب'),
  stress('STRESS', 'کاهش استرس'),
  skill('SKILL', 'یادگیری مهارت');

  const FocusArea(this.code, this.faLabel);

  final String code;
  final String faLabel;

  /// Returns [FocusArea] by code or null if invalid.
  static FocusArea? fromCode(String raw) {
    for (final area in FocusArea.values) {
      if (area.code.toUpperCase() == raw.trim().toUpperCase()) {
        return area;
      }
    }
    return null;
  }

  /// Backward compatibility with legacy Persian string labels (Stop Condition S-E).
  static FocusArea? fromLegacyFaLabel(String raw) {
    for (final area in FocusArea.values) {
      if (area.faLabel.trim() == raw.trim()) {
        return area;
      }
    }
    return null;
  }

  /// Flexible parser accepting either code or legacy FA label.
  static FocusArea? parse(String raw) {
    return fromCode(raw) ?? fromLegacyFaLabel(raw);
  }
}
