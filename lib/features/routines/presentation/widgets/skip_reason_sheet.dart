import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/services/motivation_diagnosis_service.dart';

class SkipReasonSheet extends StatelessWidget {
  const SkipReasonSheet({
    super.key,
    required this.routineId,
    required this.completionId,
    required this.dateStr,
  });

  final String routineId;
  final String completionId;
  final String dateStr;

  static Future<void> show(
    BuildContext context, {
    required String routineId,
    required String completionId,
    required String dateStr,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SkipReasonSheet(
        routineId: routineId,
        completionId: completionId,
        dateStr: dateStr,
      ),
    );
  }

  Future<void> _selectReason(BuildContext context, SkipReasonType reason) async {
    await MotivationDiagnosisService.instance.recordSkipReason(
      completionId: completionId,
      routineId: routineId,
      reason: reason,
      dateStr: dateStr,
    );

    if (!context.mounted) return;
    Navigator.pop(context);

    final action = MotivationDiagnosisService.instance.getActionForReason(reason);
    final title = action['title'] as String?;
    final desc = action['description'] as String?;

    if (title != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $desc', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final options = [
      {'label': 'خسته بودم', 'reason': SkipReasonType.tired, 'icon': Icons.battery_charging_full_rounded},
      {'label': 'نمی‌دانستم از کجا شروع کنم', 'reason': SkipReasonType.noStartPoint, 'icon': Icons.help_outline_rounded},
      {'label': 'خیلی بزرگ بود', 'reason': SkipReasonType.tooBig, 'icon': Icons.fitness_center_rounded},
      {'label': 'حوصله نداشتم', 'reason': SkipReasonType.notInMood, 'icon': Icons.sentiment_dissatisfied_rounded},
      {'label': 'یادم رفت', 'reason': SkipReasonType.forgot, 'icon': Icons.notifications_paused_rounded},
      {'label': 'بیرونی بود (مهمان، سفر، کار)', 'reason': SkipReasonType.external, 'icon': Icons.flight_takeoff_rounded},
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('علت انجام نشدن؟', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('فعلاً نه', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final reason = opt['reason'] as SkipReasonType;
            final label = opt['label'] as String;
            final icon = opt['icon'] as IconData;

            return ListTile(
              leading: Icon(icon, color: colors.primary),
              title: Text(label, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textPrimary)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () => _selectReason(context, reason),
            );
          }),
        ],
      ),
    );
  }
}
