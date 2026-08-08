import 'package:ritmo/features/study/domain/study_models.dart';

enum SessionFeedback { needAgain, partial, understood }

class ReviewResult {
  const ReviewResult({
    required this.nextReviewDays,
    required this.nextMastery,
  });

  final int nextReviewDays;
  final StudyMastery nextMastery;
}

class StudyReviewPolicy {
  const StudyReviewPolicy._();

  static ReviewResult evaluate({
    required SessionFeedback feedback,
    required StudyMastery currentMastery,
    required int reviewCount,
  }) {
    switch (feedback) {
      case SessionFeedback.needAgain:
        return const ReviewResult(nextReviewDays: 1, nextMastery: StudyMastery.learning);

      case SessionFeedback.partial:
        return ReviewResult(nextReviewDays: 3, nextMastery: currentMastery);

      case SessionFeedback.understood:
        if (reviewCount <= 0) {
          return const ReviewResult(nextReviewDays: 7, nextMastery: StudyMastery.review);
        } else if (reviewCount == 1) {
          return const ReviewResult(nextReviewDays: 16, nextMastery: StudyMastery.review);
        } else {
          return const ReviewResult(nextReviewDays: 35, nextMastery: StudyMastery.mastered);
        }
    }
  }
}
