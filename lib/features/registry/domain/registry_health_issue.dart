// lib/features/registry/domain/registry_health_issue.dart

import 'package:flutter/material.dart';

enum HealthIssueKind {
  routineWithoutSchedule, // Inspector 1
  orphanReminder, // Inspector 2
  silentReminder, // Inspector 3
  expiredAlarm, // Inspector 4
  duplicateTitle, // Inspector 5
  orphanModuleData, // Inspector 6
  orphanSettingsKey, // Inspector 7
  invalidDuration, // Inspector 8
  chronicTimeConflict, // Inspector 9
}

enum HealthSeverity { info, warning, critical }

class RegistryHealthIssue {
  const RegistryHealthIssue({
    required this.kind,
    required this.severity,
    required this.title,
    required this.description,
    required this.fixLabel,
    this.affectedIds = const [],
    required this.fix,
  });

  final HealthIssueKind kind;
  final HealthSeverity severity;
  final String title;
  final String description;
  final String fixLabel;
  final List<String> affectedIds;
  final Future<void> Function(BuildContext context) fix;
}
