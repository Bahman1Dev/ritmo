import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/agenda/occurrence_override_repository.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_snackbar.dart';

class PostponeRail extends StatelessWidget {
  const PostponeRail({
    super.key,
    required this.item,
    required this.onPostponed,
  });

  final AgendaItem item;
  final VoidCallback onPostponed;

  static String _formatDate(DateTime dt) => dt.toIso8601String().substring(0, 10);

  Future<void> _postponeTo(BuildContext context, int addDays, String label) async {
    RitmoHaptics.success();
    final sourceDate = DateTime.parse(item.dateStr);
    final targetDate = sourceDate.add(Duration(days: addDays));
    final targetDateStr = _formatDate(targetDate);
    final nowIso = DateTime.now().toIso8601String();

    final repo = const SqliteOccurrenceOverrideRepository();

    // 1. Skip on source date
    await repo.upsert(OccurrenceOverride(
      sourceType: item.domain.name,
      sourceId: item.sourceId,
      dateStr: item.dateStr,
      status: 'SKIPPED_ONCE',
      createdAt: nowIso,
      updatedAt: nowIso,
    ));

    // 2. Move to target date
    await repo.upsert(OccurrenceOverride(
      sourceType: item.domain.name,
      sourceId: item.sourceId,
      dateStr: targetDateStr,
      timeOfDay: item.timeOfDay,
      durationMinutes: item.durationMinutes,
      status: 'MOVED',
      createdAt: nowIso,
      updatedAt: nowIso,
    ));

    DayAgendaService.instance.invalidateDate(item.dateStr);
    DayAgendaService.instance.invalidateDate(targetDateStr);

    if (context.mounted) {
      RitmoSnackbar.success(
        context,
        'رویداد به $label موکول شد',
      );
    }

    onPostponed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Positioned(
        left: 0,
        top: 80,
        bottom: 80,
        width: 56.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colors.elevated.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16.0)),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTargetZone(
                context,
                label: 'فردا',
                days: 1,
                icon: Icons.next_plan_rounded,
                color: colors.primary,
              ),
              _buildTargetZone(
                context,
                label: 'پس‌فردا',
                days: 2,
                icon: Icons.update_rounded,
                color: colors.accent,
              ),
              _buildTargetZone(
                context,
                label: 'هفته بعد',
                days: 7,
                icon: Icons.event_repeat_rounded,
                color: colors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetZone(
    BuildContext context, {
    required String label,
    required int days,
    required IconData icon,
    required Color color,
  }) {
    return DragTarget<AgendaItem>(
      onAcceptWithDetails: (_) => _postponeTo(context, days, label),
      builder: (ctx, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 72,
          decoration: BoxDecoration(
            color: isHovered ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered ? color : color.withValues(alpha: 0.3),
              width: isHovered ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
