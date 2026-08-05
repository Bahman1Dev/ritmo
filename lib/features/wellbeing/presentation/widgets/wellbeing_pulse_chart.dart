import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_date.dart';
import 'package:ritmo/core/util/ritmo_number.dart';

class WellbeingPulseDayData {
  const WellbeingPulseDayData({
    required this.dateStr,
    this.sleepHours,
    this.energyLevel,
    this.moodScore,
    this.hasReflection = false,
  });

  final String dateStr;
  final double? sleepHours;   // e.g. 7.5
  final double? energyLevel;  // 1..3
  final double? moodScore;    // 1..5
  final bool hasReflection;
}

class WellbeingPulseChart extends StatelessWidget {
  const WellbeingPulseChart({
    super.key,
    required this.days,
  });

  final List<WellbeingPulseDayData> days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(RitmoSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RitmoRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'نبض دو هفته',
                style: RitmoTextStyles.cardTitle(colors.textPrimary),
              ),
              const Spacer(),
              _buildLegendPill(context, 'خواب', colors.sleepAccent),
              const SizedBox(width: 8),
              _buildLegendPill(context, 'انرژی', colors.energyAccent),
              const SizedBox(width: 8),
              _buildLegendPill(context, 'حال', colors.reflectionAccent),
            ],
          ),
          const SizedBox(height: RitmoSpacing.lg),
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final barWidth = (constraints.maxWidth - (days.length - 1) * 4) / days.length;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: days.map((d) => _buildDayBar(context, d, barWidth)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill(BuildContext context, String label, Color color) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: RitmoTextStyles.caption(colors.textSecondary)),
      ],
    );
  }

  Widget _buildDayBar(BuildContext context, WellbeingPulseDayData d, double width) {
    final colors = context.colors;

    // Sleep bar height ratio (max 12h = 1.0)
    final sleepRatio = d.sleepHours == null ? 0.0 : (d.sleepHours! / 12.0).clamp(0.0, 1.0);

    // Energy position ratio (1..3 = 0..1)
    final energyRatio = d.energyLevel == null ? null : ((d.energyLevel! - 1.0) / 2.0).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showDayDetailDialog(context, d),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Chart area
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Sleep background bar
                  if (d.sleepHours != null)
                    FractionallySizedBox(
                      heightFactor: math.max(0.08, sleepRatio),
                      child: Container(
                        width: width * 0.7,
                        decoration: BoxDecoration(
                          color: colors.sleepAccent.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                  // Energy/Mood dot
                  if (energyRatio != null)
                    Positioned(
                      bottom: energyRatio * 110.0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: d.moodScore != null
                              ? (d.moodScore! >= 4
                                  ? colors.success
                                  : (d.moodScore! <= 2 ? colors.error : colors.cautionAccent))
                              : colors.energyAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.energyAccent.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Reflection tick under axis
            if (d.hasReflection)
              Icon(Icons.check, size: 10, color: colors.reflectionAccent)
            else
              const SizedBox(height: 10),
            const SizedBox(height: 2),
            // Day label
            Text(
              _dayLabel(d.dateStr),
              style: RitmoTextStyles.caption(colors.textSecondary).copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(String dateStr) {
    final dt = RitmoDate.tryParseDayKey(dateStr);
    if (dt == null) return '';
    return RitmoNumber.fa(dt.day.toString());
  }

  void _showDayDetailDialog(BuildContext context, WellbeingPulseDayData d) {
    final colors = context.colors;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RitmoRadius.card)),
        title: Text(
          'جزئیات روز ${RitmoNumber.fa(d.dateStr)}',
          style: RitmoTextStyles.cardTitle(colors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(colors, 'خواب', d.sleepHours != null ? RitmoNumber.faHours(d.sleepHours!) : 'ثبت نشده'),
            const SizedBox(height: 8),
            _detailRow(colors, 'انرژی', d.energyLevel != null ? '${RitmoNumber.fa(d.energyLevel!.toStringAsFixed(1))} از ۳' : 'ثبت نشده'),
            const SizedBox(height: 8),
            _detailRow(colors, 'حال', d.moodScore != null ? '${RitmoNumber.fa(d.moodScore!.toStringAsFixed(1))} از ۵' : 'ثبت نشده'),
            const SizedBox(height: 8),
            _detailRow(colors, 'بازتاب', d.hasReflection ? 'ثبت شده ✓' : 'ثبت نشده'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('بستن', style: RitmoTextStyles.label(colors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(RitmoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: RitmoTextStyles.body(colors.textSecondary)),
        Text(value, style: RitmoTextStyles.label(colors.textPrimary)),
      ],
    );
  }
}
