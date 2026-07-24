/// Represents a normalized sleep / rest window block for timeline presentation.
class SleepWindowBlock {
  const SleepWindowBlock({
    required this.startMinutes,
    required this.endMinutes,
    required this.crossesMidnight,
    this.label,
    this.bedtime,
    this.wakeTime,
  });

  /// Start minute of the day (0..1439), e.g. 1410 for 23:30.
  final int startMinutes;

  /// End minute of the day (0..1439 or >=1440 if normalized past midnight), e.g. 420 or 1860.
  final int endMinutes;

  /// True if bedtime is on the target date and wake time falls on the next calendar day.
  final bool crossesMidnight;

  /// Optional label for UI rendering (e.g., "پنجره خواب" / "Sleep Window").
  final String? label;

  /// Bedtime string 'HH:mm'.
  final String? bedtime;

  /// Wake time string 'HH:mm'.
  final String? wakeTime;

  /// Duration of the sleep window in minutes.
  int get durationMinutes {
    final diff = endMinutes - startMinutes;
    return diff > 0 ? diff : diff + 1440;
  }
}

/// Helper service for resolving sleep and rest windows from settings and data.
class SleepWindowResolver {
  const SleepWindowResolver();

  /// Resolves the sleep window block for a given date using [settingsMap].
  /// Fails gracefully and returns `null` if sleep data is unavailable or disabled.
  SleepWindowBlock? resolveFromSettings(
    Map<String, String> settingsMap, {
    String defaultLabel = 'پنجره خواب',
  }) {
    final isEnabled = settingsMap['module_sleep_enabled'] == 'true';
    final bedtime = settingsMap['sleep_target_bedtime'];
    final wakeTime = settingsMap['sleep_target_wake'];

    if (!isEnabled && (bedtime == null || wakeTime == null)) {
      return null;
    }

    return resolveFromTimes(
      bedtime: bedtime ?? '23:30',
      wakeTime: wakeTime ?? '07:00',
      label: defaultLabel,
    );
  }

  /// Pure computation helper to resolve a [SleepWindowBlock] from time strings ('HH:mm').
  SleepWindowBlock? resolveFromTimes({
    required String? bedtime,
    required String? wakeTime,
    String? label,
  }) {
    if (bedtime == null || wakeTime == null) return null;

    final startM = _parseMinutes(bedtime);
    final endM = _parseMinutes(wakeTime);

    if (startM == null || endM == null) return null;

    final crossesMidnight = startM > endM;
    final normalizedEndM = crossesMidnight ? endM + 1440 : endM;

    return SleepWindowBlock(
      startMinutes: startM,
      endMinutes: normalizedEndM,
      crossesMidnight: crossesMidnight,
      label: label,
      bedtime: bedtime,
      wakeTime: wakeTime,
    );
  }

  static int? _parseMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length != 2) return null;
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      if (h < 0 || h > 23 || m < 0 || m > 59) return null;
      return (h * 60) + m;
    } catch (_) {
      return null;
    }
  }
}
