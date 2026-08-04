// lib/features/registry/presentation/widgets/registry_skeleton.dart

import 'package:flutter/material.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

/// Shimmer skeleton loader that mimics the registry card layout
/// while data is being fetched.
class RegistrySkeleton extends StatefulWidget {
  const RegistrySkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  State<RegistrySkeleton> createState() => _RegistrySkeletonState();
}

class _RegistrySkeletonState extends State<RegistrySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingL),
          child: Column(
            children: List.generate(widget.itemCount, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < widget.itemCount - 1
                      ? CalendarTokens.registryCardGap
                      : 0,
                ),
                child: _buildSkeletonCard(context),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.3)
        : Colors.grey.shade200;
    final highlightColor = isDark
        ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6)
        : Colors.grey.shade100;

    final gradient = LinearGradient(
      begin: Alignment(
        -1.0 + 2.0 * _shimmerController.value,
        0.0,
      ),
      end: Alignment(
        1.0 + 2.0 * _shimmerController.value,
        0.0,
      ),
      colors: [baseColor, highlightColor, baseColor],
      stops: const [0.0, 0.5, 1.0],
    );

    return Container(
      height: CalendarTokens.registryCardHeight,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.15)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(CalendarTokens.radiusCardLg),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.04),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          // Icon placeholder
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(
                CalendarTokens.iconContainerRadius,
              ),
            ),
            child: const SizedBox(
              width: CalendarTokens.iconContainerSize,
              height: CalendarTokens.iconContainerSize,
            ),
          ),

          const SizedBox(width: 12),

          // Text placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const SizedBox(width: 140, height: 14),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const SizedBox(width: 200, height: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Trailing badge placeholder
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(width: 60, height: 22),
          ),
        ],
      ),
    );
  }
}
