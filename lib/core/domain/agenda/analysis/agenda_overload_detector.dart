import 'package:ritmo/core/domain/agenda/agenda_item.dart';

class AgendaOverloadDetector {
  const AgendaOverloadDetector({
    this.wakingWindowMinutes = 960, // 16 hours waking time
  });

  final int wakingWindowMinutes;

  double calculateOverloadScore(List<AgendaItem> items) {
    if (items.isEmpty || wakingWindowMinutes <= 0) return 0.0;

    var totalMinutes = 0;
    for (final item in items) {
      if (item.isCompleted && item.completion == AgendaCompletion.skipped) {
        continue;
      }
      final duration = item.durationMinutes ?? (item.isTimed ? 30 : 15);
      totalMinutes += duration;
    }

    final rawRatio = totalMinutes / wakingWindowMinutes;
    return double.parse(rawRatio.toStringAsFixed(2));
  }
}
