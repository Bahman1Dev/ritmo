import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/param_spec.dart';
import 'package:ritmo/core/domain/commands/command_plan.dart';

String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

class GoalCreateCommand extends RitmoCommand {
  const GoalCreateCommand();

  @override
  String get id => 'goal.create';

  @override
  String get humanTitle => 'تعریف هدف جدید';

  @override
  String get humanDescriptionFa => 'ایجاد یک هدف جدید شخصی، تحصیلی یا ورزشی در برنامه';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.goals};

  @override
  Map<String, ParamSpec> get params => {
    'title': const ParamSpec(
      type: ParamType.text,
      labelFa: 'عنوان هدف',
      required: true,
      exampleFa: 'قبولی در آزمون وکالت',
    ),
    'goalType': const ParamSpec(
      type: ParamType.enumeration,
      labelFa: 'نوع هدف',
      required: false,
      allowed: ['HABIT', 'MILESTONE'],
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final title = ctx.payload['title']?.toString() ?? 'هدف جدید';
    return PlanDiff(kind: DiffKind.create, entityLabelFa: 'هدف: $title');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final goalId = ctx.payload['id']?.toString() ?? _genId();
    final title = ctx.payload['title']?.toString() ?? 'هدف جدید';
    final goalType = ctx.payload['goalType']?.toString() ?? 'HABIT';

    await ctx.txn.insert('goals', {
      'id': goalId,
      'title': title,
      'goalType': goalType,
      'status': 'ACTIVE',
      'progressCache': 0.0,
      'isPrivate': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    return CommandResult.ok(commandId: id, outputData: {'goalId': goalId}, inverseData: {'goalId': goalId});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final goalId = inverseData['goalId']?.toString();
    if (goalId == null) return null;
    await ctx.txn.delete('goals', where: 'id = ?', whereArgs: [goalId]);
    return CommandResult.ok(commandId: id);
  }
}

class GoalEditCommand extends RitmoCommand {
  const GoalEditCommand();

  @override
  String get id => 'goal.edit';

  @override
  String get humanTitle => 'ویرایش هدف';

  @override
  String get humanDescriptionFa => 'تغییر عنوان یا نوع یک هدف تعریف شده';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.goals};

  @override
  Map<String, ParamSpec> get params => {
    'goalId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'هدف',
      required: true,
      refTable: 'goals',
    ),
    'title': const ParamSpec(
      type: ParamType.text,
      labelFa: 'عنوان جدید هدف',
      required: false,
    ),
    'goalType': const ParamSpec(
      type: ParamType.text,
      labelFa: 'نوع جدید هدف',
      required: false,
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final goalId = ctx.payload['goalId']?.toString() ?? '';
    final rows = await ctx.txn.query('goals', columns: ['title'], where: 'id = ?', whereArgs: [goalId]);
    final oldTitle = rows.isNotEmpty ? rows.first['title']?.toString() : 'هدف نامشخص';
    final newTitle = ctx.payload['title']?.toString() ?? oldTitle;
    return PlanDiff(
      kind: DiffKind.update,
      entityLabelFa: 'هدف: $oldTitle',
      beforeFa: oldTitle,
      afterFa: newTitle,
    );
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final goalId = ctx.payload['goalId']?.toString() ?? '';
    final rows = await ctx.txn.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (rows.isEmpty) {
      return CommandResult.failure(commandId: id, errorMessage: 'هدف یافت نشد.');
    }

    final data = <String, dynamic>{};
    if (ctx.payload['title'] != null) data['title'] = ctx.payload['title'];
    if (ctx.payload['goalType'] != null) data['goalType'] = ctx.payload['goalType'];
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

    await ctx.txn.update('goals', data, where: 'id = ?', whereArgs: [goalId]);

    return CommandResult.ok(commandId: id, inverseData: {'goalId': goalId, 'oldState': rows.first});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final goalId = inverseData['goalId']?.toString();
    final oldState = inverseData['oldState'] as Map<String, dynamic>?;
    if (goalId == null || oldState == null) return null;
    await ctx.txn.update('goals', Map<String, dynamic>.from(oldState), where: 'id = ?', whereArgs: [goalId]);
    return CommandResult.ok(commandId: id);
  }
}

class GoalCompleteStepCommand extends RitmoCommand {
  const GoalCompleteStepCommand();

  @override
  String get id => 'goal.completeStep';

  @override
  String get humanTitle => 'تکمیل گام هدف';

  @override
  String get humanDescriptionFa => 'تیک زدن و ثبت تکمیل یکی از مراحل یا گام‌های هدف';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.goals};

  @override
  Map<String, ParamSpec> get params => {
    'goalId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'هدف',
      required: true,
      refTable: 'goals',
    ),
    'stepId': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'گام هدف',
      required: true,
      refTable: 'goal_steps',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final goalId = ctx.payload['goalId']?.toString() ?? '';
    final stepId = ctx.payload['stepId']?.toString() ?? '';
    final rows = await ctx.txn.query('goal_steps', columns: ['title'], where: 'id = ? AND goalId = ?', whereArgs: [stepId, goalId]);
    final title = rows.isNotEmpty ? rows.first['title']?.toString() : 'مرحله هدف';
    return PlanDiff(kind: DiffKind.update, entityLabelFa: 'تکمیل مرحله: $title');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final goalId = ctx.payload['goalId']?.toString() ?? '';
    final stepId = ctx.payload['stepId']?.toString() ?? '';

    final rows = await ctx.txn.query('goal_steps', where: 'id = ? AND goalId = ?', whereArgs: [stepId, goalId]);
    if (rows.isEmpty) {
      return CommandResult.failure(commandId: id, errorMessage: 'گام هدف یافت نشد.');
    }

    await ctx.txn.update(
      'goal_steps',
      {
        'isCompleted': 1,
        'completedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND goalId = ?',
      whereArgs: [stepId, goalId],
    );

    return CommandResult.ok(commandId: id, inverseData: {'goalId': goalId, 'stepId': stepId});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final goalId = inverseData['goalId']?.toString();
    final stepId = inverseData['stepId']?.toString();
    if (goalId == null || stepId == null) return null;

    await ctx.txn.update(
      'goal_steps',
      {
        'isCompleted': 0,
        'completedAt': null,
      },
      where: 'id = ? AND goalId = ?',
      whereArgs: [stepId, goalId],
    );

    return CommandResult.ok(commandId: id);
  }
}
