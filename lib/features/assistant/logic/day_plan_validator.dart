// lib/features/assistant/logic/day_plan_validator.dart

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';
import 'package:ritmo/features/assistant/models/day_plan_models.dart';

class DayPlanValidator {
  /// Resolves relative times, calculates durations, and detects conflicts.
  static Future<DayPlanDraft> validateAndEnrich({
    required DayPlanDraft draft,
  }) async {
    final date = DateTime.tryParse(draft.planDate) ?? DateTime.now();
    
    // 1. Fetch settings and prayer times
    final db = await DatabaseHelper.instance.database;
    final settings = await db.query('app_settings');
    final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};

    final cityId = settingsMap['prayer_city_id'] ?? settingsMap['home_city_id'] ?? 'TEHRAN_TEHRAN';
    
    Map<String, String>? prayerTimes;
    try {
      prayerTimes = await PrayerTimeProvider.instance.getPrayerTimesForDate(
        cityId: cityId,
        date: date,
      );
    } catch (e) {
      debugPrint('[DayPlanValidator] PrayerTimeProvider error: $e');
    }

    final sleepTargetWake = settingsMap['sleep_target_wake'] ?? '07:00';
    final sleepTargetBedtime = settingsMap['sleep_target_bedtime'] ?? '23:30';

    // 2. Load existing agenda items for conflict check
    var existingItems = <dynamic>[];
    try {
      final agenda = await DayAgendaService.instance.agendaForDate(date);
      existingItems = agenda.items;
    } catch (e) {
      debugPrint('[DayPlanValidator] DayAgendaService query error: $e');
    }

    // 2.5 Consolidate separate prayers into joint prayers (Dhuhr+Asr, Maghrib+Isha)
    final itemsToProcess = _consolidatePrayers(draft.items);

    // 3. Resolve start times and end times sequentially
    DateTime? lastEndTime;
    final enrichedItems = <DayPlanItemDraft>[];

    for (var i = 0; i < itemsToProcess.length; i++) {
      final item = itemsToProcess[i];
      DateTime? startTime;

      if (item.startKind == 'clock') {
        if (item.startTime != null && item.startTime!.isNotEmpty) {
          startTime = _parseTimeOfDay(date, item.startTime!);
        }
      } else if (item.startKind == 'anchor') {
        final anchor = item.anchorEvent?.toUpperCase() ?? 'WAKEUP';
        String? baseTimeStr;

        if (anchor == 'WAKEUP') {
          baseTimeStr = sleepTargetWake;
        } else if (anchor == 'BEDTIME') {
          baseTimeStr = sleepTargetBedtime;
        } else if (prayerTimes != null) {
          baseTimeStr = prayerTimes[anchor.toLowerCase()];
        }

        if (baseTimeStr != null && baseTimeStr.isNotEmpty) {
          final baseTime = _parseTimeOfDay(date, baseTimeStr);
          startTime = baseTime.add(Duration(minutes: item.offsetMin));
        }
      } else if (item.startKind == 'after_previous') {
        if (lastEndTime != null) {
          startTime = lastEndTime.add(Duration(minutes: item.bufferMin));
        } else {
          // If first item is chain, default to wakeup target
          startTime = _parseTimeOfDay(date, sleepTargetWake).add(Duration(minutes: item.bufferMin));
        }
      }

      // Fallback if could not resolve time
      startTime ??= _parseTimeOfDay(date, '08:00');

      // Update item model
      item.resolvedTime = _formatTime(startTime);
      enrichedItems.add(item);

      // Save end time for next chain
      final duration = item.durationMin ?? 30; // default duration to 30 mins if null
      lastEndTime = startTime.add(Duration(minutes: duration));
    }

    // 4. Overlap & Travel buffer detection
    for (var i = 0; i < enrichedItems.length; i++) {
      final item = enrichedItems[i];
      if (item.resolvedTime == null) continue;

      final start = _parseTimeOfDay(date, item.resolvedTime!);
      final duration = item.durationMin ?? 30;
      final end = start.add(Duration(minutes: duration));

      final conflicts = <String>[];

      // A. Overlaps with existing agenda items
      for (final existing in existingItems) {
        if (existing.timeOfDay == null) continue;
        
        final exStart = _parseTimeOfDay(date, existing.timeOfDay!);
        // Assume default 30 min duration for existing items if not specified
        final exDuration = existing.durationMinutes ?? 30;
        final exEnd = exStart.add(Duration(minutes: exDuration));

        // Overlap condition: startA < endB and startB < endA
        if (start.isBefore(exEnd) && exStart.isBefore(end)) {
          conflicts.add('تداخل با برنامه "${existing.title}"');
        }
      }

      // B. Overlaps with other drafted items in the same compose run
      for (var j = 0; j < enrichedItems.length; j++) {
        if (i == j) continue;
        final other = enrichedItems[j];
        if (other.resolvedTime == null) continue;

        final otherStart = _parseTimeOfDay(date, other.resolvedTime!);
        final otherDuration = other.durationMin ?? 30;
        final otherEnd = otherStart.add(Duration(minutes: otherDuration));

        if (start.isBefore(otherEnd) && otherStart.isBefore(end)) {
          conflicts.add('همپوشانی با "${other.title}" در پیش‌نویس');
        }
      }

      // Add conflicts to note
      if (conflicts.isNotEmpty) {
        final conflictMsg = '⚠️ ${conflicts.join('، ')}';
        item.note = item.note != null && item.note!.isNotEmpty
            ? '${item.note}\n$conflictMsg'
            : conflictMsg;
      }
    }

    // 5. Add Travel Buffer suggestions & Bedtime recommendations
    final suggestions = List<DayPlanSuggestion>.from(draft.suggestions);

    // Look for early wakeups to recommend tonight bedtime
    final wakeUpItem = enrichedItems.firstWhere(
      (it) => it.title.contains('بیدار') || it.targetModule == 'sleep',
      orElse: () => DayPlanItemDraft(
        title: '',
        targetModule: 'none',
        startKind: 'none',
        durationSource: 'none',
        recurrence: 'oneOff',
        category: 'personal',
      ),
    );

    if (wakeUpItem.resolvedTime != null && wakeUpItem.resolvedTime!.isNotEmpty) {
      final wakeTime = _parseTimeOfDay(date, wakeUpItem.resolvedTime!);
      final targetWakeTime = _parseTimeOfDay(date, sleepTargetWake);

      if (wakeTime.isBefore(targetWakeTime)) {
        // Suggested sleep duration is ~7.5 hours
        final recommendedBedtime = wakeTime.subtract(const Duration(hours: 7, minutes: 30));
        final formattedBedtime = _formatTime(recommendedBedtime);
        
        final hasSuggestion = suggestions.any((s) => s.action == 'setBedtime');
        if (!hasSuggestion) {
          suggestions.add(DayPlanSuggestion(
            text: 'برای بیداری ساعت ${wakeUpItem.resolvedTime}، بهتر است امشب ساعت $formattedBedtime بخوابی تا چرخه خواب تکمیل شود.',
            action: 'setBedtime',
            payload: {'time': formattedBedtime},
          ));
        }
      }
    }

    // 6. Total Awake Time validation
    var totalMinutes = 0;
    for (final item in enrichedItems) {
      totalMinutes += item.durationMin ?? 30;
    }

    // Awake budget is usually ~16-17 hours (960-1020 mins)
    if (totalMinutes > 1020) {
      suggestions.add(DayPlanSuggestion(
        text: '⚠️ مجموع برنامه روز شما (${(totalMinutes / 60).toStringAsFixed(1)} ساعت) بیشتر از محدوده بیداری استاندارد است. پیشنهاد می‌شود کارها را کوتاه‌تر یا جابجا کنید.',
        action: 'alert_busy',
      ));
    }

    return DayPlanDraft(
      planDate: draft.planDate,
      items: enrichedItems,
      questions: draft.questions,
      suggestions: suggestions,
    );
  }

  static DateTime _parseTimeOfDay(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static List<DayPlanItemDraft> _consolidatePrayers(List<DayPlanItemDraft> rawItems) {
    final result = <DayPlanItemDraft>[];
    DayPlanItemDraft? dhuhrItem;
    DayPlanItemDraft? asrItem;
    DayPlanItemDraft? maghribItem;
    DayPlanItemDraft? ishaItem;

    for (final item in rawItems) {
      final t = item.title.trim();
      final isWorship = item.targetModule == 'worship' || item.category == 'worship';

      final isDhuhrOnly = isWorship && (t == 'نماز ظهر' || item.anchorEvent?.toUpperCase() == 'DHUHR') && !t.contains('عصر');
      final isAsrOnly = isWorship && (t == 'نماز عصر' || item.anchorEvent?.toUpperCase() == 'ASR') && !t.contains('ظهر');
      final isMaghribOnly = isWorship && (t == 'نماز مغرب' || item.anchorEvent?.toUpperCase() == 'MAGHRIB') && !t.contains('عشا');
      final isIshaOnly = isWorship && (t == 'نماز عشا' || t == 'نماز عشاء' || item.anchorEvent?.toUpperCase() == 'ISHA') && !t.contains('مغرب');

      if (isDhuhrOnly) {
        dhuhrItem = item;
      } else if (isAsrOnly) {
        asrItem = item;
      } else if (isMaghribOnly) {
        maghribItem = item;
      } else if (isIshaOnly) {
        ishaItem = item;
      } else {
        result.add(item);
      }
    }

    if (dhuhrItem != null || asrItem != null) {
      final base = dhuhrItem ?? asrItem!;
      final totalDuration = (dhuhrItem?.durationMin ?? 15) + (asrItem?.durationMin ?? 10);
      result.add(DayPlanItemDraft(
        title: 'نماز ظهر و عصر',
        targetModule: 'worship',
        startKind: 'anchor',
        startTime: base.startTime,
        anchorEvent: 'DHUHR',
        offsetMin: base.offsetMin,
        bufferMin: base.bufferMin,
        durationMin: totalDuration > 0 ? totalDuration : 20,
        durationSource: base.durationSource,
        recurrence: base.recurrence,
        daysOfWeek: base.daysOfWeek,
        category: 'worship',
        confidence: base.confidence,
        note: base.note,
      ));
    }

    if (maghribItem != null || ishaItem != null) {
      final base = maghribItem ?? ishaItem!;
      final totalDuration = (maghribItem?.durationMin ?? 15) + (ishaItem?.durationMin ?? 10);
      result.add(DayPlanItemDraft(
        title: 'نماز مغرب و عشاء',
        targetModule: 'worship',
        startKind: 'anchor',
        startTime: base.startTime,
        anchorEvent: 'MAGHRIB',
        offsetMin: base.offsetMin,
        bufferMin: base.bufferMin,
        durationMin: totalDuration > 0 ? totalDuration : 20,
        durationSource: base.durationSource,
        recurrence: base.recurrence,
        daysOfWeek: base.daysOfWeek,
        category: 'worship',
        confidence: base.confidence,
        note: base.note,
      ));
    }

    return result;
  }
}
