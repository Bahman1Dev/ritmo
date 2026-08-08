import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/param_spec.dart';
import 'package:ritmo/core/domain/commands/command_plan.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/completion/snooze_policy.dart';
import 'package:ritmo/features/routines/presentation/quick_add_parser.dart';
import 'package:ritmo/core/database/database_helper.dart';

String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

class RoutineCreateCommand extends RitmoCommand {
  const RoutineCreateCommand();

  @override
  String get id => 'routine.create';

  @override
  String get humanTitle => 'ایجاد روتین جدید';

  @override
  String get humanDescriptionFa => 'تعریف یک روتین یا عادت جدید روزانه یا هفتگی';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'title': const ParamSpec(
      type: ParamType.text,
      labelFa: 'عنوان روتین',
      required: true,
      exampleFa: 'مطالعه کتاب',
    ),
    'category': const ParamSpec(
      type: ParamType.text,
      labelFa: 'دسته‌بندی',
      required: false,
      exampleFa: 'personal',
    ),
    'scheduleType': const ParamSpec(
      type: ParamType.enumeration,
      labelFa: 'نوع زمان‌بندی',
      required: false,
      allowed: ['daily', 'weekly', 'custom_days'],
    ),
    'scheduledTime': const ParamSpec(
      type: ParamType.timeOfDay,
      labelFa: 'ساعت یادآوری',
      required: false,
      exampleFa: '09:00',
    ),
    'targetDurationMinutes': const ParamSpec(
      type: ParamType.integer,
      labelFa: 'مدت زمان هدف (دقیقه)',
      required: false,
      exampleFa: '30',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final title = ctx.payload['title']?.toString() ?? 'روتین جدید';
    return PlanDiff(kind: DiffKind.create, entityLabelFa: 'روتین: $title');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final title = ctx.payload['title']?.toString() ?? 'روتین جدید';
    final category = ctx.payload['category']?.toString() ?? 'personal';
    final routineId = ctx.payload['id']?.toString() ?? _genId();
    final scheduleType = ctx.payload['scheduleType']?.toString() ?? 'daily';
    final scheduledTime = ctx.payload['scheduledTime']?.toString() ?? '09:00';
    final targetDurationMinutes = ctx.payload['targetDurationMinutes'] as int? ?? 30;

    final routineData = <String, dynamic>{
      'id': routineId,
      'title': title,
      'category': category,
      'routineType': 'ROUTINE',
      'notificationLevel': 'NORMAL',
      'isEssential': 0,
      'priority': 1.0,
      'targetDurationMinutes': targetDurationMinutes,
      'isArchived': 0,
      'isPrivate': 0,
      'displayOrder': 99,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    final scheduleData = <String, dynamic>{
      'id': 'sched_$routineId',
      'routineId': routineId,
      'scheduleType': scheduleType.toUpperCase(),
      'timeOfDay': scheduledTime,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      CreateRoutineCommand(routineData: routineData, scheduleData: scheduleData),
      txn: txn,
    );

    return CommandResult.ok(
      commandId: id,
      outputData: {'routineId': routineId},
      inverseData: {'routineId': routineId},
    );
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final routineId = inverseData['routineId']?.toString();
    if (routineId == null) return null;
    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      ArchiveRoutineCommand(routineId: routineId),
      txn: txn,
    );
    return CommandResult.ok(commandId: id);
  }
}

class RoutineCreateFromPhraseCommand extends RitmoCommand {
  const RoutineCreateFromPhraseCommand();

  @override
  String get id => 'routine.createFromPhrase';

  @override
  String get humanTitle => 'ایجاد روتین با متن آزاد';

  @override
  String get humanDescriptionFa => 'تحلیل و تعریف روتین جدید از روی یک جمله فارسی آزاد';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'phrase': const ParamSpec(
      type: ParamType.text,
      labelFa: 'عبارت فارسی روتین',
      required: true,
      exampleFa: 'هر روز ساعت ۹ صبح کتاب بخوانم به مدت نیم ساعت',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final phrase = ctx.payload['phrase']?.toString() ?? '';
    final parsed = QuickAddParser.parse(phrase);
    return PlanDiff(kind: DiffKind.create, entityLabelFa: 'روتین (متنی): ${parsed.title}');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final phrase = ctx.payload['phrase']?.toString() ?? '';
    final parsed = QuickAddParser.parse(phrase);
    
    final routineId = ctx.payload['id']?.toString() ?? _genId();
    final routineData = {
      'id': routineId,
      'title': parsed.title,
      'category': 'personal',
      'routineType': 'ROUTINE',
      'notificationLevel': 'NORMAL',
      'isEssential': 0,
      'priority': 1.0,
      'targetDurationMinutes': parsed.targetDurationMinutes ?? 30,
      'isArchived': 0,
      'isPrivate': 0,
      'displayOrder': 99,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    final scheduleData = {
      'id': 'sched_$routineId',
      'routineId': routineId,
      'scheduleType': parsed.recurrenceType == 'WORKDAYS' ? 'WORKDAYS' : 'DAILY',
      'timeOfDay': parsed.timeOfDay != null 
          ? '${parsed.timeOfDay!.hour.toString().padLeft(2, '0')}:${parsed.timeOfDay!.minute.toString().padLeft(2, '0')}' 
          : '09:00',
      'daysOfWeek': parsed.weekdays?.join(','),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      CreateRoutineCommand(routineData: routineData, scheduleData: scheduleData),
      txn: txn,
    );

    return CommandResult.ok(commandId: id, outputData: {'routineId': routineId}, inverseData: {'routineId': routineId});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final routineId = inverseData['routineId']?.toString();
    if (routineId == null) return null;
    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      ArchiveRoutineCommand(routineId: routineId),
      txn: txn,
    );
    return CommandResult.ok(commandId: id);
  }
}

class RoutineEditCommand extends RitmoCommand {
  const RoutineEditCommand();

  @override
  String get id => 'routine.edit';

  @override
  String get humanTitle => 'ویرایش روتین';

  @override
  String get humanDescriptionFa => 'تغییر عنوان یا تنظیمات زمان‌بندی یک روتین موجود';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'روتین',
      required: true,
      refTable: 'routines',
    ),
    'title': const ParamSpec(
      type: ParamType.text,
      labelFa: 'عنوان جدید روتین',
      required: false,
    ),
    'scheduledTime': const ParamSpec(
      type: ParamType.timeOfDay,
      labelFa: 'ساعت یادآوری جدید',
      required: false,
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final rows = await ctx.txn.query('routines', columns: ['title'], where: 'id = ?', whereArgs: [routineId]);
    final oldTitle = rows.isNotEmpty ? rows.first['title']?.toString() : 'روتین نامشخص';
    final newTitle = ctx.payload['title']?.toString() ?? oldTitle;
    return PlanDiff(
      kind: DiffKind.update,
      entityLabelFa: 'روتین: $oldTitle',
      beforeFa: oldTitle,
      afterFa: newTitle,
    );
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    
    // Save old state for inverse
    final oldRoutines = await ctx.txn.query('routines', where: 'id = ?', whereArgs: [routineId]);
    final oldSchedules = await ctx.txn.query('routine_schedules', where: 'routineId = ?', whereArgs: [routineId]);
    
    if (oldRoutines.isEmpty) {
      return CommandResult.failure(commandId: id, errorMessage: 'روتین یافت نشد.');
    }

    final routineMap = <String, dynamic>{};
    if (ctx.payload['title'] != null) routineMap['title'] = ctx.payload['title'];
    routineMap['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

    final scheduleMap = <String, dynamic>{};
    if (ctx.payload['scheduledTime'] != null) scheduleMap['timeOfDay'] = ctx.payload['scheduledTime'];
    scheduleMap['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      EditRoutineCommand(
        routineId: routineId,
        routineData: routineMap,
        scheduleData: scheduleMap.isNotEmpty ? scheduleMap : null,
      ),
      txn: txn,
    );

    return CommandResult.ok(
      commandId: id,
      inverseData: {
        'routineId': routineId,
        'oldRoutine': oldRoutines.first,
        'oldSchedule': oldSchedules.isNotEmpty ? oldSchedules.first : null,
      },
    );
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final routineId = inverseData['routineId']?.toString();
    final oldRoutine = inverseData['oldRoutine'] as Map<String, dynamic>?;
    final oldSchedule = inverseData['oldSchedule'] as Map<String, dynamic>?;
    if (routineId == null || oldRoutine == null) return null;

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      EditRoutineCommand(
        routineId: routineId,
        routineData: Map<String, dynamic>.from(oldRoutine),
        scheduleData: oldSchedule != null ? Map<String, dynamic>.from(oldSchedule) : null,
      ),
      txn: txn,
    );
    return CommandResult.ok(commandId: id);
  }
}

class RoutineArchiveCommand extends RitmoCommand {
  const RoutineArchiveCommand();

  @override
  String get id => 'routine.archive';

  @override
  String get humanTitle => 'آرشیو روتین';

  @override
  String get humanDescriptionFa => 'بایگانی کردن یک روتین تا موقتاً غیرفعال شود';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'روتین',
      required: true,
      refTable: 'routines',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final rows = await ctx.txn.query('routines', columns: ['title'], where: 'id = ?', whereArgs: [routineId]);
    final title = rows.isNotEmpty ? rows.first['title']?.toString() : 'روتین نامشخص';
    return PlanDiff(kind: DiffKind.delete, entityLabelFa: 'آرشیو روتین: $title');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      ArchiveRoutineCommand(routineId: routineId),
      txn: txn,
    );
    return CommandResult.ok(commandId: id, inverseData: {'routineId': routineId});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final routineId = inverseData['routineId']?.toString();
    if (routineId == null) return null;
    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      UnarchiveRoutineCommand(routineId: routineId),
      txn: txn,
    );
    return CommandResult.ok(commandId: id);
  }
}

class RoutineDeleteCommand extends RitmoCommand {
  const RoutineDeleteCommand();

  @override
  String get id => 'routine.delete';

  @override
  String get humanTitle => 'حذف روتین';

  @override
  String get humanDescriptionFa => 'حذف کامل روتین به همراه زمان‌بندی‌های آن از برنامه';

  @override
  Sensitivity get sensitivity => Sensitivity.sensitive;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'روتین',
      required: true,
      refTable: 'routines',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final rows = await ctx.txn.query('routines', columns: ['title'], where: 'id = ?', whereArgs: [routineId]);
    final title = rows.isNotEmpty ? rows.first['title']?.toString() : 'روتین نامشخص';
    return PlanDiff(kind: DiffKind.delete, entityLabelFa: 'حذف کامل روتین: $title');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    
    // Save state for undo
    final oldRoutines = await ctx.txn.query('routines', where: 'id = ?', whereArgs: [routineId]);
    final oldSchedules = await ctx.txn.query('routine_schedules', where: 'routineId = ?', whereArgs: [routineId]);
    
    if (oldRoutines.isEmpty) {
      return CommandResult.failure(commandId: id, errorMessage: 'روتین یافت نشد.');
    }

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      DeleteRoutineCommand(routineId: routineId),
      txn: txn,
    );

    return CommandResult.ok(
      commandId: id,
      inverseData: {
        'routineId': routineId,
        'oldRoutine': oldRoutines.first,
        'oldSchedule': oldSchedules.isNotEmpty ? oldSchedules.first : null,
      },
    );
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final routineId = inverseData['routineId']?.toString();
    final oldRoutine = inverseData['oldRoutine'] as Map<String, dynamic>?;
    final oldSchedule = inverseData['oldSchedule'] as Map<String, dynamic>?;
    if (routineId == null || oldRoutine == null) return null;

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      CreateRoutineCommand(
        routineData: Map<String, dynamic>.from(oldRoutine),
        scheduleData: oldSchedule != null ? Map<String, dynamic>.from(oldSchedule) : null,
      ),
      txn: txn,
    );
    return CommandResult.ok(commandId: id);
  }
}

class RoutineCompleteCommand extends RitmoCommand {
  const RoutineCompleteCommand();

  @override
  String get id => 'routine.complete';

  @override
  String get humanTitle => 'انجام روتین';

  @override
  String get humanDescriptionFa => 'تیک زدن و ثبت موفق روتین برای امروز یا یک روز خاص';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'روتین',
      required: true,
      refTable: 'routines',
    ),
    'dateStr': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'تاریخ انجام',
      required: false,
      exampleFa: '2026-08-08',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final rows = await ctx.txn.query('routines', columns: ['title'], where: 'id = ?', whereArgs: [routineId]);
    final title = rows.isNotEmpty ? rows.first['title']?.toString() : 'روتین نامشخص';
    return PlanDiff(kind: DiffKind.update, entityLabelFa: 'انجام روتین: $title');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final dateStr = ctx.payload['dateStr']?.toString() ?? DateTime.now().toIso8601String().split('T').first;
    final resultSource = ctx.source == CommandSource.assistant ? 'ASSISTANT' : 'USER';

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      CompleteOccurrenceCommand(
        routineId: routineId,
        dateStr: dateStr,
        resultType: 'FULL',
        durationMinutes: 30,
        resultSource: resultSource,
      ),
      txn: txn,
    );

    final undoToken = 'routine:$routineId|$dateStr';
    return CommandResult.ok(commandId: id, inverseData: {'undoToken': undoToken});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final undoToken = inverseData['undoToken']?.toString();
    if (undoToken == null) return null;
    final parts = undoToken.split(':');
    if (parts.length < 2) return null;
    final idPayload = parts.sublist(1).join(':');
    final rParts = idPayload.split('|');
    final rId = rParts[0];
    final dateStr = rParts.length >= 2 ? rParts[1] : '';

    await ctx.txn.delete('routine_completions', where: 'routineId = ? AND completionDate = ?', whereArgs: [rId, dateStr]);
    await ctx.txn.delete('skip_reasons', where: 'itemId = ? AND dateStr = ?', whereArgs: [rId, dateStr]);
    await ctx.txn.rawUpdate('''
      UPDATE routine_occurrences 
      SET status = 'pending'
      WHERE routine_id = ? AND date = ?
    ''', [rId, dateStr]);

    return CommandResult.ok(commandId: id);
  }
}

class RoutineSkipCommand extends RitmoCommand {
  const RoutineSkipCommand();

  @override
  String get id => 'routine.skip';

  @override
  String get humanTitle => 'رد کردن روتین';

  @override
  String get humanDescriptionFa => 'رد کردن موقت انجام روتین برای امروز به همراه دلیل';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'روتین',
      required: true,
      refTable: 'routines',
    ),
    'dateStr': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'تاریخ رد کردن',
      required: false,
    ),
    'reason': const ParamSpec(
      type: ParamType.text,
      labelFa: 'دلیل رد کردن',
      required: false,
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final rows = await ctx.txn.query('routines', columns: ['title'], where: 'id = ?', whereArgs: [routineId]);
    final title = rows.isNotEmpty ? rows.first['title']?.toString() : 'روتین نامشخص';
    return PlanDiff(kind: DiffKind.update, entityLabelFa: 'رد کردن روتین: $title');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final dateStr = ctx.payload['dateStr']?.toString() ?? DateTime.now().toIso8601String().split('T').first;
    final reason = ctx.payload['reason']?.toString();

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      SkipOccurrenceCommand(
        routineId: routineId,
        dateStr: dateStr,
        reason: reason,
      ),
      txn: txn,
    );

    final undoToken = 'routine:$routineId|$dateStr';
    return CommandResult.ok(commandId: id, inverseData: {'undoToken': undoToken});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final undoToken = inverseData['undoToken']?.toString();
    if (undoToken == null) return null;
    final parts = undoToken.split(':');
    if (parts.length < 2) return null;
    final idPayload = parts.sublist(1).join(':');
    final rParts = idPayload.split('|');
    final rId = rParts[0];
    final dateStr = rParts.length >= 2 ? rParts[1] : '';

    await ctx.txn.delete('routine_completions', where: 'routineId = ? AND completionDate = ?', whereArgs: [rId, dateStr]);
    await ctx.txn.delete('skip_reasons', where: 'itemId = ? AND dateStr = ?', whereArgs: [rId, dateStr]);
    await ctx.txn.rawUpdate('''
      UPDATE routine_occurrences 
      SET status = 'pending'
      WHERE routine_id = ? AND date = ?
    ''', [rId, dateStr]);

    return CommandResult.ok(commandId: id);
  }
}

class RoutineSnoozeCommand extends RitmoCommand {
  const RoutineSnoozeCommand();

  @override
  String get id => 'routine.snooze';

  @override
  String get humanTitle => 'تعویق یادآوری روتین';

  @override
  String get humanDescriptionFa => 'عقب انداختن ساعت اعلان یک روتین بر اساس محدودیت‌های خواب و شخصی';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'روتین',
      required: true,
      refTable: 'routines',
    ),
    'dateStr': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'تاریخ تعویق',
      required: false,
    ),
    'snoozeMinutes': const ParamSpec(
      type: ParamType.integer,
      labelFa: 'مدت زمان تعویق (دقیقه)',
      required: true,
      exampleFa: '15',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final dateStr = ctx.payload['dateStr']?.toString() ?? DateTime.now().toIso8601String().split('T').first;
    final snoozeMinutes = ctx.payload['snoozeMinutes'] as int? ?? 15;

    final routineRows = await ctx.txn.query('routines', where: 'id = ?', whereArgs: [routineId], limit: 1);
    if (routineRows.isEmpty) {
      return const PlanDiff(kind: DiffKind.noop, entityLabelFa: 'تعویق روتین', warningFa: 'روتین یافت نشد.');
    }
    final rMap = routineRows.first;
    final category = rMap['category']?.toString();
    final isEssential = rMap['isEssential'] as int? ?? 0;

    // Get current deferCount
    final selectedDateMidnight = DateTime.tryParse(dateStr) ?? DateTime.now();
    final startOfDay = DateTime(selectedDateMidnight.year, selectedDateMidnight.month, selectedDateMidnight.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(selectedDateMidnight.year, selectedDateMidnight.month, selectedDateMidnight.day, 23, 59, 59).millisecondsSinceEpoch;

    final reminders = await ctx.txn.query(
      'pending_reminders',
      where: 'routineId = ? AND scheduledTime >= ? AND scheduledTime <= ?',
      whereArgs: [routineId, startOfDay, endOfDay],
    );
    final currentDeferCount = reminders.isNotEmpty ? (reminders.first['deferCount'] as int? ?? 0) : 0;

    // configured max
    var configuredMax = 3;
    final rows = await ctx.txn.query('app_settings', where: 'key = ?', whereArgs: ['snooze_max_quota'], limit: 1);
    if (rows.isNotEmpty) {
      configuredMax = int.tryParse(rows.first['value']?.toString() ?? '') ?? 3;
    }

    // recurrence rule type
    String? ruleType;
    final schedRows = await ctx.txn.query('routine_schedules', where: 'routineId = ?', whereArgs: [routineId], limit: 1);
    if (schedRows.isNotEmpty) {
      ruleType = schedRows.first['scheduleType']?.toString();
    }

    final decision = SnoozePolicy.evaluate(
      itemId: routineId,
      now: DateTime.now(),
      requestedMinutes: snoozeMinutes,
      currentDeferCount: currentDeferCount,
      category: category,
      isEssential: isEssential,
      configuredMax: configuredMax,
      recurrenceRuleType: ruleType,
    );

    String? warning;
    if (decision.verdict == SnoozeVerdict.blockedMidnight) {
      warning = 'زمان جدید از نیمه‌شب می‌گذرد. امکان تعویق وجود ندارد.';
    } else if (decision.verdict == SnoozeVerdict.exhausted) {
      warning = 'سقف تعویق این آیتم پر شده است.';
    }

    return PlanDiff(
      kind: DiffKind.update,
      entityLabelFa: 'تعویق روتین: ${rMap['title']}',
      warningFa: warning,
    );
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final dateStr = ctx.payload['dateStr']?.toString() ?? DateTime.now().toIso8601String().split('T').first;
    final snoozeMinutes = ctx.payload['snoozeMinutes'] as int? ?? 15;

    // Get current defer count and find reminder row
    final selectedDateMidnight = DateTime.tryParse(dateStr) ?? DateTime.now();
    final startOfDay = DateTime(selectedDateMidnight.year, selectedDateMidnight.month, selectedDateMidnight.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(selectedDateMidnight.year, selectedDateMidnight.month, selectedDateMidnight.day, 23, 59, 59).millisecondsSinceEpoch;

    final reminders = await ctx.txn.query(
      'pending_reminders',
      where: 'routineId = ? AND scheduledTime >= ? AND scheduledTime <= ?',
      whereArgs: [routineId, startOfDay, endOfDay],
    );

    if (reminders.isEmpty) {
      return CommandResult.failure(commandId: id, errorMessage: 'یادآوری فعالی برای این روتین یافت نشد.');
    }

    final reminderRow = reminders.first;
    final reminderId = reminderRow['id'] as String;
    final currentDeferCount = (reminderRow['deferCount'] as int?) ?? 0;

    final routineRows = await ctx.txn.query('routines', where: 'id = ?', whereArgs: [routineId], limit: 1);
    final rMap = routineRows.isNotEmpty ? routineRows.first : const {};
    final category = rMap['category']?.toString();
    final isEssential = rMap['isEssential'] as int? ?? 0;

    var configuredMax = 3;
    final rows = await ctx.txn.query('app_settings', where: 'key = ?', whereArgs: ['snooze_max_quota'], limit: 1);
    if (rows.isNotEmpty) {
      configuredMax = int.tryParse(rows.first['value']?.toString() ?? '') ?? 3;
    }

    String? ruleType;
    final schedRows = await ctx.txn.query('routine_schedules', where: 'routineId = ?', whereArgs: [routineId], limit: 1);
    if (schedRows.isNotEmpty) {
      ruleType = schedRows.first['scheduleType']?.toString();
    }

    final decision = SnoozePolicy.evaluate(
      itemId: routineId,
      now: DateTime.now(),
      requestedMinutes: snoozeMinutes,
      currentDeferCount: currentDeferCount,
      category: category,
      isEssential: isEssential,
      configuredMax: configuredMax,
      recurrenceRuleType: ruleType,
    );

    if (decision.verdict == SnoozeVerdict.blockedMidnight) {
      return CommandResult.failure(commandId: id, errorMessage: 'زمان جدید از نیمه‌شب می‌گذرد. امکان تعویق وجود ندارد.');
    }
    if (decision.verdict == SnoozeVerdict.exhausted) {
      return CommandResult.failure(commandId: id, errorMessage: 'سقف تعویق این آیتم پر شده است.');
    }

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      SnoozeReminderCommand(
        reminderId: reminderId,
        snoozeMinutes: snoozeMinutes,
        dateStr: dateStr,
      ),
      txn: txn,
    );

    return CommandResult.ok(
      commandId: id,
      inverseData: {
        'reminderId': reminderId,
        'oldScheduledTime': reminderRow['scheduledTime'],
        'oldSqueezeUntil': reminderRow['snoozeUntil'],
        'oldDeferCount': currentDeferCount,
        'routineId': routineId,
        'dateStr': dateStr,
      },
    );
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final reminderId = inverseData['reminderId']?.toString();
    final oldScheduledTime = inverseData['oldScheduledTime'];
    final oldSqueezeUntil = inverseData['oldSqueezeUntil'];
    final oldDeferCount = inverseData['oldDeferCount'] as int?;
    final routineId = inverseData['routineId']?.toString();
    final dateStr = inverseData['dateStr']?.toString();

    if (reminderId == null || oldDeferCount == null || routineId == null || dateStr == null) return null;

    // Restore reminder columns
    await ctx.txn.update(
      'pending_reminders',
      {
        'scheduledTime': oldScheduledTime,
        'snoozeUntil': oldSqueezeUntil,
        'deferCount': oldDeferCount,
        'state': oldDeferCount == 0 ? 'pending' : 'delayed',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [reminderId],
    );

    // Restore routine occurrences status
    await ctx.txn.rawUpdate(
      'UPDATE routine_occurrences SET status = ? WHERE routine_id = ? AND date = ?',
      [oldDeferCount == 0 ? 'pending' : 'snoozed', routineId, dateStr],
    );

    return CommandResult.ok(commandId: id);
  }
}

class RoutineRescheduleCommand extends RitmoCommand {
  const RoutineRescheduleCommand();

  @override
  String get id => 'routine.reschedule';

  @override
  String get humanTitle => 'انتقال روتین به روز دیگر';

  @override
  String get humanDescriptionFa => 'جابجایی تاریخ انجام روتین از امروز به یک روز مشخص دیگر';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'روتین',
      required: true,
      refTable: 'routines',
    ),
    'fromDate': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'از تاریخ',
      required: false,
    ),
    'targetDate': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'به تاریخ',
      required: true,
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final targetDate = ctx.payload['targetDate']?.toString() ?? '';
    final rows = await ctx.txn.query('routines', columns: ['title'], where: 'id = ?', whereArgs: [routineId]);
    final title = rows.isNotEmpty ? rows.first['title']?.toString() : 'روتین نامشخص';
    return PlanDiff(kind: DiffKind.update, entityLabelFa: 'انتقال روتین $title به تاریخ $targetDate');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final fromDateStr = ctx.payload['fromDate']?.toString() ?? DateTime.now().toIso8601String().split('T').first;
    final toDateStr = ctx.payload['targetDate']?.toString() ?? fromDateStr;

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      RescheduleOccurrenceCommand(
        routineId: routineId,
        fromDateStr: fromDateStr,
        toDateStr: toDateStr,
      ),
      txn: txn,
    );

    final undoToken = 'reschedule:$routineId|$fromDateStr|$toDateStr';
    return CommandResult.ok(commandId: id, inverseData: {'undoToken': undoToken});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final undoToken = inverseData['undoToken']?.toString();
    if (undoToken == null) return null;
    final parts = undoToken.split(':');
    if (parts.length < 2) return null;
    final idPayload = parts.sublist(1).join(':');
    final resParts = idPayload.split('|');
    if (resParts.length < 2) return null;
    final rId = resParts[0];
    final fromDateStr = resParts[1];
    final toDateStr = resParts.length >= 3 ? resParts[2] : null;

    await ctx.txn.delete('routine_completions', where: 'routineId = ? AND completionDate = ? AND resultType = ?', whereArgs: [rId, fromDateStr, 'RESCHEDULED']);
    await ctx.txn.delete('skip_reasons', where: 'itemId = ? AND dateStr = ?', whereArgs: [rId, fromDateStr]);
    await ctx.txn.rawUpdate('''
      UPDATE routine_occurrences 
      SET status = 'pending'
      WHERE routine_id = ? AND date = ?
    ''', [rId, fromDateStr]);

    if (toDateStr != null) {
      await ctx.txn.delete(
        'routine_occurrences',
        where: 'routine_id = ? AND date = ? AND status = ?',
        whereArgs: [rId, toDateStr, 'pending'],
      );
    }

    return CommandResult.ok(commandId: id);
  }
}

class RoutineSetReminderOffsetCommand extends RitmoCommand {
  const RoutineSetReminderOffsetCommand();

  @override
  String get id => 'routine.setReminderOffset';

  @override
  String get humanTitle => 'تغییر فاصله یادآوری روتین';

  @override
  String get humanDescriptionFa => 'تنظیم چند دقیقه فاصله یادآوری اعلان قبل از زمان شروع روتین';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'روتین',
      required: true,
      refTable: 'routines',
    ),
    'offsetMinutes': const ParamSpec(
      type: ParamType.integer,
      labelFa: 'فاصله به دقیقه (مثلا ۱۵ برای ۱۵ دقیقه قبل)',
      required: true,
      exampleFa: '15',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final offset = ctx.payload['offsetMinutes'] as int? ?? 0;
    final rows = await ctx.txn.query('routines', columns: ['title', 'reminderOffsetMinutes'], where: 'id = ?', whereArgs: [routineId]);
    if (rows.isEmpty) {
      return const PlanDiff(kind: DiffKind.noop, entityLabelFa: 'یادآوری روتین', warningFa: 'روتین یافت نشد.');
    }
    final title = rows.first['title']?.toString();
    final oldOffset = rows.first['reminderOffsetMinutes'] as int? ?? 0;
    return PlanDiff(
      kind: DiffKind.update,
      entityLabelFa: 'روتین $title: یادآوری',
      beforeFa: '$oldOffset دقیقه',
      afterFa: '$offset دقیقه',
    );
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final offset = ctx.payload['offsetMinutes'] as int? ?? 0;

    final rows = await ctx.txn.query('routines', columns: ['reminderOffsetMinutes'], where: 'id = ?', whereArgs: [routineId]);
    if (rows.isEmpty) {
      return CommandResult.failure(commandId: id, errorMessage: 'روتین یافت نشد.');
    }
    final oldOffset = rows.first['reminderOffsetMinutes'] as int? ?? 0;

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      EditRoutineCommand(
        routineId: routineId,
        routineData: {'reminderOffsetMinutes': offset},
      ),
      txn: txn,
    );

    return CommandResult.ok(commandId: id, inverseData: {'routineId': routineId, 'oldOffset': oldOffset});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final routineId = inverseData['routineId']?.toString();
    final oldOffset = inverseData['oldOffset'] as int?;
    if (routineId == null || oldOffset == null) return null;

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      EditRoutineCommand(
        routineId: routineId,
        routineData: {'reminderOffsetMinutes': oldOffset},
      ),
      txn: txn,
    );
    return CommandResult.ok(commandId: id);
  }
}

class RoutineSetEssentialCommand extends RitmoCommand {
  const RoutineSetEssentialCommand();

  @override
  String get id => 'routine.setEssential';

  @override
  String get humanTitle => 'حیاتی اعلام کردن روتین';

  @override
  String get humanDescriptionFa => 'تغییر وضعیت روتین به حیاتی/معمولی جهت فعال‌سازی قوانین سفت‌وسخت خواب و تعویق';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'روتین',
      required: true,
      refTable: 'routines',
    ),
    'isEssential': const ParamSpec(
      type: ParamType.boolean,
      labelFa: 'آیا حیاتی است؟',
      required: true,
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final isEssential = ctx.payload['isEssential'] as bool? ?? false;
    final rows = await ctx.txn.query('routines', columns: ['title', 'isEssential'], where: 'id = ?', whereArgs: [routineId]);
    if (rows.isEmpty) {
      return const PlanDiff(kind: DiffKind.noop, entityLabelFa: 'وضعیت حیاتی روتین', warningFa: 'روتین یافت نشد.');
    }
    final title = rows.first['title']?.toString();
    final oldEssential = rows.first['isEssential'] == 1;
    return PlanDiff(
      kind: DiffKind.update,
      entityLabelFa: 'روتین $title: اهمیت',
      beforeFa: oldEssential ? 'حیاتی' : 'معمولی',
      afterFa: isEssential ? 'حیاتی' : 'معمولی',
    );
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final isEssential = ctx.payload['isEssential'] as bool? ?? false;

    final rows = await ctx.txn.query('routines', columns: ['isEssential'], where: 'id = ?', whereArgs: [routineId]);
    if (rows.isEmpty) {
      return CommandResult.failure(commandId: id, errorMessage: 'روتین یافت نشد.');
    }
    final oldEssential = rows.first['isEssential'] == 1;

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      EditRoutineCommand(
        routineId: routineId,
        routineData: {'isEssential': isEssential ? 1 : 0},
      ),
      txn: txn,
    );

    return CommandResult.ok(commandId: id, inverseData: {'routineId': routineId, 'oldEssential': oldEssential});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final routineId = inverseData['routineId']?.toString();
    final oldEssential = inverseData['oldEssential'] as bool?;
    if (routineId == null || oldEssential == null) return null;

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      EditRoutineCommand(
        routineId: routineId,
        routineData: {'isEssential': oldEssential ? 1 : 0},
      ),
      txn: txn,
    );
    return CommandResult.ok(commandId: id);
  }
}

class RoutineSetPrivateCommand extends RitmoCommand {
  const RoutineSetPrivateCommand();

  @override
  String get id => 'routine.setPrivate';

  @override
  String get humanTitle => 'خصوصی کردن روتین';

  @override
  String get humanDescriptionFa => 'تغییر وضعیت روتین به خصوصی جهت پنهان‌سازی اطلاعات آن در خروجی‌های اشتراکی';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'روتین',
      required: true,
      refTable: 'routines',
    ),
    'isPrivate': const ParamSpec(
      type: ParamType.boolean,
      labelFa: 'آیا خصوصی است؟',
      required: true,
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final isPrivate = ctx.payload['isPrivate'] as bool? ?? false;
    final rows = await ctx.txn.query('routines', columns: ['title', 'isPrivate'], where: 'id = ?', whereArgs: [routineId]);
    if (rows.isEmpty) {
      return const PlanDiff(kind: DiffKind.noop, entityLabelFa: 'وضعیت خصوصی روتین', warningFa: 'روتین یافت نشد.');
    }
    final title = rows.first['title']?.toString();
    final oldPrivate = rows.first['isPrivate'] == 1;
    return PlanDiff(
      kind: DiffKind.update,
      entityLabelFa: 'روتین $title: حریم خصوصی',
      beforeFa: oldPrivate ? 'خصوصی' : 'عمومی',
      afterFa: isPrivate ? 'خصوصی' : 'عمومی',
    );
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final routineId = ctx.payload['routineId']?.toString() ?? '';
    final isPrivate = ctx.payload['isPrivate'] as bool? ?? false;

    final rows = await ctx.txn.query('routines', columns: ['isPrivate'], where: 'id = ?', whereArgs: [routineId]);
    if (rows.isEmpty) {
      return CommandResult.failure(commandId: id, errorMessage: 'روتین یافت نشد.');
    }
    final oldPrivate = rows.first['isPrivate'] == 1;

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      EditRoutineCommand(
        routineId: routineId,
        routineData: {'isPrivate': isPrivate ? 1 : 0},
      ),
      txn: txn,
    );

    return CommandResult.ok(commandId: id, inverseData: {'routineId': routineId, 'oldPrivate': oldPrivate});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final routineId = inverseData['routineId']?.toString();
    final oldPrivate = inverseData['oldPrivate'] as bool?;
    if (routineId == null || oldPrivate == null) return null;

    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;
    await RitmoExecutionKernel.instance.execute(
      EditRoutineCommand(
        routineId: routineId,
        routineData: {'isPrivate': oldPrivate ? 1 : 0},
      ),
      txn: txn,
    );
    return CommandResult.ok(commandId: id);
  }
}

class RoutineBulkRescheduleCommand extends RitmoCommand {
  const RoutineBulkRescheduleCommand();

  @override
  String get id => 'routine.bulkReschedule';

  @override
  String get humanTitle => 'انتقال گروهی روتین‌ها';

  @override
  String get humanDescriptionFa => 'جابجایی همزمان تاریخ انجام چندین روتین با هم به یک روز دیگر';

  @override
  Sensitivity get sensitivity => Sensitivity.sensitive;

  @override
  Set<DataDomain> get touches => {DataDomain.routines};

  @override
  Map<String, ParamSpec> get params => {
    'routineIds': const ParamSpec(
      type: ParamType.text, // Comma separated IDs
      labelFa: 'شناسه‌های روتین (با کاما جدا شده)',
      required: true,
    ),
    'fromDate': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'از تاریخ',
      required: false,
    ),
    'targetDate': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'به تاریخ',
      required: true,
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final idsStr = ctx.payload['routineIds']?.toString() ?? '';
    final targetDate = ctx.payload['targetDate']?.toString() ?? '';
    final count = idsStr.split(',').where((s) => s.trim().isNotEmpty).length;
    return PlanDiff(kind: DiffKind.update, entityLabelFa: 'انتقال گروهی $count روتین به تاریخ $targetDate');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final idsStr = ctx.payload['routineIds']?.toString() ?? '';
    final fromDateStr = ctx.payload['fromDate']?.toString() ?? DateTime.now().toIso8601String().split('T').first;
    final toDateStr = ctx.payload['targetDate']?.toString() ?? fromDateStr;

    final ids = idsStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (ids.isEmpty) {
      return CommandResult.failure(commandId: id, errorMessage: 'هیچ روتینی مشخص نشده است.');
    }

    final tokens = <String>[];
    final txn = ctx.txn is Transaction ? ctx.txn as Transaction : null;

    for (final rId in ids) {
      await RitmoExecutionKernel.instance.execute(
        RescheduleOccurrenceCommand(
          routineId: rId,
          fromDateStr: fromDateStr,
          toDateStr: toDateStr,
        ),
        txn: txn,
      );
      tokens.add('reschedule:$rId|$fromDateStr|$toDateStr');
    }

    return CommandResult.ok(commandId: id, inverseData: {'undoTokens': tokens});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final tokens = (inverseData['undoTokens'] as List?)?.map((t) => t.toString()).toList();
    if (tokens == null || tokens.isEmpty) return null;

    for (final undoToken in tokens) {
      final parts = undoToken.split(':');
      if (parts.length < 2) continue;
      final idPayload = parts.sublist(1).join(':');
      final resParts = idPayload.split('|');
      if (resParts.length < 2) continue;
      final rId = resParts[0];
      final fromDateStr = resParts[1];
      final toDateStr = resParts.length >= 3 ? resParts[2] : null;

      await ctx.txn.delete('routine_completions', where: 'routineId = ? AND completionDate = ? AND resultType = ?', whereArgs: [rId, fromDateStr, 'RESCHEDULED']);
      await ctx.txn.delete('skip_reasons', where: 'itemId = ? AND dateStr = ?', whereArgs: [rId, fromDateStr]);
      await ctx.txn.rawUpdate('''
        UPDATE routine_occurrences 
        SET status = 'pending'
        WHERE routine_id = ? AND date = ?
      ''', [rId, fromDateStr]);

      if (toDateStr != null) {
        await ctx.txn.delete(
          'routine_occurrences',
          where: 'routine_id = ? AND date = ? AND status = ?',
          whereArgs: [rId, toDateStr, 'pending'],
        );
      }
    }

    return CommandResult.ok(commandId: id);
  }
}
