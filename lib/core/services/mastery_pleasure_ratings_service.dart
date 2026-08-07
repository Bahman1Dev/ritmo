import 'package:ritmo/core/database/database_helper.dart';

class MasteryPleasureRatingsService {
  MasteryPleasureRatingsService._();
  static final MasteryPleasureRatingsService instance = MasteryPleasureRatingsService._();

  /// Records optional 0-5 mastery and pleasure ratings for a routine completion (§3, م-۱۱).
  Future<void> recordRatings({
    required String completionId,
    int? masteryRating, // 0 to 5
    int? pleasureRating, // 0 to 5
  }) async {
    final db = await DatabaseHelper.instance.database;
    final updates = <String, dynamic>{};
    if (masteryRating != null) updates['masteryRating'] = masteryRating.clamp(0, 5);
    if (pleasureRating != null) updates['pleasureRating'] = pleasureRating.clamp(0, 5);

    if (updates.isNotEmpty) {
      await db.update(
        'routine_completions',
        updates,
        where: 'id = ?',
        whereArgs: [completionId],
      );
    }
  }

  /// Identifies activities that consistently yield high pleasure/mastery ratings (Behavioral Activation).
  Future<List<Map<String, dynamic>>> getTopActivatingActivities() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT r.id, r.title, r.category,
             AVG(rc.masteryRating) as avgMastery,
             AVG(rc.pleasureRating) as avgPleasure,
             COUNT(rc.id) as sampleCount
      FROM routine_completions rc
      JOIN routines r ON rc.routineId = r.id
      WHERE rc.masteryRating IS NOT NULL OR rc.pleasureRating IS NOT NULL
      GROUP BY r.id
      HAVING sampleCount >= 3
      ORDER BY (AVG(rc.masteryRating) + AVG(rc.pleasureRating)) DESC
      LIMIT 5
    ''');

    return rows;
  }
}
