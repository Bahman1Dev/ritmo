import 'package:ritmo/core/util/ritmo_date.dart';
import 'package:ritmo/features/study/domain/study_models.dart';

class StudyRecommendation {
  const StudyRecommendation({
    required this.subject,
    required this.topic,
    required this.suggestedMinutes,
    required this.reason,
    required this.score,
  });

  final StudySubject subject;
  final StudyTopic topic;
  final int suggestedMinutes;
  final String reason;
  final int score;
}

class StudyPlanner {
  const StudyPlanner._();

  static List<StudyRecommendation> evaluate({
    required List<StudySubject> subjects,
    required List<StudyTopic> topics,
    required List<StudySession> todaySessions,
    required DateTime today,
    int dailyCapacityMinutes = 90,
  }) {
    if (subjects.isEmpty || topics.isEmpty) return [];

    final todayStr = RitmoDate.dayKey(today);
    final subjectMap = {for (final s in subjects) s.id: s};
    final todayStudiedTopicIds = todaySessions.map((s) => s.topicId).whereType<String>().toSet();

    final recs = <StudyRecommendation>[];

    for (final topic in topics) {
      final subject = subjectMap[topic.subjectId];
      if (subject == null || subject.isArchived) continue;

      int score = 0;
      String winnerReason = 'پیشنهاد برنامه‌ریزی';
      int maxRulePoints = -999;

      // Rule 1: Review due (+40)
      if (topic.nextReviewDateIso != null && topic.nextReviewDateIso!.compareTo(todayStr) <= 0) {
        score += 40;
        if (40 > maxRulePoints) {
          maxRulePoints = 40;
          winnerReason = 'امروز موعد مرورشه';
        }
      }

      // Rule 2: >7 days unstudied (+25)
      if (topic.lastStudiedAtMs != null) {
        final daysDiff = today.difference(DateTime.fromMillisecondsSinceEpoch(topic.lastStudiedAtMs!)).inDays;
        if (daysDiff >= 7) {
          score += 25;
          if (25 > maxRulePoints) {
            maxRulePoints = 25;
            winnerReason = '$daysDiff روزه سراغ ${subject.name} نرفتی';
          }
        }
      }

      // Rule 3: Learning status (+20)
      if (topic.mastery == StudyMastery.learning) {
        score += 20;
        if (20 > maxRulePoints) {
          maxRulePoints = 20;
          winnerReason = 'نصفه رهاش کردی';
        }
      }

      // Rule 4: Planned date (+15)
      if (topic.plannedDateIso == todayStr) {
        score += 15;
        if (15 > maxRulePoints) {
          maxRulePoints = 15;
          winnerReason = 'خودت برای امروز برنامه‌ریزیش کردی';
        }
      }

      // Rule 5: Fits in capacity (+10)
      final todayStudiedMinutes = todaySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
      final remainingCap = dailyCapacityMinutes - todayStudiedMinutes;
      if (remainingCap >= 25) {
        score += 10;
        if (10 > maxRulePoints) {
          maxRulePoints = 10;
          winnerReason = 'تو وقت امروزت جا می‌شه';
        }
      }

      // Rule 6: Studied today (-30)
      if (todayStudiedTopicIds.contains(topic.id)) {
        score -= 30;
      }

      recs.add(StudyRecommendation(
        subject: subject,
        topic: topic,
        suggestedMinutes: 30,
        reason: winnerReason,
        score: score,
      ));
    }

    recs.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.topic.orderIndex.compareTo(b.topic.orderIndex);
    });

    return recs;
  }
}
