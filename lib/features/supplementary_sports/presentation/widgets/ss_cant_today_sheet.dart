// lib/features/supplementary_sports/presentation/widgets/ss_cant_today_sheet.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

void showSSCantTodaySheet(BuildContext context, {required ValueChanged<String> onReasonSelected}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _SSCantTodaySheet(onReasonSelected: onReasonSelected),
  );
}

class _SSCantTodaySheet extends StatelessWidget {
  const _SSCantTodaySheet({required this.onReasonSelected});
  final ValueChanged<String> onReasonSelected;

  @override
  Widget build(BuildContext context) {
    const theme = SupplementarySportsTheme.dark;

    final reasons = [
      {'code': 'NO_TIME', 'title': 'وقت نداشتم ⏳', 'subtitle': 'اشکالی نداره، فردا جبران می‌کنیم.'},
      {'code': 'NO_ENERGY', 'title': 'انرژی نداشتم 🔋', 'subtitle': 'استراحت مهم‌تره، امشب خوب بخواب.'},
      {'code': 'UNWELL', 'title': 'حالم خوب نبود 🤕', 'subtitle': 'مراقب سلامتیت باش، بهبود پیدا کن.'},
      {'code': 'FORGOT', 'title': 'یادم رفت 🧠', 'subtitle': 'یادآوریت رو تنظیم می‌کنیم.'},
      {'code': 'NO_MOOD', 'title': 'حوصله نداشتم 😴', 'subtitle': 'پیش میاد، فردا با انگیزه تازه می‌آی.'},
      {'code': 'OUTSIDE', 'title': 'بیرون بودم 🚗', 'subtitle': 'یک پیاده‌روی سبک بیرون هم حسابه.'},
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: theme.surfaceBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: theme.cardBorder)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'چرا امروز نه؟ 🤔',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'دلیلت رو ثبت کن تا الگوی استراحتت رو بهتر بفهمیم',
                style: TextStyle(fontSize: 13, color: theme.textSecondary, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ...reasons.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildOption(context, r['code']!, r['title']!, r['subtitle']!),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String code, String title, String subtitle) {
    const theme = SupplementarySportsTheme.dark;
    return GestureDetector(
      onTap: () async {
        RitmoHaptics.tap();
        try {
          final db = await DatabaseHelper.instance.database;
          await db.insert('skip_reasons', {
            'id': RitmoIdFactory.routine(),
            'itemId': 'ss_workout_today',
            'domain': 'sport',
            'dateStr': DateTime.now().toIso8601String().substring(0, 10),
            'reason': code,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
        } catch (_) {}
        if (context.mounted) Navigator.pop(context);
        onReasonSelected(code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: theme.textPrimary, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: theme.textSecondary, fontFamily: 'Vazirmatn')),
          ],
        ),
      ),
    );
  }
}
