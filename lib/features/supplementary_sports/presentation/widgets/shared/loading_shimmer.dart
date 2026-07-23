import 'package:flutter/material.dart';

class LoadingShimmer extends StatefulWidget {

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0);
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.3, 0.5, 0.7],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {

  const _SlidingGradientTransform({required this.slidePercent});
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final w = bounds.width;
    final translation = -w + (slidePercent * 2 * w);
    return Matrix4.translationValues(translation, 0, 0);
  }
}
