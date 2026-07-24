import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:sqflite/sqflite.dart';

/// Single source of truth repository for SS user profile with caching.
class SSProfileRepository {
  SSProfileRepository._();
  static final SSProfileRepository instance = SSProfileRepository._();

  SsUserProfile? _cachedProfile;

  /// Gets cached user profile, loading from DB if needed.
  Future<SsUserProfile?> getProfile({bool forceRefresh = false}) async {
    if (_cachedProfile != null && !forceRefresh) {
      return _cachedProfile;
    }

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('ss_user_profile', where: "id = 'default'");
    if (rows.isEmpty) {
      return null;
    }

    _cachedProfile = SsUserProfile.fromMap(rows.first);
    return _cachedProfile;
  }

  /// Saves profile to database and updates cache.
  Future<void> saveProfile(SsUserProfile profile, {DatabaseExecutor? executor}) async {
    final db = executor ?? await DatabaseHelper.instance.database;
    await db.insert(
      'ss_user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _cachedProfile = profile;
  }

  /// Clears profile cache.
  void clearCache() {
    _cachedProfile = null;
  }
}
