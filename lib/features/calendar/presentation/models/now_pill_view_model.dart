import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/utils/persian_digits.dart';

class NowPillViewModel {
  const NowPillViewModel({
    required this.isVisible,
    required this.isCurrent,
    this.targetItem,
    required this.statusLabel,
    required this.timeLabel,
  });

  final bool isVisible;
  final bool isCurrent;
  final AgendaItem? targetItem;
  final String statusLabel;
  final String timeLabel;

  factory NowPillViewModel.fromSnapshot(DayAgendaSnapshot? snapshot, {DateTime? now}) {
    if (snapshot == null) {
      return const NowPillViewModel(
        isVisible: false,
        isCurrent: false,
        statusLabel: '',
        timeLabel: '',
      );
    }

    final current = snapshot.currentActivity;
    final next = snapshot.nextActivity;

    if (current != null) {
      final timeStr = current.timeOfDay != null ? toPersianDigits(current.timeOfDay!) : '';
      final durStr = current.durationMinutes != null
          ? ' (${toPersianDigits(current.durationMinutes.toString())} دقیقه)'
          : '';
      return NowPillViewModel(
        isVisible: true,
        isCurrent: true,
        targetItem: current,
        statusLabel: 'NOW',
        timeLabel: '$timeStr$durStr',
      );
    }

    if (next != null) {
      final currentTime = now ?? DateTime.now();
      final currentMinutes = (currentTime.hour * 60) + currentTime.minute;
      final parts = (next.timeOfDay ?? '00:00').split(':');
      final startH = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
      final startM = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final nextStartMinutes = (startH * 60) + startM;
      final diffMinutes = nextStartMinutes - currentMinutes;

      final diffText = diffMinutes > 0
          ? 'تا ${toPersianDigits(diffMinutes.toString())} دقیقه دیگر'
          : (next.timeOfDay != null ? toPersianDigits(next.timeOfDay!) : '');
      return NowPillViewModel(
        isVisible: true,
        isCurrent: false,
        targetItem: next,
        statusLabel: 'NEXT',
        timeLabel: diffText,
      );
    }

    return const NowPillViewModel(
      isVisible: false,
      isCurrent: false,
      statusLabel: '',
      timeLabel: '',
    );
  }
}
