import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_snackbar.dart';
import 'package:ritmo/features/calendar/presentation/logic/today_calendar_convergence_helper.dart';

class DayReviewSheet extends StatelessWidget {
  const DayReviewSheet({
    super.key,
    required this.dateStr,
    required this.uncompletedItems,
    required this.onReviewed,
  });

  final String dateStr;
  final List<AgendaItem> uncompletedItems;
  final VoidCallback onReviewed;

  static void show(
    BuildContext context, {
    required String dateStr,
    required List<AgendaItem> uncompletedItems,
    required VoidCallback onReviewed,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DayReviewSheet(
        dateStr: dateStr,
        uncompletedItems: uncompletedItems,
        onReviewed: onReviewed,
      ),
    );
  }

  Future<void> _completeAll(BuildContext context) async {
    RitmoHaptics.success();
    final helper = TodayCalendarConvergenceHelper();
    for (final item in uncompletedItems) {
      await helper.completeItem(item);
    }
    DayAgendaService.instance.invalidateDate(dateStr);

    if (context.mounted) {
      Navigator.of(context).pop();
      RitmoSnackbar.success(
        context,
        'تمام برنامه‌های روز انجام شدند',
      );
    }
    onReviewed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rate_review_rounded, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'مرور برنامه‌های روز',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  if (uncompletedItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _completeAll(context),
                      icon: Icon(Icons.done_all_rounded, size: 18, color: colors.primary),
                      label: Text(
                        'همه انجام شد',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: uncompletedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final item = uncompletedItems[index];
                    return _buildReviewItemTile(context, item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItemTile(BuildContext context, AgendaItem item) {
    final colors = context.colors;
    final helper = TodayCalendarConvergenceHelper();

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          if (item.timeOfDay != null) ...[
            const SizedBox(height: 2),
            Text(
              'ساعت: ${item.timeOfDay}',
              style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                label: 'انجام شد',
                icon: Icons.check_circle_outline,
                color: colors.success,
                onTap: () async {
                  await helper.completeItem(item);
                  onReviewed();
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                label: 'رد شد',
                icon: Icons.block_rounded,
                color: colors.disabled,
                onTap: () async {
                  await helper.skipItem(item);
                  onReviewed();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        RitmoHaptics.tap();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
