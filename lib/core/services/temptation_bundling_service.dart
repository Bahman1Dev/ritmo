import 'package:ritmo/core/database/database_helper.dart';

class TemptationBundlingService {
  TemptationBundlingService._();
  static final TemptationBundlingService instance = TemptationBundlingService._();

  /// Pairs a low-attraction routine with a rewarding/enjoyable activity (§3, م-۱۳).
  Future<void> pairTemptationBundle({
    required String routineId,
    required String temptationBundleText,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'routines',
      {
        'temptationBundle': temptationBundleText.trim(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [routineId],
    );
  }

  /// Removes temptation bundle pairing.
  Future<void> removeTemptationBundle(String routineId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'routines',
      {
        'temptationBundle': null,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [routineId],
    );
  }
}
