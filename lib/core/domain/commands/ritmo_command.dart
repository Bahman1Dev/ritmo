import 'package:flutter/foundation.dart';

/// Sensitivity level for Ritmo Commands
enum Sensitivity {
  safe,
  confirm,
  sensitive,
  forbidden,
}

/// Data domains touched by commands and personas
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

/// Execution context passed to commands
class CommandContext {
  const CommandContext({
    required this.payload,
    required this.resultSource,
    this.assistantId,
  });

  final Map<String, dynamic> payload;

  /// Source of action execution: MUST be 'AI', 'SYSTEM', etc. MUST NOT be 'USER' for AI actions.
  final String resultSource;
  final String? assistantId;
}

/// Result returned from command execution or inverse
class CommandResult {
  const CommandResult({
    required this.success,
    required this.commandId,
    this.outputData,
    this.errorMessage,
    this.inverseToken,
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
    String? inverseToken,
  }) {
    return CommandResult(
      success: true,
      commandId: commandId,
      outputData: outputData,
      inverseToken: inverseToken,
    );
  }

  final bool success;
  final String commandId;
  final Map<String, dynamic>? outputData;
  final String? errorMessage;
  final String? inverseToken;
}

/// Sealed base class for all commands in the Ritmo Command Layer
sealed class RitmoCommand {
  const RitmoCommand();

  String get id;
  String get humanTitle;
  Sensitivity get sensitivity;
  Set<DataDomain> get touches;
  Map<String, dynamic> get schema;

  Future<CommandResult> run(CommandContext ctx);
  Future<CommandResult?> inverse(CommandResult result);
}
