// مدل تنظیمات ظاهر و تم کاربر
// شامل حالت روشنایی، شناسه پالت و تنظیمات دسترسی‌پذیری

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';

@immutable
class ThemePreferences {
  const ThemePreferences({
    required this.mode,
    required this.paletteId,
    required this.reduceTransparency,
    required this.trueBlack,
    this.autoDarkAtMaghrib = false, // Hook رزروشده بر اساس اوقات شرعی
  });

  final ThemeMode mode;
  final RitmoPaletteId paletteId;
  final bool reduceTransparency;
  final bool trueBlack;
  final bool autoDarkAtMaghrib;

  static const ThemePreferences defaults = ThemePreferences(
    mode: ThemeMode.system,
    paletteId: RitmoPaletteId.jadeNoir,
    reduceTransparency: false,
    trueBlack: false,
    autoDarkAtMaghrib: false,
  );

  ThemePreferences copyWith({
    ThemeMode? mode,
    RitmoPaletteId? paletteId,
    bool? reduceTransparency,
    bool? trueBlack,
    bool? autoDarkAtMaghrib,
  }) {
    return ThemePreferences(
      mode: mode ?? this.mode,
      paletteId: paletteId ?? this.paletteId,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
      trueBlack: trueBlack ?? this.trueBlack,
      autoDarkAtMaghrib: autoDarkAtMaghrib ?? this.autoDarkAtMaghrib,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemePreferences &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          paletteId == other.paletteId &&
          reduceTransparency == other.reduceTransparency &&
          trueBlack == other.trueBlack &&
          autoDarkAtMaghrib == other.autoDarkAtMaghrib;

  @override
  int get hashCode =>
      mode.hashCode ^
      paletteId.hashCode ^
      reduceTransparency.hashCode ^
      trueBlack.hashCode ^
      autoDarkAtMaghrib.hashCode;
}
