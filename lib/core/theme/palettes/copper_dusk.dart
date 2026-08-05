// پالت ۲ — مس غروب
// جایگزین تم‌های ثابت پیشین

import 'dart:ui';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_module_colors.dart';

const kCopperDuskModulesLight = RitmoModuleColors(
  planner: Color(0xFF8E6A16),
  routines: Color(0xFF5C7A21),
  goals: Color(0xFF20794C),
  study: Color(0xFF0C7480),
  worship: Color(0xFF2F5DA6),
  health: Color(0xFF6A44AE),
  sports: Color(0xFF96409C),
  insights: Color(0xFFA83C60),
);

const kCopperDuskModulesDark = RitmoModuleColors(
  planner: Color(0xFFD8B457),
  routines: Color(0xFFA5C462),
  goals: Color(0xFF5FC28C),
  study: Color(0xFF48BCC6),
  worship: Color(0xFF7FA6EA),
  health: Color(0xFFA992E6),
  sports: Color(0xFFD68CDA),
  insights: Color(0xFFE68AA6),
);

const RitmoColors kCopperDuskLight = RitmoColors(
  background: Color(0xFFF9F5F1),
  surface: Color(0xFFFFFFFF),
  surfaceElevated: Color(0xFFF2ECE6),
  surfaceSunken: Color(0xFFEBE3DB),
  primary: Color(0xFFA95F3B),
  primaryPressed: Color(0xFF8A4A2B),
  primaryContainer: Color(0xFFF6E3D6),
  onPrimary: Color(0xFFFFFFFF),
  accent: Color(0xFFA98245),
  accentContainer: Color(0xFFF5EBD8),
  success: Color(0xFF247D4C),
  warning: Color(0xFFC77916),
  error: Color(0xFFC44B43),
  textPrimary: Color(0xFF241A15),
  textSecondary: Color(0xFF6B5A50),
  textTertiary: Color(0xFF96877D),
  textOnColor: Color(0xFFFFFFFF),
  border: Color(0x14000000),
  divider: Color(0x0F000000),
  disabled: Color(0xFFC6B8AE),
  overlay: Color(0x66000000),
  glassTint: Color(0xCCFFFFFF),
  shadow: Color(0x1A000000),
  systemNavBar: Color(0xFFF9F5F1),
  brandGradient: [Color(0xFFA95F3B), Color(0xFFE08A5B)],
  modules: kCopperDuskModulesLight,
);

const RitmoColors kCopperDuskDark = RitmoColors(
  background: Color(0xFF15110F),
  surface: Color(0xFF211A17),
  surfaceElevated: Color(0xFF2A211D),
  surfaceSunken: Color(0xFF100D0B),
  primary: Color(0xFFE08A5B),
  primaryPressed: Color(0xFFC26F43),
  primaryContainer: Color(0xFF43261A),
  onPrimary: Color(0xFF2A1207),
  accent: Color(0xFFD8B47A),
  accentContainer: Color(0xFF3A2E1D),
  success: Color(0xFF72CC78),
  warning: Color(0xFFF1B85B),
  error: Color(0xFFE47A72),
  textPrimary: Color(0xFFF6EFE9),
  textSecondary: Color(0xFFAE9E93),
  textTertiary: Color(0xFF7E7168),
  textOnColor: Color(0xFF0B0F0E),
  border: Color(0x1FFFFFFF),
  divider: Color(0x14FFFFFF),
  disabled: Color(0xFF544A44),
  overlay: Color(0xA6000000),
  glassTint: Color(0xB3000000),
  shadow: Color(0x00000000),
  systemNavBar: Color(0xFF15110F),
  brandGradient: [Color(0xFFA95F3B), Color(0xFFE08A5B)],
  modules: kCopperDuskModulesDark,
);
