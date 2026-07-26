import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/onboarding/logic/starter_pack_catalog.dart';
import 'package:ritmo/features/onboarding/presentation/ritmo_orb.dart';

class StepCelebration extends StatelessWidget {
  const StepCelebration({
    super.key,
    required this.name,
    required this.selectedRoutines,
    required this.onFinish,
    required this.isSaving,
    this.errorMessage,
  });

  final String name;
  final List<StarterRoutineTemplate> selectedRoutines;
  final VoidCallback onFinish;
  final bool isSaving;
  final String? errorMessage;

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
        const RitmoOrb(size: 130),
        const SizedBox(height: 20),
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
        const SizedBox(height: 8),

        if (selectedRoutines.isNotEmpty) ...[
          Text(
            'پیش‌نمایش برنامه‌ریزی اولیه:',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 140),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: selectedRoutines.length,
              itemBuilder: (context, idx) {
                final r = selectedRoutines[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r.titleFa,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        _toPersianDigits('${r.defaultTime} (${r.durationMinutes} د)'),
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Vazirmatn',
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Text(
            'آماده شروع تجربه ریتمو هستید.',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],

        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontFamily: 'Vazirmatn',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isSaving ? null : onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff9B89FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    errorMessage != null ? 'تلاش مجدد' : 'ورود به ریتمو',
                    style: const TextStyle(
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
