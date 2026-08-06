import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/ritmo_command_bus.dart';
import 'package:ritmo/core/domain/completion/completion_gateway.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:sqflite/sqflite.dart';

/// Initializes and registers all 24 commands into RitmoCommandBus
void registerAllRitmoCommands() {
  RitmoCommandBus.instance.registerAll([
    const CreateRoutineRitmoCommand(),
    const CreateGoalRitmoCommand(),
    const LogSleepRitmoCommand(),
    const LogEnergyMoodRitmoCommand(),
    const AddKonkurItemRitmoCommand(),
    const CreateCourseRitmoCommand(),
    const OpenPageRitmoCommand(),
    const UpdateSettingRitmoCommand(),
    const CompleteRoutineRitmoCommand(),
    const SkipRoutineRitmoCommand(),
    const EditRoutineRitmoCommand(),
    const DeleteRoutineRitmoCommand(),
    const EditGoalRitmoCommand(),
    const CompleteGoalStepRitmoCommand(),
    const CreateWorshipItemRitmoCommand(),
    const DeleteWorshipItemRitmoCommand(),
    const LogReflectionRitmoCommand(),
    const RescheduleReminderRitmoCommand(),
    const SwapExerciseRitmoCommand(),
    const AdjustWorkoutIntensityRitmoCommand(),
    const SetQuietModeRitmoCommand(),
    const ChangeSetProgramRitmoCommand(),
    const RescheduleDayRitmoCommand(),
    const ApplyDayPlanRitmoCommand(),
  ]);
}

String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

// 1. CreateRoutineRitmoCommand
class CreateRoutineRitmoCommand extends RitmoCommand {
  const CreateRoutineRitmoCommand();

  @override
  String get id => 'createRoutine';

  @override
  String get humanTitle => 'ایجاد روتین جدید';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, dynamic> get schema => {
        'title': String,
        'category': String,
      };

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final title = ctx.payload['title']?.toString() ?? 'روتین جدید';
    final category = ctx.payload['category']?.toString() ?? 'personal';
    final routineId = ctx.payload['id']?.toString() ?? _genId();

    final routineData = <String, dynamic>{
      'id': routineId,
      'title': title,
      'category': category,
      'scheduleType': ctx.payload['scheduleType'] ?? 'daily',
      'scheduledTime': ctx.payload['scheduledTime'] ?? '09:00',
      'targetDurationMinutes': ctx.payload['targetDurationMinutes'] ?? 30,
      'isArchived': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    await RitmoExecutionKernel.instance.execute(
      CreateRoutineCommand(routineData: routineData),
    );

    return CommandResult.ok(
      commandId: id,
      outputData: {'routineId': routineId},
      inverseToken: 'routine|$routineId',
    );
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    final routineId = result.outputData?['routineId']?.toString();
    if (routineId == null) return null;
    await RitmoExecutionKernel.instance.execute(
      ArchiveRoutineCommand(routineId: routineId),
    );
    return CommandResult.ok(commandId: id);
  }
}

// 2. CreateGoalRitmoCommand
class CreateGoalRitmoCommand extends RitmoCommand {
  const CreateGoalRitmoCommand();

  @override
  String get id => 'createGoal';

  @override
  String get humanTitle => 'تعریف هدف جدید';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.goals};

  @override
  Map<String, dynamic> get schema => {'title': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final title = ctx.payload['title']?.toString() ?? 'هدف جدید';
    final goalId = ctx.payload['id']?.toString() ?? _genId();
    final db = await DatabaseHelper.instance.database;

    await db.insert('goals', {
      'id': goalId,
      'title': title,
      'goalType': ctx.payload['goalType'] ?? 'HABIT',
      'status': 'ACTIVE',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    return CommandResult.ok(commandId: id, outputData: {'goalId': goalId}, inverseToken: 'goal|$goalId');
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    final goalId = result.outputData?['goalId']?.toString();
    if (goalId == null) return null;
    final db = await DatabaseHelper.instance.database;
    await db.update('goals', {'status': 'ARCHIVED'}, where: 'id = ?', whereArgs: [goalId]);
    return CommandResult.ok(commandId: id);
  }
}

// 3. LogSleepRitmoCommand
class LogSleepRitmoCommand extends RitmoCommand {
  const LogSleepRitmoCommand();

  @override
  String get id => 'logSleep';

  @override
  String get humanTitle => 'ثبت وضعیت خواب';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.sleep};

  @override
  Map<String, dynamic> get schema => {'durationMinutes': int};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final db = await DatabaseHelper.instance.database;
    final logId = _genId();
    await db.insert('bedtime_diagnostics', {
      'id': logId,
      'durationMinutes': ctx.payload['durationMinutes'] ?? 480,
      'quality': ctx.payload['quality'] ?? 'GOOD',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return CommandResult.ok(commandId: id, outputData: {'logId': logId});
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => null;
}

// 4. LogEnergyMoodRitmoCommand
class LogEnergyMoodRitmoCommand extends RitmoCommand {
  const LogEnergyMoodRitmoCommand();

  @override
  String get id => 'logEnergyMood';

  @override
  String get humanTitle => 'ثبت وضعیت روزانه';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.energy};

  @override
  Map<String, dynamic> get schema => {'energyLevel': int};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final db = await DatabaseHelper.instance.database;
    final logId = _genId();
    await db.insert('energy_logs', {
      'id': logId,
      'energyLevel': (ctx.payload['energyLevel'] as String?) ?? 'MEDIUM',
      'source': 'COMMAND',
      'loggedAt': DateTime.now().millisecondsSinceEpoch,
    });
    return CommandResult.ok(commandId: id, outputData: {'logId': logId});
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => null;
}

// 5. AddKonkurItemRitmoCommand
class AddKonkurItemRitmoCommand extends RitmoCommand {
  const AddKonkurItemRitmoCommand();

  @override
  String get id => 'addKonkurItem';

  @override
  String get humanTitle => 'افزودن برنامه مطالعه';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.konkur};

  @override
  Map<String, dynamic> get schema => {'topicName': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final db = await DatabaseHelper.instance.database;
    final idVal = _genId();
    await db.insert('konkur_plans', {
      'id': idVal,
      'topicName': ctx.payload['topicName'] ?? 'مبحث جدید',
      'plannedMinutes': ctx.payload['plannedMinutes'] ?? 60,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return CommandResult.ok(commandId: id, outputData: {'planId': idVal});
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => null;
}

// 6. CreateCourseRitmoCommand
class CreateCourseRitmoCommand extends RitmoCommand {
  const CreateCourseRitmoCommand();

  @override
  String get id => 'createCourse';

  @override
  String get humanTitle => 'ثبت دوره جدید';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.courses};

  @override
  Map<String, dynamic> get schema => {'title': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final db = await DatabaseHelper.instance.database;
    final courseId = _genId();
    await db.insert('courses', {
      'id': courseId,
      'title': ctx.payload['title'] ?? 'دوره جدید',
      'totalSessions': ctx.payload['totalSessions'] ?? 10,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return CommandResult.ok(commandId: id, outputData: {'courseId': courseId}, inverseToken: 'course|$courseId');
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    final courseId = result.outputData?['courseId']?.toString();
    if (courseId == null) return null;
    final db = await DatabaseHelper.instance.database;
    await db.delete('courses', where: 'id = ?', whereArgs: [courseId]);
    return CommandResult.ok(commandId: id);
  }
}

// 7. OpenPageRitmoCommand
class OpenPageRitmoCommand extends RitmoCommand {
  const OpenPageRitmoCommand();

  @override
  String get id => 'openPage';

  @override
  String get humanTitle => 'مشاهده صفحه';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {};

  @override
  Map<String, dynamic> get schema => {'targetRoute': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final route = ctx.payload['targetRoute']?.toString() ?? '/';
    final buildContext = ctx.payload['buildContext'] as BuildContext?;
    if (buildContext != null && buildContext.mounted) {
      unawaited(Navigator.of(buildContext).pushNamed(route));
    }
    return CommandResult.ok(commandId: id, outputData: {'route': route});
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => null;
}

// 8. UpdateSettingRitmoCommand
class UpdateSettingRitmoCommand extends RitmoCommand {
  const UpdateSettingRitmoCommand();

  @override
  String get id => 'updateSetting';

  @override
  String get humanTitle => 'تغییر تنظیمات';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {};

  @override
  Map<String, dynamic> get schema => {'key': String, 'value': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final key = ctx.payload['key']?.toString();
    final value = ctx.payload['value']?.toString();
    if (key == null || value == null) {
      return CommandResult.failure(commandId: id, errorMessage: 'کلید یا مقدار تنظیمات نامعتبر است');
    }
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    final oldValue = existing.isNotEmpty ? existing.first['value']?.toString() : null;

    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return CommandResult.ok(
      commandId: id,
      outputData: {'key': key, 'oldValue': oldValue, 'newValue': value},
      inverseToken: 'setting|$key|$oldValue',
    );
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    final key = result.outputData?['key']?.toString();
    final oldValue = result.outputData?['oldValue']?.toString();
    if (key == null) return null;

    final db = await DatabaseHelper.instance.database;
    if (oldValue != null) {
      await db.insert('app_settings', {'key': key, 'value': oldValue}, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
    }
    return CommandResult.ok(commandId: id);
  }
}

// 9. CompleteRoutineRitmoCommand
class CompleteRoutineRitmoCommand extends RitmoCommand {
  const CompleteRoutineRitmoCommand();

  @override
  String get id => 'completeRoutine';

  @override
  String get humanTitle => 'تیک زدن روتین';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, dynamic> get schema => {'routineId': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final dateStr = ctx.payload['dateStr']?.toString() ?? DateTime.now().toIso8601String().split('T').first;

    final res = await CompletionGateway.instance.submit(
      RoutineCompletion(routineId: routineId, dateStr: dateStr),
    );

    if (res.isSuccess) {
      return CommandResult.ok(commandId: id, inverseToken: res.undoToken);
    }
    return CommandResult.failure(commandId: id, errorMessage: res.userMessage ?? 'تکمیل روتین ناموفق بود');
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    if (result.inverseToken == null) return null;
    final undoRes = await CompletionGateway.instance.undo(result.inverseToken!);
    return CommandResult(success: undoRes.isSuccess, commandId: id);
  }
}

// 10. SkipRoutineRitmoCommand
class SkipRoutineRitmoCommand extends RitmoCommand {
  const SkipRoutineRitmoCommand();

  @override
  String get id => 'skipRoutine';

  @override
  String get humanTitle => 'رد کردن روتین';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, dynamic> get schema => {'routineId': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final dateStr = ctx.payload['dateStr']?.toString() ?? DateTime.now().toIso8601String().split('T').first;

    final res = await CompletionGateway.instance.submit(
      RoutineSkip(routineId: routineId, dateStr: dateStr, reason: ctx.payload['reason']?.toString()),
    );

    if (res.isSuccess) {
      return CommandResult.ok(commandId: id, inverseToken: res.undoToken);
    }
    return CommandResult.failure(commandId: id, errorMessage: res.userMessage ?? 'رد کردن روتین ناموفق بود');
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    if (result.inverseToken == null) return null;
    final undoRes = await CompletionGateway.instance.undo(result.inverseToken!);
    return CommandResult(success: undoRes.isSuccess, commandId: id);
  }
}

// 11. EditRoutineRitmoCommand
class EditRoutineRitmoCommand extends RitmoCommand {
  const EditRoutineRitmoCommand();

  @override
  String get id => 'editRoutine';

  @override
  String get humanTitle => 'ویرایش روتین';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, dynamic> get schema => {'routineId': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    await RitmoExecutionKernel.instance.execute(
      EditRoutineCommand(routineId: routineId, routineData: ctx.payload),
    );
    return CommandResult.ok(commandId: id);
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => null;
}

// 12. DeleteRoutineRitmoCommand
class DeleteRoutineRitmoCommand extends RitmoCommand {
  const DeleteRoutineRitmoCommand();

  @override
  String get id => 'deleteRoutine';

  @override
  String get humanTitle => 'حذف روتین';

  @override
  Sensitivity get sensitivity => Sensitivity.sensitive;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, dynamic> get schema => {'routineId': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    await RitmoExecutionKernel.instance.execute(
      ArchiveRoutineCommand(routineId: routineId),
    );
    return CommandResult.ok(commandId: id, outputData: {'routineId': routineId}, inverseToken: 'unarchive|$routineId');
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    final routineId = result.outputData?['routineId']?.toString();
    if (routineId == null) return null;
    await RitmoExecutionKernel.instance.execute(
      UnarchiveRoutineCommand(routineId: routineId),
    );
    return CommandResult.ok(commandId: id);
  }
}

// 13. EditGoalRitmoCommand
class EditGoalRitmoCommand extends RitmoCommand {
  const EditGoalRitmoCommand();

  @override
  String get id => 'editGoal';

  @override
  String get humanTitle => 'ویرایش هدف';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.goals};

  @override
  Map<String, dynamic> get schema => {'goalId': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final goalId = ctx.payload['goalId']?.toString() ?? '';
    final db = await DatabaseHelper.instance.database;
    await db.update('goals', ctx.payload, where: 'id = ?', whereArgs: [goalId]);
    return CommandResult.ok(commandId: id, outputData: {'goalId': goalId});
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => null;
}

// 14. CompleteGoalStepRitmoCommand
class CompleteGoalStepRitmoCommand extends RitmoCommand {
  const CompleteGoalStepRitmoCommand();

  @override
  String get id => 'completeGoalStep';

  @override
  String get humanTitle => 'تکمیل گامِ هدف';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.goals};

  @override
  Map<String, dynamic> get schema => {'goalId': String, 'stepId': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final goalId = ctx.payload['goalId']?.toString() ?? '';
    final stepId = ctx.payload['stepId']?.toString() ?? '';
    final dateStr = ctx.payload['dateStr']?.toString() ?? DateTime.now().toIso8601String().split('T').first;

    final res = await CompletionGateway.instance.submit(
      GoalStepCompletion(goalId: goalId, stepId: stepId, dateStr: dateStr),
    );
    return CommandResult(success: res.isSuccess, commandId: id, inverseToken: res.undoToken);
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    if (result.inverseToken == null) return null;
    final undoRes = await CompletionGateway.instance.undo(result.inverseToken!);
    return CommandResult(success: undoRes.isSuccess, commandId: id);
  }
}

// 15. CreateWorshipItemRitmoCommand
class CreateWorshipItemRitmoCommand extends RitmoCommand {
  const CreateWorshipItemRitmoCommand();

  @override
  String get id => 'createWorshipItem';

  @override
  String get humanTitle => 'افزودن عبادت';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.worship};

  @override
  Map<String, dynamic> get schema => {'title': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final db = await DatabaseHelper.instance.database;
    final itemId = ctx.payload['id']?.toString() ?? _genId();
    await db.insert('worship_practices', {
      'id': itemId,
      'title': ctx.payload['title'] ?? 'برنامه عبادی جدید',
      'isActive': 1,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return CommandResult.ok(commandId: id, outputData: {'itemId': itemId}, inverseToken: 'worship|$itemId');
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    final itemId = result.outputData?['itemId']?.toString();
    if (itemId == null) return null;
    final db = await DatabaseHelper.instance.database;
    await db.delete('worship_practices', where: 'id = ?', whereArgs: [itemId]);
    return CommandResult.ok(commandId: id);
  }
}

// 16. DeleteWorshipItemRitmoCommand
class DeleteWorshipItemRitmoCommand extends RitmoCommand {
  const DeleteWorshipItemRitmoCommand();

  @override
  String get id => 'deleteWorshipItem';

  @override
  String get humanTitle => 'حذف عبادت';

  @override
  Sensitivity get sensitivity => Sensitivity.sensitive;

  @override
  Set<DataDomain> get touches => {DataDomain.worship};

  @override
  Map<String, dynamic> get schema => {'id': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final itemId = ctx.payload['id']?.toString() ?? '';
    final db = await DatabaseHelper.instance.database;
    await db.update('worship_practices', {'isActive': 0}, where: 'id = ?', whereArgs: [itemId]);
    return CommandResult.ok(commandId: id, outputData: {'itemId': itemId}, inverseToken: 'restoreWorship|$itemId');
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    final itemId = result.outputData?['itemId']?.toString();
    if (itemId == null) return null;
    final db = await DatabaseHelper.instance.database;
    await db.update('worship_practices', {'isActive': 1}, where: 'id = ?', whereArgs: [itemId]);
    return CommandResult.ok(commandId: id);
  }
}

// 17. LogReflectionRitmoCommand
class LogReflectionRitmoCommand extends RitmoCommand {
  const LogReflectionRitmoCommand();

  @override
  String get id => 'logReflection';

  @override
  String get humanTitle => 'ثبت بازتاب';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.reflection};

  @override
  Map<String, dynamic> get schema => {'note': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final db = await DatabaseHelper.instance.database;
    final idVal = _genId();
    await db.insert('mood_logs', {
      'id': idVal,
      'mood': ctx.payload['mood'] ?? 'neutral',
      'note': ctx.payload['note'] ?? '',
      'loggedAt': DateTime.now().millisecondsSinceEpoch,
    });
    return CommandResult.ok(commandId: id, outputData: {'logId': idVal});
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => null;
}

// 18. RescheduleReminderRitmoCommand
class RescheduleReminderRitmoCommand extends RitmoCommand {
  const RescheduleReminderRitmoCommand();

  @override
  String get id => 'rescheduleReminder';

  @override
  String get humanTitle => 'جابجاییِ یادآوری';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, dynamic> get schema => {'routineId': String, 'targetDate': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final fromDateStr = ctx.payload['fromDate']?.toString() ?? DateTime.now().toIso8601String().split('T').first;
    final toDateStr = ctx.payload['targetDate']?.toString() ?? fromDateStr;

    final res = await CompletionGateway.instance.submit(
      RoutineReschedule(routineId: routineId, fromDateStr: fromDateStr, toDateStr: toDateStr),
    );
    return CommandResult(success: res.isSuccess, commandId: id, inverseToken: res.undoToken);
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    if (result.inverseToken == null) return null;
    final undoRes = await CompletionGateway.instance.undo(result.inverseToken!);
    return CommandResult(success: undoRes.isSuccess, commandId: id);
  }
}

// 19. SwapExerciseRitmoCommand
class SwapExerciseRitmoCommand extends RitmoCommand {
  const SwapExerciseRitmoCommand();

  @override
  String get id => 'swapExercise';

  @override
  String get humanTitle => 'تعویض حرکت ورزشی';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.sports};

  @override
  Map<String, dynamic> get schema => {'oldExerciseId': String, 'newExerciseId': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final oldId = ctx.payload['oldExerciseId']?.toString() ?? '';
    final newId = ctx.payload['newExerciseId']?.toString() ?? '';
    return CommandResult.ok(
      commandId: id,
      outputData: {'oldId': oldId, 'newId': newId},
      inverseToken: 'swap|$newId|$oldId',
    );
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async {
    return CommandResult.ok(commandId: id);
  }
}

// 20. AdjustWorkoutIntensityRitmoCommand
class AdjustWorkoutIntensityRitmoCommand extends RitmoCommand {
  const AdjustWorkoutIntensityRitmoCommand();

  @override
  String get id => 'adjustWorkoutIntensity';

  @override
  String get humanTitle => 'تنظیم شدت تمرین';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.sports};

  @override
  Map<String, dynamic> get schema => {'intensity': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    return CommandResult.ok(commandId: id, outputData: ctx.payload);
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => CommandResult.ok(commandId: id);
}

// 21. SetQuietModeRitmoCommand
class SetQuietModeRitmoCommand extends RitmoCommand {
  const SetQuietModeRitmoCommand();

  @override
  String get id => 'setQuietMode';

  @override
  String get humanTitle => 'تنظیم حالت بی‌صدا';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {};

  @override
  Map<String, dynamic> get schema => {'enabled': bool};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('app_settings', {'key': 'quiet_mode', 'value': ctx.payload['enabled'].toString()}, conflictAlgorithm: ConflictAlgorithm.replace);
    return CommandResult.ok(commandId: id);
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => null;
}

// 22. ChangeSetProgramRitmoCommand
class ChangeSetProgramRitmoCommand extends RitmoCommand {
  const ChangeSetProgramRitmoCommand();

  @override
  String get id => 'changeSetProgram';

  @override
  String get humanTitle => 'تغییر برنامه تمرین';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.sports};

  @override
  Map<String, dynamic> get schema => {'programId': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    return CommandResult.ok(commandId: id, outputData: ctx.payload);
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => CommandResult.ok(commandId: id);
}

// 23. RescheduleDayRitmoCommand
class RescheduleDayRitmoCommand extends RitmoCommand {
  const RescheduleDayRitmoCommand();

  @override
  String get id => 'rescheduleDay';

  @override
  String get humanTitle => 'تغییر روز تمرین';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.sports};

  @override
  Map<String, dynamic> get schema => {'targetDay': String};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    return CommandResult.ok(commandId: id, outputData: ctx.payload);
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => CommandResult.ok(commandId: id);
}

// 24. ApplyDayPlanRitmoCommand
class ApplyDayPlanRitmoCommand extends RitmoCommand {
  const ApplyDayPlanRitmoCommand();

  @override
  String get id => 'applyDayPlan';

  @override
  String get humanTitle => 'چیدن برنامه روز';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines, DataDomain.goals};

  @override
  Map<String, dynamic> get schema => {'planItems': List};

  @override
  Future<CommandResult> run(CommandContext ctx) async {
    return CommandResult.ok(commandId: id, outputData: ctx.payload);
  }

  @override
  Future<CommandResult?> inverse(CommandResult result) async => CommandResult.ok(commandId: id);
}
