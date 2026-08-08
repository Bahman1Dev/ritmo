import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/command_plan.dart';
import 'package:ritmo/core/domain/commands/command_audit.dart';
import 'package:ritmo/core/domain/personas/persona_registry.dart';
import 'package:ritmo/core/domain/personas/persona_gate.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/engine_invalidation_tag.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:sqflite/sqflite.dart';

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

  List<RitmoCommand> get all => _registry.values.toList();

  List<RitmoCommand> availableFor(String personaId) {
    final persona = PersonaRegistry.instance.getPersona(personaId);
    if (persona == null) return [];
    return _registry.values.where((c) => persona.commandIds.contains(c.id)).toList();
  }

  Future<PlanPreview> preview(CommandPlan plan, {required String personaId}) async {
    final db = await DatabaseHelper.instance.database;
    final persona = PersonaRegistry.instance.getPersona(personaId);
    
    if (persona == null) {
      return const PlanPreview(diffs: [], blockers: ['دستیار مورد نظر یافت نشد'], needsBiometric: false);
    }
    
    final diffs = <PlanDiff>[];
    final blockers = <String>[];
    bool needsBiometric = false;
    final now = DateTime.now();
    
    // Validate each step in the plan using the Database instance (readonly)
    for (final step in plan.steps) {
      final cmd = getCommand(step.commandId);
      if (cmd == null) {
        blockers.add('فرمان یافت نشد: ${step.commandId}');
        continue;
      }
      if (!persona.commandIds.contains(cmd.id)) {
        blockers.add('دستیار اجازهٔ انجام این کار را ندارد: ${cmd.humanTitle}');
        continue;
      }
      final allowedWrite = await PersonaGate.canWriteDomain(personaId, cmd.touches);
      if (!allowedWrite) {
        blockers.add('دستیار اجازهٔ دسترسی به این بخش اطلاعات را ندارد: ${cmd.humanTitle}');
        continue;
      }
      
      // Parameter validation
      for (final entry in cmd.params.entries) {
        final val = step.payload[entry.key];
        final error = await entry.value.validate(val, db);
        if (error != null) {
          blockers.add(error);
        }
      }
      
      // Sensitivity
      if (cmd.sensitivity == Sensitivity.forbidden) {
        blockers.add('اجرای این کار ممنوع است: ${cmd.humanTitle}');
      } else if (cmd.sensitivity == Sensitivity.sensitive) {
        needsBiometric = true;
      }
      
      if (blockers.isEmpty) {
        final ctx = AgentCommandContext(
          payload: step.payload,
          source: CommandSource.assistant,
          personaId: personaId,
          now: now,
          txn: db,
        );
        try {
          final diff = await cmd.preview(ctx);
          diffs.add(diff);
        } catch (e) {
          blockers.add('خطا در پیش‌نمایش فرمان ${cmd.humanTitle}: $e');
        }
      }
    }
    
    return PlanPreview(diffs: diffs, blockers: blockers, needsBiometric: needsBiometric);
  }

  Future<PlanResult> execute(CommandPlan plan, {required String personaId, required CommandSource source}) async {
    final db = await DatabaseHelper.instance.database;
    final persona = PersonaRegistry.instance.getPersona(personaId);
    if (persona == null) {
      return PlanResult(success: false, planId: plan.id, results: [], errorMessage: 'پرسونا یافت نشد');
    }
    
    final now = DateTime.now();
    final planId = plan.id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : plan.id;
    
    try {
      final planResult = await db.transaction((txn) async {
        // Validate all steps first inside the transaction
        for (final step in plan.steps) {
          final cmd = getCommand(step.commandId);
          if (cmd == null) {
            throw Exception('فرمان یافت نشد: ${step.commandId}');
          }
          if (!persona.commandIds.contains(cmd.id)) {
            throw Exception('این دستیار اجازهٔ این کار را ندارد: ${cmd.humanTitle}');
          }
          final allowedWrite = await PersonaGate.canWriteDomain(personaId, cmd.touches);
          if (!allowedWrite) {
            throw Exception('دستیار اجازهٔ دسترسی و ویرایش این بخش از اطلاعات را ندارد.');
          }
          
          // Parameter validation
          for (final entry in cmd.params.entries) {
            final val = step.payload[entry.key];
            final error = await entry.value.validate(val, txn);
            if (error != null) {
              throw Exception(error);
            }
          }
          
          // Sensitivity check
          if (cmd.sensitivity == Sensitivity.forbidden) {
            throw Exception('اجرای فرمان ${cmd.humanTitle} ممنوع است.');
          }
        }
        
        // Execute steps
        final stepResults = <CommandResult>[];
        for (final step in plan.steps) {
          final cmd = getCommand(step.commandId)!;
          final ctx = AgentCommandContext(
            payload: step.payload,
            source: source,
            personaId: personaId,
            now: now,
            txn: txn,
            planId: planId,
          );
          
          final res = await cmd.run(ctx);
          if (!res.success) {
            throw Exception(res.errorMessage ?? 'خطا در اجرای فرمان ${cmd.humanTitle}');
          }
          stepResults.add(res);
          
          // Record Audit Log
          final auditId = DateTime.now().microsecondsSinceEpoch.toString();
          await CommandAuditRepository.saveStep(txn, StepAuditRecord(
            id: auditId,
            actionType: cmd.id,
            targetKey: res.inverseData != null ? jsonEncode(res.inverseData) : null,
            oldValue: null,
            newValue: step.payload.toString(),
            appliedAt: now.millisecondsSinceEpoch,
            assistantId: 'GLOBAL',
            personaId: personaId,
            planId: planId,
            commandId: cmd.id,
            payloadJson: jsonEncode(step.payload),
            inverseJson: res.inverseData != null ? jsonEncode(res.inverseData) : null,
            status: 'applied',
          ));
        }
        
        // Save Plan
        await CommandAuditRepository.savePlan(txn, PlanAuditRecord(
          id: planId,
          titleFa: plan.titleFa,
          personaId: personaId,
          stepCount: plan.steps.length,
          status: 'applied',
          createdAt: now.millisecondsSinceEpoch,
          appliedAt: now.millisecondsSinceEpoch,
        ));
        
        return stepResults;
      });
      
      // Post-commit triggers
      final allInvalidates = <EngineInvalidationTag>{};
      bool touchesRoutines = false;
      for (final step in plan.steps) {
        final cmd = getCommand(step.commandId)!;
        allInvalidates.addAll(cmd.invalidates);
        if (cmd.touches.contains(DataDomain.routines)) {
          touchesRoutines = true;
        }
      }
      
      // Fire events on RitmoEventBus for tags
      for (final tag in allInvalidates) {
        final eventType = _mapTagToEventType(tag);
        if (eventType != null) {
          RitmoEventBus().fire(RitmoEvent(
            type: eventType.code,
            timestamp: DateTime.now(),
            payload: const {},
          ));
        }
      }
      
      // Sync routines snapshot if needed
      if (touchesRoutines) {
        await SnapshotSyncService.syncAll();
      }
      
      return PlanResult(success: true, planId: planId, results: planResult);
      
    } catch (e) {
      return PlanResult(success: false, planId: planId, results: [], errorMessage: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<CommandResult> undoAudit(String auditId) async {
    final db = await DatabaseHelper.instance.database;
    
    return await db.transaction((txn) async {
      final rows = await txn.query('assistant_audit_log', where: 'id = ?', whereArgs: [auditId], limit: 1);
      if (rows.isEmpty) {
        return CommandResult.failure(commandId: '', errorMessage: 'ممیزی پیدا نشد.');
      }
      
      final record = StepAuditRecord.fromMap(rows.first);
      if (record.status == 'undone') {
        return CommandResult.failure(commandId: record.commandId ?? '', errorMessage: 'این عملیات قبلاً بازگردانده شده است.');
      }
      
      final cmd = getCommand(record.commandId ?? '');
      if (cmd == null) {
        return CommandResult.failure(commandId: record.commandId ?? '', errorMessage: 'فرمان ${record.commandId} یافت نشد.');
      }
      
      final inverseData = record.inverseJson != null ? jsonDecode(record.inverseJson!) as Map<String, dynamic> : <String, dynamic>{};
      final payload = record.payloadJson != null ? jsonDecode(record.payloadJson!) as Map<String, dynamic> : <String, dynamic>{};
      
      final ctx = AgentCommandContext(
        payload: payload,
        source: CommandSource.undo,
        personaId: record.personaId ?? 'global',
        now: DateTime.now(),
        txn: txn,
        planId: record.planId,
      );
      
      final undoResult = await cmd.undo(ctx, inverseData);
      if (undoResult == null || !undoResult.success) {
        return CommandResult.failure(
          commandId: cmd.id,
          errorMessage: undoResult?.errorMessage ?? 'امکان بازگردانی این فرمان وجود ندارد یا با خطا مواجه شد.',
        );
      }
      
      // Update step status
      await txn.update(
        'assistant_audit_log',
        {
          'status': 'undone',
          'undoneAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [auditId],
      );
      
      return CommandResult.ok(commandId: cmd.id);
    });
  }

  Future<PlanResult> undoPlan(String planId) async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      final results = await db.transaction((txn) async {
        final planRows = await txn.query('assistant_plans', where: 'id = ?', whereArgs: [planId], limit: 1);
        if (planRows.isEmpty) {
          throw Exception('برنامه یافت نشد.');
        }
        final planRecord = PlanAuditRecord.fromMap(planRows.first);
        if (planRecord.status == 'undone') {
          throw Exception('این برنامه قبلاً بازگردانده شده است.');
        }
        
        final stepRows = await txn.query(
          'assistant_audit_log',
          where: 'planId = ? AND status = "applied"',
          whereArgs: [planId],
          orderBy: 'appliedAt DESC', // reverse order
        );
        
        final stepResults = <CommandResult>[];
        for (final row in stepRows) {
          final record = StepAuditRecord.fromMap(row);
          final cmd = getCommand(record.commandId ?? '');
          if (cmd == null) {
            throw Exception('فرمان یافت نشد: ${record.commandId}');
          }
          final inverseData = record.inverseJson != null ? jsonDecode(record.inverseJson!) as Map<String, dynamic> : <String, dynamic>{};
          final payload = record.payloadJson != null ? jsonDecode(record.payloadJson!) as Map<String, dynamic> : <String, dynamic>{};
          
          final ctx = AgentCommandContext(
            payload: payload,
            source: CommandSource.undo,
            personaId: record.personaId ?? 'global',
            now: DateTime.now(),
            txn: txn,
            planId: planId,
          );
          
          final res = await cmd.undo(ctx, inverseData);
          if (res == null || !res.success) {
            throw Exception(res?.errorMessage ?? 'بازگردانی عملیات ${cmd.humanTitle} شکست خورد.');
          }
          stepResults.add(res);
          
          // Update status in db
          await txn.update(
            'assistant_audit_log',
            {
              'status': 'undone',
              'undoneAt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [record.id],
          );
        }
        
        // Update plan status
        await txn.update(
          'assistant_plans',
          {
            'status': 'undone',
            'undoneAt': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [planId],
        );
        
        return stepResults;
      });
      
      return PlanResult(success: true, planId: planId, results: results);
    } catch (e) {
      return PlanResult(success: false, planId: planId, results: [], errorMessage: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  RitmoEventType? _mapTagToEventType(EngineInvalidationTag tag) {
    switch (tag) {
      case EngineInvalidationTag.routineStructure:
        return RitmoEventType.routineUpdated;
      case EngineInvalidationTag.routineOutcome:
        return RitmoEventType.occurrenceCompleted;
      case EngineInvalidationTag.courses:
        return RitmoEventType.courseSessionCompleted;
      case EngineInvalidationTag.goals:
        return RitmoEventType.goalChanged;
      case EngineInvalidationTag.worship:
        return RitmoEventType.worshipChanged;
      case EngineInvalidationTag.energy:
        return RitmoEventType.energyLogged;
      case EngineInvalidationTag.sleep:
        return RitmoEventType.sleepLogged;
      case EngineInvalidationTag.zone:
        return RitmoEventType.zoneChanged;
      case EngineInvalidationTag.cycle:
        return RitmoEventType.cycleStarted;
      case EngineInvalidationTag.medicine:
        return RitmoEventType.medicineTaken;
      case EngineInvalidationTag.reflection:
        return RitmoEventType.reflectionSaved;
      case EngineInvalidationTag.global:
        return RitmoEventType.settingsChanged;
    }
  }
}
