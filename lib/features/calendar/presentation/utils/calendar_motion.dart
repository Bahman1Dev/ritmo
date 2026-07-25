import 'package:flutter/material.dart';

class CalendarMotion {
  const CalendarMotion._();

  static bool _userReduceMotion = false;

  static void setReduceMotion(bool value) {
    _userReduceMotion = value;
  }

  static bool get userReduceMotion => _userReduceMotion;

  /// آیا انیمیشن‌ها باید کاهش یابند؟
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? _userReduceMotion;

  static Duration d(BuildContext context, Duration base) =>
      reduced(context) ? Duration.zero : base;
}
