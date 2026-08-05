// سیستم رنگ‌های مادول‌های Ritmo — چرخهٔ ۸ رنگهٔ هارمونیک
// جایگزین رنگ‌های هاردکد پراکنده در مادول‌ها

import 'dart:ui';
import 'package:flutter/foundation.dart';

@immutable
class RitmoModuleColors {
  const RitmoModuleColors({
    required this.planner,
    required this.routines,
    required this.goals,
    required this.study,
    required this.worship,
    required this.health,
    required this.sports,
    required this.insights,
  });

  final Color planner;
  final Color routines;
  final Color goals;
  final Color study;
  final Color worship;
  final Color health;
  final Color sports;
  final Color insights;

  /// دسترسی با اندیس برای نمودارها و لیست‌های داینامیک (۰ تا ۷).
  Color bySlot(int index) {
    switch (index % 8) {
      case 0:
        return planner;
      case 1:
        return routines;
      case 2:
        return goals;
      case 3:
        return study;
      case 4:
        return worship;
      case 5:
        return health;
      case 6:
        return sports;
      case 7:
      default:
        return insights;
    }
  }

  /// دسترسی با شناسهٔ مادول؛ برای مادول ناشناخته `insights` را برگردان.
  Color byModuleId(String moduleId) {
    switch (moduleId.toLowerCase().trim()) {
      case 'planner':
      case 'calendar':
        return planner;
      case 'routines':
      case 'routine':
      case 'habits':
        return routines;
      case 'goals':
      case 'goal':
        return goals;
      case 'study':
      case 'konkur':
        return study;
      case 'worship':
      case 'prayer':
        return worship;
      case 'health':
      case 'cycle':
      case 'wellbeing':
        return health;
      case 'sports':
      case 'supplementary_sports':
        return sports;
      case 'insights':
      case 'reflection':
      case 'energy':
      default:
        return insights;
    }
  }

  RitmoModuleColors copyWith({
    Color? planner,
    Color? routines,
    Color? goals,
    Color? study,
    Color? worship,
    Color? health,
    Color? sports,
    Color? insights,
  }) {
    return RitmoModuleColors(
      planner: planner ?? this.planner,
      routines: routines ?? this.routines,
      goals: goals ?? this.goals,
      study: study ?? this.study,
      worship: worship ?? this.worship,
      health: health ?? this.health,
      sports: sports ?? this.sports,
      insights: insights ?? this.insights,
    );
  }

  static RitmoModuleColors lerp(RitmoModuleColors a, RitmoModuleColors b, double t) {
    return RitmoModuleColors(
      planner: Color.lerp(a.planner, b.planner, t)!,
      routines: Color.lerp(a.routines, b.routines, t)!,
      goals: Color.lerp(a.goals, b.goals, t)!,
      study: Color.lerp(a.study, b.study, t)!,
      worship: Color.lerp(a.worship, b.worship, t)!,
      health: Color.lerp(a.health, b.health, t)!,
      sports: Color.lerp(a.sports, b.sports, t)!,
      insights: Color.lerp(a.insights, b.insights, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RitmoModuleColors &&
          runtimeType == other.runtimeType &&
          planner == other.planner &&
          routines == other.routines &&
          goals == other.goals &&
          study == other.study &&
          worship == other.worship &&
          health == other.health &&
          sports == other.sports &&
          insights == other.insights;

  @override
  int get hashCode =>
      planner.hashCode ^
      routines.hashCode ^
      goals.hashCode ^
      study.hashCode ^
      worship.hashCode ^
      health.hashCode ^
      sports.hashCode ^
      insights.hashCode;
}
