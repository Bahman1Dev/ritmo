import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/today/presentation/widgets/reshuffle_preview_sheet.dart';
import 'package:ritmo/l10n/app_localizations.dart';

/// نوار زمینه‌ی یکپارچه: ادغام pillهای وضعیت (QuickActionsBar سابق)
/// و چیپ‌های «سیستم‌های من» (MySystemsStrip سابق) در یک ردیف اسکرولی واحد.
/// فقط لایه‌ی نمایش — همان داده‌ها و callbackهای قبلی.
class ContextStrip extends StatelessWidget {

  const ContextStrip({
    super.key,
    required this.dailyBehavior,
    required this.defaultEnergyLevel,
    required this.activeZoneName,
    required this.onReshuffleApplied,
    required this.isWorshipActive,
    required this.isMedicineActive,
    required this.isCoursesActive,
    required this.isGoalsActive,
    required this.onWorshipTap,
    required this.onHealthTap,
    required this.onProjectsTap,
    required this.onEducationTap,
  });
  // وضعیت (QuickActionsBar سابق)
  final DailyBehavior? dailyBehavior;
  final String defaultEnergyLevel;
  final String? activeZoneName;
  final VoidCallback onReshuffleApplied;

  // سیستم‌های فعال (MySystemsStrip سابق)
  final bool isWorshipActive;
  final bool isMedicineActive;
  final bool isCoursesActive;
  final bool isGoalsActive;
  final VoidCallback onWorshipTap;
  final VoidCallback onHealthTap;
  final VoidCallback onProjectsTap;
  final VoidCallback onEducationTap;

  Widget _pill({
    required BuildContext context,
    required String text,
    IconData? icon,
    Color? iconColor,
    bool isAction = false,
    VoidCallback? onTap,
  }) {
    final colors = context.colors;
    final Widget content = Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(
          horizontal: RitmoSpacing.md, vertical: RitmoSpacing.sm),
      decoration: BoxDecoration(
        color: isAction
            ? colors.primary.withValues(alpha: 0.12)
            : colors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(RitmoRadius.chip),
        border: Border.all(
          color: isAction
              ? colors.primary.withValues(alpha: 0.2)
              : colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? colors.primary, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isAction ? colors.primary : colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            RitmoHaptics.tap();
            onTap();
          },
          borderRadius: BorderRadius.circular(RitmoRadius.chip),
          child: content,
        ),
      );
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    // نام زمینه (context)
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
          contextName =
              '${dailyBehavior!.activeWorshipSeasonTitle ?? l10n.contextWorship} 🌙';
        case LifeContext.normal:
          contextName = l10n.contextNormal;
      }
    }

    // سطح انرژی
    var energyName = l10n.energyLevelMediumSymbol;
    if (defaultEnergyLevel == 'LOW') energyName = l10n.energyLevelLowSymbol;
    if (defaultEnergyLevel == 'HIGH') energyName = l10n.energyLevelHighSymbol;

    // زون فعال
    final zoneName = (activeZoneName == null ||
            activeZoneName == 'خارج از قلمرو' ||
            activeZoneName == 'خارج از زون')
        ? l10n.outOfRealmSymbol
        : activeZoneName!;

    final pills = <Widget>[
      _pill(context: context, text: '${l10n.labelContext} $contextName'),
      _pill(context: context, text: '${l10n.labelEnergy} $energyName'),
      _pill(context: context, text: '${l10n.labelRealm} $zoneName'),
      _pill(
        context: context,
        text: l10n.resolveScheduleConflict,
        isAction: true,
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) =>
                ReshufflePreviewSheet(onApplied: onReshuffleApplied),
          );
        },
      ),
    ];

    // چیپ‌های سیستم‌های فعال — در ادامه‌ی همان ردیف
    final systemChips = <Widget>[
      if (isWorshipActive)
        _pill(
          context: context,
          text: 'عبادت',
          icon: Icons.mosque,
          iconColor: colors.energyGradient.last,
          onTap: onWorshipTap,
        ),
      if (isMedicineActive)
        _pill(
          context: context,
          text: 'سلامت',
          icon: CupertinoIcons.capsule_fill,
          iconColor: colors.medicalRed,
          onTap: onHealthTap,
        ),
      if (isGoalsActive)
        _pill(
          context: context,
          text: 'پروژه‌ها',
          icon: CupertinoIcons.flag_fill,
          iconColor: colors.warning,
          onTap: onProjectsTap,
        ),
      if (isCoursesActive)
        _pill(
          context: context,
          text: 'آموزش',
          icon: Icons.school,
          iconColor: colors.primary,
          onTap: onEducationTap,
        ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < pills.length; i++) ...[
              if (i > 0) const SizedBox(width: RitmoSpacing.sm),
              pills[i],
            ],
            if (systemChips.isNotEmpty) ...[
              // جداکننده‌ی عمودی ظریف بین وضعیت و سیستم‌ها
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: RitmoSpacing.md),
                child: Container(
                  width: 1,
                  height: 20,
                  color: colors.border,
                ),
              ),
              for (var i = 0; i < systemChips.length; i++) ...[
                if (i > 0) const SizedBox(width: RitmoSpacing.sm),
                systemChips[i],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
