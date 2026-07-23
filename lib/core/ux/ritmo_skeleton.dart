import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RitmoSkeleton extends StatefulWidget {

  const RitmoSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<RitmoSkeleton> createState() => _RitmoSkeletonState();
}

class _RitmoSkeletonState extends State<RitmoSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment(widget.width > 0 ? (_controller.value * 3 - 2.0) : -1.0, -1),
                end: Alignment(widget.width > 0 ? (_controller.value * 3 - 1.0) : 1.0, 1),
                colors: [
                  colors.card.withValues(alpha: 0.3),
                  colors.border.withValues(alpha: 0.6),
                  colors.card.withValues(alpha: 0.3),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RitmoSkeletonList extends StatelessWidget {

  const RitmoSkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });
  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: RitmoSkeleton(
            width: double.infinity,
            height: itemHeight,
            borderRadius: 16,
          ),
        );
      },
    );
  }
}

class RitmoSkeletonCard extends StatelessWidget {

  const RitmoSkeletonCard({
    super.key,
    this.height = 120,
  });
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.border.withValues(alpha: 0.3)),
          color: context.colors.card.withValues(alpha: 0.2),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RitmoSkeleton(width: 80, height: 16, borderRadius: 4),
            SizedBox(height: 12),
            Expanded(child: RitmoSkeleton(width: double.infinity, height: 12, borderRadius: 4)),
            SizedBox(height: 8),
            RitmoSkeleton(width: 150, height: 12, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}
