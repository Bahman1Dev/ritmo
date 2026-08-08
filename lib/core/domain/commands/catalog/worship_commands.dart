import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/param_spec.dart';
import 'package:ritmo/core/domain/commands/command_plan.dart';
import 'package:sqflite/sqflite.dart';

String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

class WorshipCreateCommand extends RitmoCommand {
  const WorshipCreateCommand();

  @override
  String get id => 'worship.create';

  @override
  String get humanTitle => 'افزودن عبادت جدید';

  @override
  String get humanDescriptionFa => 'افزودن برنامه یا تمرین عبادی و معنوی جدید';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.worship};

  @override
  Map<String, ParamSpec> get params => {
    'title': const ParamSpec(
      type: ParamType.text,
      labelFa: 'عنوان عبادت',
      required: true,
      exampleFa: 'قرائت قرآن',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final title = ctx.payload['title']?.toString() ?? 'برنامه عبادی جدید';
    return PlanDiff(kind: DiffKind.create, entityLabelFa: 'عبادت: $title');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final itemId = ctx.payload['id']?.toString() ?? _genId();
    final title = ctx.payload['title']?.toString() ?? 'برنامه عبادی جدید';

    await ctx.txn.insert('worship_practices', {
      'id': itemId,
      'title': title,
      'practiceType': 'CUSTOM',
      'isActive': 1,
      'dailyTarget': 1,
      'dailyDone': 0,
      'totalDone': 0,
      'reminderEnabled': 0,
      'deferCount': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return CommandResult.ok(commandId: id, outputData: {'itemId': itemId}, inverseData: {'itemId': itemId});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final itemId = inverseData['itemId']?.toString();
    if (itemId == null) return null;
    await ctx.txn.delete('worship_practices', where: 'id = ?', whereArgs: [itemId]);
    return CommandResult.ok(commandId: id);
  }
}

class WorshipDeleteCommand extends RitmoCommand {
  const WorshipDeleteCommand();

  @override
  String get id => 'worship.delete';

  @override
  String get humanTitle => 'حذف عبادت';

  @override
  String get humanDescriptionFa => 'غیرفعال‌سازی یا حذف یکی از برنامه‌های عبادی تعریف شده';

  @override
  Sensitivity get sensitivity => Sensitivity.sensitive;

  @override
  Set<DataDomain> get touches => {DataDomain.worship};

  @override
  Map<String, ParamSpec> get params => {
    'id': const ParamSpec(
      type: ParamType.idRef,
      labelFa: 'برنامه عبادی',
      required: true,
      refTable: 'worship_practices',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final itemId = ctx.payload['id']?.toString() ?? '';
    final rows = await ctx.txn.query('worship_practices', columns: ['title'], where: 'id = ?', whereArgs: [itemId]);
    final title = rows.isNotEmpty ? rows.first['title']?.toString() : 'برنامه عبادی';
    return PlanDiff(kind: DiffKind.delete, entityLabelFa: 'حذف عبادت: $title');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final itemId = ctx.payload['id']?.toString() ?? '';
    await ctx.txn.update('worship_practices', {'isActive': 0}, where: 'id = ?', whereArgs: [itemId]);
    return CommandResult.ok(commandId: id, outputData: {'itemId': itemId}, inverseData: {'itemId': itemId});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final itemId = inverseData['itemId']?.toString();
    if (itemId == null) return null;
    await ctx.txn.update('worship_practices', {'isActive': 1}, where: 'id = ?', whereArgs: [itemId]);
    return CommandResult.ok(commandId: id);
  }
}
