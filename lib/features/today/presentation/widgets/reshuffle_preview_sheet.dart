import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/context_engine.dart';
import 'package:ritmo/core/domain/engines/reshuffle_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/premium/presentation/premium_upgrade_sheet.dart';
import 'package:ritmo/features/today/presentation/widgets/temporary_event_create_sheet.dart';

class ReshufflePreviewSheet extends StatefulWidget {

  const ReshufflePreviewSheet({super.key, required this.onApplied});
  final VoidCallback onApplied;

  @override
  State<ReshufflePreviewSheet> createState() => _ReshufflePreviewSheetState();
}

class _ReshufflePreviewSheetState extends State<ReshufflePreviewSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tempEvents = [];
  List<RoutineTask> _todayTasks = [];
  List<RoutineTask> _tomorrowTasks = [];
  int _maxCapacityMinutesTomorrow = 360;

  Map<String, dynamic>? _selectedEvent;
  ReshuffleResult? _reshuffleResult;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    // can() always returns true — no paywall
    _loadReshuffleData();
  }

  Future<void> _loadReshuffleData() async {
    setState(() {
      _isLoading = true;
      _reshuffleResult = null;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      // Load temporary events
      final events = await db.query(
        'temporary_events',
        where: 'date = ?',
        whereArgs: [todayStr],
      );

      // Load routines and schedules
      final routinesList = await db.query('routines', where: 'isArchived = 0');
      final schedulesList = await db.query('routine_schedules');

      // Helper to resolve RoutineTasks for a specific day
      List<RoutineTask> resolveTasksForDate(DateTime date) {
        final tasks = <RoutineTask>[];

        for (final rMap in routinesList) {
          final rId = rMap['id']! as String;
          final categoryStr = rMap['category']! as String;
          final category = Category.values.firstWhere(
            (e) => e.name.toLowerCase() == categoryStr.toLowerCase(),
            orElse: () => Category.custom,
          );

          final routine = Routine(
            id: rId,
            title: rMap['title']! as String,
            description: rMap['description'] as String?,
            category: category,
            routineType: RoutineType.values.firstWhere(
              (e) => e.name.toLowerCase() == (rMap['routineType'] as String? ?? '').toLowerCase(),
              orElse: () => RoutineType.timeBased,
            ),
            notificationLevel: NotificationLevel.values.firstWhere(
              (e) => e.name.toLowerCase() == (rMap['notificationLevel'] as String? ?? '').toLowerCase(),
              orElse: () => NotificationLevel.none,
            ),
            isEssential: rMap['isEssential'] == 1,
            energyRule: EnergyRule.values.firstWhere(
              (e) => e.name.toLowerCase() == (rMap['energyRule'] as String? ?? '').toLowerCase(),
              orElse: () => EnergyRule.none,
            ),
            priority: rMap['priority'] as double? ?? 1.0,
            targetDurationMinutes: rMap['targetDurationMinutes'] as int?,
            lightDurationMinutes: rMap['lightDurationMinutes'] as int?,
            minimalDurationMinutes: rMap['minimalDurationMinutes'] as int?,
            progressionMode: rMap['progressionMode'] as String? ?? 'NONE',
            progressionStart: rMap['progressionStart'] as int? ?? 0,
            progressionTarget: rMap['progressionTarget'] as int? ?? 0,
            progressionStep: rMap['progressionStep'] as int? ?? 0,
            progressionEveryN: rMap['progressionEveryN'] as int? ?? 1,
            progressionCurrent: rMap['progressionCurrent'] as int? ?? 0,
            progressionDoneSinceAdvance: rMap['progressionDoneSinceAdvance'] as int? ?? 0,
            itemType: rMap['itemType'] as String? ?? 'ROUTINE',
          );

          final schedule = schedulesList.firstWhere(
            (s) => s['routineId'] == rId,
            orElse: () => <String, dynamic>{},
          );

          if (schedule.isNotEmpty) {
            final daysOfWeekStr = schedule['daysOfWeek'] as String? ?? '6,7,1,2,3,4,5';
            final activeDays = daysOfWeekStr.split(',').map((d) => int.tryParse(d.trim()) ?? 1).toSet();

            if (activeDays.contains(date.weekday)) {
              final timeOfDayStr = schedule['timeOfDay'] as String? ?? '08:00';
              final parts = timeOfDayStr.split(':');
              final schedTime = date.copyWith(
                hour: int.tryParse(parts[0]) ?? 8,
                minute: int.tryParse(parts[1]) ?? 0,
                second: 0,
                millisecond: 0,
                microsecond: 0,
              );

              tasks.add(RoutineTask(
                routine: routine,
                scheduleTimeStr: timeOfDayStr,
                scheduledTime: schedTime,
              ));
            }
          }
        }
        return tasks;
      }

      final todayTasks = resolveTasksForDate(DateTime.now());
      final tomorrowTasks = resolveTasksForDate(DateTime.now().add(const Duration(days: 1)));

      // Load settings
      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      final maxCapStr = settingsMap['daily_capacity_minutes'] ?? '360';
      final maxCap = int.tryParse(maxCapStr) ?? 360;

      setState(() {
        _tempEvents = events;
        _todayTasks = todayTasks;
        _tomorrowTasks = tomorrowTasks;
        _maxCapacityMinutesTomorrow = maxCap;
        if (events.isNotEmpty) {
          _selectedEvent = events.first;
        } else {
          _selectedEvent = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading reshuffle data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _runReshuffle() {
    if (_selectedEvent == null) return;

    final parts = (_selectedEvent!['startTime'] as String).split(':');
    final startHour = int.tryParse(parts[0]) ?? 8;
    final startMin = int.tryParse(parts[1]) ?? 0;
    
    final eventStart = DateTime.now().copyWith(
      hour: startHour,
      minute: startMin,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final eventEnd = eventStart.add(Duration(minutes: _selectedEvent!['durationMinutes'] as int));

    final event = ReshuffleEvent(
      id: _selectedEvent!['id'] as String,
      title: _selectedEvent!['title'] as String,
      startTime: eventStart,
      endTime: eventEnd,
      durationMinutes: _selectedEvent!['durationMinutes'] as int,
    );

    final result = ReshuffleEngine.decideReshuffle(
      event: event,
      todayTasks: _todayTasks,
      tomorrowTasks: _tomorrowTasks,
      preferredRoutineIds: {},
      maxCapacityMinutesTomorrow: _maxCapacityMinutesTomorrow,
    );

    setState(() {
      _reshuffleResult = result;
    });

    HapticFeedback.mediumImpact();
  }

  Future<void> _applyReshuffle() async {
    if (_reshuffleResult == null || !_reshuffleResult!.success) return;

    setState(() {
      _isApplying = true;
    });

    try {
      await RitmoExecutionKernel.instance.execute(
        ConfirmReshuffleCommand(actions: _reshuffleResult!.actions),
      );

      unawaited(HapticFeedback.vibrate());
      widget.onApplied();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('برنامه‌های تداخلی با موفقیت سازماندهی و آلارم‌ها تنظیم شدند.', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error applying reshuffle: $e');
    }

    if (mounted) {
      setState(() {
        _isApplying = false;
      });
    }
  }

  void _openCreateEventSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return TemporaryEventCreateSheet(
          onSaved: _loadReshuffleData,
        );
      },
    );
  }

  String _getActionTypeName(ReshuffleActionType type) {
    switch (type) {
      case ReshuffleActionType.compress:
        return 'فشرده‌سازی ⚡';
      case ReshuffleActionType.shiftWithinZone:
        return 'جابه‌جایی زمان ⏳';
      case ReshuffleActionType.shiftToNextZone:
        return 'انتقال به زون بعد 💼';
      case ReshuffleActionType.moveToTomorrow:
        return 'انتقال به فردا 🗓️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: RitmoTheme.glassCardLight(
          borderRadius: 28,
          child: const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سازماندهی مجدد برنامه (Reshuffle)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'رفع تداخل هوشمند برنامه روتین‌ها با رویدادهای موقت.',
                style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 16),

              if (_tempEvents.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        'هیچ رویداد موقتی برای امروز ثبت نشده است.',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        ),
                        icon: const Icon(CupertinoIcons.add, size: 16),
                        label: const Text('ثبت رویداد موقت جدید', style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn')),
                        onPressed: _openCreateEventSheet,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Event selector drop down
                Text(
                  'انتخاب رویداد جهت رفع تداخل:',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: _selectedEvent,
                      dropdownColor: colors.card,
                      items: _tempEvents.map((evt) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: evt,
                          child: Text(
                            '${evt['title']} (${evt['startTime']} به مدت ${evt['durationMinutes']} دقیقه)',
                            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Vazirmatn'),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedEvent = val;
                          _reshuffleResult = null;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_reshuffleResult == null) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _runReshuffle,
                    child: const Text('شروع هوشمند سازماندهی مجدد برنامه', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                  ),
                ] else ...[
                  // Show Reshuffle Results
                  if (!_reshuffleResult!.success) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.medicalRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.medicalRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.exclamationmark_circle_fill, color: colors.medicalRed, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _reshuffleResult!.message ?? 'امکان سازماندهی مجدد برنامه به دلیل تداخل با روتین‌های حیاتی وجود ندارد.',
                              style: TextStyle(fontSize: 12, color: colors.textPrimary, height: 1.5, fontFamily: 'Vazirmatn'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.textPrimary.withValues(alpha: 0.08),
                        foregroundColor: colors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        setState(() {
                          _reshuffleResult = null;
                        });
                      },
                      child: const Text('بازگشت', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                    ),
                  ] else if (_reshuffleResult!.actions.isEmpty) ...[
                    Text(
                      'هیچ تداخلی بین رویداد و روتین‌های امروز یافت نشد! برنامه نیاز به سازماندهی ندارد. ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: colors.success, fontFamily: 'Vazirmatn'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('تایید و بستن', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                    ),
                  ] else ...[
                    // Proposed Actions List
                    Text(
                      'تغییرات پیشنهادی سیستم:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _reshuffleResult!.actions.length,
                        itemBuilder: (context, index) {
                          final action = _reshuffleResult!.actions[index];
                          var detailText = '';

                          if (action.actionType == ReshuffleActionType.compress) {
                            detailText = 'مدت زمان از ${action.originalDuration} به ${action.newDuration} دقیقه کاهش می‌یابد.';
                          } else if (action.actionType == ReshuffleActionType.shiftWithinZone ||
                              action.actionType == ReshuffleActionType.shiftToNextZone) {
                            final oldTime = action.originalTime?.toIso8601String().substring(11, 16) ?? '--:--';
                            final newTime = action.newTime?.toIso8601String().substring(11, 16) ?? '--:--';
                            detailText = 'ساعت شروع از $oldTime به $newTime تغییر می‌کند.';
                          } else if (action.actionType == ReshuffleActionType.moveToTomorrow) {
                            detailText = 'به برنامه‌های فردا منتقل می‌شود.';
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.textPrimary.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getActionTypeName(action.actionType),
                                    style: TextStyle(fontSize: 9, color: colors.primary, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        action.routineTitle,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        detailText,
                                        style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _isApplying ? null : _applyReshuffle,
                            child: _isApplying
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('تایید و اعمال سازماندهی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              setState(() {
                                _reshuffleResult = null;
                              });
                            },
                            child: const Text('انصراف / ویرایش', style: TextStyle(fontSize: 13, fontFamily: 'Vazirmatn')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
