import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class OccurrenceOverride {
  const OccurrenceOverride({
    required this.sourceType,
    required this.sourceId,
    required this.dateStr,
    this.timeOfDay,
    this.durationMinutes,
    this.status,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OccurrenceOverride.fromMap(Map<String, dynamic> map) {
    return OccurrenceOverride(
      sourceType: map['sourceType'] as String,
      sourceId: map['sourceId'] as String,
      dateStr: map['dateStr'] as String,
      timeOfDay: map['timeOfDay'] as String?,
      durationMinutes: map['durationMinutes'] as int?,
      status: map['status'] as String?,
      note: map['note'] as String?,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  final String sourceType;
  final String sourceId;
  final String dateStr;
  final String? timeOfDay;
  final int? durationMinutes;
  final String? status;
  final String? note;
  final String createdAt;
  final String updatedAt;

  String get compositeKey => '$sourceType:$sourceId';

  Map<String, dynamic> toMap() {
    return {
      'id': '$sourceType:$sourceId:$dateStr',
      'sourceType': sourceType,
      'sourceId': sourceId,
      'dateStr': dateStr,
      'timeOfDay': timeOfDay,
      'durationMinutes': durationMinutes,
      'status': status,
      'note': note,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  OccurrenceOverride copyWith({
    String? sourceType,
    String? sourceId,
    String? dateStr,
    String? timeOfDay,
    int? durationMinutes,
    String? status,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return OccurrenceOverride(
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      dateStr: dateStr ?? this.dateStr,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

abstract class OccurrenceOverrideRepository {
  Future<Map<String, OccurrenceOverride>> forDate(String dateStr);
  Future<Map<String, List<OccurrenceOverride>>> forRange(
      String startDateStr, String endDateStr);
  Future<void> upsert(OccurrenceOverride override);
  Future<void> remove(String sourceType, String sourceId, String dateStr);
  Future<void> removeAllFuture(String sourceType, String sourceId, String dateStr);
}

class SqliteOccurrenceOverrideRepository implements OccurrenceOverrideRepository {
  const SqliteOccurrenceOverrideRepository();

  @override
  Future<Map<String, OccurrenceOverride>> forDate(String dateStr) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'occurrence_overrides',
      where: 'dateStr = ?',
      whereArgs: [dateStr],
    );

    final map = <String, OccurrenceOverride>{};
    for (final row in rows) {
      final override = OccurrenceOverride.fromMap(row);
      map[override.compositeKey] = override;
    }
    return map;
  }

  @override
  Future<Map<String, List<OccurrenceOverride>>> forRange(
      String startDateStr, String endDateStr) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'occurrence_overrides',
      where: 'dateStr BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
    );

    final result = <String, List<OccurrenceOverride>>{};
    for (final row in rows) {
      final override = OccurrenceOverride.fromMap(row);
      result.putIfAbsent(override.dateStr, () => []).add(override);
    }
    return result;
  }

  @override
  Future<void> upsert(OccurrenceOverride override) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'occurrence_overrides',
      override.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> remove(String sourceType, String sourceId, String dateStr) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'occurrence_overrides',
      where: 'sourceType = ? AND sourceId = ? AND dateStr = ?',
      whereArgs: [sourceType, sourceId, dateStr],
    );
  }

  @override
  Future<void> removeAllFuture(String sourceType, String sourceId, String dateStr) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'occurrence_overrides',
      where: 'sourceType = ? AND sourceId = ? AND dateStr >= ?',
      whereArgs: [sourceType, sourceId, dateStr],
    );
  }
}
