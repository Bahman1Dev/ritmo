import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_pressable.dart';
import 'package:ritmo/core/widgets/ritmo_swipeable_row.dart';

class RoutineCard extends StatelessWidget {

  const RoutineCard({
    super.key,
    required this.routine,
    required this.isCompleted,
    required this.displayStreak,
    required this.customCategoriesMap,
    required this.onTap,
    this.onLongPress,
    this.onComplete,
    this.onSnooze,
    this.onSwipeManage,
  });
  final Routine routine;
  final bool isCompleted;
  final int displayStreak;
  final Map<String, CustomCategory> customCategoriesMap;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onComplete;
  final VoidCallback? onSnooze;
  final VoidCallback? onSwipeManage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: RitmoSwipeableRow(
          itemId: routine.id,
          onSwipeComplete: onComplete ?? onTap,
          onSwipeManage: onSwipeManage ?? onSnooze,
          child: RitmoPressable(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              decoration: BoxDecoration(
                color: isCompleted
                    ? colors.success.withValues(alpha: 0.08)
                    : colors.card.withValues(alpha: isDarkMode ? 0.04 : 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted
                      ? colors.success.withValues(alpha: 0.4)
                      : colors.border.withValues(alpha: isDarkMode ? 0.3 : 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // 1. Category vertical color indicator (pill)
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? colors.success
                            : _getCategoryColor(colors, routine.category.name),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. Emoji indicator
                    Text(
                      _getCategoryEmoji(routine.category.name, routine.customCategoryId),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),

                    // 3. Title & Time column (aligned to right, i.e. CrossAxisAlignment.start in RTL)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? colors.textSecondary : colors.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        Text(
                          toPersianDigits(routine.timeOfDay ?? '۰۹:۰۰'),
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // 4. Badges (Energy and Essential)
                    if (routine.energyRule != EnergyRule.none) ...[
                      Icon(CupertinoIcons.bolt_fill, color: colors.warning, size: 12),
                      const SizedBox(width: 4),
                    ],
                    if (routine.isEssential) ...[
                      Icon(CupertinoIcons.flag_fill, color: colors.medicalRed, size: 12),
                      const SizedBox(width: 4),
                    ],

                    // 5. Streak flame
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.whatshot, color: colors.warning, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${toPersianDigits(displayStreak.toString())} روز',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colors.warning,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 6. Checkbox / Done marker
                    GestureDetector(
                      onTap: onTap,
                      child: Icon(
                        isCompleted ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                        color: isCompleted ? colors.success : colors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji(String catId, String? customCategoryId) {
    if (catId == 'custom' || catId.startsWith('custom_')) {
      final key = customCategoryId ?? catId;
      return customCategoriesMap[key]?.icon ?? '🏷️';
    }
    switch (catId) {
      case 'religious':
        return '🕌';
      case 'medical':
        return '💊';
      case 'learning':
        return '📚';
      case 'fitness':
        return '🏃';
      case 'work':
        return '💼';
      case 'personal':
        return '👤';
      case 'free':
        return '🌿';
      default:
        return '🏷️';
    }
  }

  Color _getCategoryColor(RitmoColors colors, String catId) {
    switch (catId) {
      case 'religious':
        return const Color(0xffD4A843); // Golden
      case 'medical':
        return colors.medicalRed; // Red
      case 'learning':
        return const Color(0xff8B5CF6); // Purple
      case 'fitness':
        return const Color(0xffEC4899); // Pink
      case 'work':
        return const Color(0xff3B82F6); // Blue
      case 'personal':
        return const Color(0xff14B8A6); // Teal
      default:
        return colors.primary;
    }
  }
}
