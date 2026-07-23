import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

class RitmoPressable extends StatefulWidget {

  const RitmoPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.haptic = true,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final bool haptic;

  @override
  State<RitmoPressable> createState() => _RitmoPressableState();
}

class _RitmoPressableState extends State<RitmoPressable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
      if (widget.haptic) {
        RitmoHaptics.tap();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
