import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:sqflite/sqflite.dart';

class RescheduleOccurrenceHandler
    implements KernelCommandHandler<RescheduleOccurrenceCommand> {
  const RescheduleOccurrenceHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    RescheduleOccurrenceCommand command,
  ) async {
    final nowMs = context.now.millisecondsSinceEpoch;
    final undoId = 'comp_${command.routineId}_$nowMs';

    final existingTarget = await context.txn.query(
      'routine_occurrences',
      where: 'routine_id = ? AND date = ?',
      whereArgs: [command.routineId, command.toDateStr],
    );

    if (existingTarget.isNotEmpty) {
      await context.txn.rawUpdate('''
        UPDATE routine_occurrences 
        SET status = 'rescheduled'
        WHERE routine_id = ? AND date = ?
      ''', [command.routineId, command.fromDateStr]);

      await context.txn.insert('routine_completions', {
        'id': undoId,
        'routineId': command.routineId,
        'completionDate': command.fromDateStr,
        'completionTime': nowMs,
        'resultType': 'RESCHEDULED',
        'reason': command.reason,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });

      try {
        await context.txn.insert('skip_reasons', {
          'id': 'skip_$nowMs',
          'itemId': command.routineId,
          'domain': 'routine',
          'dateStr': command.fromDateStr,
          'reason': command.reason ?? 'موکول شد به فردا',
          'note': null,
          'createdAt': nowMs,
        });
      } catch (e) {
        // Log skip reason insert warning
      }

      return KernelMutationResult(
        domainEvents: [
          KernelEventFactory.routineEdited(now: context.now, routineId: command.routineId),
        ],
      );
    }

    String? scheduledTime;
    final todayRows = await context.txn.query(
      'routine_occurrences',
      where: 'routine_id = ? AND date = ?',
      whereArgs: [command.routineId, command.fromDateStr],
    );
    if (todayRows.isNotEmpty) {
      scheduledTime = todayRows.first['scheduled_time']?.toString();
    }

    await context.txn.rawUpdate('''
      UPDATE routine_occurrences 
      SET status = 'rescheduled'
      WHERE routine_id = ? AND date = ?
    ''', [command.routineId, command.fromDateStr]);

    await context.txn.insert('routine_occurrences', {
      'routine_id': command.routineId,
      'date': command.toDateStr,
      'status': 'pending',
      'scheduled_time': scheduledTime ?? '08:00',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    try {
      await context.txn.insert('skip_reasons', {
        'id': 'skip_$nowMs',
        'itemId': command.routineId,
        'domain': 'routine',
        'dateStr': command.fromDateStr,
        'reason': command.reason ?? 'موکول شد به فردا',
        'note': null,
        'createdAt': nowMs,
      });
    } catch (e) {
      // Log skip reason insert warning
    }

    await context.txn.insert('routine_completions', {
      'id': undoId,
      'routineId': command.routineId,
      'completionDate': command.fromDateStr,
      'completionTime': nowMs,
      'resultType': 'RESCHEDULED',
      'reason': command.reason,
      'createdAt': nowMs,
      'updatedAt': nowMs,
    });

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineEdited(now: context.now, routineId: command.routineId),
      ],
    );
  }
}
