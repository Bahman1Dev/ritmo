import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/today/presentation/widgets/reshuffle_preview_sheet.dart';
import 'package:ritmo/l10n/app_localizations.dart';

class QuickActionsBar extends StatelessWidget {

  const QuickActionsBar({
    super.key,
    required this.dailyBehavior,
    required this.defaultEnergyLevel,
    required this.activeZoneName,
    required this.onReshuffleApplied,
  });
  final DailyBehavior? dailyBehavior;
  final String defaultEnergyLevel;
  final String? activeZoneName;
  final VoidCallback onReshuffleApplied;

  Widget _buildPill({
    required String text,
    required RitmoColors colors,
    bool isAction = false,
    VoidCallback? onTap,
  }) {
    final Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAction
            ? colors.primary.withValues(alpha: 0.12)
            : colors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAction
              ? colors.primary.withValues(alpha: 0.2)
              : colors.border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: isAction ? colors.primary : colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontFamily: 'Vazirmatn',
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      );
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    
    // Resolve context name
    var contextName = l10n.contextNormal;
    if (dailyBehavior != null) {
      switch (dailyBehavior!.context) {
        case LifeContext.sick:
          contextName = l10n.contextSick;
        case LifeContext.travel:
          contextName = l10n.contextTravel;
        case LifeContext.exam:
          contextName = l10n.contextExam;
        case LifeContext.busy:
          contextName = l10n.contextBusy;
        case LifeContext.worship:
          contextName = '${dailyBehavior!.activeWorshipSeasonTitle ?? l10n.contextWorship} 🌙';
        case LifeContext.normal:
          contextName = l10n.contextNormal;
      }
    }

    // Resolve energy level name
    var energyName = l10n.energyLevelMediumSymbol;
    if (defaultEnergyLevel == 'LOW') energyName = l10n.energyLevelLowSymbol;
    if (defaultEnergyLevel == 'HIGH') energyName = l10n.energyLevelHighSymbol;

    // Resolve active zone name
    final zoneName = (activeZoneName == null || activeZoneName == 'خارج از قلمرو' || activeZoneName == 'خارج از زون')
        ? l10n.outOfRealmSymbol
        : activeZoneName!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPill(text: '${l10n.labelContext} $contextName', colors: colors),
            const SizedBox(width: 8),
            _buildPill(text: '${l10n.labelEnergy} $energyName', colors: colors),
            const SizedBox(width: 8),
            _buildPill(text: '${l10n.labelRealm} $zoneName', colors: colors),
            const SizedBox(width: 8),
            _buildPill(
              text: l10n.resolveScheduleConflict,
              colors: colors,
              isAction: true,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => ReshufflePreviewSheet(
                    onApplied: onReshuffleApplied,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
