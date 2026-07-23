import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/onboarding/presentation/ritmo_orb.dart';

class StepCelebration extends StatelessWidget {

  const StepCelebration({
    super.key,
    required this.name,
    required this.enabledSystemsCount,
    required this.onFinish,
  });
  final String name;
  final int enabledSystemsCount;
  final VoidCallback onFinish;

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayName = name.isNotEmpty ? name : 'کاربر عزیز';
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const RitmoOrb(size: 160),
        const SizedBox(height: 32),
        Text(
          'ریتم تو آماده‌ست، $displayName! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border.withValues(alpha: 0.15)),
          ),
          child: Text(
            _toPersianDigits('۱ روتین اول · $enabledSystemsCount سیستم فعال'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xff9B89FF),
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff9B89FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              'ورود به ریتمو',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
