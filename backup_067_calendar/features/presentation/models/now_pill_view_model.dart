import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/relative_time_formatter.dart';

class NowPillViewModel {
  const NowPillViewModel({
    required this.isVisible,
    required this.isCurrent,
    this.targetItem,
    required this.statusLabel,
    required this.timeLabel,
    this.isOverdue = false,
    this.isToday = true,
  });

  final bool isVisible;
  final bool isCurrent;
  final AgendaItem? targetItem;
  final String statusLabel;
  final String timeLabel;
  final bool isOverdue;
  final bool isToday;

  const NowPillViewModel.hidden()
      : isVisible = false,
        isCurrent = false,
        targetItem = null,
        statusLabel = '',
        timeLabel = '',
        isOverdue = false,
        isToday = true;

  factory NowPillViewModel.fromSnapshot(
    DayAgendaSnapshot? snapshot, {
    required DateTime now,
    required bool isToday,
    DateTime? selectedDate,
  }) {
    if (snapshot == null) {
      return const NowPillViewModel.hidden();
    }

    final targetDate = selectedDate ?? now;
    final nowMidnight = DateTime(now.year, now.month, now.day);
    final targetMidnight = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final isPastDay = targetMidnight.isBefore(nowMidnight);
    final isFutureDay = targetMidnight.isAfter(nowMidnight);

    // Past Day Mode
    if (isPastDay) {
      final total = snapshot.items.length;
      final done = snapshot.completedCount;
      if (total == 0) return const NowPillViewModel.hidden();

      return NowPillViewModel(
        isVisible: true,
        isCurrent: false,
        targetItem: null,
        statusLabel: 'REVIEW',
        timeLabel: '${toPersianDigits(done)} از ${toPersianDigits(total)} انجام شد',
        isToday: false,
      );
    }

    // Future Day Mode
    if (isFutureDay) {
      final total = snapshot.items.length;
      if (total == 0) return const NowPillViewModel.hidden();

      final firstItem = snapshot.items.firstWhere(
        (i) => i.timeOfDay != null,
        orElse: () => snapshot.items.first,
      );

      final firstTimeStr = firstItem.timeOfDay != null ? toPersianDigits(firstItem.timeOfDay!) : '';
      final label = firstTimeStr.isNotEmpty
          ? '${toPersianDigits(total)} برنامه · اولین: $firstTimeStr'
          : '${toPersianDigits(total)} برنامه';

      return NowPillViewModel(
        isVisible: true,
        isCurrent: false,
        targetItem: firstItem,
        statusLabel: 'SUMMARY',
        timeLabel: label,
        isToday: false,
      );
    }

    // Today Mode (isToday == true)
    final current = snapshot.currentActivity;
    final next = snapshot.nextActivity;

    if (current != null) {
      final timeStr = current.timeOfDay != null ? toPersianDigits(current.timeOfDay!) : '';
      final durMinutes = DurationBounds.sanitize(current.durationMinutes);
      final durStr = ' (${RelativeTimeFormatter.durationFa(durMinutes)})';

      return NowPillViewModel(
        isVisible: true,
        isCurrent: true,
        targetItem: current,
        statusLabel: 'NOW',
        timeLabel: '$timeStr$durStr',
        isToday: true,
      );
    }

    if (next != null) {
      final itemTargetTime = _resolveItemStart(next);
      if (itemTargetTime == null) {
        return const NowPillViewModel.hidden();
      }

      final isOverdue = itemTargetTime.isBefore(now) && !next.isCompleted;
      final relativeTimeStr = RelativeTimeFormatter.untilFa(itemTargetTime, now: now);

      return NowPillViewModel(
        isVisible: true,
        isCurrent: false,
        targetItem: next,
        statusLabel: 'NEXT',
        timeLabel: relativeTimeStr,
        isOverdue: isOverdue,
        isToday: true,
      );
    }

    // No current or next activity left today
    if (snapshot.completedCount > 0 && snapshot.remainingCount == 0) {
      return const NowPillViewModel(
        isVisible: true,
        isCurrent: false,
        targetItem: null,
        statusLabel: 'DONE',
        timeLabel: 'برنامه‌های امروز تمام شد 🌙',
        isToday: true,
      );
    }

    return const NowPillViewModel.hidden();
  }

  static DateTime? _resolveItemStart(AgendaItem item) {
    final date = DateTime.tryParse(item.dateStr);
    if (date == null) return null;
    final timeStr = item.timeOfDay;
    if (timeStr == null || timeStr.isEmpty) return null;

    final parts = timeStr.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

    return DateTime(date.year, date.month, date.day, h, m);
  }
}
