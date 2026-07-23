import 'dart:async';

import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';

class RitmoIntelligenceOrchestrator {

  RitmoIntelligenceOrchestrator({
    required this.engineBus,
    required this.eventBus,
  }) {
    _subscription = eventBus.onEvents.listen(_handleEvent);
  }
  final RitmoEngineBus engineBus;
  final RitmoEventBus eventBus;
  StreamSubscription<RitmoEvent>? _subscription;

  void _handleEvent(RitmoEvent event) {
    // Determine which analytical engines to invalidate based on the event type
    switch (event.type) {
      case 'RoutineCompleted':
      case 'RoutineSkipped':
      case 'RoutineCreated':
      case 'RoutineEdited':
      // Cross-section completion events (Phase 4) also shift the daily picture
      // the analytical engines summarize, so refresh them too.
      case 'CourseSessionCompleted':
      case 'GoalStepToggled':
      case 'PrayerCompleted':
      case 'WorshipUpdated':
        _invalidateAnalyticalEngines();
      case 'EnergyLogged':
      case 'SleepLogged':
        _invalidateEnergyDependentEngines();
      case 'ZoneChanged':
        _invalidateZoneDependentEngines();
      case 'CycleStarted':
      case 'CycleEnded':
        _invalidateCycleDependentEngines();
      case 'MedicineTaken':
        _invalidateMedicineDependentEngines();
      case 'DayRolledOver':
      case 'DataImported':
        _invalidateAllEngines();
    }
  }

  void _invalidateAnalyticalEngines() {
    // Invalidate engines that depend on routine completions/routines list
    // Type literals are resolved dynamically from engineRegistry when invalidating
    for (final type in engineBus.registry.registeredTypes) {
      engineBus.invalidate(type);
    }
  }

  void _invalidateEnergyDependentEngines() {
    for (final type in engineBus.registry.registeredTypes) {
      // Invalidate everything to be safe and clean
      engineBus.invalidate(type);
    }
  }

  void _invalidateZoneDependentEngines() {
    for (final type in engineBus.registry.registeredTypes) {
      engineBus.invalidate(type);
    }
  }

  void _invalidateCycleDependentEngines() {
    for (final type in engineBus.registry.registeredTypes) {
      engineBus.invalidate(type);
    }
  }

  void _invalidateMedicineDependentEngines() {
    for (final type in engineBus.registry.registeredTypes) {
      engineBus.invalidate(type);
    }
  }

  void _invalidateAllEngines() {
    for (final type in engineBus.registry.registeredTypes) {
      engineBus.invalidate(type);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
