import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_plan_models.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_plan_generator.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_exercise_library_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_plan_day_detail_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/bottom_sheet_container.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/primary_button.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/secondary_button.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_lottie_player.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_muscle_image_resolver.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SSPlanOverviewScreen extends StatefulWidget {

  const SSPlanOverviewScreen({
    super.key,
    required this.onNavigateToTab,
  });
  final Function(int) onNavigateToTab;

  @override
  State<SSPlanOverviewScreen> createState() => _SSPlanOverviewScreenState();
}

class _SSPlanOverviewScreenState extends State<SSPlanOverviewScreen> {
  List<PlanDaySummary> _weekDays = [];
  bool _isLoading = true;
  int _selectedWeek = 1;
  List<Map<String, dynamic>> _all28Days = [];
  double _planProgressPercent = 0;

  @override
  void initState() {
    super.initState();
    _loadSelectedWeekAndPlan();
  }

  Future<void> _loadSelectedWeekAndPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedWeek = prefs.getInt('ss_active_week') ?? 1;
      });
    } catch (_) {}
    await _loadWeeklyPlan();
  }

  String? _userGender;

  Future<void> _loadWeeklyPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final today = DateTime.now();
      final todayFarsiDay = _getFarsiDayOfWeek(today);

      final prefs = await SharedPreferences.getInstance();
      final currentWeek = prefs.getInt('ss_active_week') ?? 1;
      final currentDayIndex = (currentWeek - 1) * 7 + todayFarsiDay;

      // Fetch user gender
      try {
        _userGender = await DatabaseHelper.instance.getUserGender(executor: db);
      } catch (_) {}
      _userGender ??= 'MALE';

      // 1. Fetch ALL plans
      final allPlans = await db.query('ss_workout_plan');

      // 2. Fetch ALL session logs
      final allLogs = await db.query(
        'ss_workout_session_log',
        where: 'finishedAt IS NOT NULL',
      );

      final allDaysList = <Map<String, dynamic>>[];
      var completedWorkoutsCount = 0;
      var totalPlannedWorkoutsCount = 0;

      for (var w = 1; w <= 4; w++) {
        for (var dow = 1; dow <= 7; dow++) {
          final planId = 'plan_w${w}_$dow';
          final planExists = allPlans.any((p) => p['id'] == planId);
          final isCompleted = allLogs.any((l) => l['planId'] == planId);
          
          final dayIndex = (w - 1) * 7 + dow;
          var status = 'rest';

          if (planExists) {
            totalPlannedWorkoutsCount++;
            if (isCompleted) {
              status = 'done';
              completedWorkoutsCount++;
            } else if (dayIndex == currentDayIndex) {
              status = 'today';
            } else if (dayIndex < currentDayIndex) {
              status = 'missed';
            } else {
              status = 'upcoming';
            }
          } else {
            if (dayIndex == currentDayIndex) {
              status = 'today_rest';
            } else if (dayIndex < currentDayIndex) {
              status = 'past_rest';
            } else {
              status = 'future_rest';
            }
          }

          allDaysList.add({
            'dayIndex': dayIndex,
            'week': w,
            'dayOfWeek': dow,
            'planId': planId,
            'isPlanned': planExists,
            'status': status,
          });
        }
      }

      // Filter current week plans for the list view below the grid
      List<Map<String, dynamic>> plans = allPlans.where((p) => p['id'].toString().startsWith('plan_w${_selectedWeek}_')).toList();
      if (plans.isEmpty && _selectedWeek == 1) {
        plans = allPlans;
      }

      final weekDaysList = <PlanDaySummary>[];
      for (var dayNum = 1; dayNum <= 7; dayNum++) {
        final dayName = _getFarsiDayName(dayNum);
        final dayPlan = plans.firstWhere(
          (p) => (p['dayOfWeek'] as int) == dayNum,
          orElse: () => {},
        );

        if (dayPlan.isEmpty) {
          weekDaysList.add(
            PlanDaySummary(
              id: 'rest_$dayNum',
              dayName: dayName,
              muscleGroups: 'استراحت',
              status: DayStatus.rest,
            ),
          );
        } else {
          final planId = dayPlan['id'].toString();
          final musclesRaw = jsonDecode(dayPlan['muscleGroups'].toString()) as List<dynamic>;
          final musclesText = musclesRaw.join(' و ');

          final isCompleted = allLogs.any((log) => log['planId'] == planId);

          var status = DayStatus.upcoming;
          if (isCompleted) {
            status = DayStatus.completed;
          } else if (dayNum == todayFarsiDay && _selectedWeek == currentWeek) {
            status = DayStatus.today;
          }

          weekDaysList.add(
            PlanDaySummary(
              id: planId,
              dayName: dayName,
              muscleGroups: 'تمرین $musclesText',
              status: status,
            ),
          );
        }
      }

      setState(() {
        _all28Days = allDaysList;
        _planProgressPercent = totalPlannedWorkoutsCount > 0 
            ? (completedWorkoutsCount / totalPlannedWorkoutsCount) * 100 
            : 0.0;
        _weekDays = weekDaysList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading plans: $e');
      setState(() {
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

  String _getFarsiDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1: return 'شنبه';
      case 2: return 'یکشنبه';
      case 3: return 'دوشنبه';
      case 4: return 'سه‌شنبه';
      case 5: return 'چهارشنبه';
      case 6: return 'پنج‌شنبه';
      case 7: return 'جمعه';
    }
    return '';
  }

  Future<void> _regenerateWeeklyPlan() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('بازسازی کل هفته؟', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            content: const Text('با تایید این گزینه، برنامه تمرینی کل هفته مجددا بر اساس مشخصات پروفایل شما ساخته شده و تغییرات قبلی پاک می‌شوند.', style: TextStyle(fontFamily: 'Vazirmatn')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('تایید و بازسازی', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Read profile
      final profiles = await db.query('ss_user_profile', where: 'id = ?', whereArgs: ['default']);
      if (profiles.isEmpty) return;

      final profileMap = profiles.first;

      // Save snapshots to version history (including plans and crossrefs)
      final snapshotId = 'snap_$now';
      final currentPlans = await db.query('ss_workout_plan');
      final currentCrossRefs = await db.query('ss_workout_exercise_crossref');
      final serializedData = {
        'plans': currentPlans,
        'crossrefs': currentCrossRefs,
      };
      await db.insert('ss_plan_version_history', {
        'id': snapshotId,
        'serializedPlan': jsonEncode(serializedData),
        'changeReason': 'بازسازی کل هفته',
        'createdAt': now,
      });

      // Simple regeneration logic
      await db.delete('ss_workout_plan');
      await db.delete('ss_workout_exercise_crossref');

      final profile = SsUserProfile.fromMap(profileMap);

      // Load progression signals from past logs
      final signals = <String, ProgressionSignal>{};
      try {
        final twelveWeeksAgo = DateTime.now().subtract(const Duration(days: 84)).millisecondsSinceEpoch;
        final logs = await db.query(
          'ss_exercise_feeling_log',
          where: 'loggedAt >= ?',
          whereArgs: [twelveWeeksAgo],
        );
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final log in logs) {
          final exId = log['exerciseId'].toString();
          grouped.putIfAbsent(exId, () => []).add(log);
        }
        
        grouped.forEach((exId, exerciseLogs) {
          var consecutiveEasy = 0;
          var currentBlock = 0;
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          const oneWeekMs = 7 * 24 * 60 * 60 * 1000;
          
          while (currentBlock < 12) {
            final start = nowMs - (currentBlock + 1) * oneWeekMs;
            final end = nowMs - currentBlock * oneWeekMs;
            final blockLogs = exerciseLogs.where((log) {
              final time = log['loggedAt'] as int;
              return time >= start && time < end;
            }).toList();
            
            if (blockLogs.isEmpty) {
              if (currentBlock == 0) {
                currentBlock++;
                continue;
              } else {
                break;
              }
            }
            
            final easyCount = blockLogs.where((l) => l['feeling'].toString() == 'EASY').length;
            final easyRatio = easyCount / blockLogs.length;
            if (easyRatio >= 0.7) {
              consecutiveEasy++;
              currentBlock++;
            } else {
              break;
            }
          }
          
          if (consecutiveEasy >= 2) {
            signals[exId] = ProgressionSignal.increase;
          } else {
            // Also check for decrease: if the last week logged was mostly HARD
            final lastWeekLogs = exerciseLogs.where((log) => (log['loggedAt'] as int) >= nowMs - oneWeekMs).toList();
            if (lastWeekLogs.isNotEmpty) {
              final hardCount = lastWeekLogs.where((l) => l['feeling'].toString() == 'HARD').length;
              if (hardCount / lastWeekLogs.length >= 0.7) {
                signals[exId] = ProgressionSignal.decrease;
              }
            }
          }
        });
      } catch (_) {}

      for (var w = 1; w <= 4; w++) {
        await SSPlanGenerator.generateWeeklyAndMonthlyPlan(db, profile, week: w, progressionSignals: signals);
      }

      await _loadWeeklyPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('برنامه هفتگی با موفقیت بازسازی شد.', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error regenerating plans: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showVersionHistoryBottomSheet() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final histories = await db.query('ss_plan_version_history', orderBy: 'createdAt DESC');

      if (histories.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('هیچ تاریخچه تغییری ثبت نشده است.', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
          );
        }
        return;
      }

      if (mounted) {
        unawaited(showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return BottomSheetContainer(
              title: 'تاریخچه تغییرات برنامه',
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: histories.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final hist = histories[index];
                  final reason = hist['changeReason']?.toString() ?? 'تغییر نامشخص';
                  final date = DateTime.fromMillisecondsSinceEpoch(hist['createdAt']! as int);
                  final dateStr = toPersianDigits('${date.hour}:${date.minute} - ${date.year}/${date.month}/${date.day}');

                  return ListTile(
                    title: Text(
                      reason,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      dateStr,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _restoreVersion(hist['id'].toString(), hist['serializedPlan'].toString());
                      },
                      child: Text(
                        'بازیابی',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: SupplementarySportsTheme.getSuccessColor(context),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ));
      }
    } catch (e) {
      debugPrint('Error loading version histories: $e');
    }
  }

  Future<void> _restoreVersion(String id, String serializedPlansJson) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final oldPlans = jsonDecode(serializedPlansJson) as List<dynamic>;

      await db.transaction((txn) async {
        // Clear all current plans
        await txn.delete('ss_workout_plan');
        await txn.delete('ss_workout_exercise_crossref');

        // Restore plans
        for (final p in oldPlans) {
          final plan = Map<String, dynamic>.from(p as Map);
          await txn.insert('ss_workout_plan', plan, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      await _loadWeeklyPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('برنامه با موفقیت به نسخه قبلی بازیابی شد.', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error restoring version: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: SSLottiePlayer.loading(size: 100));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SupplementarySportsTheme.spacing24,
        vertical: SupplementarySportsTheme.spacing16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'برنامه‌ی هفتگی',
                style: SupplementarySportsTheme.h1.copyWith(
                  color: SupplementarySportsTheme.getTextPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              // AI Shortcut Button
              TextButton.icon(
                icon: const Icon(Icons.android, size: 18),
                label: const Text(
                  'این هفته رو سبک‌تر/سنگین‌تر کن',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
                ),
                onPressed: () => widget.onNavigateToTab(1), // AI Coach tab
                style: TextButton.styleFrom(
                  foregroundColor: SupplementarySportsTheme.getSuccessColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: SupplementarySportsTheme.spacing16),
          _build28DaysTimelineCalendar(),
          const SizedBox(height: SupplementarySportsTheme.spacing16),

          // Monthly Week Selection Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL feel
            child: Row(
              textDirection: TextDirection.rtl,
              children: List.generate(4, (index) {
                final weekNum = index + 1;
                final isSelected = _selectedWeek == weekNum;
                
                var weekTitle = 'هفته ۱';
                var weekSubtitle = 'شروع و تکنیک';
                if (weekNum == 2) {
                  weekTitle = 'هفته ۲';
                  weekSubtitle = 'حجم و تکرار';
                } else if (weekNum == 3) {
                  weekTitle = 'هفته ۳';
                  weekSubtitle = 'قدرت و شدت';
                } else if (weekNum == 4) {
                  weekTitle = 'هفته ۴';
                  weekSubtitle = 'ریکاوری سبک';
                }

                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;

                return GestureDetector(
                  onTap: () async {
                    if (_selectedWeek == weekNum) return;
                    setState(() {
                      _selectedWeek = weekNum;
                    });
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('ss_active_week', weekNum);
                    } catch (_) {}
                    await _loadWeeklyPlan();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF2E7D5B), Color(0xFF1B5E20)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2E7D5B).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weekTitle,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          weekSubtitle,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10,
                            color: isSelected ? Colors.white70 : (isDark ? Colors.white38 : Colors.black45),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: SupplementarySportsTheme.spacing16),

          // Days List
          Expanded(
            child: ListView.builder(
              itemCount: _weekDays.length,
              itemBuilder: (context, index) {
                final day = _weekDays[index];
                return _buildWeekDayRow(day);
              },
            ),
          ),
          const SizedBox(height: SupplementarySportsTheme.spacing16),

          // Exercise Library Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D5B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
              ),
              icon: const Icon(Icons.menu_book, size: 20, color: Colors.white),
              label: const Text(
                'کتابخانه کامل تمرینات ورزشی 📚',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SSExerciseLibraryScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: SupplementarySportsTheme.spacing16),

          // Bottom Action Buttons
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'بازسازی کامل هفته',
                  onPressed: _regenerateWeeklyPlan,
                ),
              ),
              const SizedBox(width: SupplementarySportsTheme.spacing12),
              Expanded(
                child: SecondaryButton(
                  label: 'تاریخچه تغییرات برنامه',
                  onPressed: _showVersionHistoryBottomSheet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayRow(PlanDaySummary day) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Status decorations
    Widget statusIcon = Container();
    Color statusColor;

    switch (day.status) {
      case DayStatus.completed:
        statusColor = SupplementarySportsTheme.getSuccessColor(context);
        statusIcon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case DayStatus.today:
        statusColor = SupplementarySportsTheme.getSuccessColor(context).withValues(alpha: 0.2);
        statusIcon = Icon(Icons.circle, color: SupplementarySportsTheme.getSuccessColor(context), size: 14);
      case DayStatus.upcoming:
        statusColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;
        statusIcon = Icon(Icons.circle_outlined, color: isDark ? Colors.grey[600]! : Colors.grey[400]!, size: 14);
      case DayStatus.rest:
        statusColor = isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey[50]!;
        statusIcon = Text(
          'استراحت',
          style: SupplementarySportsTheme.caption.copyWith(
            color: SupplementarySportsTheme.getTextSecondary(context),
          ),
        );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: SupplementarySportsTheme.spacing8),
      decoration: BoxDecoration(
        color: day.status == DayStatus.today ? statusColor : SupplementarySportsTheme.getSurfaceColor(context),
        borderRadius: SupplementarySportsTheme.borderRadiusCard,
        border: Border.all(
          color: day.status == DayStatus.today 
              ? SupplementarySportsTheme.getSuccessColor(context) 
              : isDark 
                  ? Colors.grey[850]! 
                  : Colors.grey[200]!,
          width: day.status == DayStatus.today ? 2.0 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: () {
          // Open details (rest days can also be tapped to add a plan!)
          final dayIndex = _weekDays.indexOf(day) + 1;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SSPlanDayDetailScreen(
                dayOfWeek: dayIndex,
                dayName: day.dayName,
              ),
            ),
          ).then((_) => _loadWeeklyPlan());
        },
        leading: day.status != DayStatus.rest
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  SSMuscleImageResolver.resolve(day.muscleGroups, _userGender),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.fitness_center, size: 24),
                ),
              )
            : null,
        title: Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  day.dayName,
                  style: SupplementarySportsTheme.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SupplementarySportsTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(width: SupplementarySportsTheme.spacing16),
                Text(
                  day.muscleGroups,
                  style: SupplementarySportsTheme.body.copyWith(
                    color: day.status == DayStatus.rest
                        ? SupplementarySportsTheme.getTextSecondary(context).withValues(alpha: 0.6)
                        : SupplementarySportsTheme.getTextSecondary(context),
                  ),
                ),
              ],
            ),
            statusIcon,
          ],
        ),
      ),
    );
  }

  Widget _build28DaysTimelineCalendar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
          width: 1.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تقویم ۲۸ روزه دوره',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
              Text(
                toPersianDigits('پیشرفت کل: ${_planProgressPercent.toStringAsFixed(0)}٪'),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D5B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _planProgressPercent / 100.0,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D5B)),
            ),
          ),
          const SizedBox(height: 18),
          Column(
            children: List.generate(4, (weekIdx) {
              final weekNum = weekIdx + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        'هفته $weekNum',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[500] : const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        textDirection: TextDirection.rtl,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (dayOfWeekIdx) {
                          final index = weekIdx * 7 + dayOfWeekIdx;
                          final dayData = _all28Days.length > index ? _all28Days[index] : null;

                          if (dayData == null) return const SizedBox.shrink();

                          final status = dayData['status'] as String;
                          final dayIndex = dayData['dayIndex'] as int;

                          var circleColor = Colors.transparent;
                          Border? border;
                          Widget? child;

                          if (status == 'done') {
                            circleColor = const Color(0xFF2E7D5B);
                            child = const Icon(Icons.check, size: 11, color: Colors.white);
                          } else if (status == 'today') {
                            circleColor = Colors.transparent;
                            border = Border.all(color: const Color(0xFFC9822A), width: 2);
                            child = Text(
                              toPersianDigits('$dayIndex'),
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            );
                          } else if (status == 'missed') {
                            circleColor = const Color(0xFFE63946).withValues(alpha: 0.15);
                            border = Border.all(color: const Color(0xFFE63946));
                            child = const Icon(Icons.close, size: 10, color: Color(0xFFE63946));
                          } else if (status == 'upcoming') {
                            circleColor = Colors.transparent;
                            border = Border.all(color: isDark ? Colors.white24 : Colors.black12);
                            child = Text(
                              toPersianDigits('$dayIndex'),
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                color: isDark ? Colors.grey[650] : Colors.grey[400],
                              ),
                            );
                          } else if (status == 'today_rest') {
                            circleColor = Colors.transparent;
                            border = Border.all(color: const Color(0xFFC9822A), width: 2);
                            child = const Icon(Icons.hotel, size: 10, color: Color(0xFFC9822A));
                          } else {
                            circleColor = isDark ? Colors.grey[850]!.withValues(alpha: 0.3) : Colors.grey[200]!.withValues(alpha: 0.5);
                            child = Text(
                              '-',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                color: isDark ? Colors.grey[800] : Colors.grey[300],
                              ),
                            );
                          }

                          return InkWell(
                            onTap: () {
                              if (_selectedWeek != weekNum) {
                                setState(() {
                                  _selectedWeek = weekNum;
                                });
                                SharedPreferences.getInstance().then((prefs) {
                                  prefs.setInt('ss_active_week', weekNum);
                                  _loadWeeklyPlan();
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: circleColor,
                                shape: BoxShape.circle,
                                border: border,
                              ),
                              alignment: Alignment.center,
                              child: child,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
