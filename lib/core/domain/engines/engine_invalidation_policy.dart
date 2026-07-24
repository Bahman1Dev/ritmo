import 'package:ritmo/core/analytics/assistant_engine.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/core/analytics/health_engine.dart';
import 'package:ritmo/core/analytics/insight_generation_engine.dart';
import 'package:ritmo/core/analytics/konkur_engine.dart';
import 'package:ritmo/core/analytics/life_balance_engine.dart';
import 'package:ritmo/core/analytics/milestone_engine.dart';
import 'package:ritmo/core/analytics/reflection_engine.dart';
import 'package:ritmo/core/analytics/sleep_engine.dart';
import 'package:ritmo/core/behavior/behavioral_intelligence_orchestrator.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/engines/engine_invalidation_tag.dart';
import 'package:ritmo/core/domain/engines/medical_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';

class EngineInvalidationPolicy {
  const EngineInvalidationPolicy();

  static const Map<String, Set<EngineInvalidationTag>> eventTags = {
    'RoutineCreated': {
      EngineInvalidationTag.routineStructure,
    },
    'RoutineEdited': {
      EngineInvalidationTag.routineStructure,
      EngineInvalidationTag.routineOutcome,
    },
    'RoutineDeleted': {
      EngineInvalidationTag.routineStructure,
    },
    'RoutineCompleted': {
      EngineInvalidationTag.routineOutcome,
    },
    'RoutineSkipped': {
      EngineInvalidationTag.routineOutcome,
    },

    'CourseSessionCompleted': {
      EngineInvalidationTag.courses,
    },
    'GoalStepToggled': {
      EngineInvalidationTag.goals,
    },
    'PrayerCompleted': {
      EngineInvalidationTag.worship,
    },
    'WorshipUpdated': {
      EngineInvalidationTag.worship,
    },

    'EnergyLogged': {
      EngineInvalidationTag.energy,
    },
    'SleepLogged': {
      EngineInvalidationTag.sleep,
    },
    'ZoneChanged': {
      EngineInvalidationTag.zone,
    },
    'CycleStarted': {
      EngineInvalidationTag.cycle,
    },
    'CycleEnded': {
      EngineInvalidationTag.cycle,
    },
    'MedicineTaken': {
      EngineInvalidationTag.medicine,
    },

    'DayRolledOver': {
      EngineInvalidationTag.global,
    },
    'DataImported': {
      EngineInvalidationTag.global,
    },
  };

  static const Map<Type, Set<EngineInvalidationTag>> engineTags = {
    LifeBalanceEngine: {
      EngineInvalidationTag.routineStructure,
      EngineInvalidationTag.routineOutcome,
      EngineInvalidationTag.global,
    },
    EnergyAnalyticsEngine: {
      EngineInvalidationTag.energy,
      EngineInvalidationTag.sleep,
      EngineInvalidationTag.routineOutcome,
      EngineInvalidationTag.global,
    },
    MilestoneEngine: {
      EngineInvalidationTag.routineStructure,
      EngineInvalidationTag.routineOutcome,
      EngineInvalidationTag.goals,
      EngineInvalidationTag.courses,
      EngineInvalidationTag.worship,
      EngineInvalidationTag.global,
    },
    InsightGenerationEngine: {
      EngineInvalidationTag.routineStructure,
      EngineInvalidationTag.routineOutcome,
      EngineInvalidationTag.energy,
      EngineInvalidationTag.sleep,
      EngineInvalidationTag.global,
    },
    MedicalEngine: {
      EngineInvalidationTag.medicine,
      EngineInvalidationTag.global,
    },
    CycleEngine: {
      EngineInvalidationTag.cycle,
      EngineInvalidationTag.global,
    },
    KonkurEngine: {
      EngineInvalidationTag.courses,
      EngineInvalidationTag.global,
    },
    GoalsEngine: {
      EngineInvalidationTag.goals,
      EngineInvalidationTag.routineStructure,
      EngineInvalidationTag.routineOutcome,
      EngineInvalidationTag.global,
    },
    SleepEngine: {
      EngineInvalidationTag.sleep,
      EngineInvalidationTag.energy,
      EngineInvalidationTag.global,
    },
    AssistantEngine: {
      EngineInvalidationTag.routineStructure,
      EngineInvalidationTag.routineOutcome,
      EngineInvalidationTag.energy,
      EngineInvalidationTag.sleep,
      EngineInvalidationTag.goals,
      EngineInvalidationTag.courses,
      EngineInvalidationTag.reflection,
      EngineInvalidationTag.cycle,
      EngineInvalidationTag.global,
    },
    ReflectionEngine: {
      EngineInvalidationTag.reflection,
      EngineInvalidationTag.energy,
      EngineInvalidationTag.global,
    },
    HealthEngine: {
      EngineInvalidationTag.medicine,
      EngineInvalidationTag.energy,
      EngineInvalidationTag.global,
    },
    BehavioralIntelligenceOrchestrator: {
      EngineInvalidationTag.routineOutcome,
      EngineInvalidationTag.energy,
      EngineInvalidationTag.sleep,
      EngineInvalidationTag.goals,
      EngineInvalidationTag.courses,
      EngineInvalidationTag.reflection,
      EngineInvalidationTag.cycle,
      EngineInvalidationTag.zone,
      EngineInvalidationTag.global,
    },
  };

  Set<Type> enginesToInvalidateFor(RitmoEvent event) {
    final tags = eventTags[event.type];
    if (tags == null || tags.isEmpty) return const {};

    final result = <Type>{};
    for (final entry in engineTags.entries) {
      if (entry.value.any(tags.contains)) {
        result.add(entry.key);
      }
    }
    return result;
  }
}
