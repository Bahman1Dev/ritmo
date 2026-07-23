import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/premium/presentation/premium_upgrade_sheet.dart';

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.size = 14});
  final double size;

  @override
  Widget build(BuildContext context) {
    if (PremiumService.instance.isPremium) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xffFFA500).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.diamond,
        size: size,
        color: const Color(0xffFFA500),
      ),
    );
  }
}

class PremiumGate extends StatelessWidget {

  const PremiumGate({
    super.key,
    required this.child,
    required this.feature,
    this.onPremiumTap,
  });
  final Widget child;
  final PremiumFeature feature;
  final VoidCallback? onPremiumTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAllowed = PremiumService.instance.can(feature);

    if (isAllowed) {
      return child;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Show child slightly faded
        Opacity(
          opacity: 0.5,
          child: AbsorbPointer(
            child: child,
          ),
        ),
        // Overlay gesture detector to catch click and show upgrade sheet
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (onPremiumTap != null) {
                onPremiumTap!();
              } else {
                PremiumUpgradeSheet.show(context);
              }
            },
            child: const SizedBox.expand(),
          ),
        ),
        // Small lock badge overlay
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.card,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xffFFA500).withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.padlock_solid,
              size: 14,
              color: Color(0xffFFA500),
            ),
          ),
        ),
      ],
    );
  }
}
