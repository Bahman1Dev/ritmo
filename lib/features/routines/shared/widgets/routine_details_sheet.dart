import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/routines/shared/routine_category_helper.dart';
import 'package:shamsi_date/shamsi_date.dart';

class RoutineDetailsSheet extends StatelessWidget {

  const RoutineDetailsSheet({
    super.key,
    required this.routine,
    required this.parentContext,
    this.targetDate,
    this.onReverted,
  });
  final Routine routine;
  final String? targetDate;
  final VoidCallback? onReverted;
  final BuildContext parentContext;

  static void show({
    required BuildContext context,
    required Routine routine,
    String? targetDate,
    VoidCallback? onReverted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => RoutineDetailsSheet(
        routine: routine,
        parentContext: context,
        targetDate: targetDate,
        onReverted: onReverted,
      ),
    );
  }

  Future<void> _confirmAndUndo(BuildContext context, RitmoColors colors) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final isToday = targetDate == todayStr;
    final dateLabel = isToday ? 'امروز' : 'تاریخ $targetDate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: colors.card,
          title: Text(
            'لغو ثبت انجام',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          content: Text(
            'آیا از لغو ثبت انجام این روتین برای $dateLabel اطمینان دارید؟',
            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('خیر', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text('بله، لغو شود', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.medicalRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed ?? false) {
      await AlarmSchedulerService.undoCompletion(routine.id, targetDate!);
      RitmoEvents.notifyRoutineChanged();
      if (parentContext.mounted) {
        RitmoToast.show(
          parentContext,
          'ثبت انجام روتین با موفقیت لغو شد.',
          iconColor: const Color(0xff10B981),
        );
      }
      onReverted?.call();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadCompletions() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      'routine_completions',
      where: 'routineId = ?',
      whereArgs: [routine.id],
      orderBy: 'completionTime DESC',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadCompletions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.all(16),
            height: 200,
            child: RitmoTheme.glassCardLight(
              blurSigma: 20,
              color: colors.card.withValues(alpha: isDarkMode ? 0.85 : 0.9),
              child: const Center(child: CupertinoActivityIndicator()),
            ),
          );
        }

        final completions = snapshot.data ?? [];
        final totalCompletions = completions.length;
        final currentStreak = RoutineCategoryHelper.calculateStreak(completions);
        final hasCompletionOnTargetDate = targetDate != null && completions.any((c) => c['completionDate'] == targetDate);

        final textColor = colors.textPrimary;
        final subtitleColor = colors.textSecondary;

        return Container(
          margin: const EdgeInsets.all(16),
          child: RitmoTheme.glassCardLight(
            blurSigma: 20,
            color: colors.card.withValues(alpha: isDarkMode ? 0.85 : 0.9),
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
                    'جزئیات روتین: ${routine.title}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('$totalCompletions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Vazirmatn')),
                          Text('کل انجام‌ها', style: TextStyle(fontSize: 12, color: subtitleColor, fontFamily: 'Vazirmatn')),
                        ],
                      ),
                      Column(
                        children: [
                          Text('🔥 $currentStreak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.warning, fontFamily: 'Vazirmatn')),
                          Text('تداوم فعلی', style: TextStyle(fontSize: 12, color: subtitleColor, fontFamily: 'Vazirmatn')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (completions.isEmpty)
                    const Center(child: Text('تاکنون هیچ انجام شدنی ثبت نشده است.', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.grey)))
                  else ...[
                    const Text('آخرین انجام‌ها:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: completions.length > 3 ? 3 : completions.length,
                        itemBuilder: (context, index) {
                          final c = completions[index];
                          final date = c['completionDate'] as String;
                          final time = DateTime.fromMillisecondsSinceEpoch(c['completionTime'] as int);
                          final timeStr = PersianDigits.convert('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                          final type = c['resultType'] as String == 'LIGHT' ? 'نسخه سبک' : 'نسخه کامل';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatJalaliDateWithWeekday(date), style: TextStyle(fontSize: 12, color: textColor, fontFamily: 'Vazirmatn')),
                                Text('$timeStr ($type)', style: TextStyle(fontSize: 12, color: subtitleColor, fontFamily: 'Vazirmatn')),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (hasCompletionOnTargetDate) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _confirmAndUndo(context, colors),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.medicalRed,
                        side: BorderSide(color: colors.medicalRed, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(CupertinoIcons.clear, size: 16),
                      label: const Text(
                        'لغو ثبت انجام این روتین',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('بستن', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDayOfWeekName(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'شنبه';
      case DateTime.sunday:
        return 'یکشنبه';
      case DateTime.monday:
        return 'دوشنبه';
      case DateTime.tuesday:
        return 'سه‌شنبه';
      case DateTime.wednesday:
        return 'چهارشنبه';
      case DateTime.thursday:
        return 'پنج‌شنبه';
      case DateTime.friday:
        return 'جمعه';
      default:
        return '';
    }
  }

  String _formatJalaliDateWithWeekday(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final jal = Jalali.fromDateTime(dt);
      final weekdayName = _getDayOfWeekName(dt.weekday);
      
      final yr = PersianDigits.convert(jal.year.toString());
      final mo = PersianDigits.convert(jal.month.toString().padLeft(2, '0'));
      final dy = PersianDigits.convert(jal.day.toString().padLeft(2, '0'));
      
      return '$weekdayName $yr/$mo/$dy';
    } catch (_) {
      return dateStr;
    }
  }
}
