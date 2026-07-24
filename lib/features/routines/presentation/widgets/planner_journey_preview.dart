// lib/features/routines/presentation/widgets/planner_journey_preview.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';

class PlannerJourneyPreview extends StatelessWidget {

  const PlannerJourneyPreview({
    super.key,
    required this.controller,
    this.showTitle = true,
  });
  final PlannerController controller;
  final bool showTitle;

  IconData _getCategoryIcon(dynamic category, {String? itemType}) {
    final catStr = category is Category ? category.name : (category as String? ?? '');
    switch (catStr) {
      case 'medical':
        return Icons.medication_rounded;
      case 'fitness':
        return Icons.directions_run_rounded;
      case 'religious':
        return Icons.mosque_rounded;
      case 'learning':
        return Icons.school_rounded;
      case 'custom':
        return Icons.track_changes_rounded;
      case 'free':
        return Icons.menu_book_rounded;
      case 'personal':
        if (itemType == 'REFLECT') return Icons.note_alt_rounded;
        if (itemType == 'EVENT') return Icons.event_note_rounded;
        return Icons.star_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedTimeStr = '${controller.selectedTime.hour.toString().padLeft(2, '0')}:${controller.selectedTime.minute.toString().padLeft(2, '0')}';
    
    Map<String, dynamic>? beforeItem;
    Map<String, dynamic>? afterItem;

    for (final item in controller.todayOtherRoutines) {
      final time = item['timeOfDay'] as String? ?? '08:00';
      if (time.compareTo(selectedTimeStr) < 0) {
        beforeItem = item;
      } else if (time.compareTo(selectedTimeStr) > 0 && afterItem == null) {
        afterItem = item;
      }
    }

    final selectedStartMin = controller.selectedTime.hour * 60 + controller.selectedTime.minute;
    final selectedEndMin = selectedStartMin + controller.targetDuration;
    
    OccupiedRange? conflictRange;
    for (final occ in controller.occupiedRanges) {
      if (occ.title != 'خواب' && selectedStartMin < occ.end && occ.start < selectedEndMin) {
        conflictRange = occ;
        break;
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'پیش‌نمایش مسیر فعالیت‌ها',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                if (conflictRange != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xffF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xffF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          'تداخل با ${conflictRange.title}',
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2235).withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                if (beforeItem != null)
                  _buildTimelineNode(
                    time: beforeItem['timeOfDay'] as String,
                    title: beforeItem['title'] as String,
                    icon: _getCategoryIcon(beforeItem['category'], itemType: beforeItem['itemType'] as String?),
                    color: colors.textSecondary,
                    isNew: false,
                  )
                else
                  _buildTimelineNode(
                    time: 'شروع روز',
                    title: 'ورود به صبح',
                    icon: Icons.wb_sunny_rounded,
                    color: colors.textSecondary,
                    isNew: false,
                  ),

                _buildConnectorLine(colors),

                _buildTimelineNode(
                  time: selectedTimeStr,
                  title: controller.title.isEmpty ? 'ایستگاه جدید' : controller.title,
                  icon: _getCategoryIcon(controller.selectedCategory, itemType: controller.itemType),
                  color: colors.primary,
                  isNew: true,
                ),

                _buildConnectorLine(colors),

                if (afterItem != null)
                  _buildTimelineNode(
                    time: afterItem['timeOfDay'] as String,
                    title: afterItem['title'] as String,
                    icon: _getCategoryIcon(afterItem['category'], itemType: afterItem['itemType'] as String?),
                    color: colors.textSecondary,
                    isNew: false,
                  )
                else
                  _buildTimelineNode(
                    time: 'پایان روز',
                    title: 'ورود به شب',
                    icon: Icons.nightlight_round,
                    color: colors.textSecondary,
                    isNew: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required String time,
    required String title,
    required IconData icon,
    required Color color,
    required bool isNew,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            toPersianDigits(time),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isNew ? color : color.withValues(alpha: 0.6),
            ),
          ),
        ),

        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isNew ? color.withValues(alpha: 0.16) : Colors.grey.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: isNew ? color : color.withValues(alpha: 0.3),
              width: isNew ? 2.0 : 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: isNew ? color : color.withValues(alpha: 0.65)),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12.5,
                  fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                  color: isNew ? color : color.withValues(alpha: 0.85),
                ),
              ),
              if (isNew)
                const Text(
                  'این ایستگاه به این قسمت از مسیر اضافه می‌شود.',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 9.5,
                    color: Color(0xff10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectorLine(RitmoColors colors) {
    return Container(
      margin: const EdgeInsets.only(right: 66),
      height: 24,
      width: 1.5,
      color: colors.border.withValues(alpha: 0.15),
    );
  }
}
