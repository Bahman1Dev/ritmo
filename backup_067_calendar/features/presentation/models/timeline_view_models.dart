import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/sleep_window_resolver.dart';

/// Presentation view model representing a single day's timeline state.
class DailyTimelineViewModel {
  const DailyTimelineViewModel({
    required this.dateStr,
    required this.timedItems,
    required this.untimedItems,
    this.sleepWindow,
    this.currentTimeMinutes,
  });

  final String dateStr;
  final List<AgendaItem> timedItems;
  final List<AgendaItem> untimedItems;
  final SleepWindowBlock? sleepWindow;
  final int? currentTimeMinutes;

  /// Builds a [DailyTimelineViewModel] directly from a [DayAgenda].
  factory DailyTimelineViewModel.fromAgenda(
    DayAgenda dayAgenda, {
    SleepWindowBlock? sleepWindow,
    DateTime? now,
  }) {
    final timed = <AgendaItem>[];
    final untimed = <AgendaItem>[];

    for (final item in dayAgenda.items) {
      if (item.isTimed) {
        timed.add(item);
      } else {
        untimed.add(item);
      }
    }

    int? nowMinutes;
    if (now != null) {
      final ds = now.toIso8601String().substring(0, 10);
      if (ds == dayAgenda.dateStr) {
        nowMinutes = (now.hour * 60) + now.minute;
      }
    }

    return DailyTimelineViewModel(
      dateStr: dayAgenda.dateStr,
      timedItems: timed,
      untimedItems: untimed,
      sleepWindow: sleepWindow,
      currentTimeMinutes: nowMinutes,
    );
  }

  bool get hasTimedItems => timedItems.isNotEmpty;
  bool get hasUntimedItems => untimedItems.isNotEmpty;
  bool get isCurrentDay => currentTimeMinutes != null;
}
