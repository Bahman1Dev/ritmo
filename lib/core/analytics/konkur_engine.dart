import 'dart:math';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';

class KonkurEngineInput {

  KonkurEngineInput({
    required this.subjects,
    required this.topics,
    required this.sessions,
    required this.mockExams,
    required this.mockResults,
    this.examDateIso,
    required this.today,
    required this.planItems,
  });
  final List<KonkurSubject> subjects;
  final List<KonkurTopic> topics;
  final List<KonkurStudySession> sessions;
  final List<KonkurMockExam> mockExams;
  final List<KonkurMockResult> mockResults;
  final String? examDateIso; // YYYY-MM-DD
  final DateTime today;
  final List<KonkurPlanItem> planItems;
}

class KonkurEngineOutput {

  KonkurEngineOutput({
    required this.daysUntilExam,
    required this.overallReadiness,
    required this.studyMinutesTotal,
    required this.studyMinutesThisWeek,
    required this.studyStreakDays,
    required this.perSubjectReadiness,
    required this.perSubjectTrend,
    required this.budgetCoverage,
    required this.weakestSubjects,
    required this.todayPlanItems,
  });
  final int daysUntilExam; // -1 if no exam date set
  final double overallReadiness; // 0.0 to 1.0
  final int studyMinutesTotal;
  final int studyMinutesThisWeek;
  final int studyStreakDays;
  final Map<String, double> perSubjectReadiness; // subjectId -> 0.0-1.0
  final Map<String, List<double>> perSubjectTrend; // subjectId -> list of percentages
  final double budgetCoverage; // 0.0 to 1.0
  final List<String> weakestSubjects; // subjectId list
  final List<KonkurPlanItem> todayPlanItems;
}

class KonkurEngine implements CachedEngine<KonkurEngineInput, KonkurEngineOutput> {
  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  String fingerprint(KonkurEngineInput input) {
    final dayStamp = _formatDateIso(input.today);
    return '$dayStamp|${input.examDateIso}|${input.subjects.length}|${input.topics.length}|${input.sessions.length}|${input.planItems.length}';
  }

  @override
  void invalidate() {}

  @override
  Future<KonkurEngineOutput> calculate(KonkurEngineInput input) async {
    final cleanToday = DateTime(input.today.year, input.today.month, input.today.day);
    final todayStr = _formatDateIso(cleanToday);

    // 1. daysUntilExam
    var daysUntil = -1;
    if (input.examDateIso != null && input.examDateIso!.isNotEmpty) {
      try {
        final examDate = DateTime.parse(input.examDateIso!);
        final diff = examDate.difference(cleanToday).inDays;
        daysUntil = max(0, diff);
      } catch (_) {}
    }

    // Map subject to recent mock exam weakness multiplier (Mock Exam Feedback Loop)
    final subjectMockWeakness = <String, double>{};
    for (final subject in input.subjects) {
      final results = input.mockResults.where((r) => r.subjectId == subject.id).toList();
      if (results.isNotEmpty) {
        final lastResult = results.last;
        // Low percentage (< 50%) decreases readiness perception by up to 30%
        final weakness = 1.0 - ((100.0 - lastResult.percentage).clamp(0, 100) / 100.0) * 0.3;
        subjectMockWeakness[subject.id] = weakness;
      } else {
        subjectMockWeakness[subject.id] = 1.0;
      }
    }

    // 2. perSubjectReadiness
    final perSubReadiness = <String, double>{};
    for (final subject in input.subjects) {
      final subTopics = input.topics.where((t) => t.subjectId == subject.id).toList();
      final weaknessMult = subjectMockWeakness[subject.id] ?? 1.0;

      if (subTopics.isEmpty) {
        perSubReadiness[subject.id] = 0.0;
        continue;
      }
      
      var totalQuestionCount = 0.0;
      var weightedScoreSum = 0.0;
      for (final topic in subTopics) {
        final qCount = topic.examQuestionCount.toDouble();
        totalQuestionCount += qCount;
        weightedScoreSum += topic.masteryLevel.score * qCount;
      }

      if (totalQuestionCount > 0.0) {
        perSubReadiness[subject.id] = (weightedScoreSum / totalQuestionCount) * weaknessMult;
      } else {
        var scoreSum = 0.0;
        for (final topic in subTopics) {
          scoreSum += topic.masteryLevel.score;
        }
        perSubReadiness[subject.id] = (scoreSum / subTopics.length) * weaknessMult;
      }
    }

    // 3. overallReadiness
    var overall = 0.0;
    var importanceSum = 0.0;
    for (final subject in input.subjects) {
      final readiness = perSubReadiness[subject.id] ?? 0.0;
      overall += readiness * subject.importanceFactor;
      importanceSum += subject.importanceFactor;
    }
    if (importanceSum > 0.0) {
      overall = overall / importanceSum;
    }

    // 4. studyMinutesTotal
    var totalMinutes = 0;
    for (final session in input.sessions) {
      totalMinutes += session.durationMinutes;
    }

    // 5. studyMinutesThisWeek (Saturday to Friday)
    var minutesThisWeek = 0;
    final satOfWeek = _getSaturdayOfWeek(cleanToday);
    final satStr = _formatDateIso(satOfWeek);
    final nextSatStr = _formatDateIso(satOfWeek.add(const Duration(days: 7)));

    for (final session in input.sessions) {
      if (session.dateIso.compareTo(satStr) >= 0 && session.dateIso.compareTo(nextSatStr) < 0) {
        minutesThisWeek += session.durationMinutes;
      }
    }

    // 6. studyStreakDays
    final uniqueStudyDates = input.sessions
        .where((s) => s.durationMinutes > 0)
        .map((s) => s.dateIso)
        .toSet();

    var streak = 0;
    var checkDate = cleanToday;
    final yesterdayStr = _formatDateIso(cleanToday.subtract(const Duration(days: 1)));

    final hasStreak = uniqueStudyDates.contains(todayStr) || uniqueStudyDates.contains(yesterdayStr);
    if (hasStreak) {
      if (!uniqueStudyDates.contains(todayStr)) {
        checkDate = cleanToday.subtract(const Duration(days: 1));
      }

      while (uniqueStudyDates.contains(_formatDateIso(checkDate))) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // 7. perSubjectTrend
    final perSubTrend = <String, List<double>>{};
    final examDatesMap = {for (final exam in input.mockExams) exam.id: exam.examDate};
    
    for (final subject in input.subjects) {
      final results = input.mockResults.where((r) => r.subjectId == subject.id).toList();
      
      results.sort((a, b) {
        final dateA = examDatesMap[a.mockExamId] ?? '';
        final dateB = examDatesMap[b.mockExamId] ?? '';
        return dateA.compareTo(dateB);
      });

      perSubTrend[subject.id] = results.map((r) => r.percentage).toList();
    }

    // 8. budgetCoverage
    var totalBudget = 0.0;
    var coveredBudget = 0.0;
    for (final topic in input.topics) {
      final qCount = topic.examQuestionCount.toDouble();
      totalBudget += qCount;
      if (topic.masteryLevel != MasteryLevel.notStarted) {
        coveredBudget += qCount;
      }
    }
    final coverage = totalBudget > 0.0 ? coveredBudget / totalBudget : 0.0;

    // 9. weakestSubjects
    final weakestList = <MapEntry<String, double>>[];
    for (final subject in input.subjects) {
      final readiness = perSubReadiness[subject.id] ?? 0.0;
      weakestList.add(MapEntry(subject.id, readiness));
    }
    weakestList.sort((a, b) => a.value.compareTo(b.value));
    final weakest = weakestList.map((e) => e.key).toList();

    // 10. todayPlanItems
    final todayPlan = input.planItems
        .where((item) => item.dateIso == todayStr && item.status == 'PENDING')
        .toList();

    final output = KonkurEngineOutput(
      daysUntilExam: daysUntil,
      overallReadiness: overall,
      studyMinutesTotal: totalMinutes,
      studyMinutesThisWeek: minutesThisWeek,
      studyStreakDays: streak,
      perSubjectReadiness: perSubReadiness,
      perSubjectTrend: perSubTrend,
      budgetCoverage: coverage,
      weakestSubjects: weakest,
      todayPlanItems: todayPlan,
    );

    return output;
  }

  @override
  bool canRun(KonkurEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _getSaturdayOfWeek(DateTime date) {
    var diff = date.weekday - DateTime.saturday;
    if (diff < 0) {
      diff += 7;
    }
    return date.subtract(Duration(days: diff));
  }
}
