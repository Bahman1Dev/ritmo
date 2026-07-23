// lib/features/routines/domain/strategies/planner_save_context.dart
//
// Immutable snapshot of all data needed by a PlannerCategoryStrategy to persist
// a new or edited item. Built by PlannerController.save() and handed off to the
// matching strategy — strategies never import PlannerController directly.

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:ritmo/core/domain/models.dart';

class PlannerSaveContext {

  const PlannerSaveContext({
    required this.title,
    required this.description,
    required this.notes,
    required this.selectedDate,
    required this.selectedTime,
    required this.isEditing,
    required this.routineToEdit,
    required this.selectedCategory,
    required this.itemType,
    required this.recurrenceType,
    required this.targetDuration,
    required this.reminderOffsetMinutes,
    required this.priority,
    required this.energyRule,
    required this.dependsOnRoutineId,
    required this.selectedZoneId,
    required this.worshipType,
    required this.worshipDebtType,
    required this.worshipTotalCount,
    required this.worshipDailyTarget,
    required this.worshipReminderAnchor,
    required this.worshipOffsetMinutes,
    required this.worshipSelectedDays,
    required this.worshipRepeatType,
    required this.sportsOpType,
    required this.sportsType,
    required this.sportsDuration,
    required this.sportsIntensity,
    required this.sportsLocation,
    required this.sportsFeeling,
    required this.medicalMode,
    required this.medicalTimes,
    required this.medicalStockCount,
    required this.medicalRefillWarning,
    required this.medicalMinIntervalHours,
    required this.medicalMaxDosesPerDay,
    required this.courseType,
    required this.courseTotalSessions,
    required this.courseWeeklyTarget,
    required this.courseSessionDuration,
    required this.coursePreferredDays,
    required this.coursePreferredTime,
    required this.goalType,
    required this.goalTargetDate,
    required this.goalSteps,
    required this.reflectionMood,
    required this.reflectionWins,
    required this.reflectionGratitude,
    required this.reflectionLearnings,
    required this.reflectionIsPrivate,
  });
  // ── Shared ──────────────────────────────────────────────────────────────────
  final String title;
  final String description;
  final String notes;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final bool isEditing;
  final Map<String, dynamic>? routineToEdit;
  final Category selectedCategory;
  final String itemType; // ROUTINE | REMINDER | TASK | REFLECT | EVENT

  // ── Generic / Routine-specific ──────────────────────────────────────────────
  final String recurrenceType;   // EVERY_DAY | WEEKLY | CUSTOM_DAYS
  final int targetDuration;      // minutes
  final int reminderOffsetMinutes;
  final double priority;
  final String energyRule;
  final String? dependsOnRoutineId;
  final String? selectedZoneId;

  // ── Worship ─────────────────────────────────────────────────────────────────
  final String worshipType;           // MUSTAHAB | DHIKR | QURAN | DEBT
  final String worshipDebtType;       // PRAYER | FAST
  final int worshipTotalCount;
  final int worshipDailyTarget;
  final String worshipReminderAnchor; // NONE|FAJR|SUNRISE|DHUHR|ASR|MAGHRIB|ISHA|WAKEUP|BEDTIME
  final int worshipOffsetMinutes;
  final List<int> worshipSelectedDays;
  final String worshipRepeatType;     // RECURRING | ONCE

  // ── Sports ──────────────────────────────────────────────────────────────────
  final String sportsOpType;      // ROUTINE | LOG
  final String sportsType;        // STRENGTH|RUNNING|WALKING|YOGA|CYCLING|SWIMMING|OTHER
  final int sportsDuration;
  final String sportsIntensity;   // LIGHT | MEDIUM | HIGH
  final String sportsLocation;    // GYM | HOME
  final String sportsFeeling;

  // ── Medical ─────────────────────────────────────────────────────────────────
  final String medicalMode;             // FIXED | PRN
  final List<TimeOfDay> medicalTimes;
  final int medicalStockCount;
  final int medicalRefillWarning;
  final int medicalMinIntervalHours;
  final int medicalMaxDosesPerDay;

  // ── Course ──────────────────────────────────────────────────────────────────
  final String courseType;            // VIDEO | BOOK | SKILL | CUSTOM
  final int courseTotalSessions;
  final int courseWeeklyTarget;
  final int courseSessionDuration;
  final List<int> coursePreferredDays;
  final TimeOfDay coursePreferredTime;

  // ── Goal ────────────────────────────────────────────────────────────────────
  final String goalType;          // DAILY | WEEKLY | LONG_TERM
  final DateTime goalTargetDate;
  final List<String> goalSteps;

  // ── Reflection ──────────────────────────────────────────────────────────────
  final int reflectionMood;
  final String reflectionWins;
  final String reflectionGratitude;
  final String reflectionLearnings;
  final bool reflectionIsPrivate;

  /// Helper used by worship and generic strategies.
  String formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  /// Helper to get "HH:mm" from a TimeOfDay.
  String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
