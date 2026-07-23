import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:sqflite/sqflite.dart';

class SleepLogSheet extends StatefulWidget {

  const SleepLogSheet({super.key, required this.onSaved, required this.target});
  final VoidCallback onSaved;
  final SleepTarget target;

  @override
  State<SleepLogSheet> createState() => _SleepLogSheetState();
}

class _SleepLogSheetState extends State<SleepLogSheet> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  SleepQuality _quality = SleepQuality.good;
  int _awakenings = 0;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;
  bool _showWorkoutWarning = false;

  @override
  void initState() {
    super.initState();
    // Default to target settings
    _bedtime = TimeOfDay(hour: widget.target.bedtimeHour, minute: widget.target.bedtimeMinute);
    _wakeTime = TimeOfDay(hour: widget.target.wakeHour, minute: widget.target.wakeMinute);
    _checkLateWorkout();
  }

  Future<void> _checkLateWorkout() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final today = DateTime.now();
      // Look up workouts logged in the last 24 hours
      final yesterdayMs = today.subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
      final rows = await db.query(
        'workout_logs',
        where: 'loggedAt >= ?',
        whereArgs: [yesterdayMs],
        orderBy: 'loggedAt DESC',
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final log = rows.first;
        final loggedAt = log['loggedAt']! as int;
        final dt = DateTime.fromMillisecondsSinceEpoch(loggedAt);
        final feeling = log['feeling'] as String?;
        if (dt.hour >= 20 || feeling == 'HARD') {
          if (mounted) {
            setState(() {
              _showWorkoutWarning = true;
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Calculate bedtimeAt and wakeAt epochs in milliseconds
  Map<String, dynamic> _calculateTimes() {
    final now = DateTime.now();
    // Assume wake time is today morning
    final wakeDateTime = DateTime(now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
    
    // If bedtime hour is greater than wake hour, it means they went to sleep yesterday
    DateTime bedtimeDateTime;
    if (_bedtime.hour > _wakeTime.hour) {
      bedtimeDateTime = DateTime(now.year, now.month, now.day - 1, _bedtime.hour, _bedtime.minute);
    } else {
      bedtimeDateTime = DateTime(now.year, now.month, now.day, _bedtime.hour, _bedtime.minute);
    }

    final durationMin = wakeDateTime.difference(bedtimeDateTime).inMinutes;

    return {
      'bedtimeAt': bedtimeDateTime.millisecondsSinceEpoch,
      'wakeAt': wakeDateTime.millisecondsSinceEpoch,
      'durationMinutes': durationMin,
    };
  }

  Future<void> _selectBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      cancelText: 'انصراف',
      confirmText: 'تایید',
      helpText: 'ساعت به خواب رفتن',
    );
    if (picked != null) {
      setState(() {
        _bedtime = picked;
      });
    }
  }

  Future<void> _selectWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      cancelText: 'انصراف',
      confirmText: 'تایید',
      helpText: 'ساعت بیدار شدن',
    );
    if (picked != null) {
      setState(() {
        _wakeTime = picked;
      });
    }
  }

  Future<void> _saveSleepLog() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toIso8601String().substring(0, 10);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final times = _calculateTimes();
      final duration = times['durationMinutes'] as int;

      // Determine derivative reason & note for dynamic energy penalty
      // badSleepKeywords = ['poor', 'late', 'bad', 'restless', 'tired', 'insomnia', 'کم', 'دیر', 'خستگی', 'بی‌خوابی', 'ضعیف']
      var reason = 'مناسب';
      if (_quality == SleepQuality.terrible || _quality == SleepQuality.poor) {
        reason = 'کیفیت ضعیف';
      } else if (duration < 360) {
        reason = 'مدت زمان کم';
      }

      // 1. Perform INSERT OR REPLACE in bedtime_diagnostics
      await db.insert(
        'bedtime_diagnostics',
        {
          'date': yesterdayStr,
          'reason': reason,
          'note': _noteController.text.isNotEmpty ? _noteController.text : null,
          'createdAt': nowMs,
          'bedtimeAt': times['bedtimeAt'],
          'wakeAt': times['wakeAt'],
          'durationMinutes': duration,
          'quality': _quality.score,
          'awakenings': _awakenings,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Map quality to default_energy_level and update settings
      // terrible/poor -> LOW, fair -> MEDIUM, good/excellent -> HIGH
      var energyLevel = 'MEDIUM';
      if (_quality == SleepQuality.terrible || _quality == SleepQuality.poor) {
        energyLevel = 'LOW';
      } else if (_quality == SleepQuality.good || _quality == SleepQuality.excellent) {
        energyLevel = 'HIGH';
      }

      await db.insert(
        'app_settings',
        {
          'key': 'default_energy_level',
          'value': energyLevel,
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Fire event to invalidate cache
      RitmoEventBus().fire(RitmoEvent(
        type: 'SleepLogged',
        timestamp: DateTime.now(),
        payload: {
          'date': yesterdayStr,
          'quality': _quality.score,
          'durationMinutes': duration,
        },
      ));

      HapticFeedback.mediumImpact();
      widget.onSaved();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خواب دیشب شما با موفقیت ثبت شد 🌿', style: TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: Color(0xff8B5CF6),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving sleep log: $e');
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final times = _calculateTimes();
    final durationMin = times['durationMinutes'] as int;
    final hours = durationMin ~/ 60;
    final minutes = durationMin % 60;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ثبت وضعیت خواب دیشب',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.cardTitle, fontFamily: 'Vazirmatn'),
                    ),
                    IconButton(
                      icon: Icon(CupertinoIcons.xmark, color: colors.iconSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ساعات خواب و بیداری دیشب را مشخص کنید.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
                const SizedBox(height: 20),

                // Bedtime & Wake time selectors
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectBedtime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.cardFill,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('زمان خوابیدن', style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                              const SizedBox(height: 6),
                              Text(
                                '${_bedtime.hour.toString().padLeft(2, '0')}:${_bedtime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.cardTitle),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _selectWakeTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.cardFill,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('زمان بیدار شدن', style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                              const SizedBox(height: 6),
                              Text(
                                '${_wakeTime.hour.toString().padLeft(2, '0')}:${_wakeTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.cardTitle),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Calculated Duration Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xff8B5CF6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xff8B5CF6).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مدت زمان محاسبه‌شده:',
                        style: TextStyle(fontSize: 13, color: colors.cardSubtitle, fontFamily: 'Vazirmatn'),
                      ),
                      Text(
                        hours > 0 ? '$hours ساعت و $minutes دقیقه' : '$minutes دقیقه',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.cardTitle, fontFamily: 'Vazirmatn'),
                      ),
                    ],
                  ),
                ),
                if (_showWorkoutWarning) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تمرین سخت یا دیرهنگام امروز ممکن است زمان به خواب رفتن شما را با تاخیر مواجه کند. پیشنهاد می‌کنیم دوش آب گرم بگیرید یا روتین آرام‌سازی انجام دهید. 💤',
                            style: TextStyle(fontSize: 11.5, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Sleep Quality Selector
                Text('کیفیت خواب چطور بود؟', style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: SleepQuality.values.map((q) {
                    final isSelected = _quality == q;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _quality = q;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xff8B5CF6).withValues(alpha: 0.15) : colors.cardFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xff8B5CF6).withValues(alpha: 0.5) : colors.glassBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(q.emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(
                                q.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? colors.cardTitle : colors.textSecondary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Wakeups counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('دفعات بیدار شدن در شب:', style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(CupertinoIcons.minus_circle, color: colors.iconSecondary),
                          onPressed: _awakenings > 0
                              ? () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _awakenings--);
                                }
                              : null,
                        ),
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: Text(
                            '$_awakenings',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.cardTitle),
                          ),
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.plus_circle, color: colors.iconSecondary),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => _awakenings++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Note
                TextField(
                  controller: _noteController,
                  style: TextStyle(color: colors.cardTitle, fontSize: 13, fontFamily: 'Vazirmatn'),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'جزئیات بیشتر یا دلیل بیداری (اختیاری)',
                    hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 12),
                    fillColor: colors.inputBackground,
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xff8B5CF6).withValues(alpha: 0.4)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : _saveSleepLog,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'تایید و ثبت وضعیت خواب',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
