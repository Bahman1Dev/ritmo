import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';

class PlanAuditRecord {
  PlanAuditRecord({
    required this.id,
    required this.titleFa,
    required this.personaId,
    required this.stepCount,
    required this.status,
    required this.createdAt,
    this.appliedAt,
    this.undoneAt,
  });

  final String id;
  final String titleFa;
  final String personaId;
  final int stepCount;
  final String status;
  final int createdAt;
  final int? appliedAt;
  final int? undoneAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titleFa': titleFa,
      'personaId': personaId,
      'stepCount': stepCount,
      'status': status,
      'createdAt': createdAt,
      'appliedAt': appliedAt,
      'undoneAt': undoneAt,
    };
  }

  factory PlanAuditRecord.fromMap(Map<String, dynamic> map) {
    return PlanAuditRecord(
      id: map['id'] as String,
      titleFa: map['titleFa'] as String,
      personaId: map['personaId'] as String,
      stepCount: map['stepCount'] as int,
      status: map['status'] as String,
      createdAt: map['createdAt'] as int,
      appliedAt: map['appliedAt'] as int?,
      undoneAt: map['undoneAt'] as int?,
    );
  }
}

class StepAuditRecord {
  StepAuditRecord({
    required this.id,
    required this.actionType,
    this.targetKey,
    this.oldValue,
    this.newValue,
    required this.appliedAt,
    this.assistantId,
    this.personaId,
    this.planId,
    this.commandId,
    this.payloadJson,
    this.inverseJson,
    this.status,
    this.undoneAt,
  });

  final String id;
  final String actionType;
  final String? targetKey;
  final String? oldValue;
  final String? newValue;
  final int appliedAt;
  final String? assistantId;
  final String? personaId;
  final String? planId;
  final String? commandId;
  final String? payloadJson;
  final String? inverseJson;
  final String? status;
  final int? undoneAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actionType': actionType,
      'targetKey': targetKey,
      'oldValue': oldValue,
      'newValue': newValue,
      'appliedAt': appliedAt,
      'assistantId': assistantId,
      'personaId': personaId,
      'planId': planId,
      'commandId': commandId,
      'payloadJson': payloadJson,
      'inverseJson': inverseJson,
      'status': status,
      'undoneAt': undoneAt,
    };
  }

  factory StepAuditRecord.fromMap(Map<String, dynamic> map) {
    return StepAuditRecord(
      id: map['id'] as String,
      actionType: map['actionType'] as String,
      targetKey: map['targetKey'] as String?,
      oldValue: map['oldValue'] as String?,
      newValue: map['newValue'] as String?,
      appliedAt: map['appliedAt'] as int,
      assistantId: map['assistantId'] as String?,
      personaId: map['personaId'] as String?,
      planId: map['planId'] as String?,
      commandId: map['commandId'] as String?,
      payloadJson: map['payloadJson'] as String?,
      inverseJson: map['inverseJson'] as String?,
      status: map['status'] as String?,
      undoneAt: map['undoneAt'] as int?,
    );
  }
}

class CommandAuditRepository {
  static Future<void> savePlan(DatabaseExecutor txn, PlanAuditRecord plan) async {
    await txn.insert('assistant_plans', plan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> saveStep(DatabaseExecutor txn, StepAuditRecord step) async {
    await txn.insert('assistant_audit_log', step.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<PlanAuditRecord>> getRecentPlans({int limit = 50}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'assistant_plans',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return rows.map((r) => PlanAuditRecord.fromMap(r)).toList();
  }

  static Future<int> getPlansCountInLast7Days() async {
    final db = await DatabaseHelper.instance.database;
    final cutoff = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM assistant_plans WHERE status = "applied" AND appliedAt >= ?',
      [cutoff],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<List<StepAuditRecord>> getStepsForPlan(String planId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'assistant_audit_log',
      where: 'planId = ?',
      whereArgs: [planId],
      orderBy: 'appliedAt ASC',
    );
    return rows.map((r) => StepAuditRecord.fromMap(r)).toList();
  }
}
