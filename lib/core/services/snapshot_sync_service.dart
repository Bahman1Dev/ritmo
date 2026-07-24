import 'package:ritmo/core/services/sync/rhythm_snapshot_service.dart';
import 'package:ritmo/core/services/sync/sync_coordinator.dart';
import 'package:sqflite/sqflite.dart';

class SnapshotSyncService {
  static Future<void> syncAll() {
    return const SyncCoordinator().syncAll();
  }

  static Future<void> syncDailyRhythmForDate(
    Database db,
    String dateStr,
    Map<String, String> settingsMap,
  ) {
    return const RhythmSnapshotService().syncDailyRhythmForDate(
      db: db,
      dateStr: dateStr,
      settingsMap: settingsMap,
    );
  }

  static Future<void> backfillRhythmLogs(
    Database db,
    Map<String, String> settingsMap,
  ) {
    return const RhythmSnapshotService().backfillRhythmLogs(
      db: db,
      settingsMap: settingsMap,
    );
  }
}
