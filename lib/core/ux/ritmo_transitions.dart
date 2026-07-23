import 'package:flutter/material.dart';

class RitmoTransitions {
  // Page route with fade + gentle slide (200ms)
  static PageRoute<T> fadeSlide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween<Offset>(
          begin: const Offset(0, 0.05), // Gentle slide up
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        
        final fadeTween = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

        return FadeTransition(
          opacity: fadeTween,
          child: SlideTransition(
            position: slideTween,
            child: child,
          ),
        );
      },
    );
  }

  // AnimatedSwitcher with 220ms fade
  static Widget fade({required Widget child, Key? key}) {
    return AnimatedSwitcher(
      key: key,
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: child,
    );
  }

  // Staggered list item: each item slides in from below with index * 40ms delay
  static Widget staggeredItem({
    required int index,
    required Widget child,
    Duration baseDuration = const Duration(milliseconds: 350),
  }) {
    return _StaggeredItemWrapper(
      index: index,
      duration: baseDuration,
      child: child,
    );
  }
}

class _StaggeredItemWrapper extends StatefulWidget {

  const _StaggeredItemWrapper({
    required this.index,
    required this.child,
    required this.duration,
  });
  final int index;
  final Widget child;
  final Duration duration;

  @override
  State<_StaggeredItemWrapper> createState() => _StaggeredItemWrapperState();
}

class _StaggeredItemWrapperState extends State<_StaggeredItemWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15), // Slide up from below
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Delayed execution based on index
    Future.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
