enum SnoozeVerdict { allowed, lastCall, exhausted, blockedMedical, blockedMidnight }
enum ExitOption { doMinimalNow, lastWindowTonight, moveToTomorrow, skipWithReason }

class SnoozeDecision {
  final SnoozeVerdict verdict;
  final int allowedMinutes;
  final DateTime? snoozeUntil;
  final int deferCount;
  final int remaining;
  final String? userMessage;
  final List<ExitOption> exits;

  const SnoozeDecision({
    required this.verdict,
    this.allowedMinutes = 0,
    this.snoozeUntil,
    required this.deferCount,
    required this.remaining,
    this.userMessage,
    this.exits = const [],
  });
}

class SnoozePolicy {
  SnoozePolicy._();

  static int maxCap({String? category, int? isEssential, int configuredMax = 3}) {
    if (category == 'medical' || isEssential == 1) {
      return 2;
    }
    return configuredMax;
  }

  /// Pure function to evaluate a snooze request against policies and return a SnoozeDecision.
  static SnoozeDecision evaluate({
    required String itemId,
    required DateTime now,
    required int requestedMinutes,
    required int currentDeferCount,
    String? category,
    int? isEssential,
    int configuredMax = 3,
    String? recurrenceRuleType,
  }) {
    final cap = maxCap(category: category, isEssential: isEssential, configuredMax: configuredMax);

    // 1. Check Midnight Guard
    final midnight = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final targetTime = now.add(Duration(minutes: requestedMinutes));

    if (targetTime.isAfter(midnight)) {
      final exits = <ExitOption>[
        ExitOption.doMinimalNow,
        if (recurrenceRuleType != 'EVERY_DAY') ExitOption.moveToTomorrow,
        ExitOption.skipWithReason,
      ];
      return SnoozeDecision(
        verdict: SnoozeVerdict.blockedMidnight,
        deferCount: currentDeferCount,
        remaining: 0,
        userMessage: 'زمان جدید از نیمه‌شب می‌گذرد.',
        exits: exits,
      );
    }

    // 2. Check Exhausted Cap
    if (currentDeferCount >= cap) {
      final exits = <ExitOption>[
        ExitOption.doMinimalNow,
        ExitOption.lastWindowTonight,
        if (recurrenceRuleType != 'EVERY_DAY') ExitOption.moveToTomorrow,
        ExitOption.skipWithReason,
      ];
      return SnoozeDecision(
        verdict: SnoozeVerdict.exhausted,
        deferCount: currentDeferCount,
        remaining: 0,
        userMessage: 'سقف تعویق این آیتم پر شده است.',
        exits: exits,
      );
    }

    // 3. Allowed or Last Call
    final newDeferCount = currentDeferCount + 1;
    final remaining = cap - newDeferCount;
    final verdict = remaining == 0 ? SnoozeVerdict.lastCall : SnoozeVerdict.allowed;

    return SnoozeDecision(
      verdict: verdict,
      allowedMinutes: requestedMinutes,
      snoozeUntil: targetTime,
      deferCount: newDeferCount,
      remaining: remaining,
      exits: const [],
    );
  }
}
