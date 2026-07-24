import 'package:ritmo/core/domain/agenda/agenda_item.dart';

class TimeGap {
  const TimeGap({
    required this.startMinutes,
    required this.endMinutes,
  }) : durationMinutes = endMinutes - startMinutes;

  final int startMinutes;
  final int endMinutes;
  final int durationMinutes;

  String get startTimeStr => _formatMinutes(startMinutes);
  String get endTimeStr => _formatMinutes(endMinutes);

  static String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class AgendaGapCalculator {
  const AgendaGapCalculator({
    this.wakingStartMinutes = 420, // 07:00
    this.wakingEndMinutes = 1380,  // 23:00
  });

  final int wakingStartMinutes;
  final int wakingEndMinutes;

  List<TimeGap> calculateFreeGaps(List<AgendaItem> items) {
    final timedItems = items.where((i) => i.isTimed).toList();
    if (timedItems.isEmpty) {
      if (wakingEndMinutes > wakingStartMinutes) {
        return [TimeGap(startMinutes: wakingStartMinutes, endMinutes: wakingEndMinutes)];
      }
      return [];
    }

    final intervals = <_TimeInterval>[];
    for (final item in timedItems) {
      final start = _parseStartMinutes(item.timeOfDay!);
      final duration = (item.durationMinutes ?? 0) <= 0 ? 15 : item.durationMinutes!;
      intervals.add(_TimeInterval(start, start + duration));
    }

    intervals.sort((a, b) => a.start.compareTo(b.start));

    final merged = <_TimeInterval>[];
    for (final interval in intervals) {
      if (merged.isEmpty) {
        merged.add(interval);
      } else {
        final last = merged.last;
        if (interval.start <= last.end) {
          merged[merged.length - 1] = _TimeInterval(
            last.start,
            interval.end > last.end ? interval.end : last.end,
          );
        } else {
          merged.add(interval);
        }
      }
    }

    final gaps = <TimeGap>[];
    var currentPointer = wakingStartMinutes;

    for (final block in merged) {
      if (block.start > currentPointer) {
        final gapEnd = block.start < wakingEndMinutes ? block.start : wakingEndMinutes;
        if (gapEnd > currentPointer) {
          gaps.add(TimeGap(startMinutes: currentPointer, endMinutes: gapEnd));
        }
      }
      if (block.end > currentPointer) {
        currentPointer = block.end;
      }
    }

    if (currentPointer < wakingEndMinutes) {
      gaps.add(TimeGap(startMinutes: currentPointer, endMinutes: wakingEndMinutes));
    }

    return gaps;
  }

  static int _parseStartMinutes(String timeOfDay) {
    final parts = timeOfDay.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (h * 60) + m;
  }
}

class _TimeInterval {
  const _TimeInterval(this.start, this.end);
  final int start;
  final int end;
}
