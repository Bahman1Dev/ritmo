import 'package:flutter/foundation.dart' hide Category;
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/engine_enums.dart';
import 'package:ritmo/core/domain/engines/rie/context_resolver.dart';
import 'package:ritmo/core/domain/engines/rie/daily_behavior_resolver.dart';
import 'package:ritmo/core/domain/engines/rie/rie_pipeline.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:ritmo/core/domain/models/reflection_context.dart';
import 'package:sqflite/sqflite.dart';

/// Output model containing calculated routines and context state.
class RitmoEngineOutput {

  /// Constructs a [RitmoEngineOutput].
  RitmoEngineOutput({
    required this.visibleRoutines,
    required this.hiddenRoutines,
    required this.suggestLightVersion,
    required this.criticalAlerts,
    required this.contextExplanation,
    this.suggestedRoutine,
    this.nextBestAction,
  });
  /// List of routines visible to the user today.
  final List<Routine> visibleRoutines;

  /// List of routines hidden based on current context/energy.
  final List<Routine> hiddenRoutines;

  /// Single suggested top-priority routine.
  final Routine? suggestedRoutine;

  /// Whether to suggest a lighter version of routines.
  final bool suggestLightVersion;

  /// High priority alerts or warnings.
  final List<String> criticalAlerts;

  /// Next recommended action routine.
  final Routine? nextBestAction;

  /// Explanation for why the current context was selected.
  final ContextExplanation contextExplanation;
}

/// Core intelligence engine for resolving daily behavior and evaluating routines.
class RitmoIntelligenceEngine {
  RitmoIntelligenceEngine._();

  /// Resolves the LifeContext and daily behavior for the given date.
  static Future<DailyBehavior> resolveDailyBehavior({
    required DateTime date,
    required Database db,
    required Map<String, String> settings,
  }) async {
    final dateStr = date.toIso8601String().substring(0, 10);

    final calendarExceptionsToday = await db.query(
      'calendar_exceptions',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    final activeWorshipSeasonsToday = await db.query(
      'worship_seasons',
      where: 'isActive = 1 AND startDate <= ? AND endDate >= ?',
      whereArgs: [dateStr, dateStr],
    );

    final konkurMockExamsToday = await db.query(
      'konkur_mock_exams',
      where: 'examDate = ?',
      whereArgs: [dateStr],
    );

    final nonArchivedRoutinesRaw = await db.query(
      'routines',
      where: 'isArchived = 0',
    );

    final allSchedulesRaw = await db.query('routine_schedules');

    return DailyBehaviorResolver.resolve(
      date: date,
      settings: settings,
      calendarExceptionsToday: calendarExceptionsToday,
      activeWorshipSeasonsToday: activeWorshipSeasonsToday,
      konkurMockExamsToday: konkurMockExamsToday,
      nonArchivedRoutines: nonArchivedRoutinesRaw,
      routineSchedules: allSchedulesRaw,
    );
  }

  /// Main evaluation pipeline for the engine.
  static Future<RitmoEngineOutput> evaluate({
    required List<Routine> routines,
    required Map<String, String> appSettings,
    required String? activeZoneId,
    required String? activeZoneMode,
    required EnergyLevel currentEnergy,
    required bool isMenstruating,
    required DateTime now,
    required Database db,
    ReflectionContext? reflectionContext,
  }) async {
    if (isMenstruating) {
      final dateStr = now.toIso8601String().substring(0, 10);
      try {
        await DatabaseHelper.instance.addFastingDebtIfNeeded(db, dateStr);
      } catch (e, st) {
        debugPrint('Error inserting fasting debt: $e\n$st');
      }
    }

    try {
      // 1. Resolve context snapshot
      final snapshot = await ContextResolver.resolve(
        routines: routines,
        appSettings: appSettings,
        activeZoneId: activeZoneId,
        activeZoneMode: activeZoneMode,
        currentEnergy: currentEnergy,
        isMenstruating: isMenstruating,
        now: now,
        db: db,
        reflectionContext: reflectionContext,
      );

      // 2. Run the pure evaluation pipeline
      return RitmoIntelligencePipeline().execute(snapshot);
    } catch (e, st) {
      debugPrint(
        'RIE Pipeline evaluation failed! Falling back. Error: $e\n$st',
      );

      // Minimal safe fallback: filter visible routines using only module settings
      final fallbackVisible = <Routine>[];
      for (final r in routines) {
        final isEnabled = _isFallbackModuleEnabled(r.category, appSettings);
        if (isEnabled) {
          fallbackVisible.add(r);
        }
      }

      return RitmoEngineOutput(
        visibleRoutines: fallbackVisible,
        hiddenRoutines: [],
        suggestLightVersion: false,
        criticalAlerts: [],
        contextExplanation: ContextExplanation(
          type: ContextExplanationType.rest,
        ),
      );
    }
  }

  static bool _isFallbackModuleEnabled(
    Category category,
    Map<String, String> settings,
  ) {
    switch (category) {
      case Category.religious:
        return settings['module_religion_enabled'] == 'true';
      case Category.medical:
        return settings['module_medicine_enabled'] == 'true';
      case Category.learning:
        return settings['module_courses_enabled'] == 'true';
      case Category.konkur:
        return settings['module_konkur_enabled'] == 'true';
      case Category.fitness:
      case Category.work:
      case Category.personal:
      case Category.free:
      case Category.custom:
        return true;
    }
  }
}
