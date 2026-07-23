import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/realm_countdown_widget.dart';
import 'package:ritmo/features/today/presentation/widgets/realm_management_sheet.dart';
import 'package:ritmo/l10n/app_localizations.dart';

class ZoneCard extends StatelessWidget {

  const ZoneCard({
    super.key,
    required this.isDarkMode,
    required this.currentEnergyPercent,
    required this.currentEnergyLabel,
    required this.currentEnergyDesc,
    required this.activeZone,
    required this.activeZoneName,
    required this.activeZoneIcon,
    required this.activeZoneColorHex,
    required this.activeZoneRoutinesCount,
    required this.activeZoneTimeRange,
    required this.onEnergyTap,
    required this.onRealmChanged,
  });
  final bool isDarkMode;
  final double currentEnergyPercent;
  final String currentEnergyLabel;
  final String currentEnergyDesc;
  final Map<String, dynamic>? activeZone;
  final String? activeZoneName;
  final String? activeZoneIcon;
  final String? activeZoneColorHex;
  final int activeZoneRoutinesCount;
  final String? activeZoneTimeRange;
  final VoidCallback onEnergyTap;
  final VoidCallback onRealmChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    final isOutOfZone = activeZoneName == null ||
        activeZoneName == 'خارج از زون' ||
        activeZoneName == 'خارج از قلمرو' ||
        activeZoneName == 'Out of Realm';

    final Color energyColor;
    final IconData energyIcon;
    final List<Color> energyRingColors;

    final isHigh = currentEnergyLabel == 'بالا' || currentEnergyLabel == 'High';
    final isLow = currentEnergyLabel == 'پایین' || currentEnergyLabel == 'Low';

    if (isHigh) {
      energyColor = colors.success;
      energyIcon = CupertinoIcons.flame_fill;
      energyRingColors = [colors.success, colors.primary];
    } else if (isLow) {
      energyColor = colors.medicalRed;
      energyIcon = CupertinoIcons.moon_fill;
      energyRingColors = [colors.medicalRed, colors.warning];
    } else {
      energyColor = colors.warning;
      energyIcon = CupertinoIcons.bolt_fill;
      energyRingColors = [colors.warning, colors.success];
    }

    final energyLabel = isHigh
        ? l10n.energyLevelHigh
        : isLow
            ? l10n.energyLevelLow
            : l10n.energyLevelMedium;

    final energyDesc = isHigh
        ? l10n.energyDescHigh
        : isLow
            ? l10n.energyDescLow
            : l10n.energyDescMedium;

    final realmName = isOutOfZone ? l10n.outOfRealm : activeZoneName!;
    final realmTimeRange = (activeZoneTimeRange == null ||
            activeZoneTimeRange == 'بدون زمان‌بندی فعال' ||
            activeZoneTimeRange == 'No active schedule')
        ? l10n.noActiveSchedule
        : activeZoneTimeRange!;

    return Row(
      children: [
        // Right side (RTL first child): Energy card
        Expanded(
          child: RitmoTheme.glassCardLight(
            color: colors.card.withValues(alpha: 0.65),
            child: InkWell(
              onTap: onEnergyTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.3,
                    colors: [
                      energyColor.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.currentEnergyTitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: energyColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            energyIcon,
                            size: 11,
                            color: energyColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Circle Indicator
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CustomPaint(
                            painter: _EnergyRingPainter(
                              percentage: currentEnergyPercent,
                              colors: energyRingColors,
                            ),
                            child: Center(
                              child: Text(
                                '${currentEnergyPercent.toInt()}٪',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                energyLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: energyColor,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                energyDesc,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: colors.textSecondary,
                                  fontFamily: 'Vazirmatn',
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.textSecondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.manageEnergy,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                CupertinoIcons.chevron_left,
                                size: 8,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Left side (RTL second child): Realm (Zone) card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: !isOutOfZone
                  ? RadialGradient(
                      center: const Alignment(0.8, -0.6),
                      radius: 1.2,
                      colors: [
                        (activeZoneColorHex != null
                                ? Color(int.parse(activeZoneColorHex!))
                                : colors.primary)
                            .withValues(alpha: 0.25),
                        colors.card.withValues(alpha: 0.65),
                      ],
                    )
                  : null,
              color: isOutOfZone
                  ? colors.card.withValues(alpha: 0.65)
                  : null,
              border: Border.all(
                color: !isOutOfZone
                    ? (activeZoneColorHex != null
                        ? Color(int.parse(activeZoneColorHex!))
                        : colors.primary).withValues(alpha: 0.4)
                    : colors.border.withValues(alpha: 0.5),
                width: !isOutOfZone
                    ? 1.5
                    : 1.0,
              ),
              boxShadow: !isOutOfZone
                  ? [
                      BoxShadow(
                        color: (activeZoneColorHex != null
                                ? Color(int.parse(activeZoneColorHex!))
                                : colors.primary)
                            .withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => RealmManagementSheet(
                        isDarkMode: isDarkMode,
                        onChanged: onRealmChanged,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.currentRealmTitle,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Vazirmatn'),
                            ),
                            if (activeZoneIcon != null)
                              Text(activeZoneIcon!, style: const TextStyle(fontSize: 14))
                            else
                              Icon(
                                CupertinoIcons.briefcase_fill,
                                size: 14,
                                color: activeZoneColorHex != null
                                    ? Color(int.parse(activeZoneColorHex!))
                                    : colors.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          realmName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          realmTimeRange,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (activeZone != null && !isOutOfZone)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: RealmCountdownWidget(
                              activeZone: activeZone!,
                              style: TextStyle(
                                fontSize: 11,
                                color: activeZoneColorHex != null
                                    ? Color(int.parse(activeZoneColorHex!))
                                    : colors.primary,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        Text(
                          isOutOfZone
                              ? l10n.logNewDailyRealm
                              : l10n.routinesConnectedToRealm(activeZoneRoutinesCount),
                          style: TextStyle(
                            fontSize: 10,
                            color: activeZoneColorHex != null
                                ? Color(int.parse(activeZoneColorHex!))
                                : colors.primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isOutOfZone
                              ? l10n.addRealm
                              : l10n.manageRealm,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EnergyRingPainter extends CustomPainter {

  _EnergyRingPainter({required this.percentage, required this.colors});
  final double percentage;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 5.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track
    final paintBg = Paint()
      ..color = colors.first.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, paintBg);

    // Create gradient
    final gradient = SweepGradient(
      colors: colors,
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
    );

    // Glow effect
    final paintGlow = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    // Foreground track
    final paintFg = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (percentage / 100);

    // Draw glow first
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paintGlow);
    // Draw crisp path on top
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paintFg);
  }

  @override
  bool shouldRepaint(covariant _EnergyRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.colors != colors;
  }
}
