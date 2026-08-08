import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';

class TestAlarmHandler implements KernelCommandHandler<TestAlarmCommand> {
  const TestAlarmHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    TestAlarmCommand command,
  ) async {
    final nowMs = context.now.millisecondsSinceEpoch;
    final scheduledMs = nowMs + (command.secondsFromNow * 1000);
    final testId = 'test_alarm_$nowMs';
    final tasks = <Future<void> Function()>[];

    await context.txn.insert(
      'pending_reminders',
      {
        'id': testId,
        'routineId': 'test_routine',
        'scheduleId': 'test_schedule',
        'originalTime': scheduledMs,
        'scheduledTime': scheduledMs,
        'state': 'unknown',
        'deferCount': 0,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      },
    );

    tasks.add(() async {
      final ok = await sl<AlarmPlatform>().scheduleExactAlarm(
        id: testId,
        timeMsUTC: scheduledMs,
        title: '🧪 آلارم تست ریتمو',
        isEssential: true,
      );
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'pending_reminders',
        {'nativeScheduled': ok ? 1 : 0},
        where: 'id = ?',
        whereArgs: [testId],
      );
      RitmoLog.info('ALARM_TEST', 'Test alarm scheduled for +${command.secondsFromNow}s (success: $ok)');
      await SnapshotSyncService.syncAll();
    });

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineEdited(
          now: context.now,
          routineId: null,
          payload: {'testId': testId},
        ),
      ],
      postCommitTasks: tasks,
    );
  }
}
