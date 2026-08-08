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
import 'package:ritmo/core/analytics/cognitive_routing_engine.dart';
import 'package:ritmo/core/analytics/daily_budget_engine.dart';
import 'package:ritmo/core/analytics/fresh_start_engine.dart';
import 'package:ritmo/core/analytics/motivation_diagnosis_engine.dart';
import 'package:ritmo/core/behavior/behavioral_intelligence_orchestrator.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/engines/engine_invalidation_tag.dart';
import 'package:ritmo/core/domain/engines/medical_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';

class EngineInvalidationPolicy {
  const EngineInvalidationPolicy();

  static const Map<RitmoEventType, Set<EngineInvalidationTag>> eventTags = {
    RitmoEventType.routineCreated: {
      EngineInvalidationTag.routineStructure,
    },
    RitmoEventType.routineUpdated: {
      EngineInvalidationTag.routineStructure,
      EngineInvalidationTag.routineOutcome,
    },
    RitmoEventType.routineDeleted: {
      EngineInvalidationTag.routineStructure,
    },
    RitmoEventType.occurrenceCompleted: {
      EngineInvalidationTag.routineOutcome,
    },
    RitmoEventType.occurrenceSkipped: {
      EngineInvalidationTag.routineOutcome,
    },
    RitmoEventType.reshuffleConfirmed: {
      EngineInvalidationTag.routineStructure,
    },
    RitmoEventType.goalChanged: {
      EngineInvalidationTag.goals,
    },
    RitmoEventType.goalStepToggled: {
      EngineInvalidationTag.goals,
    },
    RitmoEventType.worshipChanged: {
      EngineInvalidationTag.worship,
    },
    RitmoEventType.worshipPracticeChanged: {
      EngineInvalidationTag.worship,
    },
    RitmoEventType.workoutLogChanged: {
      EngineInvalidationTag.routineOutcome,
    },
    RitmoEventType.reflectionSaved: {
      EngineInvalidationTag.reflection,
    },
    RitmoEventType.completionRecorded: {
      EngineInvalidationTag.routineOutcome,
    },
    RitmoEventType.completionDeleted: {
      EngineInvalidationTag.routineOutcome,
    },
    RitmoEventType.konkurItemChanged: {
      EngineInvalidationTag.courses,
    },
    RitmoEventType.courseSessionCompleted: {
      EngineInvalidationTag.courses,
    },
    RitmoEventType.energyLogged: {
      EngineInvalidationTag.energy,
    },
    RitmoEventType.sleepLogged: {
      EngineInvalidationTag.sleep,
    },
    RitmoEventType.moodLogged: {
      EngineInvalidationTag.energy,
    },
    RitmoEventType.zoneChanged: {
      EngineInvalidationTag.zone,
    },
    RitmoEventType.cycleStarted: {
      EngineInvalidationTag.cycle,
    },
    RitmoEventType.cycleEnded: {
      EngineInvalidationTag.cycle,
    },
    RitmoEventType.medicineTaken: {
      EngineInvalidationTag.medicine,
    },
    RitmoEventType.dayRolledOver: {
      EngineInvalidationTag.global,
    },
    RitmoEventType.dataImported: {
      EngineInvalidationTag.global,
    },
    RitmoEventType.settingsChanged: {
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
    MotivationDiagnosisEngine: {
      EngineInvalidationTag.routineOutcome,
      EngineInvalidationTag.routineStructure,
      EngineInvalidationTag.global,
    },
    DailyBudgetEngine: {
      EngineInvalidationTag.routineStructure,
      EngineInvalidationTag.routineOutcome,
      EngineInvalidationTag.sleep,
      EngineInvalidationTag.global,
    },
    CognitiveRoutingEngine: {
      EngineInvalidationTag.energy,
      EngineInvalidationTag.routineStructure,
      EngineInvalidationTag.global,
    },
    FreshStartEngine: {
      EngineInvalidationTag.goals,
      EngineInvalidationTag.routineOutcome,
      EngineInvalidationTag.global,
    },
  };

  Set<Type> enginesToInvalidateFor(RitmoEvent event) {
    final typeEnum = RitmoEventType.values.firstWhere(
      (e) => e.code == event.type,
      orElse: () => RitmoEventType.settingsChanged,
    );
    final tags = eventTags[typeEnum]!;
    if (tags.isEmpty) return const {};

    final result = <Type>{};
    for (final entry in engineTags.entries) {
      if (entry.value.any(tags.contains)) {
        result.add(entry.key);
      }
    }
    return result;
  }
}
