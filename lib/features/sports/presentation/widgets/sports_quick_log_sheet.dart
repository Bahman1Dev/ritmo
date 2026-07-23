import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/logic/workout_suggester.dart';
import 'package:ritmo/features/sports/models/workout_split_models.dart';
import 'package:sqflite/sqflite.dart';

/// شیت ثبت تمرین — با پشتیبانی از پیش‌پر شدن از کارت امروز
void showSportsQuickLogSheet(
  BuildContext context, {
  WorkoutTier? presetTier,
  List<MuscleGroup>? presetGroups,
  VoidCallback? onLogged,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _QuickLogSheet(
      presetTier: presetTier,
      presetGroups: presetGroups,
      onLogged: onLogged,
    ),
  );
}

class _QuickLogSheet extends StatefulWidget {

  const _QuickLogSheet({this.presetTier, this.presetGroups, this.onLogged});
  final WorkoutTier? presetTier;
  final List<MuscleGroup>? presetGroups;
  final VoidCallback? onLogged;

  @override
  State<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<_QuickLogSheet> {
  late WorkoutTier _tier;
  late SportsLocation _location;
  String _feeling = 'GOOD';
  int _durationMinutes = 45;
  bool _saving = false;

  static const _feelings = [
    ('GREAT',   '🔥 عالی'),
    ('GOOD',    '👍 خوب'),
    ('TIRED',   '😓 خسته'),
    ('HARD',    '💪 سخت بود'),
  ];

  @override
  void initState() {
    super.initState();
    _tier     = widget.presetTier ?? WorkoutTier.full;
    _location = SportsLocation.home;
    _durationMinutes = _tier.defaultMinutes;
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final loc = await WorkoutSuggester.readLocation(db);
      if (mounted) setState(() => _location = loc);
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    RitmoHaptics.confirm();
    try {
      final db  = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final groups = widget.presetGroups ?? [];
      await db.insert('workout_logs', {
        'id': 'wl_${now.millisecondsSinceEpoch}',
        'type': groups.isNotEmpty ? groups.first.code : 'STRENGTH',
        'durationMinutes': _durationMinutes,
        'intensity': _tier == WorkoutTier.full ? 'HIGH' : _tier == WorkoutTier.light ? 'MEDIUM' : 'LOW',
        'note': '',
        'loggedAt': now.millisecondsSinceEpoch,
        'tier': _tier.code,
        'muscleGroups': groups.map((g) => g.code).join(','),
        'feeling': _feeling,
        'location': _location.code,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      widget.onLogged?.call();
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Log save error: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xff00F5A0);
    final groups = widget.presetGroups ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
        decoration: const BoxDecoration(
          color: Color(0xff0d1a15),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('ثبت تمرین ⚡',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                      color: Colors.white, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              if (groups.isNotEmpty)
                Text(
                  groups.map((g) => '${g.emoji} ${g.label}').join('  '),
                  style: const TextStyle(fontSize: 13, color: Colors.white38, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),

              // نسخه تمرین
              const Text('نسخه تمرین:',
                  style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 8),
              Row(children: WorkoutTier.values.map((t) {
                final sel = _tier == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      RitmoHaptics.tap();
                      setState(() {
                        _tier = t;
                        _durationMinutes = t.defaultMinutes;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? t.color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? t.color : Colors.white.withValues(alpha: 0.07),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Text(t.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, fontFamily: 'Vazirmatn',
                                color: sel ? t.color : Colors.white38,
                                fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                        Text('${t.defaultMinutes} دق',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: sel ? t.color.withValues(alpha: 0.7) : Colors.white24,
                                fontFamily: 'Vazirmatn')),
                      ]),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 20),

              // محل تمرین
              const Text('محل تمرین:',
                  style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 8),
              Row(children: SportsLocation.values.map((loc) {
                final sel = _location == loc;
                return Expanded(
                  child: GestureDetector(
                    onTap: () { RitmoHaptics.tap(); setState(() => _location = loc); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? accent.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? accent : Colors.white.withValues(alpha: 0.07),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Text('${loc.emoji} ${loc.label}',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, fontFamily: 'Vazirmatn',
                              color: sel ? accent : Colors.white38,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 20),

              // حس بعد از تمرین
              const Text('حس بعد از تمرین:',
                  style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _feelings.map((f) {
                  final sel = _feeling == f.$1;
                  return GestureDetector(
                    onTap: () { RitmoHaptics.tap(); setState(() => _feeling = f.$1); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? accent.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? accent : Colors.white.withValues(alpha: 0.07),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Text(f.$2,
                          style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn',
                              color: sel ? accent : Colors.white38,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('ثبت تمرین ✓',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15,
                            fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
