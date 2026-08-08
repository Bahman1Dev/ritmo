import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// K19 — Agenda Scale Bucketing (pure function, no DateTime.now() inside)
///
/// هفتهٔ شمسی: شنبه (Saturday) تا جمعه (Friday)
/// از CourseScheduler.getSaturdayOfWeek برای محاسبهٔ مرز هفته استفاده می‌کنیم.
enum AgendaBucket { overdue, today, tomorrow, thisWeek, nextWeek, later }

/// برچسب فارسی هر سطل
String bucketLabelFa(AgendaBucket b) {
  switch (b) {
    case AgendaBucket.overdue:
      return 'معوقه';
    case AgendaBucket.today:
      return 'امروز';
    case AgendaBucket.tomorrow:
      return 'فردا';
    case AgendaBucket.thisWeek:
      return 'این هفته';
    case AgendaBucket.nextWeek:
      return 'هفتهٔ بعد';
    case AgendaBucket.later:
      return 'بعدتر';
  }
}

/// Buckets all agenda items from [snapshots] relative to [now].
///
/// Rules (Shamsi week: Saturday → Friday):
/// - overdue   : dateStr < today  AND  completion != done/skipped
/// - today     : dateStr == today
/// - tomorrow  : dateStr == today + 1
/// - thisWeek  : dateStr in (tomorrow, endOfThisWeek]
/// - nextWeek  : dateStr in [startOfNextWeek, endOfNextWeek]
/// - later     : beyond nextWeek
///
/// Guarantee: no item appears in two buckets simultaneously.
Map<AgendaBucket, List<AgendaItem>> bucketRange(
  Map<String, DayAgendaSnapshot> snapshots, {
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  // Shamsi-week boundaries
  final thisSat = CourseScheduler.getSaturdayOfWeek(today);
  final thisFri = thisSat.add(const Duration(days: 6));
  final nextSat = thisFri.add(const Duration(days: 1));
  final nextFri = nextSat.add(const Duration(days: 6));

  // Post-tomorrow start of thisWeek: day after tomorrow up to end of this week
  final thisWeekStart = tomorrow.add(const Duration(days: 1));

  final result = <AgendaBucket, List<AgendaItem>>{
    AgendaBucket.overdue: [],
    AgendaBucket.today: [],
    AgendaBucket.tomorrow: [],
    AgendaBucket.thisWeek: [],
    AgendaBucket.nextWeek: [],
    AgendaBucket.later: [],
  };

  // Iterate snapshots in chronological order
  final sortedEntries = snapshots.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  for (final entry in sortedEntries) {
    final dateStr = entry.key;
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      continue;
    }
    final dateOnly = DateTime(date.year, date.month, date.day);

    for (final item in entry.value.items) {
      final isDone = item.completion == AgendaCompletion.done ||
          item.completion == AgendaCompletion.skipped;

      if (dateOnly.isBefore(today)) {
        // Past days — only undone items become overdue
        if (!isDone) {
          result[AgendaBucket.overdue]!.add(item);
        }
      } else if (dateOnly.isAtSameMomentAs(today)) {
        result[AgendaBucket.today]!.add(item);
      } else if (dateOnly.isAtSameMomentAs(tomorrow)) {
        result[AgendaBucket.tomorrow]!.add(item);
      } else if (!dateOnly.isBefore(thisWeekStart) &&
          !dateOnly.isAfter(thisFri)) {
        result[AgendaBucket.thisWeek]!.add(item);
      } else if (!dateOnly.isBefore(nextSat) &&
          !dateOnly.isAfter(nextFri)) {
        result[AgendaBucket.nextWeek]!.add(item);
      } else if (dateOnly.isAfter(nextFri)) {
        result[AgendaBucket.later]!.add(item);
      }
    }
  }

  return result;
}

/// Groups items within a bucket by their dateStr for sub-day headings.
/// Used by `thisWeek`, `nextWeek`, `later` buckets.
Map<String, List<AgendaItem>> groupByDate(List<AgendaItem> items) {
  final map = <String, List<AgendaItem>>{};
  for (final item in items) {
    map.putIfAbsent(item.dateStr, () => []).add(item);
  }
  return map;
}

/// Persian label for a date, used as sub-group heading inside thisWeek/nextWeek/later.
String daySubGroupLabel(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    final j = Jalali.fromDateTime(date);
    const weekdays = ['شنبه', 'یک‌شنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه'];
    // Jalali weekday: 1=Saturday, 7=Friday
    final wdLabel = weekdays[(j.weekDay - 1).clamp(0, 6)];
    return '$wdLabel ${j.day} ${j.formatter.mN}';
  } catch (_) {
    return dateStr;
  }
}
