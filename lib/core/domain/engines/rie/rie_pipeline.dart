// lib/core/domain/engines/rie/rie_pipeline.dart

import 'package:ritmo/core/domain/engines/engine_enums.dart';
import 'package:ritmo/core/domain/engines/rie/context_snapshot.dart';
import 'package:ritmo/core/domain/engines/rie/rie_filters.dart';
import 'package:ritmo/core/domain/engines/rie/rie_scorers.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_engine.dart' show RitmoEngineOutput;
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';

class RitmoIntelligencePipeline {
  final List<RoutineScorer> _scorers = const [
    ZoneMatchScorer(),
    ContextMatchScorer(),
    EnergyFitScorer(),
    TimeRelevanceScorer(),
    EssentialBonusScorer(),
    FocusAreaBoostScorer(),
    SleepWindowPenaltyScorer(),
    ReflectionAwareScorer(),
    EnergyMismatchPenaltyScorer(),
  ];

  /// Pure pipeline execution that takes a pre-loaded snapshot and performs
  /// the entire filtering, scoring, and output generation logic.
  RitmoEngineOutput execute(ContextSnapshot snapshot) {
    // 1. Run Filters step-by-step to capture specific suppression reasons
    // (matches legacy visibleRoutines & hiddenRoutines categorization exactly)
    
    // Layer 0: Module Gate
    final enteredRoutines = <Routine>[];
    for (final r in snapshot.enteredRoutines) {
      if (ModuleGateFilter.isModuleEnabled(r.category, snapshot.appSettings)) {
        enteredRoutines.add(r);
      }
    }

    // Layer 1: Biological Constraints
    final biologicalRoutines = <Routine>[];
    final suppressedByBiology = <Routine>[];
    final worshipConsent = snapshot.appSettings['cycle_consent_worship'] != 'false';
    for (final r in enteredRoutines) {
      if (snapshot.isMenstruating && r.category == Category.religious && worshipConsent) {
        suppressedByBiology.add(r);
      } else {
        biologicalRoutines.add(r);
      }
    }

    // Layer 2: Zone & Essential Rules
    final zoneCheckedRoutines = <Routine>[];
    final suppressedByZone = <Routine>[];
    for (final r in biologicalRoutines) {
      final isZoneBlocked = snapshot.blockedRoutineIdsInZone.contains(r.id) ||
          ((snapshot.activeZoneMode == 'SILENT' || snapshot.activeZoneMode == 'FOCUS') && !r.isEssential);

      if (isZoneBlocked) {
        if (r.isEssential) {
          zoneCheckedRoutines.add(r);
        } else {
          suppressedByZone.add(r);
        }
      } else {
        zoneCheckedRoutines.add(r);
      }
    }

    // Layer 3: Energy Engine
    final energyCheckedRoutines = <Routine>[];
    final suppressedByEnergy = <Routine>[];
    for (final r in zoneCheckedRoutines) {
      if (snapshot.currentEnergy == EnergyLevel.low && !r.isEssential) {
        if (r.energyRule == EnergyRule.skip || r.energyRule == EnergyRule.highEnergyOnly) {
          suppressedByEnergy.add(r);
          continue;
        }
      }
      energyCheckedRoutines.add(r);
    }

    // Layer 5: Context & Daily Behavior
    final contextCheckedRoutines = <Routine>[];
    final suppressedByContext = <Routine>[];
    final dailyBehavior = snapshot.dailyBehavior;

    for (final r in energyCheckedRoutines) {
      if (dailyBehavior.behavior == 'SILENCE_ALL') {
        final isCriticalMedicine = r.category == Category.medical && r.isEssential;
        if (!isCriticalMedicine) {
          suppressedByContext.add(r);
          continue;
        }
      } else if (dailyBehavior.behavior == 'ESSENTIAL_ONLY') {
        if (!r.isEssential) {
          suppressedByContext.add(r);
          continue;
        }
      }

      if (dailyBehavior.context == LifeContext.sick && r.category == Category.fitness) {
        suppressedByContext.add(r);
        continue;
      }

      contextCheckedRoutines.add(r);
    }

    final visibleRoutines = contextCheckedRoutines;
    final hiddenRoutines = suppressedByBiology + suppressedByZone + suppressedByEnergy + suppressedByContext;

    // 2. Score visible routines using Scorers
    final scores = <String, double>{};
    for (final r in visibleRoutines) {
      var scoreSum = 0.0;
      for (final scorer in _scorers) {
        scoreSum += scorer.score(r, snapshot);
      }
      scores[r.id] = scoreSum;
    }

    // 3. Find suggested routine (highest scoring incomplete visible routine)
    final incompleteVisible = visibleRoutines
        .where((r) => !snapshot.completedRoutineIdsToday.contains(r.id))
        .toList();

    Routine? suggestedRoutine;
    if (incompleteVisible.isNotEmpty) {
      incompleteVisible.sort((a, b) => (scores[b.id] ?? 0.0).compareTo(scores[a.id] ?? 0.0));
      suggestedRoutine = incompleteVisible.first;
    }

    // 4. Determine if light version should be suggested
    var suggestLightVersion = false;
    if (snapshot.currentEnergy == EnergyLevel.low &&
        suggestedRoutine != null &&
        !suggestedRoutine.isEssential) {
      if (suggestedRoutine.energyRule == EnergyRule.offerLight ||
          suggestedRoutine.energyRule == EnergyRule.offerMinimal) {
        suggestLightVersion = true;
      }
    }
    if (snapshot.isMenstruating &&
        suggestedRoutine != null &&
        suggestedRoutine.category == Category.fitness) {
      suggestLightVersion = true;
    }
    final reflectionLight = snapshot.gentleMode &&
        suggestedRoutine != null &&
        !suggestedRoutine.isEssential &&
        (suggestedRoutine.energyRule == EnergyRule.offerLight ||
            suggestedRoutine.energyRule == EnergyRule.offerMinimal);
    if (reflectionLight) {
      suggestLightVersion = true;
    }

    // 5. Compute Critical Alerts
    final criticalAlerts = <String>[];

    // stock alert
    for (final r in enteredRoutines) {
      if (r.category == Category.medical &&
          r.medStockCount > 0 &&
          r.medStockCount <= r.medRefillThreshold) {
        criticalAlerts.add('موجودی داروی «${r.title}» رو‌به‌اتمام است (موجودی فعلی: ${r.medStockCount}).');
      }
    }

    // time conflict alert
    final intervals = <Map<String, dynamic>>[];
    final todayWeekday = snapshot.now.weekday;

    for (final r in enteredRoutines) {
      if (r.routineType != RoutineType.timeBased) continue;

      final sched = snapshot.routineSchedulesByRoutineId[r.id];
      if (sched != null) {
        final daysOfWeekStr = sched['daysOfWeek'] as String? ?? '6,7,1,2,3,4,5';
        final activeDays = daysOfWeekStr.split(',').map((d) => int.tryParse(d.trim()) ?? 1).toSet();
        if (activeDays.contains(todayWeekday)) {
          final timeStr = sched['timeOfDay'] as String?;
          if (timeStr != null) {
            final parts = timeStr.split(':');
            if (parts.length == 2) {
              final h = int.tryParse(parts[0]) ?? 0;
              final m = int.tryParse(parts[1]) ?? 0;
              final start = h * 60 + m;
              final dur = r.targetDurationMinutes ?? 30;
              intervals.add({
                'title': r.title,
                'start': start,
                'end': start + dur,
              });
            }
          }
        }
      }
    }

    for (var i = 0; i < intervals.length; i++) {
      for (var j = i + 1; j < intervals.length; j++) {
        final a = intervals[i];
        final b = intervals[j];
        if (a['start'] < b['end'] && b['start'] < a['end']) {
          criticalAlerts.add('تداخل زمانی بین روتین‌های «${a['title']}» و «${b['title']}» شناسایی شد.');
        }
      }
    }

    // 6. Generate Context Explanation
    var contextExplanation = ContextExplanation(type: ContextExplanationType.rest);
    if (suggestedRoutine != null) {
      final title = suggestedRoutine.title;
      final context = dailyBehavior.context;

      if (suggestedRoutine.isEssential) {
        contextExplanation = ContextExplanation(type: ContextExplanationType.essential, params: {'title': title});
      } else if (snapshot.gentleMode) {
        contextExplanation = ContextExplanation(type: ContextExplanationType.reflectionAware, params: {'title': title});
      } else if (context == LifeContext.sick) {
        contextExplanation = ContextExplanation(type: ContextExplanationType.sick, params: {'title': title});
      } else if (context == LifeContext.exam) {
        contextExplanation = ContextExplanation(type: ContextExplanationType.exam, params: {'title': title});
      } else if (context == LifeContext.busy) {
        contextExplanation = ContextExplanation(type: ContextExplanationType.busy, params: {'title': title});
      } else if (context == LifeContext.worship) {
        contextExplanation = ContextExplanation(
          type: ContextExplanationType.worship,
          params: {
            'title': title,
            'season': dailyBehavior.activeWorshipSeasonTitle ?? '',
          },
        );
      } else if (snapshot.activeZoneId != null && suggestedRoutine.zoneId == snapshot.activeZoneId) {
        contextExplanation = ContextExplanation(type: ContextExplanationType.zone, params: {'title': title});
      } else if (snapshot.currentEnergy == EnergyLevel.low) {
        contextExplanation = ContextExplanation(type: ContextExplanationType.lowEnergy, params: {'title': title});
      } else {
        contextExplanation = ContextExplanation(type: ContextExplanationType.dynamic, params: {'title': title});
      }
    }

    return RitmoEngineOutput(
      visibleRoutines: visibleRoutines,
      hiddenRoutines: hiddenRoutines,
      suggestedRoutine: suggestedRoutine,
      suggestLightVersion: suggestLightVersion,
      criticalAlerts: criticalAlerts,
      nextBestAction: suggestedRoutine,
      contextExplanation: contextExplanation,
    );
  }
}
