import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/param_spec.dart';
import 'package:ritmo/core/domain/commands/command_plan.dart';
import 'package:ritmo/core/domain/commands/command_audit.dart';

class AppOpenPageCommand extends RitmoCommand {
  const AppOpenPageCommand();

  @override
  String get id => 'app.openPage';

  @override
  String get humanTitle => 'مشاهده صفحه';

  @override
  String get humanDescriptionFa => 'باز کردن یکی از بخش‌ها یا صفحات برنامه';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => const {};

  @override
  Map<String, ParamSpec> get params => {
    'targetRoute': const ParamSpec(
      type: ParamType.text,
      labelFa: 'صفحه مقصد',
      required: true,
      exampleFa: '/settings',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final route = ctx.payload['targetRoute']?.toString() ?? '/';
    return PlanDiff(kind: DiffKind.navigate, entityLabelFa: 'صفحه: $route');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final route = ctx.payload['targetRoute']?.toString() ?? '/';
    return CommandResult.ok(commandId: id, outputData: {'route': route});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async => null;
}

class AssistantHandoffCommand extends RitmoCommand {
  const AssistantHandoffCommand();

  @override
  String get id => 'assistant.handoff';

  @override
  String get humanTitle => 'ارجاع به دستیار دیگر';

  @override
  String get humanDescriptionFa => 'واگذاری گفتگو به دستیاری که تخصص بیشتری در موضوع دارد';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => const {};

  @override
  Map<String, ParamSpec> get params => {
    'personaId': const ParamSpec(
      type: ParamType.enumeration,
      labelFa: 'دستیار مقصد',
      required: true,
      allowed: ['global', 'worship', 'konkur', 'courses', 'sports', 'wellbeing', 'goals', 'sleep', 'reflection', 'cycle', 'health'],
    ),
    'reasonFa': const ParamSpec(
      type: ParamType.text,
      labelFa: 'دلیل ارجاع',
      required: false,
    ),
    'carryHistory': const ParamSpec(
      type: ParamType.boolean,
      labelFa: 'انتقال تاریخچه گفتگو',
      required: false,
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final target = ctx.payload['personaId']?.toString() ?? '';
    return PlanDiff(kind: DiffKind.noop, entityLabelFa: 'ارجاع به دستیار: $target');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final target = ctx.payload['personaId']?.toString() ?? '';
    return CommandResult.ok(commandId: id, outputData: {
      'personaId': target,
      'carryHistory': ctx.payload['carryHistory'] ?? true,
    });
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async => null;
}

class AssistantUndoLastCommand extends RitmoCommand {
  const AssistantUndoLastCommand();

  @override
  String get id => 'assistant.undoLast';

  @override
  String get humanTitle => 'بازگردانی آخرین اقدام';

  @override
  String get humanDescriptionFa => 'لغو آخرین برنامه یا تغییری که توسط دستیار اعمال شده است';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => const {};

  @override
  Map<String, ParamSpec> get params => const {};

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    return const PlanDiff(kind: DiffKind.noop, entityLabelFa: 'بازگردانی آخرین اقدام دستیار');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final plans = await CommandAuditRepository.getRecentPlans(limit: 1);
    if (plans.isEmpty) {
      return CommandResult.failure(commandId: id, errorMessage: 'هیچ برنامه قابل بازگردانی پیدا نشد.');
    }
    final lastPlan = plans.first;
    if (lastPlan.status != 'applied') {
      return CommandResult.failure(commandId: id, errorMessage: 'آخرین برنامه قبلاً بازگردانده شده است.');
    }
    return CommandResult.ok(commandId: id, outputData: {'planId': lastPlan.id});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async => null;
}
