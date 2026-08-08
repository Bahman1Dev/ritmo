import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/supplementary_sports/domain/prescription/session_prescription.dart';
import 'package:sqflite/sqflite.dart';

class SsPrescriptionRepository {
  SsPrescriptionRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static final SsPrescriptionRepository instance = SsPrescriptionRepository();

  final DatabaseHelper _dbHelper;

  Future<Database> get _database async => _dbHelper.database;

  Future<List<SessionPrescription>> getAllPrescriptions({String? status, int? limit}) async {
    final db = await _database;
    final where = status != null ? 'status = ?' : null;
    final whereArgs = status != null ? [status] : null;
    final rows = await db.query(
      'ss_session_prescription',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'dateIso ASC',
      limit: limit,
    );
    return rows.map(SessionPrescription.fromMap).toList();
  }

  Future<List<SessionPrescription>> getPrescriptionsInDateRange(String startIso, String endIso) async {
    final db = await _database;
    final rows = await db.query(
      'ss_session_prescription',
      where: 'dateIso >= ? AND dateIso <= ?',
      whereArgs: [startIso, endIso],
      orderBy: 'dateIso ASC',
    );
    return rows.map(SessionPrescription.fromMap).toList();
  }

  Future<SessionPrescription?> getPrescriptionForDate(String dateIso) async {
    final db = await _database;
    final rows = await db.query(
      'ss_session_prescription',
      where: 'dateIso = ?',
      whereArgs: [dateIso],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SessionPrescription.fromMap(rows.first);
  }

  Future<SessionPrescription?> getPrescriptionById(String id) async {
    final db = await _database;
    final rows = await db.query(
      'ss_session_prescription',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SessionPrescription.fromMap(rows.first);
  }

  Future<void> savePrescription(SessionPrescription p) async {
    final db = await _database;
    await db.insert(
      'ss_session_prescription',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> savePrescriptionsBulk(List<SessionPrescription> list) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final p in list) {
        await txn.insert(
          'ss_session_prescription',
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deletePrescriptionsBulk(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      'ss_session_prescription',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> resetAllPrescriptions() async {
    final db = await _database;
    await db.delete('ss_session_prescription');
  }

  Future<void> resetPlannedPrescriptions() async {
    final db = await _database;
    await db.delete(
      'ss_session_prescription',
      where: "status = 'PLANNED' AND isLocked = 0",
    );
  }
}
