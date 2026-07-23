import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:sqflite/sqflite.dart';

class KonkurRepository {
  KonkurRepository._init();
  static final KonkurRepository instance = KonkurRepository._init();

  Future<Database> get _database async => DatabaseHelper.instance.database;

  // READ METHODS
  Future<List<KonkurSubject>> getSubjects() async {
    final db = await _database;
    final maps = await db.query('konkur_subjects', where: 'isArchived = 0', orderBy: 'orderIndex ASC');
    return maps.map(KonkurSubject.fromMap).toList();
  }

  Future<List<KonkurTopic>> getTopics() async {
    final db = await _database;
    final maps = await db.query('konkur_topics', orderBy: 'orderIndex ASC');
    return maps.map(KonkurTopic.fromMap).toList();
  }

  Future<List<KonkurStudySession>> getStudySessions() async {
    final db = await _database;
    final maps = await db.query('konkur_study_sessions', orderBy: 'dateIso DESC, createdAt DESC');
    return maps.map(KonkurStudySession.fromMap).toList();
  }

  Future<List<KonkurMockExam>> getMockExams() async {
    final db = await _database;
    final maps = await db.query('konkur_mock_exams', orderBy: 'examDate DESC, createdAt DESC');
    return maps.map(KonkurMockExam.fromMap).toList();
  }

  Future<List<KonkurMockResult>> getMockResults() async {
    final db = await _database;
    final maps = await db.query('konkur_mock_exam_results', orderBy: 'createdAt DESC');
    return maps.map(KonkurMockResult.fromMap).toList();
  }

  Future<List<KonkurPlanItem>> getPlanItems() async {
    final db = await _database;
    final maps = await db.query('konkur_plan_items', orderBy: 'dateIso ASC, createdAt DESC');
    return maps.map(KonkurPlanItem.fromMap).toList();
  }

  Future<Map<String, String>> getAppSettings() async {
    final db = await _database;
    final maps = await db.query('app_settings');
    return {for (final item in maps) item['key']! as String: item['value']! as String};
  }

  // WRITE/UPDATE METHODS
  Future<void> insertSubject(KonkurSubject subject) async {
    final db = await _database;
    await db.insert('konkur_subjects', subject.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSubject(KonkurSubject subject) async {
    final db = await _database;
    await db.update('konkur_subjects', subject.toMap(), where: 'id = ?', whereArgs: [subject.id]);
  }

  Future<void> deleteSubject(String subjectId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('konkur_subjects', where: 'id = ?', whereArgs: [subjectId]);
      await txn.delete('konkur_topics', where: 'subjectId = ?', whereArgs: [subjectId]);
      await txn.delete('konkur_plan_items', where: 'subjectId = ?', whereArgs: [subjectId]);
      await txn.delete('konkur_study_sessions', where: 'subjectId = ?', whereArgs: [subjectId]);
      await txn.delete('konkur_mock_exam_results', where: 'subjectId = ?', whereArgs: [subjectId]);
    });
  }

  Future<void> insertTopic(KonkurTopic topic) async {
    final db = await _database;
    await db.insert('konkur_topics', topic.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTopic(KonkurTopic topic) async {
    final db = await _database;
    await db.update('konkur_topics', topic.toMap(), where: 'id = ?', whereArgs: [topic.id]);
  }

  Future<void> deleteTopic(String topicId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('konkur_topics', where: 'id = ?', whereArgs: [topicId]);
      await txn.delete('konkur_plan_items', where: 'topicId = ?', whereArgs: [topicId]);
      await txn.delete('konkur_study_sessions', where: 'topicId = ?', whereArgs: [topicId]);
    });
  }

  Future<void> insertStudySession(KonkurStudySession session) async {
    final db = await _database;
    await db.transaction((txn) async {
      // 1. Insert session
      await txn.insert('konkur_study_sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      // 2. Update subject and topic completion minutes if topicId is specified
      if (session.topicId != null) {
        final topicMapList = await txn.query('konkur_topics', where: 'id = ?', whereArgs: [session.topicId], limit: 1);
        if (topicMapList.isNotEmpty) {
          final topic = KonkurTopic.fromMap(topicMapList.first);
          final updatedCompleted = topic.studyCompletedMinutes + session.durationMinutes;
          
          await txn.update(
            'konkur_topics',
            {
              'studyCompletedMinutes': updatedCompleted,
              'lastStudiedAt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [topic.id],
          );
        }
      }
    });
  }

  Future<void> deleteStudySession(String sessionId) async {
    final db = await _database;
    await db.delete('konkur_study_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<void> insertMockExam(KonkurMockExam exam) async {
    final db = await _database;
    await db.insert('konkur_mock_exams', exam.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMockExam(String examId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('konkur_mock_exams', where: 'id = ?', whereArgs: [examId]);
      await txn.delete('konkur_mock_exam_results', where: 'mockExamId = ?', whereArgs: [examId]);
    });
  }

  Future<void> insertMockResult(KonkurMockResult result) async {
    final db = await _database;
    await db.insert('konkur_mock_exam_results', result.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMockResult(String resultId) async {
    final db = await _database;
    await db.delete('konkur_mock_exam_results', where: 'id = ?', whereArgs: [resultId]);
  }

  Future<void> insertPlanItem(KonkurPlanItem item) async {
    final db = await _database;
    await db.insert('konkur_plan_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePlanItemStatus(String itemId, String status) async {
    final db = await _database;
    await db.update('konkur_plan_items', {'status': status}, where: 'id = ?', whereArgs: [itemId]);
  }

  Future<void> savePlanItems(List<KonkurPlanItem> items) async {
    final db = await _database;
    await db.transaction((txn) async {
      // Clear future pending plan items to allow replanning
      final todayStr = _formatDate(DateTime.now());
      await txn.delete('konkur_plan_items', where: 'dateIso >= ? AND status = ?', whereArgs: [todayStr, 'PENDING']);
      
      final batch = txn.batch();
      for (final item in items) {
        batch.insert('konkur_plan_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> updateAppSetting(String key, String value) async {
    final db = await _database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> resetKonkurModule() async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('konkur_subjects');
      await txn.delete('konkur_topics');
      await txn.delete('konkur_study_sessions');
      await txn.delete('konkur_mock_exams');
      await txn.delete('konkur_mock_exam_results');
      await txn.delete('konkur_plan_items');

      final now = DateTime.now().millisecondsSinceEpoch;
      final settingsToReset = {
        'konkur_field': 'UNSET',
        'konkur_exam_date': '',
        'konkur_setup_done': 'false',
        'konkur_daily_target_minutes': '180',
        'konkur_show_in_dashboard': 'true',
      };

      for (final entry in settingsToReset.entries) {
        await txn.insert(
          'app_settings',
          {
            'key': entry.key,
            'value': entry.value,
            'updatedAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
