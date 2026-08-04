// lib/features/registry/logic/registry_index.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/domain/registry_query.dart';
import 'package:ritmo/features/registry/logic/sources/course_registry_source.dart';
import 'package:ritmo/features/registry/logic/sources/goal_registry_source.dart';
import 'package:ritmo/features/registry/logic/sources/konkur_registry_source.dart';
import 'package:ritmo/features/registry/logic/sources/medicine_registry_source.dart';
import 'package:ritmo/features/registry/logic/sources/movement_registry_source.dart';
import 'package:ritmo/features/registry/logic/sources/registry_source.dart';
import 'package:ritmo/features/registry/logic/sources/reminder_registry_source.dart';
import 'package:ritmo/features/registry/logic/sources/routine_registry_source.dart';
import 'package:ritmo/features/registry/logic/sources/worship_debt_registry_source.dart';
import 'package:ritmo/features/registry/logic/sources/worship_registry_source.dart';

class RegistryIndex {
  RegistryIndex._() {
    _initEventSubscriptions();
  }

  static final RegistryIndex instance = RegistryIndex._();

  final List<RegistrySource> _sources = [
    RoutineRegistrySource(),
    CourseRegistrySource(),
    GoalRegistrySource(),
    WorshipRegistrySource(),
    WorshipDebtRegistrySource(),
    MedicineRegistrySource(),
    KonkurRegistrySource(),
    MovementRegistrySource(),
    ReminderRegistrySource(),
  ];

  final Map<RegistryDomain, List<RegistryEntry>> _cache = {};
  final Map<RegistryDomain, int> _counts = {};
  StreamSubscription? _eventSub;

  void _initEventSubscriptions() {
    _eventSub = RitmoEventBus().onEvents.listen((event) {
      final typeStr = event.type;
      if (typeStr == 'RoutineCreated' ||
          typeStr == 'RoutineUpdated' ||
          typeStr == 'RoutineDeleted') {
        invalidate({RegistryDomain.routine, RegistryDomain.medicine});
      } else if (typeStr == 'GoalChanged' || typeStr == 'GoalStepToggled') {
        invalidate({RegistryDomain.goal});
      } else if (typeStr == 'WorshipChanged' ||
          typeStr == 'WorshipPracticeChanged') {
        invalidate({RegistryDomain.worship, RegistryDomain.worshipDebt});
      } else if (typeStr == 'WorkoutLogChanged') {
        invalidate({
          RegistryDomain.movementKind,
          RegistryDomain.workoutPlan
        });
      } else if (typeStr == 'CompletionRecorded') {
        // Clear only routine & goal cache
        invalidate({RegistryDomain.routine, RegistryDomain.goal});
      }
    });
  }

  void invalidate([Set<RegistryDomain>? domains]) {
    if (domains == null || domains.isEmpty) {
      _cache.clear();
      _counts.clear();
    } else {
      for (final d in domains) {
        _cache.remove(d);
        _counts.remove(d);
      }
    }
  }

  /// Phase A: Fast load (< 80ms) returning initial items & counts
  Future<List<RegistryEntry>> queryPhaseA(
    RegistryQuery query,
    Map<String, String> settingsMap,
  ) async {
    final results = <RegistryEntry>[];
    final seenIds = <String>{};
    final seenSourceIds = <String>{};
    final seenTitleKeys = <String>{};

    // Single SQL query for next run dates
    final nextRunDates = await _fetchNextRunDates();

    for (final src in _sources) {
      final key = src.moduleSettingsKey;
      if (key.isNotEmpty && settingsMap[key] == 'false') {
        _counts[src.domain] = 0;
        continue;
      }

      if (query.domainFilter.isNotEmpty &&
          !query.domainFilter.contains(src.domain)) {
        continue;
      }

      var items = _cache[src.domain];
      if (items == null) {
        try {
          items = await src.fetch(limit: 50, offset: 0, includeArchived: query.showArchived);
        } catch (e) {
          items = <RegistryEntry>[];
        }
        _cache[src.domain] = items;
        _counts[src.domain] = items.length;
      }

      for (final item in items) {
        final nextDate = nextRunDates[item.sourceId];
        final updated = item.copyWith(nextRunDateStr: nextDate);
        if (_matchesQuery(updated, query)) {
          final titleKey = _normalizeFa(updated.title);
          final isDuplicateId = seenIds.contains(updated.id);
          final isDuplicateSource = updated.sourceId.isNotEmpty && seenSourceIds.contains(updated.sourceId);
          final isDuplicateTitle = titleKey.isNotEmpty && seenTitleKeys.contains(titleKey);

          if (!isDuplicateId && !isDuplicateSource && !isDuplicateTitle) {
            seenIds.add(updated.id);
            if (updated.sourceId.isNotEmpty) seenSourceIds.add(updated.sourceId);
            if (titleKey.isNotEmpty) seenTitleKeys.add(titleKey);
            results.add(updated);
          }
        }
      }
    }

    return results;
  }

  /// Single optimized query for next upcoming run dates across all routines
  Future<Map<String, String>> _fetchNextRunDates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().split('T').first;

      final rows = await db.rawQuery('''
        SELECT routine_id, MIN(date) AS nextDate
        FROM routine_occurrences
        WHERE date >= ? AND status = 'pending'
        GROUP BY routine_id
      ''', [todayStr]);

      final map = <String, String>{};
      for (final r in rows) {
        final rId = r['routine_id'] as String?;
        final nextDate = r['nextDate'] as String?;
        if (rId != null && nextDate != null) {
          map[rId] = nextDate;
        }
      }
      return map;
    } catch (e) {
      debugPrint('[RegistryIndex] Error fetching next run dates: $e');
      return {};
    }
  }

  bool _matchesQuery(RegistryEntry entry, RegistryQuery query) {
    if (!query.showArchived && entry.status == RegistryStatus.archived) {
      return false;
    }
    if (query.statusFilter.isNotEmpty &&
        !query.statusFilter.contains(entry.status)) {
      return false;
    }
    if (query.searchText.trim().isNotEmpty) {
      final q = _normalizeFa(query.searchText);
      final titleNorm = _normalizeFa(entry.title);
      final subNorm = _normalizeFa(entry.subtitle ?? '');
      if (!titleNorm.contains(q) && !subNorm.contains(q)) {
        return false;
      }
    }
    return true;
  }

  static String _normalizeFa(String s) {
    return s
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('\u200c', ' ')
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  void dispose() {
    _eventSub?.cancel();
    _eventSub = null;
  }
}
