import 'package:ritmo/core/domain/agenda/agenda_item.dart';

class AgendaOverloadDetector {
  const AgendaOverloadDetector({
    this.wakingWindowMinutes = 960, // 16 hours waking time
  });

  final int wakingWindowMinutes;

  /// Computes overall capacity overload score (0.0 = empty, > 1.0 = overloaded).
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

  /// Identifies peak overloaded hour blocks (0..23) where scheduled minutes >= 45 mins.
  Set<int> findOverloadedHourBlocks(List<AgendaItem> items) {
    final hourMinutes = <int, int>{};
    final timed = items.where((i) => i.isTimed && !i.isCompleted).toList();

    for (final item in timed) {
      final startM = _parseStartMinutes(item.timeOfDay);
      final durM = (item.durationMinutes ?? 0) <= 0 ? 30 : item.durationMinutes!;
      final endM = startM + durM;

      for (var m = startM; m < endM; m += 15) {
        final hour = (m ~/ 60) % 24;
        hourMinutes[hour] = (hourMinutes[hour] ?? 0) + 15;
      }
    }

    final overloaded = <int>{};
    for (final entry in hourMinutes.entries) {
      if (entry.value >= 45) {
        overloaded.add(entry.key);
      }
    }
    return overloaded;
  }

  /// Checks if placing a slot at [startMinutes] with [durationMinutes] hits an overloaded hour block.
  bool isSlotOverloaded(int startMinutes, int durationMinutes, List<AgendaItem> items) {
    final overloadedHours = findOverloadedHourBlocks(items);
    final startHour = (startMinutes ~/ 60) % 24;
    final endHour = ((startMinutes + durationMinutes) ~/ 60) % 24;

    for (var h = startHour; h <= endHour; h++) {
      if (overloadedHours.contains(h)) return true;
    }
    return false;
  }

  static int _parseStartMinutes(String? timeOfDay) {
    if (timeOfDay == null) return 0;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeOfDay.trim());
    if (match == null) return 0;
    final h = int.tryParse(match.group(1)!) ?? 0;
    final m = int.tryParse(match.group(2)!) ?? 0;
    return (h * 60) + m;
  }
}
