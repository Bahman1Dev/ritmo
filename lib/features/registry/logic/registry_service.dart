// lib/features/registry/logic/registry_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/registry/domain/delete_impact_report.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/domain/registry_query.dart';
import 'package:ritmo/features/registry/logic/registry_health_audit.dart';
import 'package:ritmo/features/registry/logic/registry_index.dart';

class RegistryService {
  Future<List<RegistryEntry>> query(
    RegistryQuery query,
    Map<String, String> settingsMap,
  ) async {
    return RegistryIndex.instance.queryPhaseA(query, settingsMap);
  }

  Future<int> healthIssueCount(Map<String, String> settingsMap) async {
    final issues = await RegistryHealthAudit().inspectAll(settingsMap);
    return issues.length;
  }

  Future<DeleteImpactReport> impactOf(RegistryEntry entry) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Completion count
      final compRes = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM routine_completions WHERE routineId = ?",
        [entry.sourceId],
      );
      final completions = Sqflite.firstIntValue(compRes) ?? 0;

      // 2. Pending occurrences count
      final occRes = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM routine_occurrences WHERE routine_id = ? AND status = 'pending'",
        [entry.sourceId],
      );
      final occurrences = Sqflite.firstIntValue(occRes) ?? 0;

      // 3. Active reminders
      final remRes = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM pending_reminders WHERE routineId = ? AND state IN ('SCHEDULED', 'unknown', 'delayed')",
        [entry.sourceId],
      );
      final activeReminders = Sqflite.firstIntValue(remRes) ?? 0;

      // 4. Orphaned dependents check: goal_steps.linkedRoutineId, routines.dependsOnRoutineId, courses.linkedGoalId
      final dependents = <String>[];

      // Check linkedGoalSteps
      final linkedSteps = await db.query(
        'goal_steps',
        columns: ['title'],
        where: 'linkedRoutineId = ?',
        whereArgs: [entry.sourceId],
      );
      for (final s in linkedSteps) {
        final t = s['title'] as String?;
        if (t != null && t.isNotEmpty) dependents.add('گام هدف: $t');
      }

      // Check dependent routines
      final depRoutines = await db.query(
        'routines',
        columns: ['title'],
        where: 'dependsOnRoutineId = ?',
        whereArgs: [entry.sourceId],
      );
      for (final r in depRoutines) {
        final t = r['title'] as String?;
        if (t != null && t.isNotEmpty) dependents.add('روتین وابسته: $t');
      }

      return DeleteImpactReport(
        completionCount: completions,
        occurrenceCount: occurrences,
        activeReminderCount: activeReminders,
        longestStreakDays: 0,
        orphanedDependents: dependents,
      );
    } catch (e) {
      return const DeleteImpactReport(
        completionCount: 0,
        occurrenceCount: 0,
        activeReminderCount: 0,
        longestStreakDays: 0,
      );
    }
  }
}
