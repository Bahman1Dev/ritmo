import 'package:flutter/material.dart';

class GoalsTheme {
  GoalsTheme._();

  static const Color goalsAccent = Color(0xFFF59E0B); // Warm Gold / Amber Accent
  static const Color goalsSuccess = Color(0xFF10B981); // Emerald Green
  static const Color goalsWarning = Color(0xFFEF4444); // Crimson Warning
  static const Color goalsPaused = Color(0xFF6B7280); // Muted Gray

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return goalsSuccess;
      case 'PAUSED':
      case 'ABANDONED':
        return goalsPaused;
      case 'ACTIVE':
      default:
        return goalsAccent;
    }
  }
}
