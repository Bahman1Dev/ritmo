import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/l10n/app_localizations.dart';

class AssistantBanner extends StatelessWidget {

  const AssistantBanner({
    super.key,
    required this.isDarkMode,
    required this.suggestedRoutine,
    required this.suggestLightVersion,
    required this.activeZoneName,
    required this.defaultEnergyLevel,
    required this.dailyBehavior,
    required this.onStartTap,
    required this.onWhyTap,
  });
  final bool isDarkMode;
  final Routine? suggestedRoutine;
  final bool suggestLightVersion;
  final String activeZoneName;
  final String defaultEnergyLevel;
  final DailyBehavior? dailyBehavior;
  final Function(Routine) onStartTap;
  final Function(String) onWhyTap;

  Widget _buildReasonBullet(String text, RitmoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(CupertinoIcons.checkmark_circle_fill, size: 11, color: colors.success),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasNext = suggestedRoutine != null;
    final titleText = hasNext ? suggestedRoutine!.title : l10n.restAndRecovery;
    final durationText = hasNext
        ? (suggestLightVersion
            ? l10n.minutesLight(suggestedRoutine!.lightDurationMinutes ?? suggestedRoutine!.targetDurationMinutes ?? 30)
            : l10n.minutes(suggestedRoutine!.targetDurationMinutes ?? 30))
        : l10n.freeTime;
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xff2A2D3D), const Color(0xff1C1F2E)]
              : [const Color(0xffE8EDF9), const Color(0xffF1F4FC)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(CupertinoIcons.sparkles, color: colors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l10n.smartAssistantTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Focus direction of the day
              Row(
                children: [
                  Text(
                    l10n.focusOnThisToday,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.balanceAndImprovement,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              Divider(color: colors.border, height: 20),

              // NBA Box layout
              Row(
                children: [
                  // Book/Task icon
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      CupertinoIcons.sparkles,
                      color: colors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.bestNextAction,
                          style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          titleText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(CupertinoIcons.time, size: 10, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              durationText,
                              style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reasons bullet points
              Text(
                l10n.reasonForSuggestion,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 6),
              
              // Build dynamic reasons
              ...() {
                final reasons = <String>[];
                if (hasNext) {
                  if (suggestedRoutine!.isEssential) {
                    reasons.add(l10n.reasonEssential);
                  }
                  if (activeZoneName.isNotEmpty && activeZoneName != 'خارج از زون' && activeZoneName != 'خارج از قلمرو' && activeZoneName != 'Out of Realm') {
                    reasons.add(l10n.reasonActiveZone(activeZoneName));
                  }
                  final String energyStr;
                  if (defaultEnergyLevel == 'LOW') {
                    energyStr = l10n.energyLevelLow;
                  } else if (defaultEnergyLevel == 'HIGH') {
                    energyStr = l10n.energyLevelHigh;
                  } else {
                    energyStr = l10n.energyLevelMedium;
                  }
                  reasons.add(l10n.reasonEnergyLevel(energyStr));
                  
                  if (dailyBehavior?.context == LifeContext.sick) {
                    reasons.add(l10n.reasonSick);
                  } else if (dailyBehavior?.context == LifeContext.exam) {
                    reasons.add(l10n.reasonExam);
                  } else if (dailyBehavior?.context == LifeContext.busy) {
                    reasons.add(l10n.reasonBusy);
                  } else if (dailyBehavior?.context == LifeContext.worship) {
                    reasons.add(l10n.reasonWorship(dailyBehavior?.activeWorshipSeasonTitle ?? ''));
                  }
                } else {
                  reasons.add(l10n.reasonCompleted);
                  reasons.add(l10n.reasonRestTime);
                }
                return reasons.map((r) => _buildReasonBullet(r, colors));
              }(),
              const SizedBox(height: 18),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: hasNext ? () => onStartTap(suggestedRoutine!) : null,
                      icon: const Icon(CupertinoIcons.play_arrow_solid, size: 12),
                      label: Text(l10n.start, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => onWhyTap(titleText),
                      child: Text(l10n.whyThisSuggestion, style: const TextStyle(fontSize: 12, fontFamily: 'Vazirmatn')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
