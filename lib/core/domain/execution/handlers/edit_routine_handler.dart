import 'dart:convert';

import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/engines/routine_occurrence_generator.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/reminder_state.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:sqflite/sqflite.dart';

class EditRoutineHandler implements KernelCommandHandler<EditRoutineCommand> {
  const EditRoutineHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    EditRoutineCommand command,
  ) async {
    final id = command.routineId;
    final tasks = <Future<void> Function()>[];

    final routineMap = Map<String, dynamic>.from(command.routineData)..remove('id');

    await context.txn.update(
      'routines',
      routineMap,
      where: 'id = ?',
      whereArgs: [id],
    );

    RecurrenceRule? rule;
    if (command.scheduleData != null) {
      final scheduleMap = Map<String, dynamic>.from(command.scheduleData!)..remove('id');
      final updated = await context.txn.update(
        'routine_schedules',
        scheduleMap,
        where: 'routineId = ?',
        whereArgs: [id],
      );
      if (updated == 0) {
        // Upsert schedule row if missing (WU-17)
        final newSchedule = Map<String, dynamic>.from(command.scheduleData!)
          ..['id'] = command.scheduleData!['id'] ?? 'sched_$id'
          ..['routineId'] = id;
        await context.txn.insert('routine_schedules', newSchedule, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final ruleStr = command.scheduleData!['recurrenceRule'] as String? ?? '{}';
      final ruleMap = jsonDecode(ruleStr) as Map<String, dynamic>;
      rule = RecurrenceRule.fromMap(ruleMap);
    } else {
      final existingSchedules = await context.txn.query(
        'routine_schedules',
        where: 'routineId = ?',
        whereArgs: [id],
      );
      if (existingSchedules.isNotEmpty) {
        final ruleMap = jsonDecode(existingSchedules.first['recurrenceRule'] as String? ?? '{}');
        rule = RecurrenceRule.fromMap(ruleMap);
      }
    }

    final pending = await context.txn.query(
      'pending_reminders',
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed' OR state = 'active')",
      whereArgs: [id],
    );

    for (final pMap in pending) {
      final remId = pMap['id']! as String;
      tasks.add(() => sl<AlarmPlatform>().cancelAlarm(remId));
    }

    await context.txn.update(
      'pending_reminders',
      {
        'state': ReminderState.cancelled.dbValue,
        'updatedAt': context.now.millisecondsSinceEpoch,
      },
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed' OR state = 'active')",
      whereArgs: [id],
    );

    if (rule != null) {
      final todayStr = context.now.toIso8601String().substring(0, 10);

      // WU-10: Past and completed/skipped occurrences MUST NEVER be deleted!
      await context.txn.delete(
        'routine_occurrences',
        where: 'routine_id = ? AND date >= ? AND status = ?',
        whereArgs: [id, todayStr, 'pending'],
      );

      await RoutineOccurrenceGenerator.generateFutureOccurrences(
        context.txn,
        id,
        rule,
      );
    }

    tasks.add(SnapshotSyncService.syncAll);

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineEdited(
          now: context.now,
          routineId: id,
        ),
      ],
      postCommitTasks: tasks,
    );
  }
}
