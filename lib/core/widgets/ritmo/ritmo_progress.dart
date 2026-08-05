// Ritmo Progress — نوار و حلقه پیشرفت متصل به توکن‌ها
// ترک نوار از surfaceSunken و پرکردن از primary یا رنگ مادول

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RitmoProgressBar extends StatelessWidget {
  const RitmoProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 6.0,
  });

  final double progress; // 0.0 to 1.0
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeColor = color ?? colors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(RitmoRadius.pill),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: colors.surfaceSunken,
        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
      ),
    );
  }
}

class RitmoProgressRing extends StatelessWidget {
  const RitmoProgressRing({
    super.key,
    required this.progress,
    this.color,
    this.size = 48.0,
    this.strokeWidth = 4.0,
  });

  final double progress; // 0.0 to 1.0
  final Color? color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeColor = color ?? colors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        strokeWidth: strokeWidth,
        backgroundColor: colors.surfaceSunken,
        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
      ),
    );
  }
}
