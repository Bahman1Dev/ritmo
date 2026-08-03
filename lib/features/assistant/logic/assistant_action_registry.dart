import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/engines/routine_occurrence_generator.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/assistant/logic/day_plan_template_service.dart';
// Logic
import 'package:ritmo/features/assistant/logic/settings_action_guard.dart';
// Models
import 'package:ritmo/features/assistant/models/assistant_models.dart';
import 'package:ritmo/features/assistant/models/day_plan_models.dart';
import 'package:ritmo/features/courses/presentation/widgets/create_course_sheet.dart';
import 'package:ritmo/features/energy/presentation/widgets/quick_log_sheet.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
// Destination Screens
import 'package:ritmo/features/goals/presentation/goals_screen.dart';
// Sheets and Screens
import 'package:ritmo/features/goals/presentation/widgets/create_goal_sheet.dart';
import 'package:ritmo/features/health/presentation/health_screen.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:ritmo/features/konkur/presentation/konkur_screen.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_study_sheet.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_log_sheet.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_home_dashboard_screen.dart';
import 'package:ritmo/features/today/presentation/widgets/daily_reflection_sheet.dart';
import 'package:ritmo/features/wellbeing/presentation/wellbeing_screen.dart';
import 'package:ritmo/features/worship/presentation/worship_screen.dart';
import 'package:sqflite/sqflite.dart';

class AssistantActionRegistry {
  static void _showMedicalBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('محدودیت دسترسی ایمنی', textAlign: TextAlign.right),
        content: const Text(
          'برای حفظ ایمنی، اطلاعات پزشکی، یادآورهای دارویی و تغییرات سلامت از طریق دستیار هوشمند مدیریت نمی‌شوند؛ لطفاً این موارد را مستقیماً در بخش سلامت مدیریت کنید.',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Vazirmatn'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تایید'),
          ),
        ],
      ),
    );
  }

  static Future<void> executeAction(
    BuildContext context,
    AssistantAction action,
    VoidCallback onComplete,
  ) async {
    final db = await DatabaseHelper.instance.database;

    // Rule 0.5 Check: Medical payload safety guard
    final isMedicalPayload = action.payload['category']?.toString().toLowerCase() == 'medical' ||
        action.payload.values.any((val) => val.toString().contains('medicine') ||
            val.toString().contains('medical') ||
            val.toString().contains('دارو') ||
            val.toString().contains('دوز') ||
            val.toString().contains('قرص') ||
            val.toString().contains('نسخه'));
            
    if (isMedicalPayload) {
      if (context.mounted) {
        _showMedicalBlockDialog(context);
      }
      return;
    }

    if (action.type == AssistantActionType.completeRoutine ||
        action.type == AssistantActionType.skipRoutine ||
        action.type == AssistantActionType.editRoutine ||
        action.type == AssistantActionType.deleteRoutine) {
      final routineId = action.payload['routineId']?.toString();
      if (routineId != null && routineId.isNotEmpty) {
        final routinesList = await db.query('routines', where: 'id = ?', whereArgs: [routineId]);
        if (routinesList.isNotEmpty) {
          final category = routinesList.first['category']?.toString();
          if (category == 'medical') {
            if (context.mounted) {
              _showMedicalBlockDialog(context);
            }
            return;
          }
        }
      }
    }

    switch (action.type) {
      case AssistantActionType.createRoutine:
        // Map payload to edit structure
        final categoryMap = {
          'work': 'work',
          'fitness': 'fitness',
          'health': 'health',
          'study': 'study',
          'personal': 'personal',
          'worship': 'worship'
        };
        final categoryStr = categoryMap[action.payload['category']?.toString().toLowerCase()] ?? 'personal';
        
        final tempRoutine = {
          'id': '',
          'title': action.payload['title']?.toString() ?? '',
          'description': action.payload['description']?.toString() ?? '',
          'category': categoryStr,
          'routineType': action.payload['routineType']?.toString() ?? 'ROUTINE',
          'timeOfDay': action.payload['timeOfDay']?.toString() ?? '09:00',
          'recurrenceType': action.payload['recurrenceType']?.toString(),
          'intervalDays': action.payload['intervalDays'],
          'intervalHours': action.payload['intervalHours'],
          'weekdays': action.payload['weekdays'],
          'targetDurationMinutes': action.payload['durationMinutes'],
        };

        if (context.mounted) {
          unawaited(Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              barrierDismissible: true,
              pageBuilder: (context, _, _) => UniversalPlannerSheet(
                routineToEdit: tempRoutine,
                onSaved: () {
                  onComplete();
                },
              ),
            ),
          ));
        }

      case AssistantActionType.createGoal:
        final goalsMap = await db.query('goals', where: "status = 'ACTIVE'");
        final activeGoals = goalsMap.map(Goal.fromMap).toList();
        final routines = await db.query('routines', where: 'isArchived = 0');

        final typeStr = action.payload['goalType']?.toString().toUpperCase() ?? 'DAILY';
        final goalLevel = GoalLevel.fromString(typeStr);

        final tempGoal = Goal(
          id: '',
          title: action.payload['title']?.toString() ?? '',
          description: action.payload['description']?.toString() ?? '',
          goalType: goalLevel,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        if (context.mounted) {
          unawaited(showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => CreateGoalSheet(
              activeGoals: activeGoals,
              routines: routines,
              goalToEdit: tempGoal,
              onSaved: () {
                Navigator.pop(context);
                onComplete();
              },
            ),
          ));
        }

      case AssistantActionType.logSleep:
        final settings = await db.query('app_settings');
        final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
        final target = SleepTarget(
          bedtime: settingsMap['sleep_target_bedtime'] ?? '23:30',
          wake: settingsMap['sleep_target_wake'] ?? '07:00',
          durationMinutes: int.tryParse(settingsMap['sleep_target_duration_minutes'] ?? '450') ?? 450,
        );

        if (context.mounted) {
          unawaited(showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => SleepLogSheet(
              target: target,
              onSaved: () {
                Navigator.pop(context);
                onComplete();
              },
            ),
          ));
        }

      case AssistantActionType.logEnergyMood:
        if (context.mounted) {
          unawaited(showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => QuickLogSheet(
              onSaved: () {
                Navigator.pop(context);
                onComplete();
              },
            ),
          ));
        }

      case AssistantActionType.addKonkurItem:
        final subjectsMap = await db.query('konkur_subjects', where: 'isArchived = 0');
        final subjects = subjectsMap.map(KonkurSubject.fromMap).toList();

        final topicsMap = await db.query('konkur_topics');
        final topics = topicsMap.map(KonkurTopic.fromMap).toList();

        if (context.mounted) {
          unawaited(showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => KonkurStudySheet(
              subjects: subjects,
              topics: topics,
              onSaved: () {
                Navigator.pop(context);
                onComplete();
              },
            ),
          ));
        }

      case AssistantActionType.createCourse:
        if (context.mounted) {
          unawaited(showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => CreateCourseSheet(
              initialValues: action.payload,
              onCourseCreated: () {
                Navigator.pop(context);
                onComplete();
              },
            ),
          ));
        }

      case AssistantActionType.openPage:
        final route = action.targetRoute ?? action.payload['targetRoute']?.toString();
        if (route == null || !context.mounted) return;

        Widget? targetScreen;
        int? targetTabIndex;

        if (route == '/goals') {
          targetScreen = const GoalsScreen();
        } else if (route == '/sports' || route == '/sport') {
          targetScreen = const SSHomeDashboardScreen();
        } else if (route == '/konkur') {
          targetScreen = const KonkurScreen();
        } else if (route == '/health') {
          targetScreen = const HealthScreen();
        } else if (route == '/sleep') {
          targetScreen = const WellbeingScreen(initialSection: WellbeingSection.sleep);
        } else if (route == '/worship') {
          targetScreen = const WorshipScreen();
        } else if (route == '/' || route == '/today') {
          targetTabIndex = 2;
        } else if (route == '/routines' || route == '/routine') {
          targetTabIndex = 3;
        } else if (route == '/systems' || route == '/system') {
          targetTabIndex = 0;
        } else if (route == '/insights' || route == '/reports') {
          targetTabIndex = 1;
        } else if (route == '/calendar') {
          targetTabIndex = 4;
        }

        if (targetTabIndex != null) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          RitmoEventBus().fire(RitmoEvent(
            type: 'navigate_tab',
            timestamp: DateTime.now(),
            payload: {'index': targetTabIndex},
          ));
          onComplete();
          return;
        } else if (targetScreen != null) {
          unawaited(Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen!),
          ).then((_) => onComplete()));
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
          onComplete();
        }

      case AssistantActionType.updateSetting:
        final key = action.payload['key']?.toString() ?? '';
        final value = action.payload['value']?.toString() ?? '';
        final humanLabel = action.payload['humanLabel']?.toString() ?? kAiSettingsAllowlist[key]?.humanLabel ?? key;

        if (!isSettingChangeAllowed(key)) {
          if (context.mounted) {
            unawaited(showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('محدودیت دسترسی', textAlign: TextAlign.right),
                content: const Text(
                  'تغییر این تنظیمات به دلایل امنیتی از طریق دستیار هوشمند امکان‌پذیر نیست.',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: 'Vazirmatn'),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('تایید')),
                ],
              ),
            ));
          }
          return;
        }

        final normalized = validateAndNormalize(key, value);
        if (normalized == null) {
          if (context.mounted) {
            unawaited(showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('مقدار نامعتبر', textAlign: TextAlign.right),
                content: const Text(
                  'مقدار پیشنهادی برای تنظیمات معتبر نیست.',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: 'Vazirmatn'),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('تایید')),
                ],
              ),
            ));
          }
          return;
        }

        final existing = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
        final oldValue = existing.isNotEmpty ? existing.first['value']! as String : 'ثبت نشده';

        if (context.mounted) {
          unawaited(showDialog(
            context: context,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تایید تغییر تنظیمات', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                content: Text(
                  'آیا مایلید تنظیم «$humanLabel» را از «$oldValue» به «$normalized» تغییر دهید؟',
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await applySettingChange(key, normalized);
                      if (success) {
                        onComplete();
                      }
                    },
                    child: const Text('تایید', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ));
        }

      case AssistantActionType.completeRoutine:
        final routineId = action.payload['routineId']?.toString();
        if (routineId == null || routineId.isEmpty) return;

        final routinesList = await db.query('routines', where: 'id = ?', whereArgs: [routineId]);
        if (routinesList.isEmpty) return;

        final title = routinesList.first['title']?.toString() ?? '';

        if (context.mounted) {
          unawaited(showDialog(
            context: context,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تایید انجام روتین', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                content: Text(
                  'آیا روتین «$title» را امروز انجام داده‌اید؟',
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final now = DateTime.now().millisecondsSinceEpoch;
                      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                      
                      final existing = await db.query(
                        'routine_completions',
                        where: 'routineId = ? AND completionDate = ?',
                        whereArgs: [routineId, todayStr],
                      );

                      if (existing.isNotEmpty) {
                        await db.update(
                          'routine_completions',
                          {
                            'completionTime': now,
                            'resultType': 'COMPLETED',
                          },
                          where: 'routineId = ? AND completionDate = ?',
                          whereArgs: [routineId, todayStr],
                        );
                      } else {
                        await db.insert('routine_completions', {
                          'id': 'comp_${routineId}_$now',
                          'routineId': routineId,
                          'completionDate': todayStr,
                          'completionTime': now,
                          'resultType': 'COMPLETED',
                          'resultSource': 'USER',
                          'createdAt': now,
                        });
                      }

                      // Save to audit
                      final auditId = '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}';
                      await db.insert('assistant_audit_log', {
                        'id': auditId,
                        'actionType': 'completeRoutine',
                        'targetKey': routineId,
                        'newValue': 'COMPLETED',
                        'appliedAt': DateTime.now().millisecondsSinceEpoch,
                      });

                      RitmoEvents.notifyRoutineChanged();
                      onComplete();
                    },
                    child: const Text('تایید', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ));
        }

      case AssistantActionType.skipRoutine:
        final routineId = action.payload['routineId']?.toString();
        if (routineId == null || routineId.isEmpty) return;

        final routinesList = await db.query('routines', where: 'id = ?', whereArgs: [routineId]);
        if (routinesList.isEmpty) return;

        final title = routinesList.first['title']?.toString() ?? '';

        if (context.mounted) {
          unawaited(showDialog(
            context: context,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تایید رد کردن روتین', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                content: Text(
                  'آیا روتین «$title» را برای امروز رد می‌کنید؟',
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final now = DateTime.now().millisecondsSinceEpoch;
                      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                      
                      final existing = await db.query(
                        'routine_completions',
                        where: 'routineId = ? AND completionDate = ?',
                        whereArgs: [routineId, todayStr],
                      );

                      if (existing.isNotEmpty) {
                        await db.update(
                          'routine_completions',
                          {
                            'completionTime': now,
                            'resultType': 'SKIPPED',
                          },
                          where: 'routineId = ? AND completionDate = ?',
                          whereArgs: [routineId, todayStr],
                        );
                      } else {
                        await db.insert('routine_completions', {
                          'id': 'skip_${routineId}_$now',
                          'routineId': routineId,
                          'completionDate': todayStr,
                          'completionTime': now,
                          'resultType': 'SKIPPED',
                          'resultSource': 'USER',
                          'createdAt': now,
                        });
                      }

                      // Save to audit
                      final auditId = '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}';
                      await db.insert('assistant_audit_log', {
                        'id': auditId,
                        'actionType': 'skipRoutine',
                        'targetKey': routineId,
                        'newValue': 'SKIPPED',
                        'appliedAt': DateTime.now().millisecondsSinceEpoch,
                      });

                      RitmoEvents.notifyRoutineChanged();
                      onComplete();
                    },
                    child: const Text('تایید', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ));
        }

      case AssistantActionType.editRoutine:
        final routineId = action.payload['routineId']?.toString();
        if (routineId == null || routineId.isEmpty) return;

        final routinesList = await db.query('routines', where: 'id = ?', whereArgs: [routineId]);
        if (routinesList.isEmpty) return;

        final routineData = Map<String, dynamic>.from(routinesList.first);
        if (action.payload['title'] != null) {
          routineData['title'] = action.payload['title'];
        }
        if (action.payload['description'] != null) {
          routineData['description'] = action.payload['description'];
        }
        if (action.payload['timeOfDay'] != null) {
          routineData['timeOfDay'] = action.payload['timeOfDay'];
        }
        if (action.payload['durationMinutes'] != null) {
          routineData['targetDurationMinutes'] = (action.payload['durationMinutes'] as num).toInt();
        }

        if (context.mounted) {
          unawaited(Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              barrierDismissible: true,
              pageBuilder: (context, _, _) => UniversalPlannerSheet(
                routineToEdit: routineData,
                onSaved: () async {
                  final auditId = '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}';
                  await db.insert('assistant_audit_log', {
                    'id': auditId,
                    'actionType': 'editRoutine',
                    'targetKey': routineId,
                    'newValue': 'EDITED',
                    'appliedAt': DateTime.now().millisecondsSinceEpoch,
                  });
                  
                  RitmoEvents.notifyRoutineChanged();
                  onComplete();
                },
              ),
            ),
          ));
        }

      case AssistantActionType.deleteRoutine:
        final routineId = action.payload['routineId']?.toString();
        if (routineId == null || routineId.isEmpty) return;

        final routinesList = await db.query('routines', where: 'id = ?', whereArgs: [routineId]);
        if (routinesList.isEmpty) return;

        final title = routinesList.first['title']?.toString() ?? '';

        if (context.mounted) {
          unawaited(showDialog(
            context: context,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تایید حذف روتین', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                content: Text(
                  'آیا از حذف روتین «$title» اطمینان دارید؟ این عمل قابل بازگشت نیست.',
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await db.update(
                        'routines',
                        {'isArchived': 1},
                        where: 'id = ?',
                        whereArgs: [routineId],
                      );

                      // Save to audit
                      final auditId = '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}';
                      await db.insert('assistant_audit_log', {
                        'id': auditId,
                        'actionType': 'deleteRoutine',
                        'targetKey': routineId,
                        'newValue': 'ARCHIVED',
                        'appliedAt': DateTime.now().millisecondsSinceEpoch,
                      });

                      RitmoEvents.notifyRoutineChanged();
                      onComplete();
                    },
                    child: const Text('تایید حذف', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ));
        }

      case AssistantActionType.editGoal:
        final goalId = action.payload['goalId']?.toString();
        if (goalId == null || goalId.isEmpty) return;

        final goalsList = await db.query('goals', where: 'id = ?', whereArgs: [goalId]);
        if (goalsList.isEmpty) return;

        final goalData = Goal.fromMap(goalsList.first);
        final newTitle = action.payload['title']?.toString() ?? goalData.title;
        final newDesc = action.payload['description']?.toString() ?? goalData.description ?? '';
        var newLevel = goalData.goalType;
        if (action.payload['goalType'] != null) {
          newLevel = GoalLevel.fromString(action.payload['goalType'].toString().toUpperCase());
        }

        final updatedGoal = Goal(
          id: goalData.id,
          parentGoalId: goalData.parentGoalId,
          title: newTitle,
          description: newDesc,
          goalType: newLevel,
          status: goalData.status,
          targetDate: goalData.targetDate,
          progressCache: goalData.progressCache,
          isPrivate: goalData.isPrivate,
          createdAt: goalData.createdAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final activeGoalsList = await db.query('goals', where: "status = 'ACTIVE'");
        final activeGoals = activeGoalsList.map(Goal.fromMap).toList();
        final routinesListForGoals = await db.query('routines', where: 'isArchived = 0');

        if (context.mounted) {
          unawaited(showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => CreateGoalSheet(
              activeGoals: activeGoals,
              routines: routinesListForGoals,
              goalToEdit: updatedGoal,
              onSaved: () async {
                Navigator.pop(context);
                final auditId = '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}';
                await db.insert('assistant_audit_log', {
                  'id': auditId,
                  'actionType': 'editGoal',
                  'targetKey': goalId,
                  'newValue': 'EDITED',
                  'appliedAt': DateTime.now().millisecondsSinceEpoch,
                });
                onComplete();
              },
            ),
          ));
        }

      case AssistantActionType.completeGoalStep:
        final stepId = action.payload['stepId']?.toString();
        if (stepId == null || stepId.isEmpty) return;

        final stepList = await db.query('goal_steps', where: 'id = ?', whereArgs: [stepId]);
        if (stepList.isEmpty) return;

        final title = stepList.first['title']?.toString() ?? '';

        if (context.mounted) {
          unawaited(showDialog(
            context: context,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تایید تکمیل گام هدف', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                content: Text(
                  'آیا گام «$title» را تکمیل کرده‌اید؟',
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await db.update(
                        'goal_steps',
                        {'isCompleted': 1},
                        where: 'id = ?',
                        whereArgs: [stepId],
                      );

                      // Save to audit
                      final auditId = '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}';
                      await db.insert('assistant_audit_log', {
                        'id': auditId,
                        'actionType': 'completeGoalStep',
                        'targetKey': stepId,
                        'newValue': 'COMPLETED',
                        'appliedAt': DateTime.now().millisecondsSinceEpoch,
                      });

                      onComplete();
                    },
                    child: const Text('تایید', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ));
        }

      case AssistantActionType.createWorshipItem:
        final id = action.payload['id']?.toString();
        if (id != null && id.isNotEmpty) {
          final title = action.payload['title']?.toString() ?? 'عبادت جدید';
          final practiceType = action.payload['practiceType']?.toString() ?? 'MUSTAHAB';
          final subType = action.payload['subType']?.toString() ?? 'CUSTOM';
          final isActive = action.payload['isActive'] == null ? 1 : (int.tryParse(action.payload['isActive'].toString()) ?? 1);
          
          final reminderEnabled = action.payload['reminderEnabled'] == null ? 0 : (int.tryParse(action.payload['reminderEnabled'].toString()) ?? 0);
          final reminderTime = action.payload['reminderTime']?.toString() ?? '09:00';
          final reminderFrequency = action.payload['reminderFrequency']?.toString() ?? 'DAILY';
          final reminderDaysOfWeek = action.payload['reminderDaysOfWeek']?.toString();
          
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final todayStr = DateTime.now().toIso8601String().substring(0, 10);

          final existing = await db.query('worship_practices', where: 'id = ?', whereArgs: [id]);
          
          if (existing.isEmpty) {
            await db.insert(
              'worship_practices',
              {
                'id': id,
                'practiceType': practiceType,
                'subType': subType,
                'title': title,
                'dailyTarget': 1,
                'dailyDone': 0,
                'reminderEnabled': reminderEnabled,
                'reminderTime': reminderTime,
                'reminderFrequency': reminderFrequency,
                'reminderAnchor': 'NONE',
                'reminderOffsetMinutes': 0,
                'reminderDaysOfWeek': reminderDaysOfWeek,
                'reminderTimes': jsonEncode([reminderTime]),
                'isActive': isActive,
                'notes': action.payload['notes']?.toString() ?? '',
                'dailyDoneDate': todayStr,
                'createdAt': nowMs,
                'updatedAt': nowMs,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            await db.update(
              'worship_practices',
              {
                'title': title,
                'isActive': isActive,
                'reminderEnabled': reminderEnabled,
                'reminderTime': reminderTime,
                'reminderFrequency': reminderFrequency,
                'reminderDaysOfWeek': reminderDaysOfWeek,
                'reminderTimes': jsonEncode([reminderTime]),
                'updatedAt': nowMs,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }

          if (context.mounted) {
            RitmoToast.show(
              context,
              'برنامه عبادی "$title" با موفقیت تنظیم شد ✨',
            );
          }
          
          // Notify app components of the change
          RitmoEventBus().fire(RitmoEvent(
            type: 'worship_updated',
            timestamp: DateTime.now(),
            payload: {'practiceId': id},
          ));
          RitmoEvents.notifyRoutineChanged();
          
          onComplete();
        }

      case AssistantActionType.deleteWorshipItem:
        final id = action.payload['id']?.toString();
        if (id == null || id.isEmpty) return;

        final practices = await db.query('worship_practices', where: 'id = ?', whereArgs: [id]);
        if (practices.isNotEmpty) {
          final practice = practices.first;
          final practiceType = practice['practiceType']?.toString() ?? 'MUSTAHAB';
          final title = practice['title']?.toString() ?? 'برنامه عبادی';

          if (practiceType == 'MUSTAHAB') {
            await db.update(
              'worship_practices',
              {
                'isActive': 0,
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          } else {
            await db.delete(
              'worship_practices',
              where: 'id = ?',
              whereArgs: [id],
            );
          }

          if (context.mounted) {
            RitmoToast.show(context, 'برنامه عبادی "$title" با موفقیت حذف شد 🗑️');
          }

          RitmoEventBus().fire(RitmoEvent(
            type: 'worship_updated',
            timestamp: DateTime.now(),
            payload: {'practiceId': id},
          ));
          RitmoEvents.notifyRoutineChanged();
          onComplete();
        } else {
          onComplete();
        }

      case AssistantActionType.logReflection:
        if (context.mounted) {
          unawaited(showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => DailyReflectionSheet(
              onSaved: () {
                onComplete();
              },
            ),
          ));
        }

      case AssistantActionType.rescheduleReminder:
        onComplete();

      case AssistantActionType.swapExercise:
        final oldExId = action.payload['oldExerciseId']?.toString();
        final newExId = action.payload['newExerciseId']?.toString();
        if (oldExId == null || newExId == null || oldExId.isEmpty || newExId.isEmpty) {
          onComplete();
          return;
        }

        // Get today's latest workout log (within 12 hours)
        final twelveHoursAgo = DateTime.now().subtract(const Duration(hours: 12)).millisecondsSinceEpoch;
        final logs = await db.query(
          'workout_logs',
          where: 'loggedAt >= ?',
          whereArgs: [twelveHoursAgo],
          orderBy: 'loggedAt DESC',
          limit: 1,
        );

        var legacyRowsAffected = 0;
        if (logs.isNotEmpty) {
          final logId = logs.first['id']! as String;
          // Update the workout_set_logs
          legacyRowsAffected = await db.update(
            'workout_set_logs',
            {'exerciseId': newExId},
            where: 'workoutLogId = ? AND exerciseId = ?',
            whereArgs: [logId, oldExId],
          );
        }

        // Update supplementary sports table (ss_workout_exercise_crossref)
        final ssRowsAffected = await db.update(
          'ss_workout_exercise_crossref',
          {'exerciseId': newExId},
          where: 'exerciseId = ?',
          whereArgs: [oldExId],
        );

        final totalRowsAffected = legacyRowsAffected + ssRowsAffected;

        if (totalRowsAffected > 0) {
          // If we updated supplementary sports, log version history
          if (ssRowsAffected > 0) {
            // Retrieve new exercise name
            final newExRows = await db.query('ss_exercise', where: 'id = ?', whereArgs: [newExId], limit: 1);
            final newName = newExRows.isNotEmpty ? newExRows.first['name']! as String : 'حرکت جدید';

            final now = DateTime.now().millisecondsSinceEpoch;
            final currentPlans = await db.query('ss_workout_plan');
            final currentCrossRefs = await db.query('ss_workout_exercise_crossref');
            final serializedData = {
              'plans': currentPlans,
              'crossrefs': currentCrossRefs,
            };
            await db.insert('ss_plan_version_history', {
              'id': 'snap_$now',
              'serializedPlan': jsonEncode(serializedData),
              'changeReason': 'جایگزینی حرکت به $newName از طریق دستیار صوتی/متنی',
              'createdAt': now,
            });

            if (context.mounted) {
              RitmoToast.show(context, 'حرکت ورزشی با موفقیت به "$newName" تعویض شد 🔄');
            }
          } else {
            // Updated legacy sports
            final newExRows = await db.query('exercises_library', where: 'id = ?', whereArgs: [newExId], limit: 1);
            final newName = newExRows.isNotEmpty ? newExRows.first['name']! as String : 'حرکت جدید';
            if (context.mounted) {
              RitmoToast.show(context, 'حرکت ورزشی با موفقیت به "$newName" تعویض شد 🔄');
            }
          }

          RitmoEventBus().fire(RitmoEvent(
            type: 'sports_updated',
            timestamp: DateTime.now(),
            payload: {'action': 'swap', 'newExerciseId': newExId},
          ));
        } else {
          // 0 rows affected -> toast false success warning honestly
          if (context.mounted) {
            RitmoToast.show(context, 'این حرکت در برنامه فعال پیدا نشد ⚠️');
          }
        }
        onComplete();

      case AssistantActionType.adjustWorkoutIntensity:
        final duration = action.payload['sessionDuration']?.toString();
        final intensity = action.payload['intensity']?.toString();
        final crossRefId = action.payload['crossRefId']?.toString();
        final exerciseId = action.payload['exerciseId']?.toString();
        final newWeight = action.payload['newWeight'] != null ? double.tryParse(action.payload['newWeight'].toString()) : null;
        final newReps = action.payload['newReps'] != null ? int.tryParse(action.payload['newReps'].toString()) : null;
        final newSets = action.payload['newSets'] != null ? int.tryParse(action.payload['newSets'].toString()) : null;
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        var ssRowsAffected = 0;

        if (crossRefId != null && crossRefId.isNotEmpty) {
          final updateValues = <String, dynamic>{};
          if (newWeight != null) updateValues['targetWeight'] = newWeight;
          if (newReps != null) updateValues['targetReps'] = newReps;
          if (newSets != null) updateValues['targetSets'] = newSets;

          if (updateValues.isNotEmpty) {
            ssRowsAffected = await db.update(
              'ss_workout_exercise_crossref',
              updateValues,
              where: 'id = ?',
              whereArgs: [crossRefId],
            );
          }
        } else if (exerciseId != null && exerciseId.isNotEmpty) {
          final updateValues = <String, dynamic>{};
          if (newWeight != null) updateValues['targetWeight'] = newWeight;
          if (newReps != null) updateValues['targetReps'] = newReps;
          if (newSets != null) updateValues['targetSets'] = newSets;

          if (updateValues.isNotEmpty) {
            ssRowsAffected = await db.update(
              'ss_workout_exercise_crossref',
              updateValues,
              where: 'exerciseId = ?',
              whereArgs: [exerciseId],
            );
          }
        } else {
          // Construct update values for ss_user_profile
          final updateValues = <String, dynamic>{};
          if (duration != null && duration.isNotEmpty) {
            updateValues['sessionDuration'] = duration;
          }
          if (intensity != null && intensity.isNotEmpty) {
            if (intensity.toLowerCase().contains('strength')) {
              updateValues['goal'] = 'strength';
            } else if (intensity.toLowerCase().contains('muscle')) {
              updateValues['goal'] = 'muscleGain';
            } else if (intensity.toLowerCase().contains('fat') || intensity.toLowerCase().contains('cardio')) {
              updateValues['goal'] = 'fatLoss';
            } else if (intensity.toLowerCase().contains('recomp') || intensity.toLowerCase().contains('body')) {
              updateValues['goal'] = 'bodyRecomposition';
            } else if (intensity == 'HARD') {
              updateValues['experienceLevel'] = 'advanced';
            } else if (intensity == 'MEDIUM') {
              updateValues['experienceLevel'] = 'intermediate';
            } else if (intensity == 'LIGHT') {
              updateValues['experienceLevel'] = 'beginner';
            }
          }

          if (updateValues.isNotEmpty) {
            updateValues['updatedAt'] = nowMs;
            ssRowsAffected = await db.update(
              'ss_user_profile',
              updateValues,
              where: 'id = ?',
              whereArgs: ['default'],
            );
          }
        }

        // Keep legacy updates as well
        if (duration != null && duration.isNotEmpty) {
          await db.insert('app_settings', {
            'key': 'sports_session_duration',
            'value': duration,
            'updatedAt': nowMs,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          final twelveHoursAgo = DateTime.now().subtract(const Duration(hours: 12)).millisecondsSinceEpoch;
          final logs = await db.query(
            'workout_logs',
            where: 'loggedAt >= ?',
            whereArgs: [twelveHoursAgo],
            orderBy: 'loggedAt DESC',
            limit: 1,
          );
          if (logs.isNotEmpty) {
            final logId = logs.first['id']! as String;
            await db.update(
              'workout_logs',
              {'durationMinutes': int.tryParse(duration) ?? 30},
              where: 'id = ?',
              whereArgs: [logId],
            );
          }
        }

        if (intensity != null && intensity.isNotEmpty) {
          await db.insert('app_settings', {
            'key': 'sports_goal_focus',
            'value': intensity,
            'updatedAt': nowMs,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        if (ssRowsAffected > 0) {
          // Log version history
          final currentPlans = await db.query('ss_workout_plan');
          final currentCrossRefs = await db.query('ss_workout_exercise_crossref');
          final serializedData = {
            'plans': currentPlans,
            'crossrefs': currentCrossRefs,
          };
          await db.insert('ss_plan_version_history', {
            'id': 'snap_$nowMs',
            'serializedPlan': jsonEncode(serializedData),
            'changeReason': 'تغییر تنظیمات شدت/مدت جلسه تمرینی از طریق دستیار صوتی/متنی',
            'createdAt': nowMs,
          });

          if (context.mounted) {
            RitmoToast.show(context, 'تنظیمات تمرین با موفقیت به‌روزرسانی شد ⚙️');
          }
        } else {
          if (context.mounted) {
            RitmoToast.show(context, 'تنظیمات شدت و زمان تمرین با موفقیت به روز شد 🔋');
          }
        }
        RitmoEventBus().fire(RitmoEvent(
          type: 'sports_updated',
          timestamp: DateTime.now(),
          payload: {'action': 'adjust_intensity'},
        ));
        onComplete();

      case AssistantActionType.setQuietMode:
        final onVal = action.payload['on'] == true || action.payload['on']?.toString() == 'true';
        await db.update(
          'ss_user_profile',
          {'neighborFriendly': onVal ? 1 : 0},
          where: 'id = ?',
          whereArgs: ['default'],
        );
        if (context.mounted) {
          RitmoToast.show(context, onVal ? 'حالت بی‌صدا (آپارتمانی) فعال شد 🔇' : 'حالت بی‌صدا غیرفعال شد 🔊');
        }
        RitmoEventBus().fire(RitmoEvent(
          type: 'sports_updated',
          timestamp: DateTime.now(),
          payload: {'action': 'set_quiet_mode', 'enabled': onVal},
        ));
        onComplete();

      case AssistantActionType.changeSetProgram:
        final code = action.payload['set_code']?.toString() ?? '';
        final updateValues = <String, dynamic>{};
        if (code.toLowerCase() == 'beginner' || code.toLowerCase() == 'intermediate' || code.toLowerCase() == 'advanced') {
          updateValues['experienceLevel'] = code;
        } else if (code.toLowerCase() == 'musclegain' || code.toLowerCase() == 'fatloss' || code.toLowerCase() == 'bodyrecomposition' || code.toLowerCase() == 'strength') {
          updateValues['goal'] = code;
        }
        if (updateValues.isNotEmpty) {
          await db.update(
            'ss_user_profile',
            updateValues,
            where: 'id = ?',
            whereArgs: ['default'],
          );
          if (context.mounted) {
            RitmoToast.show(context, 'برنامه تمرینی شما با موفقیت تغییر یافت 🔋');
          }
        }
        RitmoEventBus().fire(RitmoEvent(
          type: 'sports_updated',
          timestamp: DateTime.now(),
          payload: {'action': 'change_set_program', 'code': code},
        ));
        onComplete();

      case AssistantActionType.rescheduleDay:
        final fromDay = int.tryParse(action.payload['from']?.toString() ?? '');
        final toDay = int.tryParse(action.payload['to']?.toString() ?? '');
        if (fromDay != null && toDay != null) {
          final fromPlan = await db.query('ss_workout_plan', where: 'dayNumber = ?', whereArgs: [fromDay]);
          final toPlan = await db.query('ss_workout_plan', where: 'dayNumber = ?', whereArgs: [toDay]);
          if (fromPlan.isNotEmpty && toPlan.isNotEmpty) {
            final fromRest = fromPlan.first['isRestDay']! as int;
            final toRest = toPlan.first['isRestDay']! as int;
            
            await db.update('ss_workout_plan', {'isRestDay': toRest}, where: 'dayNumber = ?', whereArgs: [fromDay]);
            await db.update('ss_workout_plan', {'isRestDay': fromRest}, where: 'dayNumber = ?', whereArgs: [toDay]);
            
            if (context.mounted) {
              RitmoToast.show(context, 'برنامه روز $fromDay و روز $toDay با موفقیت جابجا شد 🗓');
            }
          }
        }
        RitmoEventBus().fire(RitmoEvent(
          type: 'sports_updated',
          timestamp: DateTime.now(),
          payload: {'action': 'reschedule_day', 'from': fromDay, 'to': toDay},
        ));
        onComplete();

      case AssistantActionType.applyDayPlan:
        final planDate = action.payload['planDate']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10);
        final items = action.payload['items'] as List? ?? [];
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        final createdRoutineIds = <String>[];
        final createdWorshipIds = <String>[];
        final updatedWorshipIds = <String>[];
        final updatedSleepSettings = <String>[];

        try {
          await db.transaction((txn) async {
            for (final rawItem in items) {
              final item = Map<String, dynamic>.from(rawItem as Map);
              final targetModule = item['targetModule']?.toString() ?? '';
              final title = item['title']?.toString() ?? '';

              if (targetModule == 'worship') {
                final existing = await txn.query('worship_practices', 
                  where: 'title = ? AND isActive = 1', 
                  whereArgs: [title]);

                if (existing.isEmpty) {
                  final id = 'worship_${nowMs}_${math.Random().nextInt(99999)}';
                  final practiceType = item['category']?.toString().toUpperCase() == 'DHIKR' 
                      ? 'DHIKR' 
                      : (item['category']?.toString().toUpperCase() == 'QURAN' ? 'QURAN' : 'MUSTAHAB');
                  await txn.insert('worship_practices', {
                    'id': id,
                    'practiceType': practiceType,
                    'subType': 'CUSTOM',
                    'title': title,
                    'dailyTarget': 1,
                    'dailyDone': 0,
                    'reminderEnabled': 1,
                    'reminderTime': item['resolvedTime'] ?? '09:00',
                    'reminderFrequency': 'DAILY',
                    'reminderAnchor': item['startKind'] == 'anchor' ? item['anchorEvent'] : 'NONE',
                    'reminderOffsetMinutes': item['offsetMin'] ?? 0,
                    'reminderTimes': jsonEncode([item['resolvedTime'] ?? '09:00']),
                    'isActive': 1,
                    'notes': item['note'] ?? '',
                    'dailyDoneDate': planDate,
                    'createdAt': nowMs,
                    'updatedAt': nowMs,
                  });
                  createdWorshipIds.add(id);
                } else {
                  final existingId = existing.first['id']! as String;
                  await txn.update('worship_practices', {
                    'reminderTime': item['resolvedTime'] ?? '09:00',
                    'reminderAnchor': item['startKind'] == 'anchor' ? item['anchorEvent'] : 'NONE',
                    'reminderOffsetMinutes': item['offsetMin'] ?? 0,
                    'reminderTimes': jsonEncode([item['resolvedTime'] ?? '09:00']),
                    'updatedAt': nowMs,
                  }, where: 'id = ?', whereArgs: [existingId]);
                  updatedWorshipIds.add(existingId);
                }
              } else if (targetModule == 'sleep' || title.contains('بیدار')) {
                await txn.insert('app_settings', {
                  'key': 'sleep_target_wake',
                  'value': item['resolvedTime'] ?? '07:00',
                  'updatedAt': nowMs,
                }, conflictAlgorithm: ConflictAlgorithm.replace);
                updatedSleepSettings.add('sleep_target_wake');
              } else {
                final routineId = 'routine_${nowMs}_${math.Random().nextInt(99999)}';
                final itemType = item['recurrence'] == 'daily' ? 'ROUTINE' : 'TASK';

                final categoryMap = {
                  'work': 'work',
                  'fitness': 'fitness',
                  'health': 'health',
                  'study': 'study',
                  'personal': 'personal',
                  'worship': 'worship'
                };
                final categoryStr = categoryMap[item['category']?.toString().toLowerCase()] ?? 'personal';

                final routineData = {
                  'id': routineId,
                  'title': title,
                  'description': item['note']?.toString(),
                  'category': categoryStr,
                  'routineType': itemType == 'ROUTINE' ? 'timeBased' : 'asNeeded',
                  'notificationLevel': 'normal',
                  'isEssential': 0,
                  'isEssentialLocked': 0,
                  'energyRule': 'NONE',
                  'priority': 1.0,
                  'targetDurationMinutes': item['durationMin'] ?? 30,
                  'lightDurationMinutes': 0,
                  'minimalDurationMinutes': 0,
                  'isArchived': 0,
                  'isPrivate': 0,
                  'displayOrder': 1,
                  'createdAt': nowMs,
                  'updatedAt': nowMs,
                  'itemType': itemType,
                  'reminderOffsetMinutes': 0,
                };

                final scheduleData = {
                  'id': 'sched_$routineId',
                  'routineId': routineId,
                  'scheduleType': itemType == 'TASK' ? 'DAILY' : 'RECURRENCE',
                  'timeOfDay': item['resolvedTime'] ?? '08:00',
                  'daysOfWeek': '6,7,1,2,3,4,5',
                  'recurrenceRule': jsonEncode({
                    'weekdays': [1, 2, 3, 4, 5, 6, 7],
                    'startDate': planDate,
                  }),
                  'createdAt': nowMs,
                  'updatedAt': nowMs,
                };

                await txn.insert('routines', routineData);
                await txn.insert('routine_schedules', scheduleData);

                final rule = RecurrenceRule.fromMap({
                  'weekdays': [1, 2, 3, 4, 5, 6, 7],
                  'startDate': DateTime.tryParse(planDate) ?? DateTime.now(),
                  'reminderTimes': [item['resolvedTime'] ?? '08:00'],
                });
                await RoutineOccurrenceGenerator.generateFutureOccurrences(txn, routineId, rule);
                createdRoutineIds.add(routineId);
              }
            }

            final commitId = 'commit_$nowMs';
            final groupId = action.payload['groupId']?.toString();
            final commitData = {
              'id': commitId,
              'commitDate': planDate,
              'createdItemIds': jsonEncode({
                'routines': createdRoutineIds,
                'worship': createdWorshipIds,
                'updatedWorship': updatedWorshipIds,
                'sleep': updatedSleepSettings,
              }),
              'createdAt': nowMs,
              'groupId': groupId,
            };
            await txn.insert('day_plan_commits', commitData);
          });

          RitmoEvents.notifyRoutineChanged();
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: context.colors.bg,
                content: Text(
                  'برنامه روز با موفقیت ثبت شد ⚡',
                  style: TextStyle(fontFamily: 'Vazirmatn', color: context.colors.textPrimary),
                ),
                action: SnackBarAction(
                  textColor: context.colors.goldAccent,
                  label: 'ذخیره به عنوان قالب',
                  onPressed: () {
                    _showSaveTemplateDialog(context, items);
                  },
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('[AssistantActionRegistry] applyDayPlan transaction failed: $e');
          if (context.mounted) {
            RitmoToast.show(context, 'خطا در ثبت برنامه روزانه ❌');
          }
        }
        onComplete();
    }
  }

  static void _showSaveTemplateDialog(BuildContext context, List<dynamic> rawItems) {
    final items = rawItems.map((e) => DayPlanItemDraft.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.bg,
          title: const Text('ذخیره به عنوان قالب', textAlign: TextAlign.right),
          content: TextField(
            controller: nameController,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              hintText: 'نام قالب (مثلاً: روز کاری، روز تعطیل)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                try {
                  await DayPlanTemplateService.instance.saveTemplate(
                    name: name,
                    items: items,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    RitmoToast.show(context, 'قالب با موفقیت ذخیره شد 💾');
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    RitmoToast.show(context, 'خطا در ذخیره قالب ❌');
                  }
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> undoLastDayPlanCommit(BuildContext context) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final oneDayAgo = nowMs - (24 * 3600 * 1000);

    final lastCommits = await db.query(
      'day_plan_commits',
      where: 'createdAt >= ?',
      whereArgs: [oneDayAgo],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (lastCommits.isEmpty) {
      if (context.mounted) {
        RitmoToast.show(context, 'برنامه قابل‌بازگردانی یافت نشد یا زمان آن گذشته است ⏳');
      }
      return;
    }

    final commit = lastCommits.first;
    final groupId = commit['groupId'] as String?;

    final commitsToUndo = <Map<String, dynamic>>[];
    if (groupId != null && groupId.isNotEmpty) {
      final groupCommits = await db.query(
        'day_plan_commits',
        where: 'groupId = ? AND createdAt >= ?',
        whereArgs: [groupId, oneDayAgo],
      );
      commitsToUndo.addAll(groupCommits);
    } else {
      commitsToUndo.add(commit);
    }

    final routines = <String>[];
    final worship = <String>[];
    final commitIdsToDelete = <String>[];

    for (final c in commitsToUndo) {
      commitIdsToDelete.add(c['id'] as String);
      final createdItemIds = jsonDecode(c['createdItemIds'] as String? ?? '{}') as Map<String, dynamic>;
      routines.addAll(List<String>.from(createdItemIds['routines'] ?? []));
      worship.addAll(List<String>.from(createdItemIds['worship'] ?? []));
    }

    try {
      for (final id in routines) {
        await RitmoExecutionKernel.instance.execute(
          DeleteRoutineCommand(routineId: id),
        );
      }
      await db.transaction((txn) async {
        for (final id in worship) {
          await txn.delete('worship_practices', where: 'id = ?', whereArgs: [id]);
        }
        for (final cid in commitIdsToDelete) {
          await txn.delete('day_plan_commits', where: 'id = ?', whereArgs: [cid]);
        }
      });

      for (final id in routines) {
        RitmoEventBus().fire(RitmoEvent(
          type: 'RoutineDeleted',
          timestamp: DateTime.now(),
          payload: {'routineId': id},
        ));
      }

      RitmoEvents.notifyRoutineChanged();
      if (context.mounted) {
        RitmoToast.show(context, 'برنامه چیده شده با موفقیت بازگردانده شد ↩️');
      }
    } catch (e) {
      debugPrint('[AssistantActionRegistry] Undo day plan failed: $e');
      if (context.mounted) {
        RitmoToast.show(context, 'خطا در بازگردانی برنامه ❌');
      }
    }
  }
}
