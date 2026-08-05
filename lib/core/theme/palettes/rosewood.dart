// پالت ۳ — رز چوبی
// جایگزین تم‌های ثابت پیشین

import 'dart:ui';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_module_colors.dart';

const kRosewoodModulesLight = RitmoModuleColors(
  planner: Color(0xFFA65A2E),
  routines: Color(0xFF7E7A1E),
  goals: Color(0xFF457F28),
  study: Color(0xFF137A5E),
  worship: Color(0xFF0F6A8E),
  health: Color(0xFF414CA8),
  sports: Color(0xFF813CA4),
  insights: Color(0xFFA63C6A),
);

const kRosewoodModulesDark = RitmoModuleColors(
  planner: Color(0xFFE29B62),
  routines: Color(0xFFC6C05A),
  goals: Color(0xFF8ACB66),
  study: Color(0xFF4FC3A0),
  worship: Color(0xFF54B4D8),
  health: Color(0xFF9098EC),
  sports: Color(0xFFC689DE),
  insights: Color(0xFFE689AE),
);

const RitmoColors kRosewoodLight = RitmoColors(
  background: Color(0xFFFAF5F6),
  surface: Color(0xFFFFFFFF),
  surfaceElevated: Color(0xFFF4EBEE),
  surfaceSunken: Color(0xFFEDE1E5),
  primary: Color(0xFF92485C),
  primaryPressed: Color(0xFF763846),
  primaryContainer: Color(0xFFF5DFE6),
  onPrimary: Color(0xFFFFFFFF),
  accent: Color(0xFFA47B45),
  accentContainer: Color(0xFFF4EAD9),
  success: Color(0xFF247D4C),
  warning: Color(0xFFC77916),
  error: Color(0xFFC44B43),
  textPrimary: Color(0xFF221619),
  textSecondary: Color(0xFF6B565C),
  textTertiary: Color(0xFF968188),
  textOnColor: Color(0xFFFFFFFF),
  border: Color(0x14000000),
  divider: Color(0x0F000000),
  disabled: Color(0xFFC7B4BA),
  overlay: Color(0x66000000),
  glassTint: Color(0xCCFFFFFF),
  shadow: Color(0x1A000000),
  systemNavBar: Color(0xFFFAF5F6),
  brandGradient: [Color(0xFF92485C), Color(0xFFD9829A)],
  modules: kRosewoodModulesLight,
);

const RitmoColors kRosewoodDark = RitmoColors(
  background: Color(0xFF160F12),
  surface: Color(0xFF23191D),
  surfaceElevated: Color(0xFF2C2025),
  surfaceSunken: Color(0xFF110B0E),
  primary: Color(0xFFD9829A),
  primaryPressed: Color(0xFFB96379),
  primaryContainer: Color(0xFF421F2B),
  onPrimary: Color(0xFF2B0F17),
  accent: Color(0xFFD1AD76),
  accentContainer: Color(0xFF382C1D),
  success: Color(0xFF72CC78),
  warning: Color(0xFFF1B85B),
  error: Color(0xFFE47A72),
  textPrimary: Color(0xFFF7EFF1),
  textSecondary: Color(0xFFB09AA1),
  textTertiary: Color(0xFF806E74),
  textOnColor: Color(0xFF0B0F0E),
  border: Color(0x1FFFFFFF),
  divider: Color(0x14FFFFFF),
  disabled: Color(0xFF55474C),
  overlay: Color(0xA6000000),
  glassTint: Color(0xB3000000),
  shadow: Color(0x00000000),
  systemNavBar: Color(0xFF160F12),
  brandGradient: [Color(0xFF92485C), Color(0xFFD9829A)],
  modules: kRosewoodModulesDark,
);
