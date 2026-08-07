import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';

@immutable
class DailyBudgetInput {
  const DailyBudgetInput({
    required this.dateStr,
    required this.plannedItems,
    this.loggedSleepHours,
    this.worshipMinutes = 45,
    this.frictionCoefficient = 0.20,
  });

  final String dateStr;
  final List<Map<String, dynamic>> plannedItems;
  final double? loggedSleepHours;
  final int worshipMinutes;
  final double frictionCoefficient;

  @override
  String toString() {
    return 'DailyBudgetInput(dateStr: $dateStr, itemsCount: ${plannedItems.length}, sleep: $loggedSleepHours, worship: $worshipMinutes, friction: $frictionCoefficient)';
  }
}

@immutable
class DailyBudgetOutput {
  const DailyBudgetOutput({
    required this.dateStr,
    required this.capacityHours,
    required this.plannedHours,
    required this.isOverBudget,
    required this.overBudgetHours,
    required this.removableSuggestions,
    required this.formattedAlertMessage,
  });

  final String dateStr;
  final double capacityHours;
  final double plannedHours;
  final bool isOverBudget;
  final double overBudgetHours;
  final List<Map<String, dynamic>> removableSuggestions;
  final String formattedAlertMessage;
}

/// Real Daily Budget Engine (Kahneman Planning Fallacy for Day-level Capacity — م-۳)
class DailyBudgetEngine implements CachedEngine<DailyBudgetInput, DailyBudgetOutput> {
  @override
  bool canRun(DailyBudgetInput input) => input.dateStr.isNotEmpty;

  @override
  List<Type> dependencies() => [];

  @override
  Duration get ttl => const Duration(minutes: 10);

  @override
  void invalidate() {}

  @override
  String fingerprint(DailyBudgetInput input) => input.toString();

  @override
  Future<DailyBudgetOutput> calculate(DailyBudgetInput input) async {
    final sleepHours = input.loggedSleepHours ?? 7.5;
    final awakeHours = 24.0 - sleepHours;
    final worshipHours = input.worshipMinutes / 60.0;
    final availableAwakeHours = (awakeHours - worshipHours).clamp(0.0, 24.0);

    // Apply empirical friction factor (e.g. 20% friction)
    final capacityHours = availableAwakeHours * (1.0 - input.frictionCoefficient);

    // Sum planned minutes from items
    int totalPlannedMinutes = 0;
    final candidates = <Map<String, dynamic>>[];

    for (final item in input.plannedItems) {
      final rawEssential = item['isEssential'];
      final isEssential = rawEssential == 1 || rawEssential == true || rawEssential == '1';
      final category = (item['category'] as String? ?? '').toLowerCase();
      final isWorshipOrMed = category == 'religious' || category == 'medical';

      final duration = (item['targetDurationMinutes'] as int?) ??
          (item['durationMinutes'] as int?) ??
          (item['estimatedMinutes'] as int?) ??
          30;

      totalPlannedMinutes += duration;

      if (!isEssential && !isWorshipOrMed) {
        candidates.add({
          'id': item['id'],
          'title': item['title'] ?? 'برنامه بدون عنوان',
          'durationMinutes': duration,
          'category': category,
          'priority': (item['priority'] as num?)?.toDouble() ?? 1.0,
        });
      }
    }

    final plannedHours = totalPlannedMinutes / 60.0;
    final isOverBudget = plannedHours > capacityHours;
    final overBudgetHours = isOverBudget ? (plannedHours - capacityHours) : 0.0;

    // Pick top 3 removable/deferrable suggestions sorted by priority ascending, then duration descending
    candidates.sort((a, b) {
      final prioA = a['priority'] as double;
      final priob = b['priority'] as double;
      if (prioA != priob) return prioA.compareTo(priob);
      final durA = a['durationMinutes'] as int;
      final durB = b['durationMinutes'] as int;
      return durB.compareTo(durA);
    });

    final removableSuggestions = candidates.take(3).toList();

    String alertMessage = '';
    if (isOverBudget) {
      final pStr = plannedHours.toStringAsFixed(1);
      final cStr = capacityHours.toStringAsFixed(1);
      alertMessage = 'برنامهٔ امروزت $pStr ساعت است، ظرفیت واقعیات حدود $cStr ساعت است. برای پیشگیری از خستگی، حذف یا تعویق این موارد پیشنهاد می‌شود.';
    }

    return DailyBudgetOutput(
      dateStr: input.dateStr,
      capacityHours: capacityHours,
      plannedHours: plannedHours,
      isOverBudget: isOverBudget,
      overBudgetHours: overBudgetHours,
      removableSuggestions: removableSuggestions,
      formattedAlertMessage: alertMessage,
    );
  }
}
