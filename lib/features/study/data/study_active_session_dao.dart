import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/study/domain/study_models.dart';
import 'package:sqflite/sqflite.dart';

class StudyActiveSessionDao {
  StudyActiveSessionDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static final StudyActiveSessionDao instance = StudyActiveSessionDao();

  final DatabaseHelper _dbHelper;

  Future<ActiveStudySessionState?> getActiveSession() async {
    final db = await _dbHelper.database;
    final rows = await db.query('study_active_session', where: "id = 'singleton'");
    if (rows.isEmpty) return null;
    return ActiveStudySessionState.fromMap(rows.first);
  }

  Future<void> saveActiveSession(ActiveStudySessionState state) async {
    final db = await _dbHelper.database;
    await db.insert(
      'study_active_session',
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearActiveSession() async {
    final db = await _dbHelper.database;
    await db.delete('study_active_session', where: "id = 'singleton'");
  }
}
