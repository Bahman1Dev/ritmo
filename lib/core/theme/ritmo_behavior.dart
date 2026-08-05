// توکن‌های رفتاری دسترسی‌پذیری و تم
// کنترلی بر شفافیت و جلوه‌های شیشه‌ای

import 'package:flutter/material.dart';

@immutable
class RitmoBehavior extends ThemeExtension<RitmoBehavior> {
  const RitmoBehavior({
    required this.reduceTransparency,
  });

  final bool reduceTransparency;

  @override
  RitmoBehavior copyWith({bool? reduceTransparency}) {
    return RitmoBehavior(
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
    );
  }

  @override
  RitmoBehavior lerp(ThemeExtension<RitmoBehavior>? other, double t) {
    if (other is! RitmoBehavior) return this;
    return t < 0.5 ? this : other;
  }
}
