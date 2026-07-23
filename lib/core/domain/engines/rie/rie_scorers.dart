// lib/core/domain/engines/rie/rie_scorers.dart

import 'package:ritmo/core/domain/engines/rie/context_snapshot.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';

abstract interface class RoutineScorer {
  /// Calculates a heuristic relevance score for the [routine] in the environment
  /// defined by the [snapshot].
  double score(Routine routine, ContextSnapshot snapshot);
}

/// 1. Zone Match Scorer
class ZoneMatchScorer implements RoutineScorer {
  const ZoneMatchScorer();

  @override
  double score(Routine routine, ContextSnapshot snapshot) {
    if (routine.zoneId != null && routine.zoneId == snapshot.activeZoneId) {
      return 1;
    }
    return 0;
  }
}

/// 2. Context Match Scorer
class ContextMatchScorer implements RoutineScorer {
  const ContextMatchScorer();

  @override
  double score(Routine routine, ContextSnapshot snapshot) {
    final context = snapshot.dailyBehavior.context;
    
    if (context == LifeContext.exam &&
        (routine.category == Category.learning || routine.category == Category.konkur)) {
      return 2;
    }
    if (context == LifeContext.sick && routine.category == Category.medical) {
      return 2;
    }
    if (context == LifeContext.travel && routine.category == Category.free) {
      return 1;
    }
    if (context == LifeContext.worship && routine.category == Category.religious) {
      return 2;
    }
    return 0;
  }
}

/// 3. Energy Fit Scorer
class EnergyFitScorer implements RoutineScorer {
  const EnergyFitScorer();

  @override
  double score(Routine routine, ContextSnapshot snapshot) {
    final currentEnergy = snapshot.currentEnergy;

    if (currentEnergy == EnergyLevel.high) {
      return (routine.category == Category.fitness || routine.priority > 1.5) ? 2.0 : 1.0;
    }
    if (currentEnergy == EnergyLevel.medium) {
      return 1;
    }
    if (currentEnergy == EnergyLevel.low) {
      if (routine.energyRule == EnergyRule.offerLight || routine.energyRule == EnergyRule.offerMinimal) {
        return 2;
      }
    }
    return 0;
  }
}

/// 4. Time Relevance Scorer
class TimeRelevanceScorer implements RoutineScorer {
  const TimeRelevanceScorer();

  @override
  double score(Routine routine, ContextSnapshot snapshot) {
    final sched = snapshot.routineSchedulesByRoutineId[routine.id];
    if (sched == null) return 0;

    final timeStr = sched['timeOfDay'] as String?;
    if (timeStr == null) return 0;

    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;

    final hour = int.tryParse(parts[0]) ?? 0;
    final min = int.tryParse(parts[1]) ?? 0;
    final now = snapshot.now;

    final diff = (hour * 60 + min - now.hour * 60 - now.minute).abs();
    if (diff <= 30) {
      return 2;
    }
    if (diff <= 60) {
      return 1;
    }
    return 0;
  }
}

/// 5. Essential Bonus Scorer
class EssentialBonusScorer implements RoutineScorer {
  const EssentialBonusScorer();

  @override
  double score(Routine routine, ContextSnapshot snapshot) {
    return routine.isEssential ? 3.0 : 0.0;
  }
}

/// 6. Focus Area Boost Scorer
class FocusAreaBoostScorer implements RoutineScorer {
  const FocusAreaBoostScorer();

  @override
  double score(Routine routine, ContextSnapshot snapshot) {
    final focusAreas = snapshot.focusAreas;
    if (focusAreas.isEmpty) return 0;

    var isFocusCategory = false;
    for (final area in focusAreas) {
      if (area == 'سلامتی' && routine.category == Category.medical) isFocusCategory = true;
      if (area == 'ورزش' && routine.category == Category.fitness) isFocusCategory = true;
      if (area == 'درس' && (routine.category == Category.learning || routine.category == Category.konkur)) isFocusCategory = true;
      if (area == 'یادگیری مهارت' && routine.category == Category.learning) isFocusCategory = true;
      if (area == 'کار' && routine.category == Category.work) isFocusCategory = true;
      if (area == 'کسب درآمد' && routine.category == Category.work) isFocusCategory = true;
      if (area == 'عبادت' && routine.category == Category.religious) isFocusCategory = true;
      if (area == 'خانواده' && routine.category == Category.personal) isFocusCategory = true;
      if (area == 'کاهش استرس' && (routine.category == Category.free || routine.category == Category.personal)) isFocusCategory = true;
    }

    return isFocusCategory ? 1.5 : 0.0;
  }
}

/// 7. Sleep Window Penalty Scorer
class SleepWindowPenaltyScorer implements RoutineScorer {
  const SleepWindowPenaltyScorer();

  @override
  double score(Routine routine, ContextSnapshot snapshot) {
    if (snapshot.isSleepTime && !routine.isEssential) {
      return -5; // sleep penalty subtracted
    }
    return 0;
  }
}

/// 8. Reflection-Aware Scorer
class ReflectionAwareScorer implements RoutineScorer {
  const ReflectionAwareScorer();

  @override
  double score(Routine routine, ContextSnapshot snapshot) {
    if (!snapshot.gentleMode || routine.isEssential) return 0;

    var scoreAdjustment = 0.0;
    final isHeavy = routine.priority > 1.5 ||
        routine.energyRule == EnergyRule.highEnergyOnly ||
        routine.energyImpact > 0;

    if (isHeavy) scoreAdjustment -= 1.5;
    if (routine.energyRule == EnergyRule.offerLight ||
        routine.energyRule == EnergyRule.offerMinimal) {
      scoreAdjustment += 1.0;
    }
    return scoreAdjustment;
  }
}

/// 9. Energy Mismatch Penalty Scorer
class EnergyMismatchPenaltyScorer implements RoutineScorer {
  const EnergyMismatchPenaltyScorer();

  @override
  double score(Routine routine, ContextSnapshot snapshot) {
    if (snapshot.currentEnergy == EnergyLevel.low &&
        routine.energyRule == EnergyRule.highEnergyOnly) {
      return -2; // penalty subtracted
    }
    return 0;
  }
}
