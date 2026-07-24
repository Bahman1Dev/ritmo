import 'package:ritmo/core/domain/models/energy_context.dart';
import 'package:ritmo/features/konkur/logic/konkur_planning_engine.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';

/// Thin compatibility wrapper for Konkur study plan generation.
/// Real planning logic is handled by [KonkurPlanningEngine].
class KonkurPlanner {
  /// Build an adaptive, exam-aware, spaced-repetition study plan.
  static List<KonkurPlanItem> buildPlan({
    required List<KonkurSubject> subjects,
    required List<KonkurTopic> topics,
    required DateTime examDate,
    required DateTime from,
    required int dailyTargetMinutes,
    List<KonkurStudySession> studySessions = const [],
    List<KonkurMockExam> mockExams = const [],
    List<KonkurMockResult> mockResults = const [],
    List<KonkurPlanItem> existingPlanItems = const [],
    String energyLevel = 'MEDIUM',
    EnergyContext? energyContext,
  }) {
    final cleanFrom = DateTime(from.year, from.month, from.day);
    final cleanExam = DateTime(examDate.year, examDate.month, examDate.day);

    final daysUntilExam = cleanExam.difference(cleanFrom).inDays + 1;
    if (daysUntilExam <= 0) return [];

    final context = KonkurPlanningContext(
      subjects: subjects,
      topics: topics,
      studySessions: studySessions,
      mockExams: mockExams,
      mockResults: mockResults,
      existingPlanItems: existingPlanItems,
      today: cleanFrom,
      planningHorizonDays: daysUntilExam.clamp(7, 30),
      dailyCapacityMinutes: dailyTargetMinutes,
      energyProfile: energyLevel,
      energyContext: energyContext,
    );

    return const KonkurPlanningEngine().buildPlan(context);
  }

  /// Generates Spaced Repetition review slots (+2 days, +10 days, +30 days)
  /// for topics where concept phase is finished.
  static List<KonkurPlanItem> buildSpacedRepetitionSlots({
    required List<KonkurTopic> topics,
    required DateTime from,
  }) {
    final reviewItems = <KonkurPlanItem>[];
    final cleanFrom = DateTime(from.year, from.month, from.day);
    final dateStr = _formatDateIso(cleanFrom);

    for (final topic in topics) {
      if (topic.isConceptFinished ||
          topic.masteryLevel == MasteryLevel.needsReview) {
        final dueStr = topic.nextReviewDate;
        if (dueStr != null &&
            dueStr.isNotEmpty &&
            dueStr.compareTo(dateStr) <= 0) {
          reviewItems.add(
            KonkurPlanItem(
              id: 'review_${dateStr}_${topic.id}',
              dateIso: dateStr,
              subjectId: topic.subjectId,
              topicId: topic.id,
              plannedMinutes: 30,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              plannedMode: 'REVIEW',
              sourceType: 'REVIEW',
              planningReason: 'مرور سررسید شده منحنی یادگیری',
            ),
          );
        }
      }
    }

    return reviewItems;
  }

  /// Generates review slots for mastered topics.
  static List<KonkurPlanItem> buildReviewSlots({
    required List<KonkurTopic> mastered,
    required DateTime from,
  }) {
    return buildSpacedRepetitionSlots(topics: mastered, from: from);
  }

  /// Calculates how many pending plan items fall before [today].
  static int daysBehind({
    required List<KonkurPlanItem> planItems,
    required DateTime today,
  }) {
    final todayStr = _formatDateIso(today);
    return planItems
        .where(
          (item) => item.dateIso.compareTo(todayStr) < 0 && item.status == 'PENDING',
        )
        .length;
  }

  static List<KonkurPlanItem> carryForward({
    required List<KonkurPlanItem> overdueItems,
    required DateTime today,
    required int dailyTargetMinutes,
    required int alreadyAllocatedMinutes,
  }) {
    final todayStr = _formatDateIso(today);
    final remaining = dailyTargetMinutes - alreadyAllocatedMinutes;
    if (remaining <= 0) return [];

    var budget = remaining;
    final carried = <KonkurPlanItem>[];

    for (final item in overdueItems) {
      if (budget <= 0) break;
      final mins = item.plannedMinutes.clamp(15, budget);
      carried.add(item.copyWith(
        id: 'carry_${todayStr}_${item.id}',
        dateIso: todayStr,
        plannedMinutes: mins,
        note: 'انتقال از ${item.dateIso}',
        status: 'PENDING',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      budget -= mins;
    }

    return carried;
  }

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
