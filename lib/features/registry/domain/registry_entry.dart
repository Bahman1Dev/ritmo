// lib/features/registry/domain/registry_entry.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';

enum RegistryDomain {
  routine,
  course,
  goal,
  worship,
  worshipDebt,
  medicine,
  konkur,
  movementKind,
  workoutPlan,
  doctorVisit,
}

extension RegistryDomainX on RegistryDomain {
  String get faLabel {
    switch (this) {
      case RegistryDomain.routine:
        return 'روتین';
      case RegistryDomain.course:
        return 'دوره';
      case RegistryDomain.goal:
        return 'هدف';
      case RegistryDomain.worship:
        return 'عبادت';
      case RegistryDomain.worshipDebt:
        return 'بدهی عبادی';
      case RegistryDomain.medicine:
        return 'دارو';
      case RegistryDomain.konkur:
        return 'کنکور';
      case RegistryDomain.movementKind:
        return 'حرکت';
      case RegistryDomain.workoutPlan:
        return 'برنامه تمرین';
      case RegistryDomain.doctorVisit:
        return 'نوبت پزشک';
    }
  }

  IconData get icon {
    switch (this) {
      case RegistryDomain.routine:
        return Icons.sync_rounded;
      case RegistryDomain.worship:
      case RegistryDomain.worshipDebt:
        return Icons.mosque_rounded;
      case RegistryDomain.course:
        return Icons.school_rounded;
      case RegistryDomain.goal:
        return Icons.track_changes_rounded;
      case RegistryDomain.konkur:
        return Icons.assignment_rounded;
      case RegistryDomain.medicine:
        return Icons.medication_rounded;
      case RegistryDomain.movementKind:
      case RegistryDomain.workoutPlan:
        return Icons.fitness_center_rounded;
      case RegistryDomain.doctorVisit:
        return Icons.local_hospital_rounded;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case RegistryDomain.routine:
        return Colors.teal.shade600;
      case RegistryDomain.course:
        return Colors.amber.shade700;
      case RegistryDomain.goal:
        return Colors.deepPurple.shade600;
      case RegistryDomain.worship:
      case RegistryDomain.worshipDebt:
        return Colors.indigo.shade600;
      case RegistryDomain.medicine:
        return Colors.orange.shade700;
      case RegistryDomain.konkur:
        return Colors.red.shade600;
      case RegistryDomain.movementKind:
      case RegistryDomain.workoutPlan:
        return Colors.green.shade600;
      case RegistryDomain.doctorVisit:
        return Colors.orange.shade700;
    }
  }

  String get settingsKey {
    switch (this) {
      case RegistryDomain.course:
        return 'module_courses_enabled';
      case RegistryDomain.goal:
        return 'module_goals_enabled';
      case RegistryDomain.worship:
      case RegistryDomain.worshipDebt:
        return 'module_worship_enabled';
      case RegistryDomain.medicine:
        return 'module_health_enabled';
      case RegistryDomain.konkur:
        return 'module_konkur_enabled';
      case RegistryDomain.movementKind:
      case RegistryDomain.workoutPlan:
        return 'module_supplementary_sports_enabled';
      case RegistryDomain.doctorVisit:
        return 'module_health_enabled';
      case RegistryDomain.routine:
        return ''; // Always enabled
    }
  }
}

enum RegistryStatus { active, paused, archived, completed, expired }

enum ReminderHealth {
  off, // 🔕 Reminder off
  armed, // 🔔 Armed and has future SCHEDULED record
  silent, // ⚠️ Enabled but no SCHEDULED record found
  overdue, // 🔴 Past scheduled time still in unknown state
}

class RegistryCapabilities {
  final bool canEdit;
  final bool canDelete;
  final bool canArchive;
  final bool canPause;
  final bool canToggleReminder;
  final bool canDuplicate;

  const RegistryCapabilities({
    this.canEdit = true,
    this.canDelete = true,
    this.canArchive = true,
    this.canPause = true,
    this.canToggleReminder = true,
    this.canDuplicate = true,
  });

  /// Mandatory worship practices & system defaults: no action allowed except setting reminder
  const RegistryCapabilities.systemGenerated()
      : canEdit = false,
        canDelete = false,
        canArchive = false,
        canPause = false,
        canToggleReminder = true,
        canDuplicate = false;
}

class RegistryEntry {
  const RegistryEntry({
    required this.id,
    required this.domain,
    required this.sourceId,
    required this.title,
    this.subtitle,
    required this.scheduleSummary,
    this.nextRunDateStr,
    this.status = RegistryStatus.active,
    this.reminderHealth = ReminderHealth.off,
    this.streakDays,
    this.completionRate30d,
    this.isEssential = false,
    this.caps = const RegistryCapabilities(),
    required this.agendaProxy,
    this.meta = const {},
  });

  final String id; // e.g. 'routine:rt_abc'
  final RegistryDomain domain;
  final String sourceId;
  final String title;
  final String? subtitle;
  final String scheduleSummary;
  final String? nextRunDateStr; // 'YYYY-MM-DD' or null
  final RegistryStatus status;
  final ReminderHealth reminderHealth;
  final int? streakDays;
  final double? completionRate30d; // 0.0..1.0
  final bool isEssential;
  final RegistryCapabilities caps;
  final AgendaItem agendaProxy;
  final Map<String, dynamic> meta;

  RegistryEntry copyWith({
    int? streakDays,
    double? completionRate30d,
    RegistryStatus? status,
    ReminderHealth? reminderHealth,
    String? nextRunDateStr,
  }) {
    return RegistryEntry(
      id: id,
      domain: domain,
      sourceId: sourceId,
      title: title,
      subtitle: subtitle,
      scheduleSummary: scheduleSummary,
      nextRunDateStr: nextRunDateStr ?? this.nextRunDateStr,
      status: status ?? this.status,
      reminderHealth: reminderHealth ?? this.reminderHealth,
      streakDays: streakDays ?? this.streakDays,
      completionRate30d: completionRate30d ?? this.completionRate30d,
      isEssential: isEssential,
      caps: caps,
      agendaProxy: agendaProxy,
      meta: meta,
    );
  }
}
