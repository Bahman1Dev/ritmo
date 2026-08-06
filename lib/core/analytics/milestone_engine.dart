import 'dart:math';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';

class Milestone {

  Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.isUnlocked,
    this.unlockedAt,
  });
  final String id;
  final String title;
  final String description;
  final double progress; // 0.0 to 1.0
  final bool isUnlocked;
  final int? unlockedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'progress': progress,
      'isUnlocked': isUnlocked ? 1 : 0,
      'unlockedAt': unlockedAt,
    };
  }
}

class MilestoneEngineInput {

  MilestoneEngineInput({
    required this.currentStreak,
    required this.longestStreak,
    required this.routineCompletions,
    required this.routines,
    required this.courses,
    required this.courseSessions,
    required this.konkurSubjects,
    required this.unlockedMilestonesMap,
  });
  final int currentStreak;
  final int longestStreak;
  final List<Map<String, dynamic>> routineCompletions;
  final List<Map<String, dynamic>> routines;
  final List<Map<String, dynamic>> courses;
  final List<Map<String, dynamic>> courseSessions;
  final List<Map<String, dynamic>> konkurSubjects;
  final Map<String, int> unlockedMilestonesMap;
}

class MilestoneEngine implements CachedEngine<MilestoneEngineInput, List<Milestone>> {
  @override
  Future<List<Milestone>> calculate(MilestoneEngineInput input) async {
    return evaluate(
      currentStreak: input.currentStreak,
      longestStreak: input.longestStreak,
      routineCompletions: input.routineCompletions,
      routines: input.routines,
      courses: input.courses,
      courseSessions: input.courseSessions,
      konkurSubjects: input.konkurSubjects,
      unlockedMilestonesMap: input.unlockedMilestonesMap,
    );
  }

  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  String fingerprint(MilestoneEngineInput input) {
    return '${input.currentStreak}|${input.longestStreak}|${input.routineCompletions.length}|${input.courses.length}|${input.courseSessions.length}';
  }

  @override
  void invalidate() {}

  @override
  bool canRun(MilestoneEngineInput input) => true;

  @override
  List<Type> dependencies() => [];
  /// Evaluates and returns all milestones with their current lock/progress state.
  static List<Milestone> evaluate({
    required int currentStreak,
    required int longestStreak,
    required List<Map<String, dynamic>> routineCompletions,
    required List<Map<String, dynamic>> routines,
    required List<Map<String, dynamic>> courses,
    required List<Map<String, dynamic>> courseSessions,
    required List<Map<String, dynamic>> konkurSubjects,
    required Map<String, int> unlockedMilestonesMap, // id -> unlockedAt
  }) {
    final list = <Milestone>[];
    final totalCompletions = routineCompletions.where((c) {
      final type = c['resultType'] as String? ?? 'FULL';
      return type != 'CANNOT_NOW' && type != 'SNOOZED';
    }).length;

    // Helper for consecutive days of a category
    int getCategoryStreak(String categoryName) {
      final routineIdsOfCategory = routines
          .where((r) => (r['category'] as String).toLowerCase() == categoryName.toLowerCase())
          .map((r) => r['id'] as String)
          .toSet();

      if (routineIdsOfCategory.isEmpty) return 0;

      final dates = routineCompletions
          .where((c) {
            final type = c['resultType'] as String? ?? 'FULL';
            return routineIdsOfCategory.contains(c['routineId'] as String) &&
                type != 'CANNOT_NOW' &&
                type != 'SNOOZED';
          })
          .map((c) => c['completionDate'] as String)
          .toSet();

      if (dates.isEmpty) return 0;

      final parsedDates = dates.map(DateTime.parse).toList()..sort();
      var maxStreak = 1;
      var current = 1;

      for (var i = 0; i < parsedDates.length - 1; i++) {
        final diff = parsedDates[i + 1].difference(parsedDates[i]).inDays;
        if (diff == 1) {
          current++;
        } else if (diff > 1) {
          maxStreak = max(maxStreak, current);
          current = 1;
        }
      }
      return max(maxStreak, current);
    }

    // Helper to build milestone
    Milestone buildMilestone({
      required String id,
      required String title,
      required String description,
      required bool condition,
      required double progressCalc,
    }) {
      final wasUnlocked = unlockedMilestonesMap.containsKey(id);
      final isUnlocked = wasUnlocked || condition;
      final progress = isUnlocked ? 1.0 : progressCalc.clamp(0.0, 0.99);
      final unlockedTime = wasUnlocked ? unlockedMilestonesMap[id] : (condition ? DateTime.now().millisecondsSinceEpoch : null);

      return Milestone(
        id: id,
        title: title,
        description: description,
        progress: progress,
        isUnlocked: isUnlocked,
        unlockedAt: unlockedTime,
      );
    }

    // 1. Streak Milestones
    final maxStreak = max(currentStreak, longestStreak);
    list.add(buildMilestone(
      id: 'streak_7',
      title: 'تداوم ۷ روزه 🔥',
      description: 'ثبت روتین‌های روزانه برای ۷ روز متوالی',
      condition: maxStreak >= 7,
      progressCalc: maxStreak / 7.0,
    ));

    list.add(buildMilestone(
      id: 'streak_30',
      title: 'تداوم ۳۰ روزه ⚡',
      description: 'ثبت روتین‌های روزانه برای ۳۰ روز متوالی',
      condition: maxStreak >= 30,
      progressCalc: maxStreak / 30.0,
    ));

    list.add(buildMilestone(
      id: 'streak_100',
      title: 'تداوم ۱۰۰ روزه 🏆',
      description: 'ثبت روتین‌های روزانه برای ۱۰۰ روز متوالی',
      condition: maxStreak >= 100,
      progressCalc: maxStreak / 100.0,
    ));

    list.add(buildMilestone(
      id: 'streak_365',
      title: 'تداوم یک ساله 🎖️',
      description: 'ثبت روتین‌های روزانه برای ۳۶۵ روز متوالی',
      condition: maxStreak >= 365,
      progressCalc: maxStreak / 365.0,
    ));

    // 2. Count Milestones
    list.add(buildMilestone(
      id: 'completions_100',
      title: '۱۰۰ روتین کامل 🌿',
      description: 'تکمیل ۱۰۰ روتین در برنامه ریتمو',
      condition: totalCompletions >= 100,
      progressCalc: totalCompletions / 100.0,
    ));

    list.add(buildMilestone(
      id: 'completions_1000',
      title: '۱۰۰۰ روتین کامل 👑',
      description: 'تکمیل ۱۰۰۰ روتین در برنامه ریتمو',
      condition: totalCompletions >= 1000,
      progressCalc: totalCompletions / 1000.0,
    ));

    // 3. Course Completion
    var courseProgress = 0.0;
    var courseCondition = false;
    if (courses.isNotEmpty) {
      for (final course in courses) {
        final courseId = course['id'] as String;
        final total = course['totalSessions'] as int? ?? 1;
        final completed = courseSessions.where((s) => s['courseId'] == courseId && s['completionStatus'] == 'COMPLETED').length;
        final ratio = completed / total.toDouble();
        courseProgress = max(courseProgress, ratio);
        if (completed >= total) {
          courseCondition = true;
        }
      }
    }
    list.add(buildMilestone(
      id: 'first_course',
      title: 'پایان اولین دوره 🎓',
      description: 'تکمیل تمام جلسات یک دوره آموزشی',
      condition: courseCondition,
      progressCalc: courseProgress,
    ));

    // 4. Konkur Completion
    var konkurProgress = 0.0;
    var konkurCondition = false;
    if (konkurSubjects.isNotEmpty) {
      for (final subject in konkurSubjects) {
        final progress = (subject['progressPercentage'] as num? ?? 0.0).toDouble() / 100.0;
        konkurProgress = max(konkurProgress, progress);
        if (progress >= 1.0) {
          konkurCondition = true;
        }
      }
    }
    list.add(buildMilestone(
      id: 'first_konkur',
      title: 'تسلط بر اولین مبحث کنکور 🎯',
      description: 'رسیدن به پیشرفت ۱۰۰ درصدی در یک مبحث کنکور',
      condition: konkurCondition,
      progressCalc: konkurProgress,
    ));

    // 5. Category Streak Milestones
    final prayerStreak = getCategoryStreak('religious');
    list.add(buildMilestone(
      id: 'continuous_prayer_30',
      title: '۳۰ روز عبادات مستمر 🕋',
      description: 'انجام روتین‌های عبادی برای ۳۰ روز متوالی',
      condition: prayerStreak >= 30,
      progressCalc: prayerStreak / 30.0,
    ));

    final exerciseStreak = getCategoryStreak('fitness');
    list.add(buildMilestone(
      id: 'continuous_exercise_30',
      title: '۳۰ روز ورزش مستمر 🏃‍♂️',
      description: 'انجام روتین‌های سلامتی و ورزشی برای ۳۰ روز متوالی',
      condition: exerciseStreak >= 30,
      progressCalc: exerciseStreak / 30.0,
    ));

    return list;
  }
}
