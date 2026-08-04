import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:sqflite/sqflite.dart';

/// Central Command Bus for dispatching, dry-running, auditing, and inverting commands.
class RitmoCommandBus {
  RitmoCommandBus._();
  static final RitmoCommandBus instance = RitmoCommandBus._();

  final Map<String, RitmoCommand> _registry = {};

  void register(RitmoCommand command) {
    _registry[command.id] = command;
  }

  void registerAll(List<RitmoCommand> commands) {
    for (final cmd in commands) {
      register(cmd);
    }
  }

  RitmoCommand? getCommand(String commandId) => _registry[commandId];

  Set<String> get registeredCommandIds => _registry.keys.toSet();

  /// Dry run check before executing a command. Performs schema & sensitivity checks.
  Future<CommandResult> dryRun({
    required String commandId,
    required CommandContext ctx,
  }) async {
    final command = _registry[commandId];
    if (command == null) {
      return CommandResult.failure(
        commandId: commandId,
        errorMessage: 'دستور با شناسه "$commandId" پیدا نشد.',
      );
    }

    if (command.sensitivity == Sensitivity.forbidden) {
      return CommandResult.failure(
        commandId: commandId,
        errorMessage: 'اجرای این دستور غیرمجاز و ممنوع است.',
      );
    }

    return CommandResult.ok(commandId: commandId);
  }

  /// Dispatch and execute a command through execution kernel / gateway.
  /// Automatically writes an entry in assistant_audit_log upon success.
  Future<CommandResult> dispatch({
    required String commandId,
    required CommandContext ctx,
  }) async {
    // Zero Tolerance Rule: resultSource must not falsely claim 'USER' for AI actions
    if (ctx.assistantId != null && ctx.resultSource.toUpperCase() == 'USER') {
      throw ArgumentError(
        'ثبت resultSource="USER" برای عملیاتی که هوش مصنوعی انجام داده ممنوع است.',
      );
    }

    final command = _registry[commandId];
    if (command == null) {
      return CommandResult.failure(
        commandId: commandId,
        errorMessage: 'دستور با شناسه "$commandId" پیدا نشد.',
      );
    }

    final dryResult = await dryRun(commandId: commandId, ctx: ctx);
    if (!dryResult.success) {
      return dryResult;
    }

    try {
      final result = await command.run(ctx);
      if (result.success) {
        await _recordAuditLog(command: command, ctx: ctx, result: result);
      }
      return result;
    } catch (e, st) {
      debugPrint('[RitmoCommandBus] Exception executing "$commandId": $e\n$st');
      return CommandResult.failure(
        commandId: commandId,
        errorMessage: 'خطا در اجرای دستور: $e',
      );
    }
  }

  /// Inverse / Undo a previously executed command (supported for confirm & sensitive commands)
  Future<CommandResult> inverse({
    required CommandResult result,
  }) async {
    final command = _registry[result.commandId];
    if (command == null) {
      return CommandResult.failure(
        commandId: result.commandId,
        errorMessage: 'دستور برای بازگردانی پیدا نشد: ${result.commandId}',
      );
    }

    if (command.sensitivity == Sensitivity.safe || command.sensitivity == Sensitivity.forbidden) {
      return CommandResult.failure(
        commandId: result.commandId,
        errorMessage: 'دستورهای امن یا ممنوعه قابل بازگردانی از این مسیر نیستند.',
      );
    }

    return (await command.inverse(result)) ??
        CommandResult.failure(
          commandId: result.commandId,
          errorMessage: 'بازگردانی عملیات انجام نشد.',
        );
  }

  Future<void> _recordAuditLog({
    required RitmoCommand command,
    required CommandContext ctx,
    required CommandResult result,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final auditId = RitmoIdFactory.uuid();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Ensure assistant_id column exists
      try {
        await db.execute('ALTER TABLE assistant_audit_log ADD COLUMN assistant_id TEXT;');
      } catch (_) {}

      await db.insert(
        'assistant_audit_log',
        {
          'id': auditId,
          'actionType': command.id,
          'targetKey': result.inverseToken ?? ctx.payload['id']?.toString() ?? ctx.payload['routineId']?.toString(),
          'oldValue': null,
          'newValue': ctx.payload.toString(),
          'appliedAt': now,
          'assistant_id': ctx.assistantId ?? 'GLOBAL',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[RitmoCommandBus] Audit log error: $e');
    }
  }
}
