import 'package:sqflite/sqflite.dart';

/// Single source of truth for onboarding completion state.
class OnboardingGate {
  const OnboardingGate._();

  static const int currentVersion = 1;

  /// Returns true if onboarding has been completed.
  static Future<bool> isCompleted(DatabaseExecutor db) async {
    try {
      final rows = await db.query(
        'app_settings',
        where: "key = 'onboarding_completed'",
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return rows.first['value'] == 'true';
      }
    } catch (_) {}
    return false;
  }

  /// Returns the version number of the completed onboarding flow.
  static Future<int> completedVersion(DatabaseExecutor db) async {
    try {
      final rows = await db.query(
        'app_settings',
        where: "key = 'onboarding_version'",
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return int.tryParse(rows.first['value']! as String) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Marks onboarding as completed in SQLite. Must be called inside the final completion transaction.
  static Future<void> markCompleted(DatabaseExecutor txn, {required int version}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await txn.insert(
      'app_settings',
      {
        'key': 'onboarding_completed',
        'value': 'true',
        'updatedAt': nowMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await txn.insert(
      'app_settings',
      {
        'key': 'onboarding_version',
        'value': version.toString(),
        'updatedAt': nowMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
