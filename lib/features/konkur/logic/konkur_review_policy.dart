import 'package:ritmo/features/konkur/models/konkur_models.dart';

/// Spaced repetition review policy and scheduling rules engine for Konkur preparation.
class KonkurReviewPolicy {
  const KonkurReviewPolicy();

  /// Computes the next review date based on session outcome and mastery level.
  DateTime? computeNextReviewDate({
    required String? outcome,
    required MasteryLevel currentMastery,
    required DateTime from,
  }) {
    final cleanFrom = DateTime(from.year, from.month, from.day);

    if (outcome == 'NEEDS_REVIEW') {
      return cleanFrom.add(const Duration(days: 1));
    }

    if (outcome == 'NEEDS_PRACTICE') {
      return cleanFrom.add(const Duration(days: 2));
    }

    if (outcome == 'PARTIAL') {
      return cleanFrom.add(const Duration(days: 3));
    }

    if (outcome == 'UNDERSTOOD') {
      switch (currentMastery) {
        case MasteryLevel.notStarted:
        case MasteryLevel.learning:
          return cleanFrom.add(const Duration(days: 3));
        case MasteryLevel.needsReview:
          return cleanFrom.add(const Duration(days: 7));
        case MasteryLevel.mastered:
          return cleanFrom.add(const Duration(days: 21));
      }
    }

    // Default fallback interval for non-outcome updates
    if (currentMastery == MasteryLevel.mastered) {
      return cleanFrom.add(const Duration(days: 21));
    } else if (currentMastery == MasteryLevel.needsReview) {
      return cleanFrom.add(const Duration(days: 3));
    }

    return null;
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
