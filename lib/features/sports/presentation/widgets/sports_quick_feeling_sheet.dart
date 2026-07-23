import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/models/sports_models.dart';

void showSportsQuickFeelingSheet(
  BuildContext context, {
  required String exerciseName,
  required ValueChanged<Feeling> onFeelingSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // برای اینکه بتونیم ارتفاع دقیق بدیم
    barrierColor: Colors.black.withValues(alpha: 0.2), // کم‌رنگ‌تر تا حس interruption کمتری بده
    builder: (ctx) => _QuickFeelingSheet(
      exerciseName: exerciseName,
      onFeelingSelected: onFeelingSelected,
    ),
  );
}

class _QuickFeelingSheet extends StatefulWidget {

  const _QuickFeelingSheet({
    required this.exerciseName,
    required this.onFeelingSelected,
  });
  final String exerciseName;
  final ValueChanged<Feeling> onFeelingSelected;

  @override
  State<_QuickFeelingSheet> createState() => _QuickFeelingSheetState();
}

class _QuickFeelingSheetState extends State<_QuickFeelingSheet> {
  // auto-dismiss time
  // طبق طراحی سند، اگر لمس نکنه خودش بسته میشه بدون ثبت احساس
  
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pop(context); // بستن خودکار بعد از 4 ثانیه
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xff1E293B), // رنگ متفاوت برای جلب توجه
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('«${widget.exerciseName}» چطور بود؟',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: Colors.white, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildFeelingOption(context, Feeling.easy, '😌', 'راحت', const Color(0xff34D399)),
                const SizedBox(width: 8),
                _buildFeelingOption(context, Feeling.good, '🙂', 'خوب بود', const Color(0xff60A5FA)),
                const SizedBox(width: 8),
                _buildFeelingOption(context, Feeling.hard, '😓', 'سخت', const Color(0xffF87171)),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFeelingOption(BuildContext context, Feeling feeling, String emoji, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          RitmoHaptics.tap();
          widget.onFeelingSelected(feeling);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(fontSize: 12, color: color,
                      fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
