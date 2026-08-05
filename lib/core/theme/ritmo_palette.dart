// سیستم پالت‌های Ritmo — شامل ۵ پالت هارمونیک
// جایگزین پالت‌های هاردکد قبلی

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/theme/palettes/copper_dusk.dart';
import 'package:ritmo/core/theme/palettes/graphite_champagne.dart';
import 'package:ritmo/core/theme/palettes/jade_noir.dart';
import 'package:ritmo/core/theme/palettes/olive_sand.dart';
import 'package:ritmo/core/theme/palettes/rosewood.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';

enum RitmoPaletteId {
  jadeNoir,
  copperDusk,
  rosewood,
  oliveSand,
  graphiteChampagne,
}

@immutable
class RitmoPalette {
  const RitmoPalette({
    required this.id,
    required this.nameFa,
    required this.taglineFa,
    required this.light,
    required this.dark,
    this.requiresPremium = false, // Hook رزروشده برای ویژگی پرمیوم
  });

  final RitmoPaletteId id;
  final String nameFa; // مثلاً «یشم شب»
  final String taglineFa; // یک خط توصیف شخصیت برای کارت تنظیمات
  final RitmoColors light;
  final RitmoColors dark;
  final bool requiresPremium;

  RitmoColors forBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;

  static const RitmoPalette jadeNoir = RitmoPalette(
    id: RitmoPaletteId.jadeNoir,
    nameFa: 'یشم شب',
    taglineFa: 'آرام و طبیعی',
    light: kJadeNoirLight,
    dark: kJadeNoirDark,
  );

  static const RitmoPalette copperDusk = RitmoPalette(
    id: RitmoPaletteId.copperDusk,
    nameFa: 'مس غروب',
    taglineFa: 'گرم و لوکس',
    light: kCopperDuskLight,
    dark: kCopperDuskDark,
  );

  static const RitmoPalette rosewood = RitmoPalette(
    id: RitmoPaletteId.rosewood,
    nameFa: 'رز چوبی',
    taglineFa: 'شخصی و صمیمی',
    light: kRosewoodLight,
    dark: kRosewoodDark,
  );

  static const RitmoPalette oliveSand = RitmoPalette(
    id: RitmoPaletteId.oliveSand,
    nameFa: 'زیتون و شن',
    taglineFa: 'مینیمال و تمرکزمحور',
    light: kOliveSandLight,
    dark: kOliveSandDark,
  );

  static const RitmoPalette graphiteChampagne = RitmoPalette(
    id: RitmoPaletteId.graphiteChampagne,
    nameFa: 'گرافیت و شامپاینی',
    taglineFa: 'خنثی و رسمی',
    light: kGraphiteChampagneLight,
    dark: kGraphiteChampagneDark,
  );

  /// ترتیب این لیست دقیقاً ترتیب نمایش در تنظیمات است.
  static const List<RitmoPalette> all = <RitmoPalette>[
    jadeNoir,
    copperDusk,
    rosewood,
    oliveSand,
    graphiteChampagne,
  ];

  static RitmoPalette byId(RitmoPaletteId id) {
    switch (id) {
      case RitmoPaletteId.copperDusk:
        return copperDusk;
      case RitmoPaletteId.rosewood:
        return rosewood;
      case RitmoPaletteId.oliveSand:
        return oliveSand;
      case RitmoPaletteId.graphiteChampagne:
        return graphiteChampagne;
      case RitmoPaletteId.jadeNoir:
        return jadeNoir;
    }
  }

  /// رشتهٔ نامعتبر یا null باید به jadeNoir برگردد
  /// و یک لاگ دیباگ با تگ THEME_WARN بزند. هرگز throw نکند.
  static RitmoPaletteId parseId(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return RitmoPaletteId.jadeNoir;
    }
    switch (raw.trim().toLowerCase()) {
      case 'jade_noir':
      case 'jadenoir':
        return RitmoPaletteId.jadeNoir;
      case 'copper_dusk':
      case 'copperdusk':
        return RitmoPaletteId.copperDusk;
      case 'rosewood':
        return RitmoPaletteId.rosewood;
      case 'olive_sand':
      case 'olivesand':
        return RitmoPaletteId.oliveSand;
      case 'graphite_champagne':
      case 'graphitechampagne':
        return RitmoPaletteId.graphiteChampagne;
      default:
        debugPrint('[THEME_WARN] Unknown palette id "$raw". Falling back to jadeNoir.');
        return RitmoPaletteId.jadeNoir;
    }
  }

  static String serializeId(RitmoPaletteId id) {
    switch (id) {
      case RitmoPaletteId.jadeNoir:
        return 'jade_noir';
      case RitmoPaletteId.copperDusk:
        return 'copper_dusk';
      case RitmoPaletteId.rosewood:
        return 'rosewood';
      case RitmoPaletteId.oliveSand:
        return 'olive_sand';
      case RitmoPaletteId.graphiteChampagne:
        return 'graphite_champagne';
    }
  }
}
