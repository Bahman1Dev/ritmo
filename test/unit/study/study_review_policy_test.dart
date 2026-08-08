import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/study/domain/study_models.dart';
import 'package:ritmo/features/study/domain/study_review_policy.dart';

void main() {
  group('StudyReviewPolicy Unit Tests', () {
    test('needAgain returns 1 day and learning mastery', () {
      final res = StudyReviewPolicy.evaluate(
        feedback: SessionFeedback.needAgain,
        currentMastery: StudyMastery.mastered,
        reviewCount: 2,
      );
      expect(res.nextReviewDays, equals(1));
      expect(res.nextMastery, equals(StudyMastery.learning));
    });

    test('partial returns 3 days and keeps current mastery', () {
      final res = StudyReviewPolicy.evaluate(
        feedback: SessionFeedback.partial,
        currentMastery: StudyMastery.learning,
        reviewCount: 1,
      );
      expect(res.nextReviewDays, equals(3));
      expect(res.nextMastery, equals(StudyMastery.learning));
    });

    test('understood first time returns 7 days and review mastery', () {
      final res = StudyReviewPolicy.evaluate(
        feedback: SessionFeedback.understood,
        currentMastery: StudyMastery.learning,
        reviewCount: 0,
      );
      expect(res.nextReviewDays, equals(7));
      expect(res.nextMastery, equals(StudyMastery.review));
    });

    test('understood second time returns 16 days and review mastery', () {
      final res = StudyReviewPolicy.evaluate(
        feedback: SessionFeedback.understood,
        currentMastery: StudyMastery.review,
        reviewCount: 1,
      );
      expect(res.nextReviewDays, equals(16));
      expect(res.nextMastery, equals(StudyMastery.review));
    });

    test('understood third+ time returns 35 days and mastered mastery', () {
      final res = StudyReviewPolicy.evaluate(
        feedback: SessionFeedback.understood,
        currentMastery: StudyMastery.review,
        reviewCount: 2,
      );
      expect(res.nextReviewDays, equals(35));
      expect(res.nextMastery, equals(StudyMastery.mastered));
    });
  });
}
