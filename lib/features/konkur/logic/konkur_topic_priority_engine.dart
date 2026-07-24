import 'dart:math';

import 'package:ritmo/features/konkur/models/konkur_models.dart';

/// Rank topics using transparent weighted scores, recommended study modes,
/// duration blocks, and human-readable explanations.
class KonkurTopicPriorityEngine {
  const KonkurTopicPriorityEngine();

  List<KonkurTopicPriority> rankTopics(KonkurPlanningContext context) {
    final todayStr = _formatDateIso(context.today);
    final subjectMap = {for (final s in context.subjects) s.id: s};
    final topicMap = {for (final t in context.topics) t.id: t};

    // Calculate subject mock exam performance (latest result per subject)
    final subjectMockScores = <String, double>{};
    for (final res in context.mockResults) {
      subjectMockScores[res.subjectId] = res.percentage;
    }

    // Calculate recent subject distribution (last 7 study sessions or plan items)
    final recentSubjectCounts = <String, int>{};
    for (final session in context.studySessions.take(14)) {
      if (session.subjectId != null) {
        recentSubjectCounts[session.subjectId!] =
            (recentSubjectCounts[session.subjectId!] ?? 0) + 1;
      }
    }

    final totalRecentSessions = recentSubjectCounts.values.fold(0, (a, b) => a + b);

    final ranked = <KonkurTopicPriority>[];

    for (final topic in context.topics) {
      final subject = subjectMap[topic.subjectId];
      if (subject == null) continue;

      // Check prerequisite DAG constraint: skip if prerequisites aren't met
      if (!_arePrerequisitesMet(topic, topicMap)) continue;

      final reasons = <String>[];
      final latestMockScore = subjectMockScores[subject.id];

      // 1. Exam Weight Score
      final examWeightScore = (subject.importanceFactor * 12) + (topic.examQuestionCount * 4);
      final isHighYield = topic.examQuestionCount >= 5 || subject.importanceFactor >= 2.5;
      if (isHighYield) {
        reasons.add('مبحث پرسوال و با ضریب بالای آزمون کنکور');
      }

      // 2. Mastery Gap Score
      double masteryGapScore = 0;
      switch (topic.masteryLevel) {
        case MasteryLevel.notStarted:
          masteryGapScore = 28;
          reasons.add('مبحث تاکنون مطالعه نشده و نیازمند یادگیری مفاهیم است');
        case MasteryLevel.learning:
          masteryGapScore = 22;
          reasons.add('در مرحله یادگیری فعال است');
        case MasteryLevel.needsReview:
          masteryGapScore = 18;
          reasons.add('توسط سیستم نیازمند مرور شناخته شده است');
        case MasteryLevel.mastered:
          masteryGapScore = 4;
      }

      // 3. Review Urgency Score
      double reviewUrgencyScore = 0;
      bool isReviewDue = false;
      int urgencyLevel = 1;

      if (topic.nextReviewDate != null && topic.nextReviewDate!.isNotEmpty) {
        final cmp = topic.nextReviewDate!.compareTo(todayStr);
        if (cmp <= 0) {
          isReviewDue = true;
          int daysOverdue = 0;
          try {
            final dueDt = DateTime.parse(topic.nextReviewDate!);
            daysOverdue = context.today.difference(dueDt).inDays;
          } catch (_) {}

          if (daysOverdue >= 8) {
            reviewUrgencyScore = 32;
            urgencyLevel = 5;
            reasons.add('بیش از ۸ روز از موعد مرور منحنی فراموشی گذشته است');
          } else if (daysOverdue >= 4) {
            reviewUrgencyScore = 24;
            urgencyLevel = 4;
            reasons.add('۴ تا ۷ روز عقب‌افتادگی در مرور دارد');
          } else if (daysOverdue >= 2) {
            reviewUrgencyScore = 16;
            urgencyLevel = 3;
            reasons.add('۲ الی ۳ روز از زمان مرور گذشته است');
          } else {
            reviewUrgencyScore = 10;
            urgencyLevel = 2;
            reasons.add('سررسید مرور منحنی یادگیری امروز است');
          }
        }
      }

      // 4. Weakness Score
      double weaknessScore = 0;
      bool isWeakArea = false;
      if (latestMockScore != null) {
        if (latestMockScore < 30) {
          weaknessScore = 26;
          isWeakArea = true;
          urgencyLevel = max(urgencyLevel, 4);
          reasons.add('عملکرد اخیر در آزمون آزمایشی زیر ۳۰٪ بوده و نیاز به نجات دارد');
        } else if (latestMockScore < 45) {
          weaknessScore = 18;
          isWeakArea = true;
          urgencyLevel = max(urgencyLevel, 3);
          reasons.add('نمره آزمون آزمایشی این درس ضعیف (زیر ۴۵٪) است');
        } else if (latestMockScore < 60) {
          weaknessScore = 10;
          reasons.add('نیاز به بهبود درصد آزمون تا سطح بالای ۶۰٪ دارد');
        }
      }

      // 5. Backlog Score
      final carryOverCount = context.pendingCarryOverMap[topic.id] ?? 0;
      final backlogScore = min(16.0, carryOverCount * 4.0);
      if (carryOverCount > 0) {
        reasons.add('$carryOverCount بار از برنامه‌های قبلی معوق شده است');
      }

      // 6. Freshness Decay Score
      double freshnessDecayScore = 0;
      if (topic.lastStudiedAt == null) {
        freshnessDecayScore = 18;
      } else {
        final lastStudiedDate = DateTime.fromMillisecondsSinceEpoch(topic.lastStudiedAt!);
        final daysSinceStudy = context.today.difference(lastStudiedDate).inDays;
        if (daysSinceStudy > 14) {
          freshnessDecayScore = 14;
          reasons.add('بیش از دو هفته از آخرین مطالعه این مبحث می‌گذرد');
        } else if (daysSinceStudy >= 7) {
          freshnessDecayScore = 8;
        } else if (daysSinceStudy >= 3) {
          freshnessDecayScore = 4;
        }
      }

      // 7. Phase Need Score & Recommended Mode
      const double phaseNeedScore = 10;
      final String recommendedMode;

      final conceptTarget = topic.conceptTargetMinutes > 0 ? topic.conceptTargetMinutes : max(45, (topic.studyTargetMinutes * 0.5).round());
      final practiceTarget = topic.practiceTargetMinutes > 0 ? topic.practiceTargetMinutes : max(30, (topic.studyTargetMinutes * 0.3).round());
      final reviewTarget = topic.reviewTargetMinutes > 0 ? topic.reviewTargetMinutes : max(20, (topic.studyTargetMinutes * 0.2).round());

      final conceptGap = max(0, conceptTarget - topic.conceptCompletedMinutes);
      final practiceGap = max(0, practiceTarget - topic.practiceCompletedMinutes);
      final reviewGap = max(0, reviewTarget - topic.reviewCompletedMinutes);

      if (isReviewDue) {
        recommendedMode = 'REVIEW';
      } else if (conceptGap >= practiceGap && conceptGap >= reviewGap && conceptGap > 0) {
        recommendedMode = 'STUDY';
      } else if (practiceGap >= reviewGap && practiceGap > 0) {
        recommendedMode = 'TEST';
      } else {
        recommendedMode = 'REVIEW';
      }

      // 8. Recency Penalty or Bonus
      double recencyPenalty = 0;
      if (topic.lastStudiedAt != null) {
        final lastDt = DateTime.fromMillisecondsSinceEpoch(topic.lastStudiedAt!);
        final diffDays = context.today.difference(lastDt).inDays;
        if (diffDays == 0) {
          recencyPenalty = -30;
        } else if (diffDays == 1) {
          recencyPenalty = -12;
        } else if (diffDays == 2) {
          recencyPenalty = -4;
        }
      }

      // 9. Variety Pressure Score
      double varietyPressureScore = 0;
      if (totalRecentSessions > 3) {
        final count = recentSubjectCounts[subject.id] ?? 0;
        final ratio = count / totalRecentSessions;
        if (ratio < 0.10) {
          varietyPressureScore = 12;
          reasons.add('این درس در مطالعه هفته اخیر کم‌تر پرداخته شده است');
        } else if (ratio < 0.20) {
          varietyPressureScore = 6;
        }
      }

      // Compute Total Weighted Score
      final totalScore = examWeightScore +
          masteryGapScore +
          reviewUrgencyScore +
          weaknessScore +
          backlogScore +
          freshnessDecayScore +
          phaseNeedScore +
          recencyPenalty +
          varietyPressureScore;

      // Recommended Block Duration Calculation
      int minDuration = 20;
      int maxDuration = 60;
      if (recommendedMode == 'STUDY') {
        minDuration = 45;
        maxDuration = 75;
      } else if (recommendedMode == 'TEST') {
        minDuration = 30;
        maxDuration = 60;
      } else {
        minDuration = 20;
        maxDuration = 45;
      }

      final rawBlock = (topic.studyTargetMinutes * 0.18).round();
      final recommendedBlock = rawBlock.clamp(minDuration, maxDuration).clamp(20, 90);

      // Primary Reason Summary
      String primaryReason = 'برنامه‌ریزی بر اساس اولویت مبحث';
      if (isReviewDue) {
        primaryReason = 'مرور سررسید شده جهت تثبیت در حافظه بلندمدت';
      } else if (isWeakArea) {
        primaryReason = 'تقویت نقطه ضعف بر اساس نتایج آزمون اخیر';
      } else if (isHighYield) {
        primaryReason = 'مبحث پرسوال کنکوری با ضریب بالا';
      } else if (topic.masteryLevel == MasteryLevel.notStarted) {
        primaryReason = 'شروع و یادگیری اولیه مفهوم مبحث';
      } else if (recommendedMode == 'TEST') {
        primaryReason = 'افزایش تسلط با تمرین تست‌زنی';
      }

      ranked.add(KonkurTopicPriority(
        topicId: topic.id,
        score: totalScore,
        primaryReason: primaryReason,
        reasons: reasons,
        recommendedMode: recommendedMode,
        recommendedBlockMinutes: recommendedBlock,
        urgencyLevel: urgencyLevel.clamp(1, 5),
        isReviewDue: isReviewDue,
        isWeakArea: isWeakArea,
        isHighYield: isHighYield,
      ));
    }

    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  bool _arePrerequisitesMet(KonkurTopic topic, Map<String, KonkurTopic> topicMap) {
    if (topic.prerequisiteTopicIds.isEmpty) return true;
    for (final prereqId in topic.prerequisiteTopicIds) {
      final prereq = topicMap[prereqId];
      if (prereq == null) continue;
      if (prereq.progressPercentage < 0.6 && prereq.masteryLevel == MasteryLevel.notStarted) {
        return false;
      }
    }
    return true;
  }

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
