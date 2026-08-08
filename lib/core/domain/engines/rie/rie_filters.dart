// lib/core/domain/engines/rie/rie_filters.dart

import 'package:ritmo/core/domain/engines/rie/context_snapshot.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';

abstract interface class RoutineFilter {
  /// Returns a filtered list of routines based on the environment rules
  /// defined in the [snapshot].
  List<Routine> filter(List<Routine> routines, ContextSnapshot snapshot);
}

/// Layer 0: Module Gate Filter
class ModuleGateFilter implements RoutineFilter {
  const ModuleGateFilter();

  @override
  List<Routine> filter(List<Routine> routines, ContextSnapshot snapshot) {
    return routines.where((r) => isModuleEnabled(r.category, snapshot.appSettings)).toList();
  }

  static bool isModuleEnabled(Category category, Map<String, String> settings) {
    switch (category) {
      case Category.religious:
        return settings['module_religion_enabled'] == 'true';
      case Category.medical:
        return settings['module_medicine_enabled'] == 'true';
      case Category.learning:
        return settings['module_courses_enabled'] == 'true';
      case Category.konkur:
        return settings['module_study_enabled'] == 'true';
      case Category.work:
      case Category.personal:
      case Category.fitness:
      case Category.free:
      case Category.custom:
        return true;
    }
  }
}

/// Layer 1: Biological Constraints Filter
class BiologicalConstraintsFilter implements RoutineFilter {
  const BiologicalConstraintsFilter();

  @override
  List<Routine> filter(List<Routine> routines, ContextSnapshot snapshot) {
    final worshipConsent = snapshot.appSettings['cycle_consent_worship'] != 'false';
    
    return routines.where((r) {
      // Menstruation suppresses religious routines if consent is enabled
      if (snapshot.isMenstruating && r.category == Category.religious && worshipConsent) {
        return false;
      }
      return true;
    }).toList();
  }
}

/// Layer 2: Zone & Essential Rules Filter
class ZoneAndEssentialFilter implements RoutineFilter {
  const ZoneAndEssentialFilter();

  @override
  List<Routine> filter(List<Routine> routines, ContextSnapshot snapshot) {
    final activeZoneMode = snapshot.activeZoneMode;
    final blockedRoutineIds = snapshot.blockedRoutineIdsInZone;

    return routines.where((r) {
      final isZoneBlocked = blockedRoutineIds.contains(r.id) ||
          ((activeZoneMode == 'SILENT' || activeZoneMode == 'FOCUS') && !r.isEssential);

      if (isZoneBlocked) {
        // Bypass blocked zone constraint if the routine is marked essential
        return r.isEssential;
      }
      return true;
    }).toList();
  }
}

/// Layer 3: Energy Engine Filter
class EnergyEngineFilter implements RoutineFilter {
  const EnergyEngineFilter();

  @override
  List<Routine> filter(List<Routine> routines, ContextSnapshot snapshot) {
    final currentEnergy = snapshot.currentEnergy;

    return routines.where((r) {
      if (currentEnergy == EnergyLevel.low && !r.isEssential) {
        if (r.energyRule == EnergyRule.skip || r.energyRule == EnergyRule.highEnergyOnly) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}

/// Layer 5: Context & Daily Behavior Filter
class ContextDailyBehaviorFilter implements RoutineFilter {
  const ContextDailyBehaviorFilter();

  @override
  List<Routine> filter(List<Routine> routines, ContextSnapshot snapshot) {
    final dailyBehavior = snapshot.dailyBehavior;
    final behavior = dailyBehavior.behavior;
    final context = dailyBehavior.context;

    return routines.where((r) {
      if (behavior == 'SILENCE_ALL') {
        final isCriticalMedicine = r.category == Category.medical && r.isEssential;
        if (!isCriticalMedicine) {
          return false;
        }
      } else if (behavior == 'ESSENTIAL_ONLY') {
        if (!r.isEssential) {
          return false;
        }
      }

      if (context == LifeContext.sick && r.category == Category.fitness) {
        return false;
      }

      return true;
    }).toList();
  }
}
