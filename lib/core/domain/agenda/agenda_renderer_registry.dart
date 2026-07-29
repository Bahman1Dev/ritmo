import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_action_handler.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/quran_dhikr_agenda_renderer.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
import 'package:ritmo/features/routines/presentation/widgets/routine_snooze_bottom_sheet.dart';
import 'package:ritmo/features/routines/shared/routine_actions.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_card.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_details_sheet.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';
import 'package:ritmo/features/today/presentation/active_timer_overlay.dart';
import 'package:ritmo/features/worship/presentation/widgets/prayer_agenda_card.dart';

abstract class AgendaTileRenderer {
  const AgendaTileRenderer();

  Widget build(BuildContext context, AgendaItem item, {required VoidCallback onChanged});
}

class AgendaRendererRegistry {
  static final Map<AgendaDomain, AgendaTileRenderer> _registry = {
    AgendaDomain.prayer: const PrayerAgendaRenderer(),
    AgendaDomain.routine: const RoutineAgendaRenderer(),
  };

  static void register(AgendaDomain domain, AgendaTileRenderer renderer) {
    _registry[domain] = renderer;
  }

  static Widget render(BuildContext context, AgendaItem item, {required VoidCallback onChanged}) {
    if (item.domain == AgendaDomain.mustahab) {
      final practice = item.meta['practice'] as Map<String, dynamic>? ?? {};
      final type = practice['practiceType'] as String?;
      if (type == 'QURAN' || type == 'DHIKR') {
        return const QuranDhikrAgendaRenderer().build(context, item, onChanged: onChanged);
      }
    }

    final renderer = _registry[item.domain] ?? const DefaultAgendaRenderer();
    return renderer.build(context, item, onChanged: onChanged);
  }
}

class PrayerAgendaRenderer extends AgendaTileRenderer {
  const PrayerAgendaRenderer();

  Duration get expiringSoonThreshold => const Duration(minutes: 30);

  @override
  Widget build(BuildContext context, AgendaItem item, {required VoidCallback onChanged}) {
    final practice = item.meta['practice'] as Map<String, dynamic>? ?? {};
    final isDone = item.isCompleted;
    final isSkipped = item.completion == AgendaCompletion.skipped;
    final isSnoozed = practice['lastDeferredUntil'] != null;
    final deferCount = practice['deferCount'] as int? ?? 0;
    
    // Check if the setting module_religion_enabled is true
    // Also check menstruation

    String? snoozeText;
    if (isSnoozed) {
      final latestSnooze = practice['lastDeferredUntil'] as int? ?? 0;
      if (latestSnooze > 0) {
        final time = DateTime.fromMillisecondsSinceEpoch(latestSnooze);
        final hour = time.hour.toString().padLeft(2, '0');
        final min = time.minute.toString().padLeft(2, '0');
        snoozeText = 'تعویق تا ${toPersianDigits("$hour:$min")}';
      }
    }

    // Expiration alerts
    var isExpired = false;
    var isExpiringSoon = false;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final isToday = item.dateStr == todayStr;

    if (isToday && item.windowEnd != null && !isDone && !isSkipped) {
      final now = DateTime.now();
      isExpired = now.isAfter(item.windowEnd!);
      isExpiringSoon = !isExpired && now.isAfter(item.windowEnd!.subtract(expiringSoonThreshold));
    }

    final hasReminder = (practice['reminderEnabled'] as int? ?? 0) == 1;

    return PrayerAgendaCard(
      title: item.title,
      timeStr: item.timeOfDay ?? '--:--',
      isDone: isDone,
      isSkipped: isSkipped,
      isSnoozed: isSnoozed,
      snoozeText: snoozeText,
      deferCount: deferCount,
      hasReminder: hasReminder,
      isExpired: isExpired,
      isExpiringSoon: isExpiringSoon,
      onToggle: (val) async {
        var group = 'FAJR';
        if (item.id.contains('wp_fajr') || item.sourceId == 'wp_fajr') {
          group = 'FAJR';
        } else if (item.id.contains('wp_dhuhr') || item.sourceId == 'wp_dhuhr') {
          group = 'DHUHR_ASR';
        } else if (item.id.contains('wp_maghrib') || item.sourceId == 'wp_maghrib') {
          group = 'MAGHRIB_ISHA';
        }
        await AgendaActionHandler.instance.togglePrayer(
          group: group,
          isDone: val,
          dateStr: item.dateStr,
        );
        onChanged();
      },
      onSnooze: () async {
        // Show snooze dialog
        await _showSnoozeBottomSheet(context, item, practice, onChanged);
      },
      onSkip: () async {
        // Show skip confirmation dialog
        await _showSkipConfirmationDialog(context, item, practice, onChanged);
      },
      onReminderSettings: () {
        // We can optionally delegate settings opening, but for the scope of mirroring,
        // let's show a snackbar or implement it if settings dialog is accessible.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تنظیمات یادآور نماز را می‌توانید در بخش عبادات تغییر دهید.', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
        );
      },
    );
  }

  Future<void> _showSnoozeBottomSheet(BuildContext context, AgendaItem item, Map<String, dynamic> practice, VoidCallback onChanged) async {
    final colors = context.colors;
    var selectedMinutes = 15;

    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              'تعویق نماز',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'نماز را برای چند دقیقه به تعویق می‌اندازید؟',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<int>(
                      value: selectedMinutes,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('۵ دقیقه', style: TextStyle(fontFamily: 'Vazirmatn'))),
                        DropdownMenuItem(value: 10, child: Text('۱۰ دقیقه', style: TextStyle(fontFamily: 'Vazirmatn'))),
                        DropdownMenuItem(value: 15, child: Text('۱۵ دقیقه', style: TextStyle(fontFamily: 'Vazirmatn'))),
                        DropdownMenuItem(value: 30, child: Text('۳۰ دقیقه', style: TextStyle(fontFamily: 'Vazirmatn'))),
                        DropdownMenuItem(value: 45, child: Text('۴۵ دقیقه', style: TextStyle(fontFamily: 'Vazirmatn'))),
                        DropdownMenuItem(value: 60, child: Text('۱ ساعت', style: TextStyle(fontFamily: 'Vazirmatn'))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedMinutes = val;
                          });
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('انصراف', style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD4A843),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await AgendaActionHandler.instance.snoozePrayer(
                      practiceIds: [practice['id'] as String],
                      minutes: selectedMinutes,
                      dateStr: item.dateStr,
                    );
                    if (context.mounted) {
                      onChanged();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll('Exception: ', ''),
                            style: const TextStyle(fontFamily: 'Vazirmatn'),
                          ),
                          backgroundColor: colors.medicalRed,
                        ),
                      );
                    }
                  }
                },
                child: Text('ثبت تعویق', style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSkipConfirmationDialog(BuildContext context, AgendaItem item, Map<String, dynamic> practice, VoidCallback onChanged) async {
    final colors = context.colors;

    final addToQada = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'ثبت نماز قضای ${item.title}',
              style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'آیا مایلید نماز امروز (${item.title}) را به بدهی‌های عبادی (نماز قضا) اضافه کنید؟',
              style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn', fontSize: 14.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('خیر', style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD4A843),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text('بله، اضافه کن', style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        );
      },
    );

    if (addToQada != null) {
      await AgendaActionHandler.instance.skipPrayer(
        practices: [
          {
            'id': practice['id'] as String,
            'subType': practice['subType'] as String?,
            'title': practice['title'] as String?,
            'practiceType': practice['practiceType'] as String?,
          }
        ],
        addToQada: addToQada,
        dateStr: item.dateStr,
      );

      if (addToQada && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('نماز قضای ${item.title} به بدهی‌های شما اضافه شد.', style: const TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: const Color(0xffD4A843),
          ),
        );
      }
      onChanged();
    }
  }
}

class RoutineAgendaRenderer extends AgendaTileRenderer {
  const RoutineAgendaRenderer();

  @override
  Widget build(BuildContext context, AgendaItem item, {required VoidCallback onChanged}) {
    final routineMap = item.meta['routine'] as Map<String, dynamic>? ?? {};
    final routine = Routine.fromMap(routineMap);
    final isDone = item.isCompleted;

    return RoutineCard(
      routine: routine,
      isCompleted: isDone,
      displayStreak: 0,
      customCategoriesMap: const {},
      onTap: () {
        if (isDone) {
          RoutineDetailsSheet.show(
            context: context,
            routine: routine,
            targetDate: item.dateStr,
            onReverted: onChanged,
          );
        } else {
          RoutineNiyyahSheet.show(
            context: context,
            routine: routine,
            onStartTimer: (selectedMode) async {
              final todayStr = DateTime.now().toIso8601String().substring(0, 10);
              final isToday = item.dateStr == todayStr;
              if (isToday) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActiveTimerOverlay(
                      routine: routine,
                      completionMode: selectedMode,
                      onFinished: () {
                        Navigator.pop(context);
                        onChanged();
                      },
                    ),
                  ),
                );
              } else {
                await RoutineActions.completeRoutine(
                  context: context,
                  routineId: routine.id,
                  resultType: selectedMode,
                  dateStr: item.dateStr,
                  onDone: onChanged,
                );
              }
            },
            onCompleteInstantly: (selectedMode, duration) async {
              await RoutineActions.completeRoutine(
                context: context,
                routineId: routine.id,
                resultType: selectedMode,
                dateStr: item.dateStr,
                onDone: onChanged,
              );
            },
            onSnooze: () async {
              RoutineSnoozeBottomSheet.show(
                context: context,
                routine: routine,
                onSnoozeSelected: (minutes) async {
                  await RoutineActions.snoozeRoutine(
                    context: context,
                    routineId: routine.id,
                    dateStr: item.dateStr,
                    minutes: minutes,
                    onDone: onChanged,
                  );
                },
              );
            },
            onEdit: () async {
              final rMap = {
                'id': routine.id,
                'title': routine.title,
                'description': routine.description,
                'category': routine.category.name,
                'routineType': routine.routineType.name,
                'notificationLevel': routine.notificationLevel.name,
                'isEssential': routine.isEssential ? 1 : 0,
                'energyRule': routine.energyRule.name,
                'priority': routine.priority,
                'targetDurationMinutes': routine.targetDurationMinutes,
                'lightDurationMinutes': routine.lightDurationMinutes,
                'minimalDurationMinutes': routine.minimalDurationMinutes,
              };

              await Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  barrierDismissible: true,
                  pageBuilder: (context, _, _) => UniversalPlannerSheet(
                    routineToEdit: rMap,
                    onSaved: () {
                      onChanged();
                    },
                  ),
                ),
              );
            },
            onViewDetails: () async {
              RoutineDetailsSheet.show(
                context: context,
                routine: routine,
                targetDate: item.dateStr,
                onReverted: onChanged,
              );
            },
          );
        }
      },
    );
  }
}

class DefaultAgendaRenderer extends AgendaTileRenderer {
  const DefaultAgendaRenderer();

  @override
  Widget build(BuildContext context, AgendaItem item, {required VoidCallback onChanged}) {
    final colors = context.colors;
    final isDone = item.isCompleted;
    // All module/system items are read-only mirrors in the calendar screen
    final isCompletable = item.domain == AgendaDomain.prayer ||
        item.domain == AgendaDomain.course ||
        item.domain == AgendaDomain.goalStep ||
        item.domain == AgendaDomain.worshipDebt ||
        item.domain == AgendaDomain.routine ||
        item.domain == AgendaDomain.mustahab;

    final Widget card = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.circle, size: 14, color: colors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (item.subtitle != null && item.subtitle!.isNotEmpty)
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (item.timeOfDay != null) ...[
            Text(
              item.timeOfDay!,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isCompletable) ...[
            Icon(
              isDone ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isDone ? colors.success : colors.textSecondary,
              size: 20,
            ),
          ],
        ],
      ),
    );

    if (isCompletable) {
      return GestureDetector(
        onTap: () async {
          await AgendaActionHandler.instance.toggleAgendaItem(
            item: item,
            isDone: !isDone,
          );
          onChanged();
        },
        child: card,
      );
    }

    return card;
  }
}
