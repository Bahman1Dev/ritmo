import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/sleep_window_resolver.dart';

class TimeGap {
  const TimeGap({
    required this.startMinutes,
    required this.endMinutes,
    this.qualityScore = 0.5,
    this.qualityTag = '',
  }) : durationMinutes = endMinutes - startMinutes;

  final int startMinutes;
  final int endMinutes;
  final int durationMinutes;
  final double qualityScore;
  final String qualityTag;

  String get startTimeStr => _formatMinutes(startMinutes);
  String get endTimeStr => _formatMinutes(endMinutes);

  /// Returns true if this gap is large enough to host a meaningful activity (>= 15 mins).
  bool get isUsable => durationMinutes >= 15;

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

  List<TimeGap> calculateFreeGaps(
    List<AgendaItem> items, {
    DateTime? now,
    SleepWindowBlock? sleepWindow,
  }) {
    final timedItems = items.where((i) => i.isTimed).toList();
    final rawGaps = <_TimeInterval>[];

    if (timedItems.isEmpty) {
      if (wakingEndMinutes > wakingStartMinutes) {
        rawGaps.add(_TimeInterval(wakingStartMinutes, wakingEndMinutes));
      }
    } else {
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

      var currentPointer = wakingStartMinutes;
      for (final block in merged) {
        if (block.start > currentPointer) {
          final gapEnd = block.start < wakingEndMinutes ? block.start : wakingEndMinutes;
          if (gapEnd > currentPointer) {
            rawGaps.add(_TimeInterval(currentPointer, gapEnd));
          }
        }
        if (block.end > currentPointer) {
          currentPointer = block.end;
        }
      }

      if (currentPointer < wakingEndMinutes) {
        rawGaps.add(_TimeInterval(currentPointer, wakingEndMinutes));
      }
    }

    final scoredGaps = <TimeGap>[];
    for (final raw in rawGaps) {
      final gapDuration = raw.end - raw.start;
      if (gapDuration < 10) continue; // Suppress micro tiny gaps

      final score = _computeGapQualityScore(
        startM: raw.start,
        endM: raw.end,
        durationM: gapDuration,
        now: now,
        sleepWindow: sleepWindow,
      );

      final tag = _deriveQualityTag(gapDuration, score);

      scoredGaps.add(TimeGap(
        startMinutes: raw.start,
        endMinutes: raw.end,
        qualityScore: score,
        qualityTag: tag,
      ));
    }

    scoredGaps.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
    return scoredGaps;
  }

  static double _computeGapQualityScore({
    required int startM,
    required int endM,
    required int durationM,
    DateTime? now,
    SleepWindowBlock? sleepWindow,
  }) {
    var score = 0.5;

    // 1. Duration sufficiency (30..120 mins is prime)
    if (durationM >= 45) {
      score += 0.3;
    } else if (durationM >= 30) {
      score += 0.2;
    } else if (durationM < 15) {
      score -= 0.3;
    }

    // 2. Daytime waking hour preference (08:00 to 20:00 = 480..1200)
    if (startM >= 480 && endM <= 1200) {
      score += 0.15;
    } else if (startM < 420 || endM > 1320) {
      score -= 0.2;
    }

    // 3. Proximity to current time (if today)
    if (now != null) {
      final nowM = (now.hour * 60) + now.minute;
      if (endM <= nowM) {
        score -= 0.4; // Past gap
      } else if (startM >= nowM && startM <= nowM + 180) {
        score += 0.1; // Near future gap
      }
    }

    // 4. Sleep window overlap penalty
    if (sleepWindow != null) {
      if (startM < sleepWindow.endMinutes && endM > sleepWindow.startMinutes) {
        score -= 0.5;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  static String _deriveQualityTag(int durationM, double score) {
    if (score < 0.3) return 'فرصت کم‌کیفیت';
    if (durationM >= 45) return 'فرصت عالی (تمرکز/ورزش)';
    if (durationM >= 30) return 'فرصت مناسب';
    return 'فرصت کوتاه';
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
