import 'dart:convert';

import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/engines/routine_occurrence_generator.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/domain/models.dart';
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

    await context.txn.update(
      'routines',
      command.routineData,
      where: 'id = ?',
      whereArgs: [id],
    );

    RecurrenceRule? rule;
    if (command.scheduleData != null) {
      await context.txn.update(
        'routine_schedules',
        command.scheduleData!,
        where: 'routineId = ?',
        whereArgs: [id],
      );

      final ruleMap =
          jsonDecode(command.scheduleData!['recurrenceRule'] as String? ?? '{}');
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
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed')",
      whereArgs: [id],
    );

    for (final pMap in pending) {
      final remId = pMap['id']! as String;
      tasks.add(() => sl<AlarmPlatform>().cancelAlarm(remId));
    }

    await context.txn.update(
      'pending_reminders',
      {
        'state': 'CANCELLED',
        'updatedAt': context.now.millisecondsSinceEpoch,
      },
      where: "routineId = ? AND (state = 'unknown' OR state = 'delayed')",
      whereArgs: [id],
    );

    if (rule != null) {
      if (command.applyToAll) {
        await context.txn.delete(
          'routine_occurrences',
          where: 'routine_id = ?',
          whereArgs: [id],
        );

        final today = DateTime(
          context.now.year,
          context.now.month,
          context.now.day,
        );

        for (var i = -30; i < 30; i++) {
          final targetDate = today.add(Duration(days: i));
          final dateStr = targetDate.toIso8601String().substring(0, 10);

          if (RoutineOccurrenceGenerator.shouldOccurOnDate(targetDate, rule)) {
            final timeStr =
                rule.reminderTimes.isNotEmpty ? rule.reminderTimes.first : '08:00';

            await context.txn.insert(
              'routine_occurrences',
              {
                'routine_id': id,
                'date': dateStr,
                'scheduled_time': timeStr,
                'status': 'pending',
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      } else {
        final todayStr = context.now.toIso8601String().substring(0, 10);

        await context.txn.delete(
          'routine_occurrences',
          where: 'routine_id = ? AND date >= ?',
          whereArgs: [id, todayStr],
        );

        await RoutineOccurrenceGenerator.generateFutureOccurrences(
          context.txn,
          id,
          rule,
        );
      }
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
