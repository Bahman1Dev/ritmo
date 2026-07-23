import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/logic/workout_suggester.dart';
import 'package:ritmo/features/sports/models/workout_split_models.dart';
import 'package:ritmo/features/sports/presentation/plan_day_detail_screen.dart';

/// ویرایشگر برنامه هفتگی — Split Editor
class SportsSplitEditor extends StatefulWidget {

  const SportsSplitEditor({
    super.key,
    required this.split,
    required this.onChanged,
  });
  final Map<int, SplitDay> split;
  final VoidCallback onChanged;

  @override
  State<SportsSplitEditor> createState() => _SportsSplitEditorState();
}

class _SportsSplitEditorState extends State<SportsSplitEditor> {
  /// گروه‌های قابل انتخاب (بدون rest — rest با تاگل جداگانه)
  static const _selectable = [
    MuscleGroup.chest, MuscleGroup.back, MuscleGroup.shoulders,
    MuscleGroup.biceps, MuscleGroup.triceps, MuscleGroup.legs,
    MuscleGroup.abs, MuscleGroup.fullBody, MuscleGroup.cardio,
  ];

  // نام فارسی روزهای هفته بر اساس DateTime.weekday (1=دوشنبه...7=یکشنبه)
  static const _dayNames = {
    1: 'دوشنبه', 2: 'سه‌شنبه', 3: 'چهارشنبه', 4: 'پنج‌شنبه',
    5: 'جمعه', 6: 'شنبه', 7: 'یکشنبه',
  };

  void _editDay(int weekday) {
    RitmoHaptics.tap();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanDayDetailScreen(
          weekday: weekday,
          dayPlan: widget.split[weekday] ?? SplitDay(weekday: weekday, groups: []),
        ),
      ),
    ).then((changed) {
      if (changed == true) {
        widget.onChanged();
      }
    });
  }

  void _openGroupsSheet(int weekday) {
    RitmoHaptics.tap();
    final current = widget.split[weekday];
    final selectedGroups = List<MuscleGroup>.from(current?.groups ?? []);
    var isRest = current?.isRest ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: const BoxDecoration(
              color: Color(0xff0d1a15),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('${_dayNames[weekday]} — چه گروهی؟',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        color: Colors.white, fontFamily: 'Vazirmatn'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),

                // تاگل روز استراحت
                GestureDetector(
                  onTap: () {
                    RitmoHaptics.tap();
                    setSheet(() {
                      isRest = !isRest;
                      if (isRest) selectedGroups.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isRest
                          ? const Color(0xff64748B).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isRest
                            ? const Color(0xff94A3B8)
                            : Colors.white.withValues(alpha: 0.08),
                        width: isRest ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      const Text('😴', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      const Text('روز استراحت',
                          style: TextStyle(fontSize: 13, color: Colors.white70,
                              fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (isRest)
                        const Icon(Icons.check_circle, color: Color(0xff94A3B8), size: 18),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                if (!isRest) ...[
                  const Text('گروه‌های عضلانی (چندتایی):',
                      style: TextStyle(fontSize: 12, color: Colors.white38,
                          fontFamily: 'Vazirmatn')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _selectable.map((g) {
                      final sel = selectedGroups.contains(g);
                      return GestureDetector(
                        onTap: () {
                          RitmoHaptics.tap();
                          setSheet(() {
                            if (sel) {
                              selectedGroups.remove(g);
                            } else {
                              selectedGroups.add(g);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? g.color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? g.color : Colors.white.withValues(alpha: 0.08),
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(g.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(g.label,
                                style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn',
                                    color: sel ? g.color : Colors.white60,
                                    fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton(
                  onPressed: () async {
                    RitmoHaptics.confirm();
                    final db = await DatabaseHelper.instance.database;
                    final day = SplitDay(
                      weekday: weekday,
                      groups: isRest ? [] : selectedGroups,
                      isRest: isRest,
                    );
                    await WorkoutSuggester.saveSplitDay(db, day);
                    if (ctx.mounted) Navigator.pop(ctx);
                    widget.onChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00F5A0),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('ذخیره',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('📅 برنامه هفتگی',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                  color: Colors.white, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 4),
          const Text('💡 برای تغییر عضلات، روی روز لمس طولانی (Long Press) کن.\nبرای جزئیات حرکات، یکبار ضربه بزن.',
              style: TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 16),
          ...List.generate(7, (i) {
            final wd = i + 1; // 1..7
            final day = widget.split[wd];
            final isRest = day?.isRest ?? false;
            final isToday = DateTime.now().weekday == wd;
            final groups = day?.groups ?? [];

            return GestureDetector(
              onTap: () => _editDay(wd),
              onLongPress: () {
                RitmoHaptics.tap();
                _openGroupsSheet(wd);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xff00F5A0).withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isToday
                        ? const Color(0xff00F5A0).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.06),
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  // نام روز
                  SizedBox(
                    width: 64,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xff00F5A0).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('امروز',
                              style: TextStyle(fontSize: 9, color: Color(0xff00F5A0),
                                  fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                        ),
                      Text(_dayNames[wd]!,
                          style: TextStyle(
                              fontSize: 12.5, fontFamily: 'Vazirmatn',
                              color: isToday ? const Color(0xff00F5A0) : Colors.white70,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                    ]),
                  ),

                  const SizedBox(width: 12),

                  // محتوا
                  Expanded(
                    child: isRest
                        ? const Text('😴 استراحت',
                            style: TextStyle(fontSize: 12.5, color: Color(0xff94A3B8),
                                fontFamily: 'Vazirmatn'))
                        : groups.isEmpty
                            ? const Text('تنظیم نشده',
                                style: TextStyle(fontSize: 12, color: Colors.white24,
                                    fontFamily: 'Vazirmatn'))
                            : Wrap(
                                spacing: 5, runSpacing: 4,
                                children: groups.map((g) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: g.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('${g.emoji} ${g.label}',
                                      style: TextStyle(fontSize: 11, color: g.color,
                                          fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                                )).toList(),
                              ),
                  ),

                  const Icon(Icons.chevron_left_rounded, color: Colors.white24, size: 18),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}
