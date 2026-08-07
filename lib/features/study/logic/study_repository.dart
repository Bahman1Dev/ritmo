import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:sqflite/sqflite.dart';

typedef StudySubject = KonkurSubject;
typedef StudyTopic = KonkurTopic;
typedef StudySession = KonkurStudySession;

class StudyRepository {
  StudyRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static final StudyRepository instance = StudyRepository();

  final DatabaseHelper _dbHelper;

  Future<Database> get _database async => _dbHelper.database;

  Future<List<StudySubject>> getSubjects() async {
    final db = await _database;
    final rows = await db.query('konkur_subjects', where: 'isArchived = 0', orderBy: 'orderIndex ASC');
    return rows.map(StudySubject.fromMap).toList();
  }

  Future<void> insertSubject(StudySubject subject) async {
    final db = await _database;
    await db.insert('konkur_subjects', subject.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StudyTopic>> getTopics({String? subjectId}) async {
    final db = await _database;
    final where = subjectId != null ? 'subjectId = ?' : null;
    final whereArgs = subjectId != null ? [subjectId] : null;
    final rows = await db.query('konkur_topics', where: where, whereArgs: whereArgs, orderBy: 'orderIndex ASC');
    return rows.map(StudyTopic.fromMap).toList();
  }

  Future<void> insertTopic(StudyTopic topic) async {
    final db = await _database;
    await db.insert('konkur_topics', topic.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StudySession>> getSessions({String? date}) async {
    final db = await _database;
    final where = date != null ? 'dateIso = ?' : null;
    final whereArgs = date != null ? [date] : null;
    final rows = await db.query('konkur_study_sessions', where: where, whereArgs: whereArgs, orderBy: 'createdAt DESC');
    return rows.map(StudySession.fromMap).toList();
  }

  Future<void> insertSession(StudySession session) async {
    final db = await _database;
    await db.insert('konkur_study_sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

typedef KonkurRepository = StudyRepository;
