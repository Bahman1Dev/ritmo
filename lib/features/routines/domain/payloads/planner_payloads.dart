// lib/features/routines/domain/payloads/planner_payloads.dart
//
// Typed payload containers for each planner category.
// These classes extract category-specific state out of the monolithic PlannerController.

import 'package:flutter/material.dart';

// ─── WORSHIP ────────────────────────────────────────────────────────────────────

class WorshipPlannerPayload {
  String worshipType = 'MUSTAHAB';
  String worshipDebtType = 'PRAYER';
  int worshipTotalCount = 10;
  int worshipDailyTarget = 1;
  String worshipReminderAnchor = 'NONE';
  int worshipOffsetMinutes = 0;
  List<int> worshipSelectedDays = [6, 7, 1, 2, 3, 4, 5];
  String worshipRepeatType = 'RECURRING';

  void reset() {
    worshipType = 'MUSTAHAB';
    worshipDebtType = 'PRAYER';
    worshipTotalCount = 10;
    worshipDailyTarget = 1;
    worshipReminderAnchor = 'NONE';
    worshipOffsetMinutes = 0;
    worshipSelectedDays = [6, 7, 1, 2, 3, 4, 5];
    worshipRepeatType = 'RECURRING';
  }
}

// ─── SPORTS ─────────────────────────────────────────────────────────────────────

class SportsPlannerPayload {
  String sportsOpType = 'ROUTINE';
  String sportsType = 'STRENGTH';
  int sportsDuration = 45;
  String sportsIntensity = 'MEDIUM';
  String sportsLocation = 'GYM';
  String sportsFeeling = 'خوب';
  // Fix for the old shared-field bug — sports now has its own day selection
  List<int> sportsSelectedDays = [6, 7, 1, 2, 3, 4, 5];

  void reset() {
    sportsOpType = 'ROUTINE';
    sportsType = 'STRENGTH';
    sportsDuration = 45;
    sportsIntensity = 'MEDIUM';
    sportsLocation = 'GYM';
    sportsFeeling = 'خوب';
    sportsSelectedDays = [6, 7, 1, 2, 3, 4, 5];
  }
}

// ─── MEDICAL ─────────────────────────────────────────────────────────────────────

class MedicalPlannerPayload {
  String medicalMode = 'FIXED';
  List<TimeOfDay> medicalTimes = [const TimeOfDay(hour: 8, minute: 0)];
  int medicalStockCount = 30;
  int medicalRefillWarning = 5;
  int medicalMinIntervalHours = 4;
  int medicalMaxDosesPerDay = 4;
  String doseDescription = '';

  void reset() {
    medicalMode = 'FIXED';
    medicalTimes = [const TimeOfDay(hour: 8, minute: 0)];
    medicalStockCount = 30;
    medicalRefillWarning = 5;
    medicalMinIntervalHours = 4;
    medicalMaxDosesPerDay = 4;
    doseDescription = '';
  }
}

// ─── COURSE ──────────────────────────────────────────────────────────────────────

class CoursePlannerPayload {
  String courseType = 'VIDEO';
  int courseTotalSessions = 10;
  int courseWeeklyTarget = 3;
  int courseSessionDuration = 45;
  List<int> coursePreferredDays = [6, 1, 3];
  TimeOfDay coursePreferredTime = const TimeOfDay(hour: 18, minute: 0);

  void reset() {
    courseType = 'VIDEO';
    courseTotalSessions = 10;
    courseWeeklyTarget = 3;
    courseSessionDuration = 45;
    coursePreferredDays = [6, 1, 3];
    coursePreferredTime = const TimeOfDay(hour: 18, minute: 0);
  }
}

// ─── GOAL ────────────────────────────────────────────────────────────────────────

class GoalPlannerPayload {
  String goalType = 'DAILY';
  DateTime goalTargetDate = DateTime.now().add(const Duration(days: 30));
  List<String> goalSteps = [''];

  void reset() {
    goalType = 'DAILY';
    goalTargetDate = DateTime.now().add(const Duration(days: 30));
    goalSteps = [''];
  }
}

// ─── REFLECTION ──────────────────────────────────────────────────────────────────

class ReflectionPlannerPayload {
  int reflectionMood = 3;
  String reflectionWins = '';
  String reflectionGratitude = '';
  String reflectionLearnings = '';
  bool reflectionIsPrivate = false;

  void reset() {
    reflectionMood = 3;
    reflectionWins = '';
    reflectionGratitude = '';
    reflectionLearnings = '';
    reflectionIsPrivate = false;
  }
}

// ─── GENERIC ─────────────────────────────────────────────────────────────────────

class GenericPlannerPayload {
  String recurrenceType = 'EVERY_DAY';
  int targetDuration = 60;
  int reminderOffsetMinutes = 15;
  double priority = 1;
  String energyRule = 'NONE';
  String? dependsOnRoutineId;
  String? selectedZoneId;

  void reset() {
    recurrenceType = 'EVERY_DAY';
    targetDuration = 60;
    reminderOffsetMinutes = 15;
    priority = 1.0;
    energyRule = 'NONE';
    dependsOnRoutineId = null;
    selectedZoneId = null;
  }
}
