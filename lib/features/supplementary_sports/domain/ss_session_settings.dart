import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Configuration settings for workout sessions.
class SSSessionSettings {
  final int defaultRestSeconds;
  final bool ttsEnabled;
  final bool ttsCountdownEnabled;
  final bool audioCuesEnabled;
  final bool unitsMetric;
  final bool neighborFriendly;
  final int defaultRir;

  const SSSessionSettings({
    this.defaultRestSeconds = 90,
    this.ttsEnabled = true,
    this.ttsCountdownEnabled = true,
    this.audioCuesEnabled = true,
    this.unitsMetric = true,
    this.neighborFriendly = false,
    this.defaultRir = 2,
  });

  /// Loads session settings from database.
  static Future<SSSessionSettings> load({DatabaseExecutor? executor}) async {
    final db = executor ?? await DatabaseHelper.instance.database;
    final profileRows = await db.query('ss_user_profile', where: "id = 'default'");
    final neighborFriendly = profileRows.isNotEmpty && (profileRows.first['neighborFriendly'] == 1);

    return SSSessionSettings(
      defaultRestSeconds: 90,
      ttsEnabled: true,
      ttsCountdownEnabled: true,
      audioCuesEnabled: true,
      unitsMetric: true,
      neighborFriendly: neighborFriendly,
      defaultRir: 2,
    );
  }
}
