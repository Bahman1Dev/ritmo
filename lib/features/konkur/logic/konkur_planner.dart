import 'dart:math';

import 'package:ritmo/features/konkur/models/konkur_models.dart';

/// Service responsible for generating study plans, spaced repetition schedules,
/// and progress metrics for Konkur preparation.
class KonkurPlanner {
  /// Build a balanced study plan without last-day dump spikes.
  /// Uses Windowed Backfill (horizon capped between 7 and 30 days)
  /// and checks DAG prerequisites before scheduling topics.
  static List<KonkurPlanItem> buildPlan({
    required List<KonkurSubject> subjects,
    required List<KonkurTopic> topics,
    required DateTime examDate,
    required DateTime from,
    required int dailyTargetMinutes,
  }) {
    final cleanFrom = DateTime(from.year, from.month, from.day);
    final cleanExam = DateTime(examDate.year, examDate.month, examDate.day);

    final daysUntilExam = cleanExam.difference(cleanFrom).inDays + 1;
    if (daysUntilExam <= 0) return [];

    final topicMap = {for (final t in topics) t.id: t};

    // Filter candidate topics: not mastered and prerequisites met (DAG check)
    final candidates =
        topics.where((t) {
          if (t.masteryLevel == MasteryLevel.mastered) return false;
          return _arePrerequisitesMet(t, topicMap);
        }).toList();

    if (candidates.isEmpty) return [];

    // Calculate subject importance map
    final subjectImportance = {
      for (final s in subjects) s.id: s.importanceFactor,
    };

    // Calculate priority for each topic
    final priorityList = <MapEntry<KonkurTopic, double>>[];
    for (final topic in candidates) {
      final imp = subjectImportance[topic.subjectId] ?? 1.0;
      var priority = topic.examQuestionCount * imp;

      if (topic.masteryLevel == MasteryLevel.learning) {
        priority *= 1.3;
      } else if (topic.masteryLevel == MasteryLevel.needsReview) {
        priority *= 1.5;
      }
      priorityList.add(MapEntry(topic, priority));
    }

    // Sort descending by priority
    priorityList.sort((a, b) => b.value.compareTo(a.value));
    final sortedTopics = priorityList.map((e) => e.key).toList();

    final planItems = <KonkurPlanItem>[];

    // Windowed Backfill: effective horizon is capped between 7 and 30 days
    final effectiveHorizon = max(7, min(daysUntilExam, 30));

    // Cap backfill to max 30% of daily capacity
    final maxBackfillMinutesPerDay = (dailyTargetMinutes * 0.30).round();
    final regularStudyMinutesPerDay =
        dailyTargetMinutes - maxBackfillMinutesPerDay;

    var topicIndex = 0;

    // Distribute topics day by day across effectiveHorizon
    for (var dayOffset = 0; dayOffset < effectiveHorizon; dayOffset++) {
      final currentDay = cleanFrom.add(Duration(days: dayOffset));
      final dateStr = _formatDateIso(currentDay);
      var allocatedMinutesToday = 0;

      while (allocatedMinutesToday < regularStudyMinutesPerDay &&
          topicIndex < sortedTopics.length) {
        final topic = sortedTopics[topicIndex];
        final remainingMinutes = max(
          30,
          topic.studyTargetMinutes - topic.studyCompletedMinutes,
        );

        // Flexible Pomodoro session: 45 to 60 minutes
        final sessionMinutes = min(
          60,
          min(regularStudyMinutesPerDay - allocatedMinutesToday, remainingMinutes),
        );

        if (sessionMinutes < 15) break;

        planItems.add(
          KonkurPlanItem(
            id: 'plan_${dateStr}_${topic.id}_$dayOffset',
            dateIso: dateStr,
            subjectId: topic.subjectId,
            topicId: topic.id,
            plannedMinutes: sessionMinutes,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        allocatedMinutesToday += sessionMinutes;

        if (sessionMinutes >= remainingMinutes) {
          topicIndex++;
        } else {
          break; // Continue this topic on subsequent day
        }
      }
    }

    return planItems;
  }

  /// Checks if all prerequisite topics are sufficiently completed.
  static bool _arePrerequisitesMet(
    KonkurTopic topic,
    Map<String, KonkurTopic> topicMap,
  ) {
    if (topic.prerequisiteTopicIds.isEmpty) return true;
    for (final prereqId in topic.prerequisiteTopicIds) {
      final prereq = topicMap[prereqId];
      if (prereq == null) continue;
      if (prereq.progressPercentage < 0.6 &&
          prereq.masteryLevel == MasteryLevel.notStarted) {
        return false; // Prerequisite not met
      }
    }
    return true;
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
              plannedMinutes: 30, // 30 mins spaced repetition slot
              createdAt: DateTime.now().millisecondsSinceEpoch,
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

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
