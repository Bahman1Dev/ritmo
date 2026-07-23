import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

void showSportsCantTodaySheet(BuildContext context, {required ValueChanged<String> onReasonSelected}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _CantTodaySheet(onReasonSelected: onReasonSelected),
  );
}

class _CantTodaySheet extends StatelessWidget {

  const _CantTodaySheet({required this.onReasonSelected});
  final ValueChanged<String> onReasonSelected;

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('چرا امروز نه؟ 🤔',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.white, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('دلیلت رو بگو تا برنامه‌ت رو تنظیم کنم',
                style: TextStyle(fontSize: 13, color: Colors.white38, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            
            _buildOption(context, 'TIME', 'وقت ندارم ⏳', 'شاید یه تمرین ۵ دقیقه‌ای بتونیم جور کنیم.'),
            const SizedBox(height: 12),
            _buildOption(context, 'TIRED', 'خیلی خسته‌ام 😓', 'استراحت مهم‌تره، امروز رو استراحت می‌کنیم.'),
            const SizedBox(height: 12),
            _buildOption(context, 'PAIN', 'درد دارم 🤕', 'مراقب خودت باش! حرکات رو سبک می‌کنیم یا استراحت.'),
            const SizedBox(height: 12),
            _buildOption(context, 'OTHER', 'دلیل دیگه...', 'مشکلی نیست، فقط بدون که جا زدن نداریم!'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String code, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        RitmoHaptics.tap();
        Navigator.pop(context);
        onReasonSelected(code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.white, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'Vazirmatn')),
          ],
        ),
      ),
    );
  }
}
