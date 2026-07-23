import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/l10n/app_localizations.dart';

class SubsystemsList extends StatelessWidget {

  const SubsystemsList({
    super.key,
    required this.isDarkMode,
    required this.isWorshipActive,
    required this.isMedicineActive,
    required this.isCoursesActive,
    required this.isGoalsActive,
    required this.medicationRoutinesCount,
    required this.onWorshipTap,
    required this.onHealthTap,
    required this.onProjectsTap,
    required this.onEducationTap,
  });
  final bool isDarkMode;
  final bool isWorshipActive;
  final bool isMedicineActive;
  final bool isCoursesActive;
  final bool isGoalsActive;
  final int medicationRoutinesCount;
  final VoidCallback onWorshipTap;
  final VoidCallback onHealthTap;
  final VoidCallback onProjectsTap;
  final VoidCallback onEducationTap;

  Widget _buildGridCard({
    required bool isDarkMode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required RitmoColors colors,
  }) {
    return RitmoTheme.glassCardLight(
      borderRadius: 20,
      color: colors.card.withValues(alpha: 0.6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledGridCard(String title, RitmoColors colors, AppLocalizations l10n) {
    return RitmoTheme.glassCardLight(
      borderRadius: 20,
      color: colors.textPrimary.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Opacity(
          opacity: 0.35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.moduleDisabled,
                style: TextStyle(
                  fontSize: 9,
                  color: colors.textSecondary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickSystemsTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            // 1. Worship (Conditional render)
            if (isWorshipActive)
              _buildGridCard(
                isDarkMode: isDarkMode,
                title: l10n.systemWorships,
                subtitle: l10n.worshipItemsToday,
                icon: Icons.mosque,
                iconColor: const Color(0xff9B89FF),
                onTap: onWorshipTap,
                colors: colors,
              )
            else
              _buildDisabledGridCard(l10n.systemWorships, colors, l10n),

            // 2. Health (Conditional render)
            if (isMedicineActive)
              _buildGridCard(
                isDarkMode: isDarkMode,
                title: l10n.systemHealth,
                subtitle: l10n.medicineToday(medicationRoutinesCount),
                icon: CupertinoIcons.capsule_fill,
                iconColor: const Color(0xffFF6B6B),
                onTap: onHealthTap,
                colors: colors,
              )
            else
              _buildDisabledGridCard(l10n.systemHealth, colors, l10n),

            // 3. Goals (Conditional)
            _buildGridCard(
              isDarkMode: isDarkMode,
              title: l10n.systemGoals,
              subtitle: isGoalsActive ? l10n.goalsAndPlans : l10n.disabled,
              icon: CupertinoIcons.flag_fill,
              iconColor: const Color(0xffF5B95B),
              onTap: onProjectsTap,
              colors: colors,
            ),

            // 4. Education (Conditional)
            _buildGridCard(
              isDarkMode: isDarkMode,
              title: l10n.systemEducation,
              subtitle: isCoursesActive ? l10n.activeCourse : l10n.disabled,
              icon: Icons.school,
              iconColor: const Color(0xff5B8AF5),
              onTap: onEducationTap,
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }
}
