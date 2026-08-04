import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

/// A reusable swipeable wrapper for routine rows and agenda items.
///
/// In RTL (Right-to-Left) physical layout:
/// - [DismissDirection.startToEnd] (Right-to-Left drag) triggers [onSwipeComplete] (Complete Routine).
/// - [DismissDirection.endToStart] (Left-to-Right drag) triggers [onSwipeManage] (Snooze/Skip/Manage).
class RitmoSwipeableRow extends StatelessWidget {
  const RitmoSwipeableRow({
    required this.itemId,
    required this.child,
    this.onSwipeComplete,
    this.onSwipeManage,
    super.key,
  });

  final String itemId;
  final Widget child;
  final VoidCallback? onSwipeComplete;
  final VoidCallback? onSwipeManage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rowKey = key ?? ValueKey('swipeable_$itemId');

    return Dismissible(
      key: rowKey,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right (startToEnd in RTL) -> Complete Routine
          if (onSwipeComplete != null) {
            RitmoHaptics.confirm();
            onSwipeComplete!();
          }
        } else if (direction == DismissDirection.endToStart) {
          // Swipe Left (endToStart in RTL) -> Manage / Snooze / Skip
          if (onSwipeManage != null) {
            RitmoHaptics.tap();
            onSwipeManage!();
          }
        }
        return false; // Do not dismiss row from tree directly
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.success.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: colors.success, size: 24),
            const SizedBox(width: 8),
            Text(
              'ثبت انجام',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.bold,
                color: colors.success,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'مدیریت / تعویق',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.bold,
                color: colors.warning,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.tune_rounded, color: colors.warning, size: 24),
          ],
        ),
      ),
      child: child,
    );
  }
}
