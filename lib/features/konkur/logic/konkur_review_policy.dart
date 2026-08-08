import 'package:ritmo/features/konkur/models/konkur_models.dart';

/// Spaced repetition review policy and scheduling rules engine for Konkur preparation.
class KonkurReviewPolicy {
  const KonkurReviewPolicy();

  static const List<int> standardIntervals = [1, 3, 7, 16, 35, 90];
  static const int masteryDecayThresholdDays = 60;

  /// Computes the next review date based on session outcome, mastery level, and optional exam date.
  DateTime? computeNextReviewDate({
    required String? outcome,
    required MasteryLevel currentMastery,
    required DateTime from,
    DateTime? examDate,
    DateTime? lastStudiedAt,
  }) {
    final cleanFrom = DateTime(from.year, from.month, from.day);

    // Final 30 days compression before exam
    final isFinal30Days = examDate != null &&
        examDate.difference(cleanFrom).inDays <= 30 &&
        examDate.difference(cleanFrom).inDays > 0;

    int intervalDays = 7;

    if (outcome == 'NEEDS_REVIEW') {
      intervalDays = 1;
    } else if (outcome == 'NEEDS_PRACTICE') {
      intervalDays = 3;
    } else if (outcome == 'PARTIAL') {
      intervalDays = 3;
    } else if (outcome == 'UNDERSTOOD') {
      switch (currentMastery) {
        case MasteryLevel.notStarted:
        case MasteryLevel.learning:
          intervalDays = 3;
          break;
        case MasteryLevel.needsReview:
          intervalDays = 7;
          break;
        case MasteryLevel.mastered:
          intervalDays = 35;
          break;
      }
    } else {
      if (currentMastery == MasteryLevel.mastered) {
        intervalDays = 35;
      } else if (currentMastery == MasteryLevel.needsReview) {
        intervalDays = 7;
      } else {
        return null;
      }
    }

    if (isFinal30Days) {
      intervalDays = intervalDays.clamp(1, 7);
    }

    final nextReviewDate = cleanFrom.add(Duration(days: intervalDays));
    if (examDate != null && nextReviewDate.isAfter(examDate)) {
      return examDate;
    }

    return nextReviewDate;
  }

  /// Recommends mode (STUDY / TEST / REVIEW) based on completion targets and review due date.
  String recommendModeForTopic(KonkurTopic topic, DateTime today) {
    final todayStr = _formatDateIso(today);

    // Overdue review takes precedence
    if (topic.nextReviewDate != null &&
        topic.nextReviewDate!.isNotEmpty &&
        topic.nextReviewDate!.compareTo(todayStr) <= 0) {
      return 'REVIEW';
    }

    // Concept unfinished
    if (!topic.isConceptFinished) {
      return 'STUDY';
    }

    // Practice unfinished
    if (topic.practiceCompletedMinutes < topic.practiceTargetMinutes) {
      return 'TEST';
    }

    return 'REVIEW';
  }

  /// Computes numerical review urgency score (0..32).
  int computeReviewUrgency({
    required KonkurTopic topic,
    required DateTime today,
  }) {
    if (topic.nextReviewDate == null || topic.nextReviewDate!.isEmpty) return 0;

    final todayStr = _formatDateIso(today);
    final cmp = topic.nextReviewDate!.compareTo(todayStr);
    if (cmp > 0) return 0;

    try {
      final dueDt = DateTime.parse(topic.nextReviewDate!);
      final daysOverdue = today.difference(dueDt).inDays;

      if (daysOverdue >= 8) return 32;
      if (daysOverdue >= 4) return 24;
      if (daysOverdue >= 2) return 16;
      return 10;
    } catch (_) {
      return 10;
    }
  }

  /// Maintenance review rule: Mastered topics unstudied for 21+ days must be reviewed.
  bool needsMaintenanceReview(KonkurTopic topic, DateTime today) {
    if (topic.masteryLevel != MasteryLevel.mastered) return false;
    if (topic.lastStudiedAt == null) return true;

    final lastDt = DateTime.fromMillisecondsSinceEpoch(topic.lastStudiedAt!);
    final days = today.difference(lastDt).inDays;
    return days >= 21;
  }

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
