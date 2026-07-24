import 'package:ritmo/core/domain/models/energy_context.dart';
import 'package:ritmo/features/konkur/logic/konkur_planning_engine.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';

/// Replan service that rebuilds future plans while preserving user edits,
/// completed items, and carry-over history.
class KonkurReplanService {
  const KonkurReplanService({
    this.planningEngine = const KonkurPlanningEngine(),
  });

  final KonkurPlanningEngine planningEngine;

  Future<List<KonkurPlanItem>> rebuildFuturePlan({
    required KonkurRepository repository,
    required DateTime today,
    bool preserveToday = true,
    bool preserveLocked = true,
    bool preserveUserEdited = true,
    int planningHorizonDays = 14,
    EnergyContext? energyContext,
  }) async {
    final cleanToday = DateTime(today.year, today.month, today.day);
    final todayStr = _formatDateIso(cleanToday);

    // Fetch all context data from repository
    final subjects = await repository.getSubjects();
    final topics = await repository.getTopics();
    final studySessions = await repository.getStudySessions();
    final mockExams = await repository.getMockExams();
    final mockResults = await repository.getMockResults();
    final existingPlanItems = await repository.getPlanItems();
    final settings = await repository.getAppSettings();

    final energyProfile = settings['energy_level'] ?? 'MEDIUM';
    final dailyTargetMinutes = int.tryParse(settings['konkur_daily_target_minutes'] ?? '180') ?? 180;
    final fieldStr = settings['konkur_field'] ?? 'RIYAZI';
    final field = KonkurField.fromString(fieldStr);

    // Map carryover count for pending overdue items before today
    final pendingCarryOverMap = <String, int>{};
    for (final item in existingPlanItems) {
      if (item.status == 'PENDING' && item.dateIso.compareTo(todayStr) < 0) {
        if (item.topicId != null) {
          pendingCarryOverMap[item.topicId!] =
              (pendingCarryOverMap[item.topicId!] ?? 0) + item.carryOverCount + 1;
        }
      }
    }

    final context = KonkurPlanningContext(
      subjects: subjects,
      topics: topics,
      studySessions: studySessions,
      mockExams: mockExams,
      mockResults: mockResults,
      existingPlanItems: existingPlanItems,
      today: cleanToday,
      planningHorizonDays: planningHorizonDays,
      dailyCapacityMinutes: dailyTargetMinutes,
      preferredField: field,
      energyProfile: energyProfile,
      pendingCarryOverMap: pendingCarryOverMap,
      energyContext: energyContext,
    );

    // Generate new plan using PlanningEngine
    final newPlanItems = planningEngine.buildPlan(context);

    // Save plan with surgical deletion (preserving DONE, SKIPPED, user-edited, locked, and today)
    await repository.savePlanItemsSmart(
      newPlanItems,
      preserveToday: preserveToday,
      preserveLocked: preserveLocked,
      preserveUserEdited: preserveUserEdited,
    );

    return repository.getPlanItems();
  }

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
