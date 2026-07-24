import 'dart:math';

import 'package:ritmo/features/konkur/logic/konkur_capacity_estimator.dart';
import 'package:ritmo/features/konkur/logic/konkur_topic_priority_engine.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';

/// The core adaptive planning engine for Konkur preparation.
/// Schedules topics based on priority rankings, exam feedback loops,
/// spaced repetition, capacity constraints, cognitive alternation, and user locks.
class KonkurPlanningEngine {
  const KonkurPlanningEngine({
    this.priorityEngine = const KonkurTopicPriorityEngine(),
    this.capacityEstimator = const KonkurCapacityEstimator(),
  });

  final KonkurTopicPriorityEngine priorityEngine;
  final KonkurCapacityEstimator capacityEstimator;

  List<KonkurPlanItem> buildPlan(KonkurPlanningContext context) {
    if (context.subjects.isEmpty || context.topics.isEmpty) return [];

    final cleanToday = DateTime(context.today.year, context.today.month, context.today.day);
    final topicMap = {for (final t in context.topics) t.id: t};

    // Estimate per-day capacities for the planning horizon
    final dailyCapacities = capacityEstimator.estimate(
      start: cleanToday,
      days: context.planningHorizonDays,
      sessions: context.studySessions,
      currentEnergyLevel: context.energyProfile,
    );

    // Rank all topics
    final rankedPriorities = priorityEngine.rankTopics(context);

    // Map existing user-locked and user-edited items by dateIso
    final lockedItemsByDate = <String, List<KonkurPlanItem>>{};
    for (final item in context.existingPlanItems) {
      if (item.isLocked || item.isUserEdited) {
        lockedItemsByDate.putIfAbsent(item.dateIso, () => []).add(item);
      }
    }

    // Separate ranked topics into categories
    final overdueReviewTopics = rankedPriorities.where((p) => p.isReviewDue).toList();
    final weakRescueTopics = rankedPriorities.where((p) => p.isWeakArea && !p.isReviewDue).toList();
    final progressionTopics = rankedPriorities.where((p) => !p.isReviewDue && !p.isWeakArea).toList();

    final generatedPlan = <KonkurPlanItem>[];

    // Topic remaining minutes tracker for chunking
    final topicRemainingMinutes = <String, int>{};
    for (final topic in context.topics) {
      final rem = max(0, topic.studyTargetMinutes - topic.studyCompletedMinutes);
      topicRemainingMinutes[topic.id] = rem > 0 ? rem : 45;
    }

    // Track subject total minutes allocated per day to enforce 40% diversity rule
    final singleSubjectUser = context.subjects.length == 1;

    for (final dayCap in dailyCapacities) {
      final dateIso = dayCap.dateIso;
      final dayPlannedItems = <KonkurPlanItem>[];

      // Keep existing locked/user-edited items for this day
      final existingLocked = lockedItemsByDate[dateIso] ?? const [];
      int allocatedMinutes = 0;
      final daySubjectMinutes = <String, int>{};
      final dayConsecutiveSubjects = <String>[];

      for (final locked in existingLocked) {
        dayPlannedItems.add(locked);
        allocatedMinutes += locked.plannedMinutes;
        if (locked.subjectId != null) {
          daySubjectMinutes[locked.subjectId!] =
              (daySubjectMinutes[locked.subjectId!] ?? 0) + locked.plannedMinutes;
          dayConsecutiveSubjects.add(locked.subjectId!);
        }
      }

      final maxBlocksToday = dayCap.maxBlocks;
      final maxSubjectMinutesToday = singleSubjectUser
          ? dayCap.totalMinutes
          : (dayCap.totalMinutes * 0.45).round();

      // Helper function to check block eligibility
      bool canPlaceBlock(KonkurTopic topic, int blockMins) {
        if (dayPlannedItems.length >= maxBlocksToday) return false;
        if (allocatedMinutes + blockMins > dayCap.totalMinutes + 15) return false;

        // Anti-fragmentation: don't place micro-tasks if less than 20 mins remaining
        final remCapacity = dayCap.totalMinutes - allocatedMinutes;
        if (remCapacity < 20 && remCapacity < blockMins) return false;

        // Subject max percentage rule
        final currentSubMins = daySubjectMinutes[topic.subjectId] ?? 0;
        if (!singleSubjectUser && (currentSubMins + blockMins) > maxSubjectMinutesToday) {
          return false;
        }

        // Max 2 consecutive same-subject blocks
        if (dayConsecutiveSubjects.length >= 2) {
          final last1 = dayConsecutiveSubjects[dayConsecutiveSubjects.length - 1];
          final last2 = dayConsecutiveSubjects[dayConsecutiveSubjects.length - 2];
          if (last1 == topic.subjectId && last2 == topic.subjectId) {
            return false;
          }
        }

        return true;
      }

      // Helper function to add a plan block
      bool tryAddBlock(KonkurTopicPriority priority, String sourceType) {
        final topic = topicMap[priority.topicId];
        if (topic == null) return false;

        final remMinutes = topicRemainingMinutes[topic.id] ?? 45;
        if (remMinutes <= 0 && sourceType == 'AUTO') return false;

        // Block duration based on mode, energyContext multiplier, and capacity
        final multiplier = context.energyContext?.sessionMultiplier ?? 1.0;
        final maxSession = (60 * multiplier).round().clamp(20, 60);

        int blockMins = min(priority.recommendedBlockMinutes, maxSession);
        if (dayCap.energyLevel == 'LOW') {
          blockMins = min(blockMins, 35);
        }

        // Anti-cramming chunking: cap single block at maxSession mins
        blockMins = min(blockMins, remMinutes > 0 ? remMinutes : 45);

        if (!canPlaceBlock(topic, blockMins)) return false;

        // Build human explainability summary & bullets
        final explanation = _buildExplanation(topic, priority, sourceType, blockMins);
        final energyNote = multiplier < 1.0 ? context.energyContext?.farsiNote : null;

        final planItem = KonkurPlanItem(
          id: 'plan_${dateIso}_${topic.id}_${dayPlannedItems.length}',
          dateIso: dateIso,
          subjectId: topic.subjectId,
          topicId: topic.id,
          plannedMinutes: blockMins,
          status: 'PENDING',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          plannedMode: priority.recommendedMode,
          priorityScore: priority.score,
          planningReason: explanation.summary,
          sourceType: sourceType,
          recommendedEnergy: dayCap.energyLevel,
          carryOverCount: context.pendingCarryOverMap[topic.id] ?? 0,
          energyNote: energyNote,
        );

        dayPlannedItems.add(planItem);
        allocatedMinutes += blockMins;
        daySubjectMinutes[topic.subjectId] =
            (daySubjectMinutes[topic.subjectId] ?? 0) + blockMins;
        dayConsecutiveSubjects.add(topic.subjectId);

        if (topicRemainingMinutes.containsKey(topic.id)) {
          topicRemainingMinutes[topic.id] = max(0, remMinutes - blockMins);
        }

        return true;
      }

      // Step 1: Add overdue review blocks first
      for (final priority in overdueReviewTopics) {
        if (allocatedMinutes >= dayCap.totalMinutes) break;
        tryAddBlock(priority, 'REVIEW');
      }

      // Step 2: Add weak-area rescue blocks second
      for (final priority in weakRescueTopics) {
        if (allocatedMinutes >= dayCap.totalMinutes) break;
        tryAddBlock(priority, 'EXAM_RESCUE');
      }

      // Step 3: Add normal study progression topics third
      for (final priority in progressionTopics) {
        if (allocatedMinutes >= dayCap.totalMinutes) break;
        tryAddBlock(priority, 'AUTO');
      }

      // Step 4: Light review filler if 15-30 mins remain
      final remainingCap = dayCap.totalMinutes - allocatedMinutes;
      if (remainingCap >= 15 && dayPlannedItems.length < maxBlocksToday) {
        for (final priority in rankedPriorities) {
          if (priority.recommendedMode == 'REVIEW') {
            final topic = topicMap[priority.topicId];
            if (topic != null && canPlaceBlock(topic, remainingCap)) {
              tryAddBlock(priority, 'REVIEW');
              break;
            }
          }
        }
      }

      generatedPlan.addAll(dayPlannedItems);
    }

    return generatedPlan;
  }

  KonkurPlanExplanation _buildExplanation(
    KonkurTopic topic,
    KonkurTopicPriority priority,
    String sourceType,
    int blockMinutes,
  ) {
    final bullets = <String>[...priority.reasons];
    String summary = priority.primaryReason;

    if (sourceType == 'REVIEW') {
      summary = 'مرور سررسید شده جهت تثبیت در حافظه بلندمدت';
    } else if (sourceType == 'EXAM_RESCUE') {
      summary = 'برنامه ویژه نجات و تقویت مبحث بر اساس آزمون آزمایشی اخیر';
    }

    return KonkurPlanExplanation(
      itemId: topic.id,
      summary: summary,
      bullets: bullets,
    );
  }
}
