// lib/features/routines/presentation/widgets/planner_summary_card.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_formatters.dart' hide toPersianDigits;
import 'package:ritmo/features/health/presentation/widgets/medication_form_sheet.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';

class PlannerSummaryCard extends StatelessWidget {

  const PlannerSummaryCard({super.key, required this.controller});
  final PlannerController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.selectedCategory == Category.medical && controller.tempMedicationData != null) {
      return MedicationPreviewCard(
        data: controller.tempMedicationData!,
        onEdit: () {
          if (controller.openMedicalSheet != null) {
            controller.openMedicalSheet!(controller.tempMedicationData);
          }
        },
      );
    }

    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateLabel = formatShamsiDate(controller.selectedDate.toIso8601String().substring(0, 10));
    final timeLabel = '${controller.selectedTime.hour.toString().padLeft(2, '0')}:${controller.selectedTime.minute.toString().padLeft(2, '0')}';

    // Dynamic category labels driven by controller
    final (String catEmoji, String catLabel, String fallbackTitle) = switch (controller.selectedCategory) {
      Category.medical   => ('💊', 'دارو',              'ثبت دارو'),
      Category.fitness   => ('🏃', 'ورزش',              'ورزش و تندرستی'),
      Category.religious => ('🕌', 'عبادات',            'تمرین عبادی'),
      Category.learning  => ('📚', 'آموزش',             'دوره آموزشی'),
      Category.custom    => ('🎯', 'اهداف',             'هدف جدید'),
      Category.personal  => ('✨', 'شخصی',              'برنامه شخصی'),
      _                  => ('📌', 'برنامه',            'برنامه جدید'),
    };

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$catEmoji $catLabel',
                    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => controller.updatePage(0),
                  child: Icon(Icons.edit_rounded, size: 18, color: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              controller.title.isEmpty ? fallbackTitle : controller.title,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            if (controller.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                controller.description,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11.5,
                  color: colors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
            const Divider(height: 24),
            
            _buildDetailRow(Icons.calendar_today_rounded, 'تاریخ انجام', dateLabel, colors),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.access_time_rounded, 'ساعت شروع', toPersianDigits(timeLabel), colors),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.hourglass_empty_rounded, 'مدت زمان', '${toPersianDigits(controller.targetDuration.toString())} دقیقه', colors),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.repeat_rounded, 'تکرار', 'هر روز', colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, RitmoColors colors) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textSecondary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            color: colors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
