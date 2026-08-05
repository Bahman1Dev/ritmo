// پالت ۴ — زیتون و شن
// جایگزین تم‌های ثابت پیشین

import 'dart:ui';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_module_colors.dart';

const kOliveSandModulesLight = RitmoModuleColors(
  planner: Color(0xFF4C7C26),
  routines: Color(0xFF177A5B),
  goals: Color(0xFF0D6F8A),
  study: Color(0xFF3652AA),
  worship: Color(0xFF7840A6),
  health: Color(0xFFA43C70),
  sports: Color(0xFFA85832),
  insights: Color(0xFF836F1C),
);

const kOliveSandModulesDark = RitmoModuleColors(
  planner: Color(0xFF93CA63),
  routines: Color(0xFF52C29B),
  goals: Color(0xFF4CB7D0),
  study: Color(0xFF869CEE),
  worship: Color(0xFFBF8CE0),
  health: Color(0xFFE389B4),
  sports: Color(0xFFE59A6E),
  insights: Color(0xFFCDB755),
);

const RitmoColors kOliveSandLight = RitmoColors(
  background: Color(0xFFF7F7F1),
  surface: Color(0xFFFFFFFF),
  surfaceElevated: Color(0xFFEFF0E7),
  surfaceSunken: Color(0xFFE7E9DD),
  primary: Color(0xFF5E7236),
  primaryPressed: Color(0xFF485827),
  primaryContainer: Color(0xFFE4EDCE),
  onPrimary: Color(0xFFFFFFFF),
  accent: Color(0xFFA3752C),
  accentContainer: Color(0xFFF4EAD3),
  success: Color(0xFF247D4C),
  warning: Color(0xFFC77916),
  error: Color(0xFFC44B43),
  textPrimary: Color(0xFF1B1F16),
  textSecondary: Color(0xFF5F6555),
  textTertiary: Color(0xFF8B917F),
  textOnColor: Color(0xFFFFFFFF),
  border: Color(0x14000000),
  divider: Color(0x0F000000),
  disabled: Color(0xFFBCC1AF),
  overlay: Color(0x66000000),
  glassTint: Color(0xCCFFFFFF),
  shadow: Color(0x1A000000),
  systemNavBar: Color(0xFFF7F7F1),
  brandGradient: [Color(0xFF5E7236), Color(0xFFA8C46C)],
  modules: kOliveSandModulesLight,
);

const RitmoColors kOliveSandDark = RitmoColors(
  background: Color(0xFF11140F),
  surface: Color(0xFF1B2018),
  surfaceElevated: Color(0xFF232920),
  surfaceSunken: Color(0xFF0C0F0A),
  primary: Color(0xFFA8C46C),
  primaryPressed: Color(0xFF87A64F),
  primaryContainer: Color(0xFF2C3A1C),
  onPrimary: Color(0xFF182106),
  accent: Color(0xFFD0A557),
  accentContainer: Color(0xFF352B18),
  success: Color(0xFF72CC78),
  warning: Color(0xFFF1B85B),
  error: Color(0xFFE47A72),
  textPrimary: Color(0xFFF1F4EC),
  textSecondary: Color(0xFFA0A795),
  textTertiary: Color(0xFF73796A),
  textOnColor: Color(0xFF0B0F0E),
  border: Color(0x1FFFFFFF),
  divider: Color(0x14FFFFFF),
  disabled: Color(0xFF4B5145),
  overlay: Color(0xA6000000),
  glassTint: Color(0xB3000000),
  shadow: Color(0x00000000),
  systemNavBar: Color(0xFF11140F),
  brandGradient: [Color(0xFF5E7236), Color(0xFFA8C46C)],
  modules: kOliveSandModulesDark,
);
