import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/onboarding/presentation/ritmo_orb.dart';

class StepWelcome extends StatelessWidget {

  const StepWelcome({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const RitmoOrb(size: 160),
        const SizedBox(height: 24),
        Text(
          'ریتمو',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
            shadows: [
              Shadow(
                color: const Color(0xff5B8AF5).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'سیستم‌عامل شخصی زندگی شما',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff9B89FF),
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'ریتمو فقط کارها را یادآوری نمی‌کند؛\nبلکه به شما کمک می‌کند ریتم طبیعی زندگی خود را کشف و حفظ کنید.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: colors.textSecondary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff9B89FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'شروع سفر',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
