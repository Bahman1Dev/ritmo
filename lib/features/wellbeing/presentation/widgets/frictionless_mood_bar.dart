import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_date.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:sqflite/sqflite.dart';

class FrictionlessMoodBar extends StatefulWidget {
  const FrictionlessMoodBar({
    super.key,
    required this.onLogChanged,
  });

  final VoidCallback onLogChanged;

  @override
  State<FrictionlessMoodBar> createState() => _FrictionlessMoodBarState();
}

class _FrictionlessMoodBarState extends State<FrictionlessMoodBar> {
  int? _selectedMood; // 1 (Sad), 3 (Neutral), 5 (Happy)
  String? _lastLoggedId;

  @override
  void initState() {
    super.initState();
    _loadTodayMood();
  }

  Future<void> _loadTodayMood() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final todayMs = RitmoDate.startOfDayMillis(DateTime.now());
      final rows = await db.query(
        'mood_logs',
        where: 'loggedAt >= ?',
        whereArgs: [todayMs],
        orderBy: 'loggedAt DESC',
        limit: 1,
      );
      if (rows.isNotEmpty && mounted) {
        final valence = (rows.first['valence'] as num?)?.toInt() ?? 3;
        setState(() {
          _selectedMood = valence;
          _lastLoggedId = rows.first['id'] as String?;
        });
      }
    } catch (_) {}
  }

  Future<void> _logMood(int valence, String label) async {
    RitmoHapticsPolicy.tap();
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final id = 'mood_${now.millisecondsSinceEpoch}';

    final previousMood = _selectedMood;
    final previousId = _lastLoggedId;

    setState(() {
      _selectedMood = valence;
      _lastLoggedId = id;
    });

    try {
      await db.insert(
        'mood_logs',
        {
          'id': id,
          'mood': valence >= 4 ? 'HAPPY' : (valence <= 2 ? 'SAD' : 'NEUTRAL'),
          'valence': valence,
          'source': 'QUICK_BAR',
          'loggedAt': now.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      widget.onLogChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حال شما ثبت شد ($label)'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'برگردان',
              onPressed: () async {
                try {
                  await db.delete('mood_logs', where: 'id = ?', whereArgs: [id]);
                  if (mounted) {
                    setState(() {
                      _selectedMood = previousMood;
                      _lastLoggedId = previousId;
                    });
                    widget.onLogChanged();
                  }
                } catch (_) {}
              },
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RitmoSpacing.lg,
        vertical: RitmoSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RitmoRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'الان چطوری؟',
              style: RitmoTextStyles.body(colors.textPrimary),
            ),
          ),
          _moodButton(context, 1, '😔', 'غمگین یا خسته', colors.error),
          const SizedBox(width: 8),
          _moodButton(context, 3, '😐', 'معمولی', colors.cautionAccent),
          const SizedBox(width: 8),
          _moodButton(context, 5, '🙂', 'خوب و باانرژی', colors.success),
        ],
      ),
    );
  }

  Widget _moodButton(
    BuildContext context,
    int valence,
    String emoji,
    String label,
    Color color,
  ) {
    final isSelected = _selectedMood == valence;

    return Semantics(
      button: true,
      label: 'ثبت حال: $label',
      selected: isSelected,
      child: InkWell(
        onTap: () => _logMood(valence, label),
        borderRadius: BorderRadius.circular(RitmoRadius.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(RitmoRadius.card),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}
