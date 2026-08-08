import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/param_spec.dart';
import 'package:ritmo/core/domain/commands/command_plan.dart';

String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

class CourseCreateCommand extends RitmoCommand {
  const CourseCreateCommand();

  @override
  String get id => 'course.create';

  @override
  String get humanTitle => 'ثبت دوره جدید';

  @override
  String get humanDescriptionFa => 'افزودن دوره آموزشی جدید جهت پیگیری جلسات مطالعه';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.courses};

  @override
  Map<String, ParamSpec> get params => {
    'title': const ParamSpec(
      type: ParamType.text,
      labelFa: 'عنوان دوره',
      required: true,
      exampleFa: 'آموزش فلاتر',
    ),
    'totalSessions': const ParamSpec(
      type: ParamType.integer,
      labelFa: 'تعداد کل جلسات',
      required: false,
      exampleFa: '10',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final title = ctx.payload['title']?.toString() ?? 'دوره جدید';
    return PlanDiff(kind: DiffKind.create, entityLabelFa: 'دوره: $title');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final courseId = ctx.payload['id']?.toString() ?? _genId();
    final title = ctx.payload['title']?.toString() ?? 'دوره جدید';
    final totalSessions = ctx.payload['totalSessions'] as int? ?? 10;

    await ctx.txn.insert('courses', {
      'id': courseId,
      'title': title,
      'totalSessions': totalSessions,
      'sessionDurationMinutes': 60,
      'activityType': 'STUDY',
      'weeklyTargetSessions': 3,
      'isArchived': 0,
      'status': 'ACTIVE',
      'masteryScore': 0.0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    return CommandResult.ok(commandId: id, outputData: {'courseId': courseId}, inverseData: {'courseId': courseId});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final courseId = inverseData['courseId']?.toString();
    if (courseId == null) return null;
    await ctx.txn.delete('courses', where: 'id = ?', whereArgs: [courseId]);
    return CommandResult.ok(commandId: id);
  }
}

class KonkurCreateTopicCommand extends RitmoCommand {
  const KonkurCreateTopicCommand();

  @override
  String get id => 'konkur.createTopic';

  @override
  String get humanTitle => 'افزودن برنامه مطالعه کنکور';

  @override
  String get humanDescriptionFa => 'افزودن مبحث یا سرفصل جدید به برنامه‌ریزی مطالعه کنکور';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.konkur};

  @override
  Map<String, ParamSpec> get params => {
    'topicName': const ParamSpec(
      type: ParamType.text,
      labelFa: 'عنوان مبحث مطالعه',
      required: true,
      exampleFa: 'فیزیک حرکت شناسی',
    ),
    'plannedMinutes': const ParamSpec(
      type: ParamType.integer,
      labelFa: 'زمان مطالعه پیشنهادی (دقیقه)',
      required: false,
      exampleFa: '60',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final topicName = ctx.payload['topicName']?.toString() ?? 'مبحث جدید';
    return PlanDiff(kind: DiffKind.create, entityLabelFa: 'برنامه کنکور: $topicName');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final planId = ctx.payload['id']?.toString() ?? _genId();
    final topicName = ctx.payload['topicName']?.toString() ?? 'مبحث جدید';
    final plannedMinutes = ctx.payload['plannedMinutes'] as int? ?? 60;

    await ctx.txn.insert('konkur_plans', {
      'id': planId,
      'topicName': topicName,
      'plannedMinutes': plannedMinutes,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    return CommandResult.ok(commandId: id, outputData: {'planId': planId}, inverseData: {'planId': planId});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final planId = inverseData['planId']?.toString();
    if (planId == null) return null;
    await ctx.txn.delete('konkur_plans', where: 'id = ?', whereArgs: [planId]);
    return CommandResult.ok(commandId: id);
  }
}
