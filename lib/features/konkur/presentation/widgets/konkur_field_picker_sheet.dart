import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/konkur/data/konkur_curriculum.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';

class KonkurFieldPickerSheet extends StatelessWidget {
  const KonkurFieldPickerSheet({super.key});

  static Future<KonkurField?> show(BuildContext context) {
    return showModalBottomSheet<KonkurField>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const KonkurFieldPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.border),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'بارگذاری سرفصل‌های کنکور',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'رشته موردنظر را انتخاب کنید — مباحث کامل و اوزان آزمون اضافه می‌شود',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              ...KonkurField.values.map((field) => _buildFieldCard(context, field, colors)),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(
                  'انصراف',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard(BuildContext context, KonkurField field, RitmoColors colors) {
    final curriculum = KonkurCurriculum.byField[field] ?? [];
    final subjectCount = curriculum.length;
    int topicCount = 0;
    for (final s in curriculum) {
      topicCount += s.topics.length;
    }

    final (icon, colorHex) = switch (field) {
      KonkurField.riyazi  => ('📐', const Color(0xFF3B82F6)),
      KonkurField.tajrobi => ('🧬', const Color(0xFF10B981)),
      KonkurField.ensani  => ('📚', const Color(0xFFF59E0B)),
      KonkurField.honar   => ('🎨', const Color(0xFFEC4899)),
      KonkurField.zaban   => ('🗣️', const Color(0xFF8B5CF6)),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context, field),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorHex.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorHex.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.label,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$subjectCount درس · $topicCount مبحث',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorHex,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
