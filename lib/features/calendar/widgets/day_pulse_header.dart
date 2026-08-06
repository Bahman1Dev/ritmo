import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class DayPulseHeader extends StatelessWidget {
  const DayPulseHeader({
    super.key,
    required this.snapshot,
    this.onConflictTap,
    this.isPastDay = false,
    this.isFutureDay = false,
  });

  final DayAgendaSnapshot snapshot;
  final VoidCallback? onConflictTap;
  final bool isPastDay;
  final bool isFutureDay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final rhythm = snapshot.rhythmScore.clamp(0, 100);
    final freeMins = snapshot.freeGaps.fold<int>(
      0,
      (sum, gap) => sum + (gap.endMinutes - gap.startMinutes),
    );

    final freeHoursStr = (freeMins ~/ 60) > 0
        ? '${toPersianDigits((freeMins ~/ 60).toString())} س و ${toPersianDigits((freeMins % 60).toString())} م'
        : '${toPersianDigits(freeMins.toString())} د';

    final conflictCount = snapshot.conflicts.length;
    final overloadScore = snapshot.overloadScore;

    String loadText;
    Color loadColor;
    if (overloadScore > 0.75) {
      loadText = 'سنگین';
      loadColor = colors.warning;
    } else if (overloadScore < 0.35) {
      loadText = 'سبک';
      loadColor = colors.success;
    } else {
      loadText = 'متعادل';
      loadColor = colors.primary;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 64.0,
        margin: const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingL, vertical: CalendarTokens.spacingS),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          border: Border.all(color: colors.border.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. Rhythm Arc
            _buildTile(
              context,
              label: isPastDay ? 'مرور ریتم' : 'ریتم روز',
              value: isFutureDay ? '—' : '${toPersianDigits(rhythm.toString())}٪',
              color: colors.primary,
              icon: Icons.speed_rounded,
            ),
            _buildDivider(colors),

            // 2. Free Time
            _buildTile(
              context,
              label: 'زمان آزاد',
              value: freeHoursStr,
              color: colors.success,
              icon: Icons.hourglass_bottom_rounded,
            ),
            _buildDivider(colors),

            // 3. Conflicts
            InkWell(
              onTap: conflictCount > 0 ? onConflictTap : null,
              borderRadius: BorderRadius.circular(8),
              child: _buildTile(
                context,
                label: 'تداخل‌ها',
                value: conflictCount == 0 ? '۰' : toPersianDigits(conflictCount.toString()),
                color: conflictCount > 0 ? colors.warning : colors.textTertiary,
                icon: Icons.warning_amber_rounded,
              ),
            ),
            _buildDivider(colors),

            // 4. Day Load
            _buildTile(
              context,
              label: 'بار روز',
              value: loadText,
              color: loadColor,
              icon: Icons.bar_chart_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: colors.textSecondary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(RitmoColors colors) {
    return Container(
      width: 1.0,
      height: 28.0,
      color: colors.border.withValues(alpha: 0.15),
    );
  }
}
