import 'package:ritmo/core/database/database_helper.dart';

class PersonalKanbanWIPService {
  PersonalKanbanWIPService._();
  static final PersonalKanbanWIPService instance = PersonalKanbanWIPService._();

  static const int defaultMaxActiveGoals = 3;

  /// Fetches max allowed active goals limit from settings.
  Future<int> getMaxActiveGoalsLimit() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'app_settings',
      where: "key = 'wip_limit_max_goals'",
    );
    if (rows.isNotEmpty) {
      final val = int.tryParse(rows.first['value']?.toString() ?? '');
      if (val != null && val > 0) return val;
    }
    return defaultMaxActiveGoals;
  }

  /// Returns currently active goals.
  Future<List<Map<String, dynamic>>> getActiveGoals() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      'goals',
      where: "status = 'ACTIVE'",
      orderBy: 'updatedAt DESC',
    );
  }

  /// Checks if adding/activating a goal exceeds the WIP limit.
  Future<bool> isWIPLimitExceeded() async {
    final limit = await getMaxActiveGoalsLimit();
    final activeGoals = await getActiveGoals();
    return activeGoals.length >= limit;
  }

  /// Parks an active goal (status = 'PARKED').
  Future<void> parkGoal(String goalId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'goals',
      {
        'status': 'PARKED',
        'pausedAt': now,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  /// Unparks a goal (status = 'ACTIVE').
  Future<void> unparkGoal(String goalId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'goals',
      {
        'status': 'ACTIVE',
        'pausedAt': null,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }
}
