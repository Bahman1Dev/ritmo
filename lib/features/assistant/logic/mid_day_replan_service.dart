// lib/features/assistant/logic/mid_day_replan_service.dart

import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/features/assistant/models/day_plan_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MidDayReplanService {
  MidDayReplanService._();
  static final MidDayReplanService instance = MidDayReplanService._();

  // Configurable thresholds
  static const int minSlippedItems = 2;
  static const int minSlippedMinutes = 45;
  static const int maxSuggestionsPerDay = 2;
  static const int coolDownHours = 3;

  /// Checks if the user is eligible for a replan suggestion today.
  Future<bool> shouldSuggestReplan() async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // 1. Anti-spam checks
    final prefs = await SharedPreferences.getInstance();
    final suggestCount = prefs.getInt('replan_suggest_count_$todayStr') ?? 0;
    if (suggestCount >= maxSuggestionsPerDay) {
      return false;
    }

    final lastRejectMs = prefs.getInt('replan_last_reject_ts') ?? 0;
    if (lastRejectMs > 0) {
      final lastReject = DateTime.fromMillisecondsSinceEpoch(lastRejectMs);
      if (now.difference(lastReject).inHours < coolDownHours) {
        return false;
      }
    }

    // 2. Fetch today's agenda
    final agenda = await DayAgendaService.instance.agendaForDate(now);
    final slipped = _getSlippedItems(agenda.items, now);

    if (slipped.isEmpty) return false;

    // Check thresholds: slipped items count or total minutes
    final totalSlippedMins = slipped.fold<int>(0, (sum, item) => sum + (item.durationMinutes ?? 30));
    if (slipped.length >= minSlippedItems || totalSlippedMins >= minSlippedMinutes) {
      return true;
    }

    return false;
  }

  /// Records suggestion display to enforce limits.
  Future<void> recordSuggestionShown() async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();
    final suggestCount = prefs.getInt('replan_suggest_count_$todayStr') ?? 0;
    await prefs.setInt('replan_suggest_count_$todayStr', suggestCount + 1);
  }

  /// Records user rejection to trigger cooldown.
  Future<void> recordUserRejected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('replan_last_reject_ts', DateTime.now().millisecondsSinceEpoch);
  }

  /// Computes the replanned schedule using a local deterministic greedy packing algorithm.
  Future<DayPlanDraft?> computeReplan() async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // Fetch today's agenda
    final agenda = await DayAgendaService.instance.agendaForDate(now);
    
    // Identify uncompleted items (both already slipped and upcoming today)
    final remainingItems = agenda.items.where((item) {
      return item.completion == AgendaCompletion.pending && item.timeOfDay != null;
    }).toList();

    if (remainingItems.isEmpty) return null;

    // Sort remaining items: Essential first, then priority (descending), then original time
    remainingItems.sort((a, b) {
      if (a.isEssential != b.isEssential) {
        return a.isEssential ? -1 : 1;
      }
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return (a.timeOfDay ?? '').compareTo(b.timeOfDay ?? '');
    });

    // Determine current time boundary to start packing (round to nearest 15 mins ahead)
    var packStart = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final minuteMod = packStart.minute % 15;
    if (minuteMod != 0) {
      packStart = packStart.add(Duration(minutes: 15 - minuteMod));
    }

    // Get bedtime setting
    final db = await DatabaseHelper.instance.database;
    final settings = await db.query('app_settings', where: 'key = ?', whereArgs: ['sleep_target_bedtime'], limit: 1);
    final bedtimeStr = settings.isNotEmpty ? settings.first['value']! as String : '23:30';
    final parts = bedtimeStr.split(':');
    final bedtimeHour = int.tryParse(parts[0]) ?? 23;
    final bedtimeMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 30) : 30;
    final bedtime = DateTime(now.year, now.month, now.day, bedtimeHour, bedtimeMin);

    final replannedDraftItems = <DayPlanItemDraft>[];
    var currentPointer = packStart;

    for (final item in remainingPointer(remainingItems)) {
      final duration = item.durationMinutes ?? 30;
      final originalTime = item.timeOfDay;

      if (currentPointer.add(Duration(minutes: duration)).isAfter(bedtime)) {
        // Doesn't fit today anymore. Flag to move to tomorrow
        final note = originalTime != null ? 'تغییر زمان از $originalTime (انتقال به فردا به دلیل کمبود وقت)' : 'انتقال به فردا';
        replannedDraftItems.add(DayPlanItemDraft(
          title: item.title,
          targetModule: _mapDomainToModule(item.domain),
          startKind: 'clock',
          startTime: '09:00', // default tomorrow start time
          durationMin: duration,
          durationSource: 'llm',
          recurrence: 'oneOff',
          category: item.category.name,
          note: note,
        ));
      } else {
        // Fits today. Calculate new start time
        final newStartStr = _formatTime(currentPointer);
        final note = originalTime != null && originalTime != newStartStr ? 'جابه‌جا شد از $originalTime' : null;

        replannedDraftItems.add(DayPlanItemDraft(
          title: item.title,
          targetModule: _mapDomainToModule(item.domain),
          startKind: 'clock',
          startTime: newStartStr,
          durationMin: duration,
          durationSource: 'llm',
          recurrence: 'oneOff',
          category: item.category.name,
          note: note,
          resolvedTime: newStartStr,
        ));

        currentPointer = currentPointer.add(Duration(minutes: duration));
      }
    }

    final draft = DayPlanDraft(
      planDate: todayStr,
      items: replannedDraftItems,
      questions: [],
      suggestions: [
        DayPlanSuggestion(
          text: 'برنامه باقی‌مانده روز شما بر اساس اولویت کارها مجدداً چیده شد.',
          action: 'applyReplan',
        ),
      ],
    );

    return draft;
  }

  // Iterable wrapper to handle list during packing loop
  Iterable<AgendaItem> remainingPointer(List<AgendaItem> items) sync* {
    for (final item in items) {
      yield item;
    }
  }

  List<AgendaItem> _getSlippedItems(List<AgendaItem> items, DateTime now) {
    return items.where((item) {
      if (item.timeOfDay == null || item.completion != AgendaCompletion.pending) {
        return false;
      }
      final parts = item.timeOfDay!.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final min = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final startTime = DateTime(now.year, now.month, now.day, hour, min);
      final endTime = startTime.add(Duration(minutes: item.durationMinutes ?? 30));

      return endTime.isBefore(now);
    }).toList();
  }

  String _mapDomainToModule(AgendaDomain domain) {
    switch (domain) {
      case AgendaDomain.routine: return 'routine';
      case AgendaDomain.prayer: return 'worship';
      case AgendaDomain.mustahab: return 'worship';
      default: return 'task';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
