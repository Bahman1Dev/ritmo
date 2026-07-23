import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/continuity_bar.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/primary_button.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_lottie_player.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/stat_card.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen summarizing the results of a completed supplementary sports workout session.
class SSSessionSummaryScreen extends StatefulWidget {

  /// Constructs an [SSSessionSummaryScreen].
  const SSSessionSummaryScreen({
    super.key,
    required this.sessionId,
    required this.completedCount,
    required this.totalCount,
    required this.durationSeconds,
    this.overallFeeling,
  });
  /// Unique identifier of the session log.
  final String sessionId;

  /// Number of completed exercises.
  final int completedCount;

  /// Total number of exercises in the plan.
  final int totalCount;

  /// Total duration of the workout session in seconds.
  final int durationSeconds;

  /// Optional overall feeling rating reported by the user.
  final Feeling? overallFeeling;

  @override
  State<SSSessionSummaryScreen> createState() =>
      _SSSessionSummaryScreenState();
}

class _SSSessionSummaryScreenState extends State<SSSessionSummaryScreen> {
  List<bool> _continuity = List.filled(7, false);
  bool _isLoading = true;
  double _caloriesBurned = 0;
  double _userWeight = 70;
  bool _isRegisteredInCalendar = false;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _loadContinuityAndCalories();
  }

  Future<void> _loadContinuityAndCalories() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final today = DateTime.now();
      final last7DaysStart =
          today.subtract(const Duration(days: 7)).millisecondsSinceEpoch;

      // 1. Fetch continuity
      final recentLogs = await db.query(
        'ss_workout_session_log',
        where: 'startedAt >= ? AND finishedAt IS NOT NULL',
        whereArgs: [last7DaysStart],
      );

      final contList = List<bool>.generate(7, (i) {
        final date = today.subtract(Duration(days: i));
        final start =
            DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
        final end = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
        ).millisecondsSinceEpoch;
        return recentLogs.any(
          (log) =>
              (log['startedAt']! as int) >= start &&
              (log['startedAt']! as int) <= end,
        );
      });

      // 2. Load weight
      final prefs = await SharedPreferences.getInstance();
      _userWeight = prefs.getDouble('ss_onboarding_weight') ?? 70.0;

      // 3. Calculate MET calories
      final results = await db.rawQuery('''
        SELECT e.category, e.cat_cardio, e.cat_plyometric, e.cat_core, e.cat_stretching, e.cat_yoga
        FROM ss_workout_session_log s
        JOIN ss_workout_exercise_crossref c ON s.planId = c.planId
        JOIN ss_exercise e ON c.exerciseId = e.id
        WHERE s.id = ?
      ''', [widget.sessionId]);

      var avgMet = 6.0; // fallback strength MET
      if (results.isNotEmpty) {
        var totalMet = 0.0;
        for (final row in results) {
          final cat = row['category']?.toString() ?? '';
          final cardioVal =
              int.tryParse(row['cat_cardio']?.toString() ?? '0') ?? 0;
          final plyoVal =
              int.tryParse(row['cat_plyometric']?.toString() ?? '0') ?? 0;
          final coreVal = int.tryParse(row['cat_core']?.toString() ?? '0') ?? 0;
          final stretchVal =
              int.tryParse(row['cat_stretching']?.toString() ?? '0') ?? 0;
          final yogaVal = int.tryParse(row['cat_yoga']?.toString() ?? '0') ?? 0;

          var met = 6.0;
          if (cardioVal >= 4 || plyoVal >= 4 || cat == 'cardio') {
            met = 8.0;
          } else if (coreVal >= 4 || cat == 'core') {
            met = 4.0;
          } else if (stretchVal >= 4 ||
              yogaVal >= 4 ||
              cat == 'stretching' ||
              cat == 'yoga') {
            met = 2.5;
          }
          totalMet += met;
        }
        avgMet = totalMet / results.length;
      }

      final durationHours = widget.durationSeconds / 3600.0;
      _caloriesBurned = avgMet * _userWeight * durationHours;

      setState(() {
        _continuity = contList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading summary data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerInMainCalendar() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Ensure Routine exists in main database
      final check = await db.query(
        'routines',
        where: 'id = ?',
        whereArgs: ['routine_supplementary_sports'],
      );
      if (check.isEmpty) {
        await db.insert('routines', {
          'id': 'routine_supplementary_sports',
          'title': 'ورزش تکمیلی',
          'description': 'تمرینات ورزشی Fitify',
          'durationMinutes': 30,
          'itemType': 'ROUTINE',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // 2. Log completion
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final compId = 'comp_ss_${DateTime.now().millisecondsSinceEpoch}';

      await db.insert('routine_completions', {
        'id': compId,
        'routineId': 'routine_supplementary_sports',
        'completionDate': todayStr,
        'completionTime': DateTime.now().millisecondsSinceEpoch,
        'resultType': 'COMPLETED',
        'resultSource': 'USER',
        'durationMinutes': (widget.durationSeconds / 60).round(),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // 3. Fire event to live sync calendar views
      RitmoEventBus().fire(
        RitmoEvent(
          type: 'RoutineCompleted',
          timestamp: DateTime.now(),
          payload: {
            'date': todayStr,
            'routineId': 'routine_supplementary_sports',
          },
        ),
      );

      setState(() {
        _isRegisteredInCalendar = true;
        _isRegistering = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تمرین با موفقیت در تقویم ریتمو ثبت شد! 🗓',
              style: TextStyle(fontFamily: 'Vazirmatn'),
            ),
            backgroundColor: Color(0xFF2E7D5B),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error registering in calendar: $e');
      setState(() {
        _isRegistering = false;
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return toPersianDigits('$minutes دقیقه و $seconds ثانیه');
    }
    return toPersianDigits('$seconds ثانیه');
  }

  String _getFeelingText(Feeling? feeling) {
    if (feeling == null) return 'ثبت نشده';
    switch (feeling) {
      case Feeling.easy:
        return '😌 راحت';
      case Feeling.good:
        return '🙂 خوب';
      case Feeling.hard:
        return '😓 سخت';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
        body: Center(child: SSLottiePlayer.loading(size: 100)),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: const Text(
          'خلاصه تمرین امروز',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Trophy Lottie animation
                        SSLottiePlayer.trophy(size: 180),
                        const SizedBox(height: 8),
                        Text(
                          'خسته نباشید قهرمان! 🎉',
                          style: SupplementarySportsTheme.h1.copyWith(
                            color: SupplementarySportsTheme.getTextPrimary(
                              context,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تمرین امروز با موفقیت ثبت شد و روند پیشرفت شما به‌روزرسانی گردید.',
                          textAlign: TextAlign.center,
                          style: SupplementarySportsTheme.body.copyWith(
                            color: SupplementarySportsTheme.getTextSecondary(
                              context,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Stats Grid
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              child: StatCard(
                                value:
                                    '${widget.completedCount}/${widget.totalCount}',
                                label: 'حرکات انجام‌شده',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                value: _getFeelingText(widget.overallFeeling),
                                label: 'احساس غالب',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              child: StatCard(
                                value: _formatDuration(widget.durationSeconds),
                                label: 'مدت زمان واقعی',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                value: toPersianDigits(
                                  '${_caloriesBurned.toStringAsFixed(0)} کیلوکالری',
                                ),
                                label: 'کالری سوزانده شده (MET)',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Continuity Display
                        Text(
                          'میزان تداوم ۷ روز اخیر',
                          style: SupplementarySportsTheme.h2.copyWith(
                            color: SupplementarySportsTheme.getTextPrimary(
                              context,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ContinuityBar(daysCompleted: _continuity),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Button row
                Column(
                  children: [
                    if (!_isRegisteredInCalendar)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isRegistering ? null : _registerInMainCalendar,
                          icon: _isRegistering
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.white,
                                ),
                          label: const Text(
                            'ثبت در تقویم اصلی ریتمو 🗓',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC9822A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D5B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2E7D5B)),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Color(0xFF2E7D5B),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'در تقویم اصلی ثبت شد',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D5B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'بازگشت به خانه',
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
