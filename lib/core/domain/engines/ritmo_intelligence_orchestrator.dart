import 'dart:async';

import 'package:ritmo/core/domain/engines/engine_invalidation_policy.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';

class RitmoIntelligenceOrchestrator {
  RitmoIntelligenceOrchestrator({
    required this.engineBus,
    required this.eventBus,
    EngineInvalidationPolicy? invalidationPolicy,
  }) : _invalidationPolicy =
            invalidationPolicy ?? const EngineInvalidationPolicy() {
    _subscription = eventBus.onEvents.listen(_handleEvent);
  }

  final RitmoEngineBus engineBus;
  final RitmoEventBus eventBus;
  final EngineInvalidationPolicy _invalidationPolicy;
  StreamSubscription<RitmoEvent>? _subscription;

  void _handleEvent(RitmoEvent event) {
    final targets = _invalidationPolicy.enginesToInvalidateFor(event);
    for (final type in targets) {
      engineBus.invalidate(type);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
