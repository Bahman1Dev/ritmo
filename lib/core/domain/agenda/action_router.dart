import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/action_feedback.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/completion/completion_gateway.dart';
import 'package:ritmo/core/domain/completion/completion_outcome.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/domain/completion/snooze_policy.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/completion_result.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/core/services/ritmo_timer_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/core/utils/ritmo_date.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_study_sheet.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
import 'package:ritmo/features/routines/shared/routine_actions.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_details_sheet.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';
import 'package:ritmo/features/supplementary_sports/movement/presentation/movement_log_sheet.dart';
import 'package:ritmo/features/today/presentation/active_timer_overlay.dart';

/// Central action router for opening the appropriate action sheet for any AgendaItem.
class ActionRouter {
  ActionRouter._();

  static Future<void> open(BuildContext context, {required AgendaItem item, VoidCallback? onChanged}) async {
    switch (item.domain) {
      case AgendaDomain.routine:
        await _handleRoutineAction(context, item, onChanged: onChanged);
        break;

      case AgendaDomain.prayer:
        await _showDomainConfirmationSheet(
          context,
          item: item,
          title: item.title,
          domainLabel: 'نماز',
          successMessage: 'نماز اول وقت ثبت شد',
          onConfirm: () => CompletionGateway.instance.submit(
            PrayerCompletion(
              prayerKey: item.sourceId,
              dateStr: item.dateStr,
              mode: 'ON_TIME',
            ),
          ),
        );
        break;

      case AgendaDomain.mustahab:
        await _showDomainConfirmationSheet(
          context,
          item: item,
          title: item.title,
          domainLabel: 'مستحبات',
          successMessage: 'مستحب انجام شد',
          onConfirm: () => CompletionGateway.instance.submit(
            WorshipCompletion(
              practiceId: item.sourceId,
              dateStr: item.dateStr,
            ),
          ),
        );
        break;

      case AgendaDomain.course:
        await _showDomainConfirmationSheet(
          context,
          item: item,
          title: item.title,
          domainLabel: 'دوره / کلاس',
          successMessage: 'حضور در جلسه دوره ثبت شد',
          onConfirm: () => CompletionGateway.instance.submit(
            CourseSessionCompletion(
              sessionId: item.sourceId,
              courseId: item.meta['courseId'] as String? ?? '',
              dateStr: item.dateStr,
            ),
          ),
        );
        break;

      case AgendaDomain.konkur:
        await _handleKonkurAction(context, item);
        break;

      case AgendaDomain.worshipDebt:
        await _showDomainConfirmationSheet(
          context,
          item: item,
          title: item.title,
          domainLabel: 'بدهی عبادی',
          successMessage: 'یک واحد از بدهی کسر شد',
          onConfirm: () => CompletionGateway.instance.submit(
            WorshipDebtProgress(
              debtId: item.sourceId,
              delta: 1,
            ),
          ),
        );
        break;

      case AgendaDomain.sport:
        await showMovementLogSheet(
          context,
          presetDate: DateTime.tryParse(item.dateStr) ?? DateTime.now(),
          presetDurationMinutes: item.durationMinutes,
          onLogged: () {
            if (context.mounted) {
              ActionFeedback.success(
                context,
                message: 'فعالیت ورزشی ثبت شد',
                dateStr: item.dateStr,
              );
            }
          },
        );
        break;

      case AgendaDomain.goalStep:
        await _showDomainConfirmationSheet(
          context,
          item: item,
          title: item.title,
          domainLabel: 'گام هدف',
          successMessage: 'گام هدف ثبت شد',
          onConfirm: () => CompletionGateway.instance.submit(
            GoalStepCompletion(
              goalId: item.meta['goalId'] as String? ?? '',
              stepId: item.sourceId,
              dateStr: item.dateStr,
            ),
          ),
        );
        break;

      case AgendaDomain.medicine:
        await _showDomainConfirmationSheet(
          context,
          item: item,
          title: item.title,
          domainLabel: 'دارو',
          successMessage: 'مصرف دارو ثبت شد',
          onConfirm: () => CompletionGateway.instance.submit(
            MedicationTake(
              medicationId: item.sourceId,
              dateStr: item.dateStr,
            ),
          ),
        );
        break;

      case AgendaDomain.cycle:
        bool canShow = false;
        try {
          final db = await DatabaseHelper.instance.database;
          final rows = await db.query('app_settings', where: 'key = ?', whereArgs: ['user_gender']);
          if (rows.isNotEmpty) {
            final val = rows.first['value'] as String?;
            canShow = CyclePrivacyGuard.isVisible({'user_gender': val ?? ''});
          }
        } catch (e, st) {
          debugPrint('[ActionRouter] Error checking cycle privacy: $e\n$st');
        }

        if (!canShow) {
          if (context.mounted) {
            ActionFeedback.info(
              context,
              message: 'سیستم چرخه سلامت غیرفعال یا پنهان است.',
            );
          }
        } else {
          if (context.mounted) {
            Navigator.pushNamed(context, '/cycle');
          }
        }
        break;
    }
  }

  static Future<void> _guard(
    BuildContext context, {
    required String tag,
    required Future<void> Function() run,
    required String failureMessage,
  }) async {
    try {
      await run();
    } catch (e, st) {
      debugPrint('[ActionRouter][$tag] $e\n$st');
      if (context.mounted) {
        ActionFeedback.failure(context, message: failureMessage);
      }
    }
  }

  static Future<void> _handleRoutineAction(BuildContext context, AgendaItem item, {VoidCallback? onChanged}) async {
    Routine? routine;
    final routineMap = item.meta['routine'] as Map<String, dynamic>?;

    if (routineMap != null) {
      routine = Routine.fromMap(routineMap);
    } else {
      try {
        final db = await DatabaseHelper.instance.database;
        final rows = await db.query('routines', where: 'id = ?', whereArgs: [item.sourceId], limit: 1);
        if (rows.isNotEmpty) {
          routine = Routine.fromMap(rows.first);
        }
      } catch (e) {
        debugPrint('[ActionRouter] Failed DB lookup for routine ${item.sourceId}: $e');
      }
    }

    if (routine == null) {
      if (context.mounted) {
        ActionFeedback.failure(context, message: 'اطلاعات این برنامه در دسترس نیست');
      }
      debugPrint('[ActionRouter] routine meta and DB fallback missing for item ${item.id}');
      return;
    }

    final targetRoutine = routine;

    if (!context.mounted) return;

    // T1: Single decision point — completed/skipped items go to details, not niyyah.
    // ⛔ This is the ONLY place this check lives; do not duplicate in journey_screen or renderer.
    if (item.isCompleted || item.completion == AgendaCompletion.skipped) {
      await RoutineDetailsSheet.show(
        context: context,
        routine: targetRoutine,
        targetDate: item.dateStr,
        onReverted: () {
          DayAgendaService.instance.invalidateDate(item.dateStr);
          onChanged?.call();
        },
      );
      return;
    }

    await RoutineNiyyahSheet.show(
      context: context,
      routine: targetRoutine,
      onStartTimer: (selectedMode) async {
        await _guard(
          context,
          tag: 'startTimer',
          failureMessage: 'تایمر شروع نشد. دوباره تلاش کن.',
          run: () async {
            final minutes = _minutesForMode(targetRoutine, selectedMode);
            if (minutes <= 0) {
              if (context.mounted) {
                ActionFeedback.failure(context, message: 'مدت زمانی برای این حالت تعریف نشده است');
              }
              return;
            }

            // T7: router starts timer with canonical ID; overlay's _startTimer
            // calls startTimer with the same ID — ConflictAlgorithm.replace deduplicates.
            await RitmoTimerService.instance.startTimer(
              id: 'routine_${targetRoutine.id}',
              domain: 'routine',
              itemId: targetRoutine.id,
              mode: selectedMode,
              durationMinutes: minutes,
            );

            if (!context.mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => ActiveTimerOverlay(
                  routine: targetRoutine,
                  completionMode: selectedMode,
                  dateStr: item.dateStr,    // T4: item date, not DateTime.now()
                  onCompleted: (outcome) {  // T6: only fires on confirmed completion
                    Navigator.pop(ctx);
                    DayAgendaService.instance.invalidateDate(item.dateStr);
                    onChanged?.call();
                    if (outcome.didWrite) {
                      ActionFeedback.success(
                        context,
                        message: 'تایمر تمام شد و روتین ثبت شد',
                        dateStr: item.dateStr,
                        undoToken: outcome.undoToken,
                      );
                    } else {
                      ActionFeedback.failure(
                        context,
                        message: outcome.errorMessage ?? 'ثبت پس از تایمر انجام نشد. دوباره تلاش کن.',
                      );
                    }
                  },
                  onCancelled: () {         // T6: neutral — no success message
                    Navigator.pop(ctx);
                    DayAgendaService.instance.invalidateDate(item.dateStr);
                    onChanged?.call();
                    ActionFeedback.info(context, message: 'تایمر لغو شد');
                  },
                ),
              ),
            );
          },
        );
      },
      onCompleteInstantly: (modeStr, duration) async {
        await _guard(
          context,
          tag: 'completeInstantly',
          failureMessage: 'ثبت انجام نشد. دوباره تلاش کن.',
          run: () async {
            final outcome = await CompletionGateway.instance.submit(
              RoutineCompletion(
                routineId: targetRoutine.id,
                dateStr: item.dateStr,
                result: CompletionResult.fromDb(modeStr),
                durationMinutes: DurationBounds.sanitize(duration),
              ),
            );

            DayAgendaService.instance.invalidateDate(item.dateStr);
            onChanged?.call();

            if (!context.mounted) return;

            if (outcome.didWrite) {
              ActionFeedback.success(
                context,
                message: 'ثبت شد: ${_modeFaLabel(modeStr)}',
                dateStr: item.dateStr,
                undoToken: outcome.undoToken,
              );
            } else {
              ActionFeedback.failure(context, message: outcome.errorMessage ?? 'ثبت انجام نشد');
            }
          },
        );
      },
      onSnooze: () async {
        await _guard(
          context,
          tag: 'snooze',
          failureMessage: 'تعویق انجام نشد. دوباره تلاش کن.',
          run: () async {
            final currentDeferCount = await _getCurrentDeferCount(targetRoutine.id, item.dateStr);
            final requestedMinutes = await _snoozeMinutesFromSettings();
            final configuredMax = await _configuredMaxDefer();
            final recurrenceRuleType = await _getRecurrenceRuleType(targetRoutine.id);

            final decision = SnoozePolicy.evaluate(
              itemId: targetRoutine.id,
              now: DateTime.now(),
              requestedMinutes: requestedMinutes,
              currentDeferCount: currentDeferCount,
              category: targetRoutine.category.name,
              isEssential: targetRoutine.isEssential ? 1 : 0,
              configuredMax: configuredMax,
              recurrenceRuleType: recurrenceRuleType,
            );

            if (!context.mounted) return;

            switch (decision.verdict) {
              case SnoozeVerdict.allowed:
              case SnoozeVerdict.lastCall:
                await RoutineActions.snoozeRoutine(
                  context: context,
                  routineId: targetRoutine.id,
                  dateStr: item.dateStr,
                  minutes: requestedMinutes,
                  onDone: () {
                    DayAgendaService.instance.invalidateDate(item.dateStr);
                    onChanged?.call();
                  },
                );
                if (decision.verdict == SnoozeVerdict.lastCall && context.mounted) {
                  ActionFeedback.info(context, message: 'این آخرین تعویق ممکن برای امروز است');
                }
                break;

              case SnoozeVerdict.exhausted:
                await _showExitOptionsSheet(context, routine: targetRoutine, dateStr: item.dateStr);
                break;

              case SnoozeVerdict.blockedMidnight:
                ActionFeedback.failure(context, message: 'زمان امروز به پایان رسیده است');
                break;
            }
          },
        );
      },
      onEdit: () async {
        await _guard(
          context,
          tag: 'edit',
          failureMessage: 'صفحهٔ ویرایش باز نشد.',
          run: () async {
            await UniversalPlannerSheet.show(
              context: context,
              routineToEdit: targetRoutine.toMap(),
              onSaved: () {
                DayAgendaService.instance.invalidateDate(item.dateStr);
                onChanged?.call();
              },
            );
          },
        );
      },
      onViewDetails: () async {
        await _guard(
          context,
          tag: 'viewDetails',
          failureMessage: 'جزئیات بارگذاری نشد.',
          run: () async {
            await RoutineDetailsSheet.show(
              context: context,
              routine: targetRoutine,
              targetDate: item.dateStr,
              onReverted: () {
                DayAgendaService.instance.invalidateDate(item.dateStr);
                onChanged?.call();
              },
            );
          },
        );
      },
    );
  }

  static Future<void> _handleKonkurAction(BuildContext context, AgendaItem item) async {
    try {
      final subjects = await KonkurRepository.instance.getSubjects();
      final allTopics = await KonkurRepository.instance.getTopics();
      final topics = subjects.isNotEmpty
          ? allTopics.where((t) => t.subjectId == subjects.first.id).toList()
          : <KonkurTopic>[];

      if (!context.mounted) return;

      if (subjects.isEmpty) {
        ActionFeedback.failure(context, message: 'ماژول کنکور غیرفعال است یا سرفصل‌ها بارگذاری نشده‌اند');
        return;
      }

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => KonkurStudySheet(
          subjects: subjects,
          topics: topics,
          onSaved: () {
            ActionFeedback.success(
              context,
              message: 'جلسه مطالعه کنکور ثبت شد',
              dateStr: item.dateStr,
            );
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ActionFeedback.failure(context, message: 'خطا در بارگذاری دروس کنکور');
      }
    }
  }

  static int _minutesForMode(Routine routine, String mode) {
    int dur;
    if (mode == 'FULL') {
      dur = routine.currentTargetMinutes > 0
          ? routine.currentTargetMinutes
          : (routine.targetDurationMinutes ?? 30);
    } else if (mode == 'LIGHT') {
      dur = routine.lightDurationMinutes ?? 20;
    } else if (mode == 'MINIMAL') {
      dur = routine.minimalDurationMinutes ?? 10;
    } else {
      dur = 30;
    }
    return DurationBounds.sanitize(dur);
  }

  static String _modeFaLabel(String mode) {
    switch (mode) {
      case 'LIGHT':
        return 'نسخه سبک';
      case 'MINIMAL':
        return 'نسخه حداقلی';
      case 'FULL':
      default:
        return 'نسخه کامل';
    }
  }

  static Future<int> _snoozeMinutesFromSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['snooze_minutes'],
      );
      if (rows.isNotEmpty) {
        final val = int.tryParse(rows.first['value']?.toString() ?? '');
        if (val != null && val > 0) return val;
      }
    } catch (_) {}
    return 10;
  }

  static Future<int> _getCurrentDeferCount(String routineId, String dateStr) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final selectedDateMidnight = DateTime.tryParse(dateStr) ?? DateTime.now();
      final startOfDay = DateTime(selectedDateMidnight.year, selectedDateMidnight.month, selectedDateMidnight.day).millisecondsSinceEpoch;
      final endOfDay = DateTime(selectedDateMidnight.year, selectedDateMidnight.month, selectedDateMidnight.day, 23, 59, 59).millisecondsSinceEpoch;

      final reminders = await db.query(
        'pending_reminders',
        where: 'routineId = ? AND scheduledTime >= ? AND scheduledTime <= ?',
        whereArgs: [routineId, startOfDay, endOfDay],
      );
      if (reminders.isNotEmpty) {
        return (reminders.first['deferCount'] as int?) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  static Future<void> _showExitOptionsSheet(
    BuildContext context, {
    required Routine routine,
    required String dateStr,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final colors = sheetCtx.colors;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.all(16),
            child: RitmoTheme.glassCardLight(
              blurSigma: 20,
              color: colors.card.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 40,
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'پایان سقف تعویق',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سقف تعویق این روتین برای امروز پر شده است. لطفاً وضعیت آن را مشخص کنید:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.flash_on_rounded, size: 20),
                      label: const Text(
                        'همین حالا نسخهٔ حداقلی را انجام بده',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        final outcome = await CompletionGateway.instance.submit(
                          RoutineCompletion(
                            routineId: routine.id,
                            dateStr: dateStr,
                            result: CompletionResult.minimal,
                            durationMinutes: _minutesForMode(routine, 'MINIMAL'),
                          ),
                        );
                        if (!context.mounted) return;
                        if (outcome.didWrite) {
                          ActionFeedback.success(
                            context,
                            message: 'ثبت شد: نسخه حداقلی',
                            dateStr: dateStr,
                            undoToken: outcome.undoToken,
                          );
                        } else {
                          ActionFeedback.failure(context, message: outcome.errorMessage ?? 'ثبت انجام نشد');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text(
                        'به فردا منتقل کن',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        final tomorrowStr = RitmoDate.parse(dateStr)!.addDays(1).value;
                        final outcome = await CompletionGateway.instance.submit(
                          RoutineReschedule(
                            routineId: routine.id,
                            fromDateStr: dateStr,
                            toDateStr: tomorrowStr,
                          ),
                        );
                        if (!context.mounted) return;
                        if (outcome.didWrite) {
                          ActionFeedback.success(
                            context,
                            message: 'روتین به فردا موکول شد',
                            dateStr: dateStr,
                          );
                        } else {
                          ActionFeedback.failure(context, message: outcome.errorMessage ?? 'انتقال انجام نشد');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      label: const Text(
                        'امروز نمی‌توانم انجام دهم',
                        style: TextStyle(fontFamily: 'Vazirmatn'),
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        final outcome = await CompletionGateway.instance.submit(
                          RoutineSkip(
                            routineId: routine.id,
                            dateStr: dateStr,
                            reason: 'عدم امکان انجام امروز',
                          ),
                        );
                        if (!context.mounted) return;
                        if (outcome.didWrite) {
                          ActionFeedback.success(
                            context,
                            message: 'عدم انجام ثبت شد',
                            dateStr: dateStr,
                          );
                        } else {
                          ActionFeedback.failure(context, message: outcome.errorMessage ?? 'ثبت انجام نشد');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showDomainConfirmationSheet(
    BuildContext context, {
    required AgendaItem item,
    required String title,
    required String domainLabel,
    required Future<CompletionOutcome> Function() onConfirm,
    required String successMessage,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final colors = sheetCtx.colors;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.all(16),
            child: RitmoTheme.glassCardLight(
              blurSigma: 20,
              color: colors.card.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 40,
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'دسته‌بندی: $domainLabel | تاریخ: ${item.dateStr}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'ثبت انجام',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        final outcome = await onConfirm();
                        if (!context.mounted) return;
                        if (outcome.didWrite) {
                          ActionFeedback.success(
                            context,
                            message: successMessage,
                            dateStr: item.dateStr,
                            undoToken: outcome.undoToken,
                          );
                        } else {
                          ActionFeedback.failure(
                            context,
                            message: outcome.errorMessage ?? 'ثبت انجام نشد',
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                      ),
                      child: const Text(
                        'انصراف',
                        style: TextStyle(fontFamily: 'Vazirmatn'),
                      ),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<int> _configuredMaxDefer() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['snooze_max_defer_count'],
        limit: 1,
      );
      if (rows.isNotEmpty && rows.first['value'] != null) {
        final parsed = int.tryParse(rows.first['value'].toString());
        if (parsed != null && parsed > 0) return parsed;
      }
    } catch (_) {}
    return 3;
  }

  static Future<String?> _getRecurrenceRuleType(String routineId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'routine_schedules',
        columns: ['recurrenceRule', 'scheduleType'],
        where: 'routineId = ?',
        whereArgs: [routineId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final rule = rows.first['recurrenceRule']?.toString();
        if (rule != null && rule.isNotEmpty) return rule;
        return rows.first['scheduleType']?.toString();
      }
    } catch (_) {}
    return null;
  }
}
