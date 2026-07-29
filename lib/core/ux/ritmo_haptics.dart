import 'package:flutter/services.dart';

class RitmoHaptics {
  // Light: tap اصلی، انتخاب
  static void tap() => HapticFeedback.selectionClick();
  
  // Medium: تأیید، complete، start timer
  static void confirm() => HapticFeedback.mediumImpact();
  
  // Heavy: حذف، خطا، snooze
  static void warning() => HapticFeedback.heavyImpact();
  
  // Success: ثبت موفق، بکاپ موفق
  static void success() => HapticFeedback.lightImpact();
  
  // Subtle: scroll snap، slider tick
  static void subtle() => HapticFeedback.selectionClick();

  static void selection() => tap();

  static void sheetOpen() => HapticFeedback.lightImpact();
  static void sheetClose() => HapticFeedback.selectionClick();
  static void error() => HapticFeedback.heavyImpact();
}
