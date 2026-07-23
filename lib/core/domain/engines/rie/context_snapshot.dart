// lib/core/domain/engines/rie/context_snapshot.dart

import 'package:ritmo/core/domain/engines/zone_engine.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:ritmo/core/domain/models/reflection_context.dart';

/// Immutable point-in-time snapshot of the user's daily life environment, settings,
/// active constraints, and pre-fetched database records.
class ContextSnapshot {

  ContextSnapshot({
    required this.now,
    required this.appSettings,
    required this.activeZoneId,
    required this.activeZoneMode,
    required this.currentEnergy,
    required this.isMenstruating,
    this.reflectionContext,
    required this.dailyBehavior,
    required this.blockedRoutineIdsInZone,
    required this.completedRoutineIdsToday,
    required this.routineSchedulesByRoutineId,
    required this.enteredRoutines,
  });
  final DateTime now;
  final Map<String, String> appSettings;
  final String? activeZoneId;
  final String? activeZoneMode;
  final EnergyLevel currentEnergy;
  final bool isMenstruating;
  final ReflectionContext? reflectionContext;
  final DailyBehavior dailyBehavior;

  // Pre-fetched sets and maps to avoid database calls inside pipeline loops
  final Set<String> blockedRoutineIdsInZone;
  final Set<String> completedRoutineIdsToday;
  
  /// Mapped by routineId to its routine_schedules record
  final Map<String, Map<String, dynamic>> routineSchedulesByRoutineId;

  /// Raw list of entered routines (before biological, zone, or energy gates)
  final List<Routine> enteredRoutines;

  /// True if reflection context indicates gentle mode should be active
  bool get gentleMode => reflectionContext?.wantsGentleMode ?? false;

  /// Helper to check if current time lies in the sleep range
  bool get isSleepTime {
    final wakeTimeStr = appSettings['wake_time'] ?? '07:00';
    final sleepTimeStr = appSettings['sleep_time'] ?? '23:00';
    return ZoneEngine.isTimeWithinRange(
      time: now,
      startTimeStr: sleepTimeStr,
      endTimeStr: wakeTimeStr,
    );
  }

  /// Parses the focus areas list from settings
  List<String> get focusAreas {
    final focusAreasStr = appSettings['primary_focus_areas'];
    if (focusAreasStr == null || focusAreasStr.isEmpty) return const [];
    try {
      // Basic JSON array decoding
      final cleaned = focusAreasStr.trim();
      if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
        // Strip square brackets and split by comma & quotes
        return cleaned
            .substring(1, cleaned.length - 1)
            .split(',')
            .map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return const [];
  }
}
