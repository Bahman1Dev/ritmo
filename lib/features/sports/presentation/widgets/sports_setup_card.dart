import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/logic/workout_suggester.dart';
import 'package:ritmo/features/sports/models/workout_split_models.dart';

/// کارت راه‌اندازی اولیه — انتخاب محل + روزهای هفته + هدف
class SportsSetupCard extends StatefulWidget {
  const SportsSetupCard({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<SportsSetupCard> createState() => _SportsSetupCardState();
}

class _SportsSetupCardState extends State<SportsSetupCard> {
  SportsLocation _location = SportsLocation.home;
  int _daysPerWeek = 4;
  String _goalFocus = 'GENERAL';
  bool _saving = false;

  static const _goals = [
    ('GENERAL',      '💪 عمومی'),
    ('WEIGHT_LOSS',  '🔥 کاهش وزن'),
    ('MUSCLE',       '🏋️ عضله‌سازی'),
    ('ENDURANCE',    '🏃 استقامت'),
  ];

  Future<void> _save() async {
    setState(() => _saving = true);
    RitmoHaptics.confirm();
    try {
      final db = await DatabaseHelper.instance.database;
      await WorkoutSuggester.saveSetup(
        db,
        location: _location,
        daysPerWeek: _daysPerWeek,
        goalFocus: _goalFocus,
      );
      widget.onDone();
    } catch (e) {
      debugPrint('Setup save error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xff00F5A0);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('⚙️ تنظیم برنامه ورزشی',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: Colors.white, fontFamily: 'Vazirmatn'),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text('یک‌بار تنظیم کن — ریتمو بقیه رو هوشمند می‌کنه',
              style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn'),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),

          // محل تمرین
          const Text('کجا تمرین می‌کنی؟',
              style: TextStyle(fontSize: 13, color: Colors.white60, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 12),
          Row(children: SportsLocation.values.map((loc) {
            final sel = _location == loc;
            return Expanded(
              child: GestureDetector(
                onTap: () { RitmoHaptics.tap(); setState(() => _location = loc); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: sel ? accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: sel ? accent : Colors.white.withValues(alpha: 0.08),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(children: [
                    Text(loc.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(loc.label,
                        style: TextStyle(
                            fontSize: 13, fontFamily: 'Vazirmatn',
                            color: sel ? accent : Colors.white60,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                  ]),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 24),

          // تعداد روز
          const Text('چند روز در هفته تمرین می‌کنی؟',
              style: TextStyle(fontSize: 13, color: Colors.white60, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 12),
          Row(children: [3, 4, 5, 6].map((d) {
            final sel = _daysPerWeek == d;
            return Expanded(
              child: GestureDetector(
                onTap: () { RitmoHaptics.tap(); setState(() => _daysPerWeek = d); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? accent : Colors.white.withValues(alpha: 0.08),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text('$d روز',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, fontFamily: 'Vazirmatn',
                          color: sel ? accent : Colors.white60,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 24),

          // هدف ورزشی
          const Text('هدف اصلی تمرین؟',
              style: TextStyle(fontSize: 13, color: Colors.white60, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _goals.map((g) {
              final sel = _goalFocus == g.$1;
              return GestureDetector(
                onTap: () { RitmoHaptics.tap(); setState(() => _goalFocus = g.$1); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? accent : Colors.white.withValues(alpha: 0.08),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(g.$2,
                      style: TextStyle(
                          fontSize: 12.5, fontFamily: 'Vazirmatn',
                          color: sel ? accent : Colors.white60,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text('شروع و ساختن برنامه هفتگی ⚡',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
