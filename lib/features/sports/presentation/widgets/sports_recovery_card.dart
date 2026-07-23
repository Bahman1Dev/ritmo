import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:sqflite/sqflite.dart';

/// کارت خوداظهاری ریکاوری روزانه
/// بعد از ثبت قفل می‌شه و نمی‌شه دوباره ثبت کرد (مگر با دکمه ویرایش)
class SportsRecoveryCard extends StatefulWidget {

  const SportsRecoveryCard({
    super.key,
    required this.alreadyLogged,
    required this.initialSoreness,
    required this.initialFatigue,
    required this.initialHydration,
    required this.onSaved,
  });
  final bool alreadyLogged;
  final int initialSoreness;
  final int initialFatigue;
  final int initialHydration;
  final VoidCallback onSaved;

  @override
  State<SportsRecoveryCard> createState() => _SportsRecoveryCardState();
}

class _SportsRecoveryCardState extends State<SportsRecoveryCard> {
  late double _soreness;
  late double _fatigue;
  late double _hydration;
  bool _saving = false;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _soreness  = widget.initialSoreness.toDouble();
    _fatigue   = widget.initialFatigue.toDouble();
    _hydration = widget.initialHydration.toDouble();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    RitmoHaptics.confirm();
    try {
      final db  = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await db.insert(
        'workout_recovery_logs',
        {
          'id': 'recovery_${now.millisecondsSinceEpoch}',
          'date': dateKey,
          'soreness': _soreness.toInt(),
          'fatigue': _fatigue.toInt(),
          'hydration': _hydration.toInt(),
          'loggedAt': now.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      widget.onSaved();
      if (mounted) setState(() => _editMode = false);
    } catch (e) {
      debugPrint('Recovery save error: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xff00F5A0);
    final isLocked = widget.alreadyLogged && !_editMode;

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
          Row(children: [
            const Text('🔋 خوداظهاری ریکاوری',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                    color: Colors.white, fontFamily: 'Vazirmatn')),
            const Spacer(),
            if (widget.alreadyLogged && !_editMode)
              GestureDetector(
                onTap: () { RitmoHaptics.tap(); setState(() => _editMode = true); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('ویرایش',
                      style: TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'Vazirmatn')),
                ),
              ),
            if (widget.alreadyLogged && !_editMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('✓ ثبت شد',
                    style: TextStyle(fontSize: 11, color: accent,
                        fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          const Text('امروز بدنت چطوره؟',
              style: TextStyle(fontSize: 11.5, color: Colors.white38, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 16),

          _buildSlider(
            emoji: '😓',
            title: 'خستگی بدنی',
            value: _fatigue,
            labels: {0: 'شاداب', 1: 'معمولی', 2: 'خسته', 3: 'فرسوده'},
            onChanged: isLocked ? null : (v) => setState(() => _fatigue = v),
          ),
          const SizedBox(height: 14),
          _buildSlider(
            emoji: '💢',
            title: 'کوفتگی عضلانی',
            value: _soreness,
            labels: {0: 'بدون درد', 1: 'خفیف', 2: 'متوسط', 3: 'شدید'},
            onChanged: isLocked ? null : (v) => setState(() => _soreness = v),
          ),
          const SizedBox(height: 14),
          _buildSlider(
            emoji: '💧',
            title: 'آب بدن',
            value: _hydration,
            labels: {0: 'تشنه', 1: 'کم', 2: 'کافی', 3: 'عالی'},
            onChanged: isLocked ? null : (v) => setState(() => _hydration = v),
          ),

          // نکته پیشنهادی (اجباری نیست)
          if (!isLocked && (_soreness + _fatigue) >= 4) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xffFBBF24).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffFBBF24).withValues(alpha: 0.2)),
              ),
              child: const Text(
                '💡 با توجه به وضعیتت، امروز بهتره سبک‌تر تمرین کنی — این یه پیشنهاده نه اجبار',
                style: TextStyle(fontSize: 11.5, color: Color(0xffFBBF24), fontFamily: 'Vazirmatn'),
              ),
            ),
          ],

          if (!isLocked) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('ثبت وضعیت ریکاوری',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13,
                          fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String emoji,
    required String title,
    required double value,
    required Map<int, String> labels,
    required ValueChanged<double>? onChanged,
  }) {
    const accent = Color(0xff00F5A0);
    final locked = onChanged == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60, fontFamily: 'Vazirmatn')),
          const Spacer(),
          Text(labels[value.toInt()] ?? '',
              style: TextStyle(fontSize: 12, color: locked ? Colors.white38 : accent,
                  fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: locked ? Colors.white24 : accent,
            inactiveTrackColor: Colors.white12,
            thumbColor: locked ? Colors.white24 : accent,
            overlayColor: accent.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value, max: 3, divisions: 3,
            onChanged: onChanged == null ? null : (v) {
              if (v.toInt() != value.toInt()) RitmoHaptics.tap();
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}
