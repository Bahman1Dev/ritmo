import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/domain/engines/engine_invalidation_tag.dart';
import 'package:ritmo/core/domain/commands/param_spec.dart';
import 'package:ritmo/core/domain/commands/command_plan.dart';

enum Sensitivity {
  safe,
  confirm,
  sensitive,
  forbidden,
}

enum DataDomain {
  routines,
  goals,
  worship,
  konkur,
  sleep,
  energy,
  cycle,
  medical,
  reflection,
  sports,
  courses,
}

enum CommandSource {
  user,
  assistant,
  system,
  undo,
}

class AgentCommandContext {
  const AgentCommandContext({
    required this.payload,
    required this.source,
    required this.personaId,
    required this.now,
    required this.txn,
    this.assistantId,
    this.planId,
  });

  final Map<String, dynamic> payload;
  final CommandSource source;
  final String personaId;
  final DateTime now;
  final DatabaseExecutor txn;
  final String? assistantId;
  final String? planId;
}

class CommandResult {
  const CommandResult({
    required this.success,
    required this.commandId,
    this.outputData,
    this.inverseData,
    this.errorMessage,
  });

  factory CommandResult.failure({
    required String commandId,
    required String errorMessage,
  }) {
    return CommandResult(
      success: false,
      commandId: commandId,
      errorMessage: errorMessage,
    );
  }

  factory CommandResult.ok({
    required String commandId,
    Map<String, dynamic>? outputData,
    Map<String, dynamic>? inverseData,
  }) {
    return CommandResult(
      success: true,
      commandId: commandId,
      outputData: outputData,
      inverseData: inverseData,
    );
  }

  final bool success;
  final String commandId;
  final Map<String, dynamic>? outputData;
  final Map<String, dynamic>? inverseData;
  final String? errorMessage;
}

abstract class RitmoCommand {
  const RitmoCommand();

  String get id;
  String get humanTitle;
  String get humanDescriptionFa;
  Sensitivity get sensitivity;
  Set<DataDomain> get touches;
  Map<String, ParamSpec> get params;

  Future<bool> isAvailable(AgentCommandContext ctx) async => true;

  Future<PlanDiff> preview(AgentCommandContext ctx);

  Future<CommandResult> run(AgentCommandContext ctx);

  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData);

  Set<EngineInvalidationTag> get invalidates => const {};
}
