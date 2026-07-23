// lib/core/domain/engines/rie/daily_behavior_resolver.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';

class DailyBehaviorResolver {
  DailyBehaviorResolver._();

  /// Pure resolver for DailyBehavior context and behavior rules based on pre-fetched inputs.
  /// Priority order: SICK > TRAVEL > EXAM > BUSY > WORSHIP > NORMAL
  static DailyBehavior resolve({
    required DateTime date,
    required Map<String, String> settings,
    required List<Map<String, dynamic>> calendarExceptionsToday,
    required List<Map<String, dynamic>> activeWorshipSeasonsToday,
    required List<Map<String, dynamic>> konkurMockExamsToday,
    required List<Map<String, dynamic>> nonArchivedRoutines,
    required List<Map<String, dynamic>> routineSchedules,
  }) {
    Map<String, dynamic>? sickException;
    Map<String, dynamic>? travelException;
    Map<String, dynamic>? examException;

    for (final exc in calendarExceptionsToday) {
      final type = exc['exceptionType'] as String?;
      if (type == 'SICK') {
        sickException = exc;
      } else if (type == 'TRAVEL') {
        travelException = exc;
      } else if (type == 'EXAM') {
        examException = exc;
      }
    }

    // Parse onboarding general life contexts
    final contextsStr = settings['life_contexts'];
    final lifeContexts = <String>[];
    if (contextsStr != null && contextsStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(contextsStr);
        if (decoded is List) {
          lifeContexts.addAll(decoded.map((e) => e.toString()));
        }
      } catch (e, st) {
        debugPrint('Error in DailyBehaviorResolver JSON parsing: $e\n$st');
      }
    }

    // Determine active worship season title
    String? activeSeasonTitle;
    Map<String, dynamic>? maxSeason;
    if (activeWorshipSeasonsToday.isNotEmpty) {
      maxSeason = activeWorshipSeasonsToday.first;
      var maxWeight = (maxSeason['priority_weight'] as num?)?.toDouble() ?? 1.0;
      for (final season in activeWorshipSeasonsToday) {
        final weight = (season['priority_weight'] as num?)?.toDouble() ?? 1.0;
        if (weight > maxWeight) {
          maxWeight = weight;
          maxSeason = season;
        }
      }
      activeSeasonTitle = maxSeason?['title'] as String?;
    }

    // 1. SICK (Highest Priority exception)
    if (sickException != null || lifeContexts.contains('🤒 بیماری')) {
      final behavior = sickException != null ? (sickException['behavior'] as String? ?? 'NORMAL') : 'ESSENTIAL_ONLY';
      return DailyBehavior(
        context: LifeContext.sick,
        behavior: behavior,
        activeWorshipSeasonTitle: activeSeasonTitle,
      );
    }

    // 2. TRAVEL
    if (travelException != null || lifeContexts.contains('✈️ سفر')) {
      final behavior = travelException != null ? (travelException['behavior'] as String? ?? 'NORMAL') : 'NORMAL';
      return DailyBehavior(
        context: LifeContext.travel,
        behavior: behavior,
        activeWorshipSeasonTitle: activeSeasonTitle,
      );
    }

    // 3. EXAM (Mock exam scheduled or calendar exception)
    final isExamDay = examException != null || lifeContexts.contains('📚 امتحانات') || konkurMockExamsToday.isNotEmpty;
    if (isExamDay) {
      final behavior = examException != null ? (examException['behavior'] as String? ?? 'NORMAL') : 'NORMAL';
      return DailyBehavior(
        context: LifeContext.exam,
        behavior: behavior,
        activeWorshipSeasonTitle: activeSeasonTitle,
      );
    }

    // 4. BUSY (density calculation based on TIME_BASED routines scheduled for today)
    var totalScheduledDuration = 0;
    final todayWeekday = date.weekday;

    for (final r in nonArchivedRoutines) {
      final rType = r['routineType'] as String?;
      if (rType != 'timeBased') continue;

      final rId = r['id'] as String;
      final schedule = routineSchedules.firstWhere(
        (s) => s['routineId'] == rId,
        orElse: () => <String, dynamic>{},
      );

      if (schedule.isNotEmpty) {
        final daysOfWeekStr = schedule['daysOfWeek'] as String? ?? '6,7,1,2,3,4,5';
        final activeDays = daysOfWeekStr.split(',').map((d) => int.tryParse(d.trim()) ?? 1).toSet();
        if (activeDays.contains(todayWeekday)) {
          final targetDur = r['targetDurationMinutes'] as int? ?? 30;
          totalScheduledDuration += targetDur;
        }
      }
    }

    final capacityLimitStr = settings['daily_capacity_minutes'] ?? '360';
    final capacityLimit = int.tryParse(capacityLimitStr) ?? 360;

    final hasBusyContext = lifeContexts.contains('💼 فصل کاری سنگین') || lifeContexts.contains('🎯 پروژه مهم');

    if (totalScheduledDuration > capacityLimit || hasBusyContext) {
      return DailyBehavior(
        context: LifeContext.busy,
        behavior: 'NORMAL',
        activeWorshipSeasonTitle: activeSeasonTitle,
      );
    }

    // 5. WORSHIP (if religion module is enabled and a worship season is active)
    if (activeSeasonTitle != null && settings['module_religion_enabled'] == 'true' && maxSeason != null) {
      var behavior = 'NORMAL';
      final behaviorRaw = maxSeason['behaviorJson'] as String?;
      if (behaviorRaw != null && behaviorRaw.isNotEmpty) {
        if (behaviorRaw.trim().startsWith('{')) {
          try {
            final map = jsonDecode(behaviorRaw);
            if (map is Map && map.containsKey('behavior')) {
              behavior = map['behavior'] as String? ?? 'NORMAL';
            }
          } catch (e, st) {
            debugPrint('Error in DailyBehaviorResolver JSON parsing: $e\n$st');
          }
        } else {
          behavior = behaviorRaw;
        }
      }
      return DailyBehavior(
        context: LifeContext.worship,
        behavior: behavior,
        activeWorshipSeasonTitle: activeSeasonTitle,
      );
    }

    // 6. NORMAL (Default Context)
    return DailyBehavior(
      context: LifeContext.normal,
      behavior: 'NORMAL',
      activeWorshipSeasonTitle: activeSeasonTitle,
    );
  }
}
