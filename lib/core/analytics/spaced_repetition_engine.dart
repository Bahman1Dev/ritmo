import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';

@immutable
class SpacedRepetitionInput {
  const SpacedRepetitionInput({
    required this.topics,
    this.examDate,
    this.dailyTargetMinutes = 120,
    this.now,
  });

  final List<Map<String, dynamic>> topics;
  final DateTime? examDate;
  final int dailyTargetMinutes;
  final DateTime? now;

  @override
  String toString() {
    return 'SpacedRepetitionInput(topicsCount: ${topics.length}, examDate: $examDate, dailyTarget: $dailyTargetMinutes, now: $now)';
  }
}

@immutable
class ScheduledReviewItem {
  const ScheduledReviewItem({
    required this.topicId,
    required this.topicName,
    required this.subjectId,
    required this.scheduledDateStr,
    required this.estimatedMinutes,
    required this.intervalDays,
    required this.isDecayed,
  });

  final String topicId;
  final String topicName;
  final String subjectId;
  final String scheduledDateStr;
  final int estimatedMinutes;
  final int intervalDays;
  final bool isDecayed;
}

@immutable
class SpacedRepetitionOutput {
  const SpacedRepetitionOutput({
    required this.scheduledReviews,
    required this.decayedTopicsCount,
    required this.overallReadinessPercentage,
  });

  final List<ScheduledReviewItem> scheduledReviews;
  final int decayedTopicsCount;
  final double overallReadinessPercentage;
}

/// Spaced Repetition & Mastery Decay Engine (Ebbinghaus, Cepeda — §7, م-۸, م-۱۴)
class SpacedRepetitionEngine
    implements CachedEngine<SpacedRepetitionInput, SpacedRepetitionOutput> {
  static const List<int> standardIntervals = [1, 3, 7, 16, 35, 90];
  static const int masteryDecayThresholdDays = 60;

  @override
  bool canRun(SpacedRepetitionInput input) => true;

  @override
  List<Type> dependencies() => [];

  @override
  Duration get ttl => const Duration(minutes: 15);

  @override
  void invalidate() {}

  @override
  String fingerprint(SpacedRepetitionInput input) => input.toString();

  @override
  Future<SpacedRepetitionOutput> calculate(SpacedRepetitionInput input) async {
    final now = input.now ?? DateTime.now();
    
    final scheduledReviews = <ScheduledReviewItem>[];
    int decayedCount = 0;
    final totalTopics = input.topics.length;
    int masteredCount = 0;

    final isFinal30Days = input.examDate != null &&
        input.examDate!.difference(now).inDays <= 30 &&
        input.examDate!.difference(now).inDays > 0;

    for (final topic in input.topics) {
      final topicId = topic['id'] as String? ?? '';
      final name = topic['name'] as String? ?? 'مبحث';
      final subjectId = topic['subjectId'] as String? ?? '';
      final masteryLevel = (topic['masteryLevel'] as String? ?? 'NOT_STARTED').toUpperCase();
      final lastStudiedMs = topic['lastStudiedAt'] as int?;
      
      bool isDecayed = false;

      // Mastery Decay (§7, م-۱۴): Unreviewed for > 60 days
      if (lastStudiedMs != null) {
        final lastStudiedDate = DateTime.fromMillisecondsSinceEpoch(lastStudiedMs);
        final daysSinceLastStudy = now.difference(lastStudiedDate).inDays;
        if (daysSinceLastStudy > masteryDecayThresholdDays && masteryLevel == 'MASTERED') {
          isDecayed = true;
          decayedCount++;
        }
      }

      if (masteryLevel == 'MASTERED' && !isDecayed) {
        masteredCount++;
      }

      // Calculate next review interval
      int currentInterval = 1;
      final prevInterval = topic['lastIntervalDays'] as int? ?? 1;
      final score = (topic['lastReviewScore'] as num?)?.toDouble() ?? 80.0;

      if (score >= 70.0) {
        currentInterval = (prevInterval * 2.5).round().clamp(1, 90);
        if (isFinal30Days) {
          // Compress interval in final 30 days before exam
          currentInterval = currentInterval.clamp(1, 7);
        }
      } else {
        currentInterval = 1; // Reset on failure
      }

      final nextReviewDate = now.add(Duration(days: currentInterval));

      // Guard: Do not schedule review past exam date
      if (input.examDate != null && nextReviewDate.isAfter(input.examDate!)) {
        continue;
      }

      final nextDateStr = nextReviewDate.toIso8601String().substring(0, 10);
      final minutes = (topic['reviewTargetMinutes'] as int?) ?? 30;

      scheduledReviews.add(ScheduledReviewItem(
        topicId: topicId,
        topicName: name,
        subjectId: subjectId,
        scheduledDateStr: nextDateStr,
        estimatedMinutes: minutes,
        intervalDays: currentInterval,
        isDecayed: isDecayed,
      ));
    }

    final overallReadiness = totalTopics > 0 ? (masteredCount / totalTopics) * 100.0 : 0.0;

    return SpacedRepetitionOutput(
      scheduledReviews: scheduledReviews,
      decayedTopicsCount: decayedCount,
      overallReadinessPercentage: overallReadiness,
    );
  }
}
