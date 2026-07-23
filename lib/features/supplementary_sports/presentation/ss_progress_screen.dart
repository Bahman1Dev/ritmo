import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_session_models.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/continuity_bar.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/empty_state_view.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_lottie_player.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/stat_card.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/ss_ai_coach_sheet.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// --- Sealed Class for Progress State ---
sealed class SSProgressUiState {
  const SSProgressUiState();
}

class SSProgressEmpty extends SSProgressUiState {
  const SSProgressEmpty();
}

class SSProgressLoaded extends SSProgressUiState {

  const SSProgressLoaded({
    required this.streakDays,
    required this.streakRecord,
    required this.totalMinutes,
    required this.totalCalories,
    required this.weeklyDots,
    required this.recentFeelings,
    required this.totalSessionCount,
    required this.monthContinuityPercent,
    required this.exercisesReadyToProgress,
    required this.weeklyMinutes,
    required this.weightLogs,
    required this.completedDates,
  });
  final int streakDays;
  final int streakRecord;
  final int totalMinutes;
  final int totalCalories;
  final List<bool> weeklyDots;
  final List<Feeling> recentFeelings;
  final int totalSessionCount;
  final double monthContinuityPercent;
  final List<ExerciseReadyForIncrease> exercisesReadyToProgress;
  final List<double> weeklyMinutes;
  final List<Map<String, dynamic>> weightLogs;
  final List<String> completedDates;
}

class SSProgressScreen extends StatefulWidget {

  const SSProgressScreen({
    super.key,
    required this.onNavigateToTab,
  });
  final Function(int) onNavigateToTab;

  @override
  State<SSProgressScreen> createState() => _SSProgressScreenState();
}

class _SSProgressScreenState extends State<SSProgressScreen> {
  SSProgressUiState _state = const SSProgressEmpty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // Ensure weight logs table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ss_weight_log (
          id TEXT PRIMARY KEY,
          weight REAL NOT NULL,
          loggedAt INTEGER NOT NULL
        );
      ''');

      final today = DateTime.now();

      // 1. Fetch total session count
      final totalSessionsResult = await db.rawQuery('SELECT COUNT(*) as count FROM ss_workout_session_log WHERE finishedAt IS NOT NULL');
      final totalSessions = Sqflite.firstIntValue(totalSessionsResult) ?? 0;

      // 2. Fetch total duration in minutes
      final totalMinutesResult = await db.rawQuery('SELECT SUM(durationSeconds) as total FROM ss_workout_session_log WHERE finishedAt IS NOT NULL');
      final totalMinutes = ((Sqflite.firstIntValue(totalMinutesResult) ?? 0) / 60).round();

      // 3. Fetch all completed session logs
      final allLogs = await db.query(
        'ss_workout_session_log',
        where: 'finishedAt IS NOT NULL',
        orderBy: 'startedAt ASC',
      );

      // 4. Calculate total calories using MET table logic
      var totalCalories = 0.0;
      final prefs = await SharedPreferences.getInstance();
      final weightVal = prefs.getDouble('ss_onboarding_weight') ?? 70.0;

      for (final log in allLogs) {
        final logId = log['id'].toString();
        final durationSec = log['durationSeconds'] as int? ?? 0;
        
        final exercises = await db.rawQuery('''
          SELECT e.category, e.cat_cardio, e.cat_plyometric, e.cat_core, e.cat_stretching, e.cat_yoga
          FROM ss_workout_session_log s
          JOIN ss_workout_exercise_crossref c ON s.planId = c.planId
          JOIN ss_exercise e ON c.exerciseId = e.id
          WHERE s.id = ?
        ''', [logId]);

        var avgMet = 6.0;
        if (exercises.isNotEmpty) {
          var totalMet = 0.0;
          for (final ex in exercises) {
            final cat = ex['category']?.toString() ?? '';
            final cardioVal = int.tryParse(ex['cat_cardio']?.toString() ?? '0') ?? 0;
            final plyoVal = int.tryParse(ex['cat_plyometric']?.toString() ?? '0') ?? 0;
            final coreVal = int.tryParse(ex['cat_core']?.toString() ?? '0') ?? 0;
            final stretchVal = int.tryParse(ex['cat_stretching']?.toString() ?? '0') ?? 0;
            final yogaVal = int.tryParse(ex['cat_yoga']?.toString() ?? '0') ?? 0;

            var met = 6.0;
            if (cardioVal >= 4 || plyoVal >= 4 || cat == 'cardio') {
              met = 8.0;
            } else if (coreVal >= 4 || cat == 'core') {
              met = 4.0;
            } else if (stretchVal >= 4 || yogaVal >= 4 || cat == 'stretching' || cat == 'yoga') {
              met = 2.5;
            }
            totalMet += met;
          }
          avgMet = totalMet / exercises.length;
        }
        totalCalories += avgMet * weightVal * (durationSec / 3600.0);
      }

      // 5. Calculate streak
      var currentStreak = 0;
      var maxStreak = 0;
      if (allLogs.isNotEmpty) {
        final dates = allLogs.map((l) {
          final dt = DateTime.fromMillisecondsSinceEpoch(l['startedAt']! as int);
          return DateTime(dt.year, dt.month, dt.day);
        }).toSet().toList();
        
        dates.sort();
        
        var tempStreak = 1;
        for (var i = 0; i < dates.length; i++) {
          if (i > 0) {
            final diff = dates[i].difference(dates[i - 1]).inDays;
            if (diff == 1) {
              tempStreak++;
            } else if (diff > 1) {
              if (tempStreak > maxStreak) maxStreak = tempStreak;
              tempStreak = 1;
            }
          }
        }
        if (tempStreak > maxStreak) maxStreak = tempStreak;
        
        if (dates.isNotEmpty) {
          final daysSinceLatest = today.difference(dates.last).inDays;
          if (daysSinceLatest <= 1) {
            currentStreak = tempStreak;
          } else {
            currentStreak = 0;
          }
        }
      }

      // 6. Fetch weekly dots
      final last7DaysStart = today.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      final recentLogs = await db.query(
        'ss_workout_session_log',
        where: 'startedAt >= ? AND finishedAt IS NOT NULL',
        whereArgs: [last7DaysStart],
      );

      final contList = List<bool>.generate(7, (i) {
        final date = today.subtract(Duration(days: i));
        final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
        final end = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
        return recentLogs.any((log) => (log['startedAt']! as int) >= start && (log['startedAt']! as int) <= end);
      });

      // 7. Calculate weekly minutes for chart (Saturday to Friday)
      final dayOfWeek = _getFarsiDayOfWeek(today);
      final startOfWeek = today.subtract(Duration(days: dayOfWeek - 1));
      final startOfWeekMidnight = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      final weeklyMins = List<double>.generate(7, (i) {
        final targetDate = startOfWeekMidnight.add(Duration(days: i));
        final start = DateTime(targetDate.year, targetDate.month, targetDate.day).millisecondsSinceEpoch;
        final end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59).millisecondsSinceEpoch;
        
        final targetLogs = allLogs.where((log) => (log['startedAt']! as int) >= start && (log['startedAt']! as int) <= end);
        double mins = 0;
        for (final l in targetLogs) {
          mins += (l['durationSeconds'] as int? ?? 0) / 60.0;
        }
        return mins;
      });

      // 8. Fetch weight logs
      final weightLogs = await db.query('ss_weight_log', orderBy: 'loggedAt ASC', limit: 10);

      // 9. Load recent feelings
      final recentFeelingsLogs = await db.query(
        'ss_exercise_feeling_log',
        orderBy: 'loggedAt DESC',
        limit: 10,
      );
      final recentFeelings = recentFeelingsLogs.map((l) {
        final fStr = l['feeling'].toString();
        if (fStr == 'EASY') return Feeling.easy;
        if (fStr == 'GOOD') return Feeling.good;
        return Feeling.hard;
      }).toList();

      // 10. Load month continuity percent
      final startOfMonth = DateTime(today.year, today.month).millisecondsSinceEpoch;
      final monthLogs = await db.query(
        'ss_workout_session_log',
        where: 'startedAt >= ? AND finishedAt IS NOT NULL',
        whereArgs: [startOfMonth],
      );
      final monthDaysCount = monthLogs.map((l) {
        final dt = DateTime.fromMillisecondsSinceEpoch(l['startedAt']! as int);
        return '${dt.year}-${dt.month}-${dt.day}';
      }).toSet().length;
      final totalDaysInMonth = today.difference(DateTime(today.year, today.month)).inDays + 1;
      final monthPercent = totalDaysInMonth > 0 ? (monthDaysCount / totalDaysInMonth) * 100 : 0.0;

      // 11. Completed Dates
      final completedDatesList = allLogs.map((l) {
        final dt = DateTime.fromMillisecondsSinceEpoch(l['startedAt']! as int);
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }).toSet().toList();

      // 12. Ready to progress exercises
      final readyList = <ExerciseReadyForIncrease>[];
      final exFeelingSummary = await db.rawQuery('''
        SELECT f.exerciseId, e.name, COUNT(*) as total,
               SUM(CASE WHEN f.feeling = 'EASY' THEN 1 ELSE 0 END) as easyCount
        FROM ss_exercise_feeling_log f
        JOIN ss_exercise e ON f.exerciseId = e.id
        GROUP BY f.exerciseId
      ''');

      for (final row in exFeelingSummary) {
        final total = row['total'] as int? ?? 0;
        final easyCount = row['easyCount'] as int? ?? 0;
        if (total >= 4 && easyCount / total >= 0.7) {
          readyList.add(ExerciseReadyForIncrease(
            exerciseId: row['exerciseId'].toString(),
            exerciseName: row['name'].toString(),
            consecutiveEasyWeeks: (total / 2).round(),
          ));
        }
      }

      setState(() {
        _state = SSProgressLoaded(
          streakDays: currentStreak,
          streakRecord: maxStreak > currentStreak ? maxStreak : currentStreak,
          totalMinutes: totalMinutes,
          totalCalories: totalCalories.round(),
          weeklyDots: contList,
          recentFeelings: recentFeelings,
          totalSessionCount: totalSessions,
          monthContinuityPercent: monthPercent,
          exercisesReadyToProgress: readyList,
          weeklyMinutes: weeklyMins,
          weightLogs: weightLogs,
          completedDates: completedDatesList,
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading progress data: $e');
      setState(() {
        _state = const SSProgressEmpty();
        _isLoading = false;
      });
    }
  }

  int _getFarsiDayOfWeek(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday: return 3;
      case DateTime.tuesday: return 4;
      case DateTime.wednesday: return 5;
      case DateTime.thursday: return 6;
      case DateTime.friday: return 7;
      case DateTime.saturday: return 1;
      case DateTime.sunday: return 2;
    }
    return 1;
  }

  String _getDominantFeelingText(List<Feeling> feelings) {
    if (feelings.isEmpty) return 'ثبت نشده';
    final counts = <Feeling, int>{};
    for (final f in feelings) {
      counts[f] = (counts[f] ?? 0) + 1;
    }
    final dominant = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    switch (dominant) {
      case Feeling.easy: return 'بیشتر تمرین‌های اخیرت راحت بود 😌';
      case Feeling.good: return 'بیشتر تمرین‌های اخیرت خوب بود 🙂';
      case Feeling.hard: return 'بیشتر تمرین‌های اخیرت سخت بود 😓';
    }
  }

  String _getFeelingEmoji(Feeling feeling) {
    switch (feeling) {
      case Feeling.easy: return '😌';
      case Feeling.good: return '🙂';
      case Feeling.hard: return '😓';
    }
  }

  void _showAddWeightDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ثبت وزن جدید ⚖️', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'وزن به کیلوگرم (مثلاً ۷۵.۵)',
              labelStyle: TextStyle(fontFamily: 'Vazirmatn'),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final weightStr = controller.text;
                final weight = double.tryParse(weightStr);
                if (weight != null && weight > 0) {
                  Navigator.pop(ctx);
                  await _addWeightLog(weight);
                }
              },
              child: const Text('ثبت', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addWeightLog(double weight) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('ss_weight_log', {
        'id': 'weight_$now',
        'weight': weight,
        'loggedAt': now,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('ss_onboarding_weight', weight);

      await _loadProgressData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('وزن جدید با موفقیت ثبت شد!', style: TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: Color(0xFF2E7D5B),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error logging weight: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
        body: Center(child: SSLottiePlayer.loading(size: 100)),
      );
    }

    switch (_state) {
      case SSProgressEmpty():
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
          body: EmptyStateView(
            message: 'روند پیشرفت شما پس از ثبت حداقل ۱ جلسه تمرینی آغاز می‌شود. تا کنون تمرینی تمام نشده است.',
            actionLabel: 'شروع تمرین امروز',
            onAction: () => widget.onNavigateToTab(0),
          ),
        );
      case SSProgressLoaded(
        streakDays: final streakDays,
        streakRecord: final streakRecord,
        totalMinutes: final totalMinutes,
        totalCalories: final totalCalories,
        weeklyDots: final weeklyDots,
        recentFeelings: final recentFeelings,
        totalSessionCount: final totalSessionCount,
        monthContinuityPercent: _,
        exercisesReadyToProgress: final readyList,
        weeklyMinutes: final weeklyMinutes,
        weightLogs: final weightLogs,
        completedDates: final completedDates
      ):
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'گزارش پیشرفت',
                      style: SupplementarySportsTheme.h1.copyWith(
                        color: SupplementarySportsTheme.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ContinuityStreakCard
                    _buildStreakCard(streakDays, streakRecord, weeklyDots),
                    const SizedBox(height: 20),

                    // Jalali Heatmap Calendar Grid
                    _buildJalaliHeatmap(completedDates),
                    const SizedBox(height: 20),

                    // Weekly Minutes Bar Chart
                    _buildWeeklyBarChart(weeklyMinutes),
                    const SizedBox(height: 20),

                    // User Weight Tracker & Line Graph
                    _buildWeightTracker(weightLogs),
                    const SizedBox(height: 20),

                    // FeelingTrendStrip
                    _buildFeelingTrendStrip(recentFeelings),
                    const SizedBox(height: 20),

                    // OverallStatsGrid
                    Text(
                      'آمار کلی دوره',
                      style: SupplementarySportsTheme.h2.copyWith(
                        color: SupplementarySportsTheme.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: StatCard(
                            value: toPersianDigits('$totalSessionCount جلسه'),
                            label: 'کل جلسات تمرین',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            value: toPersianDigits('$totalMinutes دقیقه'),
                            label: 'کل مدت زمان واقعی',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StatCard(
                      value: toPersianDigits('$totalCalories کیلوکالری'),
                      label: 'کل کالری تخمینی (MET)',
                    ),
                    const SizedBox(height: 20),

                    // ReadyToProgressList
                    Text(
                      'حرکات آماده برای افزایش شدت ⚡',
                      style: SupplementarySportsTheme.h2.copyWith(
                        color: SupplementarySportsTheme.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildReadyToProgressList(readyList),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _buildStreakCard(int current, int record, List<bool> dots) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SupplementarySportsTheme.getSurfaceColor(context),
        borderRadius: SupplementarySportsTheme.borderRadiusCard,
        border: Border.all(color: isDark ? Colors.grey[850]! : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 36),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toPersianDigits('$current روز متوالی'),
                    style: SupplementarySportsTheme.h1.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: SupplementarySportsTheme.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    toPersianDigits('رکورد کل شما: $record روز'),
                    style: SupplementarySportsTheme.caption.copyWith(
                      color: SupplementarySportsTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          ContinuityBar(daysCompleted: dots),
        ],
      ),
    );
  }

  Widget _buildJalaliHeatmap(List<String> completedDates) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = Jalali.now();
    final monthLength = now.monthLength;
    final year = now.year;
    final month = now.month;
    final monthName = now.formatter.mN;

    final firstDay = Jalali(year, month).toDateTime();
    final firstDow = _getFarsiDayOfWeek(firstDay);

    final farsiDays = <String>['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SupplementarySportsTheme.getSurfaceColor(context),
        borderRadius: SupplementarySportsTheme.borderRadiusCard,
        border: Border.all(color: isDark ? Colors.grey[850]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            toPersianDigits('تقویم فعالیت ماهانه ($monthName $year)'),
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: farsiDays.map((d) => Text(
              d,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: monthLength + (firstDow - 1),
            itemBuilder: (context, index) {
              final paddingDays = firstDow - 1;
              if (index < paddingDays) {
                return const SizedBox.shrink();
              }

              final day = index - paddingDays + 1;
              final jDate = Jalali(year, month, day);
              final gDate = jDate.toDateTime();
              final gDateStr = '${gDate.year}-${gDate.month.toString().padLeft(2, '0')}-${gDate.day.toString().padLeft(2, '0')}';

              final isCompleted = completedDates.contains(gDateStr);

              return Container(
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? const Color(0xFF2E7D5B) 
                      : (isDark ? Colors.grey[850] : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCompleted 
                        ? Colors.transparent 
                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  toPersianDigits('$day'),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10,
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted 
                        ? Colors.white 
                        : (isDark ? Colors.grey[500] : Colors.grey[600]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<double> mins) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekDayLabels = <String>['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    final maxMin = mins.reduce(max);
    final maxRange = maxMin == 0 ? 10.0 : maxMin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SupplementarySportsTheme.getSurfaceColor(context),
        borderRadius: SupplementarySportsTheme.borderRadiusCard,
        border: Border.all(color: isDark ? Colors.grey[850]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'میزان دقایق تمرین این هفته',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final val = mins[index];
              final heightPercent = (val / maxRange).clamp(0.05, 1.0);
              final barHeight = heightPercent * 90.0;

              return Column(
                children: [
                  Text(
                    toPersianDigits(val.toStringAsFixed(0)),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: val > 0 ? const Color(0xFF2E7D5B) : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 24,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: val > 0 
                          ? const LinearGradient(
                              colors: [Color(0xFF2E7D5B), Color(0xFF1B5E20)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            )
                          : null,
                      color: val > 0 ? null : (isDark ? Colors.grey[850] : Colors.grey[200]),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weekDayLabels[index],
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTracker(List<Map<String, dynamic>> logs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weights = logs.map((l) => (l['weight'] as num).toDouble()).toList();
    final dates = logs.map((l) {
      final dt = DateTime.fromMillisecondsSinceEpoch(l['loggedAt'] as int);
      final jdt = Jalali.fromDateTime(dt);
      return '${jdt.month}/${jdt.day}';
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SupplementarySportsTheme.getSurfaceColor(context),
        borderRadius: SupplementarySportsTheme.borderRadiusCard,
        border: Border.all(color: isDark ? Colors.grey[850]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ردیاب وزن شما ⚖️',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddWeightDialog,
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: const Text('ثبت وزن', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D5B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          WeightLineChart(weights: weights, dates: dates, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildFeelingTrendStrip(List<Feeling> feelings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SupplementarySportsTheme.getSurfaceColor(context),
        borderRadius: SupplementarySportsTheme.borderRadiusCard,
        border: Border.all(color: isDark ? Colors.grey[850]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            'روند کیفی تمرینات اخیر',
            style: SupplementarySportsTheme.caption.copyWith(
              color: SupplementarySportsTheme.getTextSecondary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            textDirection: TextDirection.rtl,
            children: feelings.isEmpty 
              ? [Text('ثبت نشده', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey[500]))]
              : feelings.map((f) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _getFeelingEmoji(f),
                      style: const TextStyle(fontSize: 22),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            _getDominantFeelingText(feelings),
            textDirection: TextDirection.rtl,
            style: SupplementarySportsTheme.body.copyWith(
              fontWeight: FontWeight.w500,
              color: SupplementarySportsTheme.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToProgressList(List<ExerciseReadyForIncrease> list) {
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SupplementarySportsTheme.getSurfaceColor(context),
          borderRadius: SupplementarySportsTheme.borderRadiusCard,
        ),
        child: Text(
          'هنوز حرکتی به حد اشباع سبکی نرسیده است.',
          style: SupplementarySportsTheme.caption.copyWith(
            color: SupplementarySportsTheme.getTextSecondary(context),
          ),
        ),
      );
    }

    return Column(
      children: list.map((item) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: SupplementarySportsTheme.getSurfaceColor(context),
            borderRadius: SupplementarySportsTheme.borderRadiusCard,
          ),
          child: ListTile(
            title: Text(
              item.exerciseName,
              style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              toPersianDigits('${item.consecutiveEasyWeeks} هفته متوالی سبک بوده است.'),
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
            ),
            trailing: TextButton(
              onPressed: () {
                _navigateToCoachWithQuery(item.exerciseName);
              },
              child: Text(
                'ارتقای شدت ⚡',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: SupplementarySportsTheme.getSuccessColor(context),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _navigateToCoachWithQuery(String exerciseName) {
    SSAiCoachSheet.prefilledMessage = 'حرکت «$exerciseName» ۳ هفته برایم راحت بوده است. وزنه را اضافه کنم؟';
    widget.onNavigateToTab(1);
  }
}

// --- Weight Tracker Paint Graph Widget ---
class WeightLineChart extends StatelessWidget {

  const WeightLineChart({
    super.key,
    required this.weights,
    required this.dates,
    required this.isDark,
  });
  final List<double> weights;
  final List<String> dates;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text('داده‌ای برای نمایش وجود ندارد. وزن خود را ثبت کنید.', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
      );
    }

    return CustomPaint(
      size: const Size(double.infinity, 120),
      painter: WeightChartPainter(weights: weights, dates: dates, isDark: isDark),
    );
  }
}

class WeightChartPainter extends CustomPainter {

  WeightChartPainter({
    required this.weights,
    required this.dates,
    required this.isDark,
  });
  final List<double> weights;
  final List<String> dates;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFC9822A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = const Color(0xFFC9822A)
      ..style = PaintingStyle.fill;

    final paintArea = Paint()
      ..color = const Color(0xFFC9822A).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final minW = weights.reduce(min);
    final maxW = weights.reduce(max);
    final diffW = (maxW - minW) == 0 ? 1.0 : (maxW - minW);

    final points = <Offset>[];
    final stepX = weights.length > 1 ? size.width / (weights.length - 1) : size.width;

    for (var i = 0; i < weights.length; i++) {
      final x = i * stepX;
      final normalizedY = (weights[i] - minW) / diffW;
      final y = size.height - (normalizedY * (size.height - 30) + 15);
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final areaPath = Path()
        ..moveTo(points.first.dx, size.height)
        ..lineTo(points.first.dx, points.first.dy);
      
      for (var i = 1; i < points.length; i++) {
        areaPath.lineTo(points[i].dx, points[i].dy);
      }
      areaPath.lineTo(points.last.dx, size.height);
      areaPath.close();
      canvas.drawPath(areaPath, paintArea);
    }

    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, paintLine);
    }

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, paintDot);
      
      final textSpan = TextSpan(
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 9,
          color: isDark ? Colors.white70 : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        text: toPersianDigits('${weights[i]}'),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.rtl,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, points[i].dy - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
