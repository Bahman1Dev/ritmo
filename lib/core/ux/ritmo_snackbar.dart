import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

class RitmoSnackbar {
  static void success(BuildContext context, String message) {
    RitmoHaptics.success();
    _show(context, message, Icons.check_circle_rounded, context.colors.success);
  }

  static void error(BuildContext context, String message, {VoidCallback? onRetry}) {
    RitmoHaptics.warning();
    _show(
      context,
      message,
      Icons.error_outline_rounded,
      context.colors.medicalRed,
      retry: onRetry,
    );
  }

  static void warning(BuildContext context, String message) {
    RitmoHaptics.warning();
    _show(context, message, Icons.warning_amber_rounded, context.colors.warning);
  }

  static void info(BuildContext context, String message) {
    RitmoHaptics.tap();
    _show(context, message, Icons.info_outline_rounded, context.colors.primary);
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color iconColor, {
    VoidCallback? retry,
  }) {
    // Redirect to RitmoToast so that notifications appear at the top of the screen globally
    RitmoToast.show(
      context,
      message,
      icon: icon,
      iconColor: iconColor,
      onUndo: retry, // Mapped to undo/retry callback action
    );
  }
}
