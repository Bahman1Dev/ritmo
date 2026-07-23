import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class MySystemsStrip extends StatelessWidget {

  const MySystemsStrip({
    super.key,
    required this.isWorshipActive,
    required this.isMedicineActive,
    required this.isCoursesActive,
    required this.isGoalsActive,
    required this.onWorshipTap,
    required this.onHealthTap,
    required this.onProjectsTap,
    required this.onEducationTap,
  });
  final bool isWorshipActive;
  final bool isMedicineActive;
  final bool isCoursesActive;
  final bool isGoalsActive;
  final VoidCallback onWorshipTap;
  final VoidCallback onHealthTap;
  final VoidCallback onProjectsTap;
  final VoidCallback onEducationTap;

  Widget _buildSystemChip({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
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
    final activeChips = <Widget>[];

    if (isWorshipActive) {
      activeChips.add(_buildSystemChip(
        context: context,
        title: 'عبادت',
        icon: Icons.mosque,
        iconColor: const Color(0xff9B89FF),
        onTap: onWorshipTap,
      ));
    }

    if (isMedicineActive) {
      activeChips.add(_buildSystemChip(
        context: context,
        title: 'سلامت',
        icon: CupertinoIcons.capsule_fill,
        iconColor: const Color(0xffFF6B6B),
        onTap: onHealthTap,
      ));
    }

    if (isGoalsActive) {
      activeChips.add(_buildSystemChip(
        context: context,
        title: 'پروژه‌ها',
        icon: CupertinoIcons.flag_fill,
        iconColor: const Color(0xffF5B95B),
        onTap: onProjectsTap,
      ));
    }

    if (isCoursesActive) {
      activeChips.add(_buildSystemChip(
        context: context,
        title: 'آموزش',
        icon: Icons.school,
        iconColor: const Color(0xff5B8AF5),
        onTap: onEducationTap,
      ));
    }

    if (activeChips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سیستم‌های من',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: activeChips
                  .map((chip) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: chip,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
