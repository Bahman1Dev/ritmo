// پالت ۵ — گرافیت و شامپاینی
// جایگزین تم‌های ثابت پیشین

import 'dart:ui';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_module_colors.dart';

const kGraphiteModulesLight = RitmoModuleColors(
  planner: Color(0xFF7A6B2E),
  routines: Color(0xFF546F3A),
  goals: Color(0xFF2E6E5C),
  study: Color(0xFF2C6379),
  worship: Color(0xFF4A559A),
  health: Color(0xFF6E4A8E),
  sports: Color(0xFF8F4763),
  insights: Color(0xFF96593A),
);

const kGraphiteModulesDark = RitmoModuleColors(
  planner: Color(0xFFC0B173),
  routines: Color(0xFF9CB681),
  goals: Color(0xFF7CB4A2),
  study: Color(0xFF7FAEC2),
  worship: Color(0xFF9BA1D8),
  health: Color(0xFFB396CE),
  sports: Color(0xFFD291A6),
  insights: Color(0xFFD0997C),
);

const RitmoColors kGraphiteChampagneLight = RitmoColors(
  background: Color(0xFFF5F5F4),
  surface: Color(0xFFFFFFFF),
  surfaceElevated: Color(0xFFECEDEC),
  surfaceSunken: Color(0xFFE3E5E4),
  primary: Color(0xFF3D4441),
  primaryPressed: Color(0xFF282E2B),
  primaryContainer: Color(0xFFDFE3E1),
  onPrimary: Color(0xFFFFFFFF),
  accent: Color(0xFF9A7334),
  accentContainer: Color(0xFFF3EAD8),
  success: Color(0xFF247D4C),
  warning: Color(0xFFC77916),
  error: Color(0xFFC44B43),
  textPrimary: Color(0xFF191C1B),
  textSecondary: Color(0xFF5C6260),
  textTertiary: Color(0xFF8A908E),
  textOnColor: Color(0xFFFFFFFF),
  border: Color(0x14000000),
  divider: Color(0x0F000000),
  disabled: Color(0xFFB9BEBC),
  overlay: Color(0x66000000),
  glassTint: Color(0xCCFFFFFF),
  shadow: Color(0x1A000000),
  systemNavBar: Color(0xFFF5F5F4),
  brandGradient: [Color(0xFF3D4441), Color(0xFFD8C79E)],
  modules: kGraphiteModulesLight,
);

const RitmoColors kGraphiteChampagneDark = RitmoColors(
  background: Color(0xFF0A0B0C),
  surface: Color(0xFF17191A),
  surfaceElevated: Color(0xFF202324),
  surfaceSunken: Color(0xFF060708),
  primary: Color(0xFFD8C79E),
  primaryPressed: Color(0xFFBCA97D),
  primaryContainer: Color(0xFF302B22),
  onPrimary: Color(0xFF241C0C),
  accent: Color(0xFFC9A45D),
  accentContainer: Color(0xFF33291A),
  success: Color(0xFF72CC78),
  warning: Color(0xFFF1B85B),
  error: Color(0xFFE47A72),
  textPrimary: Color(0xFFF2F3F3),
  textSecondary: Color(0xFF9EA4A2),
  textTertiary: Color(0xFF727776),
  textOnColor: Color(0xFF0B0F0E),
  border: Color(0x1FFFFFFF),
  divider: Color(0x14FFFFFF),
  disabled: Color(0xFF4A4F4E),
  overlay: Color(0xA6000000),
  glassTint: Color(0xB3000000),
  shadow: Color(0x00000000),
  systemNavBar: Color(0xFF0A0B0C),
  brandGradient: [Color(0xFF3D4441), Color(0xFFD8C79E)],
  modules: kGraphiteModulesDark,
);
