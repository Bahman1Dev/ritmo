// پالت ۱ — یشم شب (پیش‌فرض)
// جایگزین تم‌های ثابت پیشین

import 'dart:ui';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_module_colors.dart';

const kJadeNoirModulesLight = RitmoModuleColors(
  planner: Color(0xFF0E6F86),
  routines: Color(0xFF3A50A8),
  goals: Color(0xFF7A3FA6),
  study: Color(0xFFA63A73),
  worship: Color(0xFFA85A22),
  health: Color(0xFF8A7420),
  sports: Color(0xFF4A7C2A),
  insights: Color(0xFF187A56),
);

const kJadeNoirModulesDark = RitmoModuleColors(
  planner: Color(0xFF4EB8CE),
  routines: Color(0xFF8A9BEB),
  goals: Color(0xFFBE8EE0),
  study: Color(0xFFE289B4),
  worship: Color(0xFFE5A05E),
  health: Color(0xFFD2BC5E),
  sports: Color(0xFF8FC96A),
  insights: Color(0xFF54C295),
);

const RitmoColors kJadeNoirLight = RitmoColors(
  background: Color(0xFFF6F8F6),
  surface: Color(0xFFFFFFFF),
  surfaceElevated: Color(0xFFEEF2EF),
  surfaceSunken: Color(0xFFE7ECE9),
  primary: Color(0xFF0F7A68),
  primaryPressed: Color(0xFF095E51),
  primaryContainer: Color(0xFFD9F0E8),
  onPrimary: Color(0xFFFFFFFF),
  accent: Color(0xFFAA7E2F),
  accentContainer: Color(0xFFF6EBD6),
  success: Color(0xFF247D4C),
  warning: Color(0xFFC77916),
  error: Color(0xFFC44B43),
  textPrimary: Color(0xFF17201D),
  textSecondary: Color(0xFF606D67),
  textTertiary: Color(0xFF8B968F),
  textOnColor: Color(0xFFFFFFFF),
  border: Color(0x14000000),
  divider: Color(0x0F000000),
  disabled: Color(0xFFB9C2BD),
  overlay: Color(0x66000000),
  glassTint: Color(0xCCFFFFFF),
  shadow: Color(0x1A000000),
  systemNavBar: Color(0xFFF6F8F6),
  brandGradient: [Color(0xFF0F7A68), Color(0xFF45BFA0)],
  modules: kJadeNoirModulesLight,
);

const RitmoColors kJadeNoirDark = RitmoColors(
  background: Color(0xFF0E1211),
  surface: Color(0xFF171D1B),
  surfaceElevated: Color(0xFF202825),
  surfaceSunken: Color(0xFF0A0D0C),
  primary: Color(0xFF45BFA0),
  primaryPressed: Color(0xFF2B9B80),
  primaryContainer: Color(0xFF173D34),
  onPrimary: Color(0xFF06231D),
  accent: Color(0xFFD6B56C),
  accentContainer: Color(0xFF3A2E1B),
  success: Color(0xFF72CC78),
  warning: Color(0xFFF1B85B),
  error: Color(0xFFE47A72),
  textPrimary: Color(0xFFF1F5F3),
  textSecondary: Color(0xFF9AA7A1),
  textTertiary: Color(0xFF6E7A75),
  textOnColor: Color(0xFF0B0F0E),
  border: Color(0x1FFFFFFF),
  divider: Color(0x14FFFFFF),
  disabled: Color(0xFF47504C),
  overlay: Color(0xA6000000),
  glassTint: Color(0xB3000000),
  shadow: Color(0x00000000),
  systemNavBar: Color(0xFF0E1211),
  brandGradient: [Color(0xFF0F7A68), Color(0xFF45BFA0)],
  modules: kJadeNoirModulesDark,
);
