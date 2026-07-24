import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/sync/agenda_widget_snapshot_service.dart';
import 'package:ritmo/core/services/sync/home_widget_snapshot_service.dart';
import 'package:ritmo/core/services/sync/occurrence_sync_service.dart';
import 'package:ritmo/core/services/sync/reminder_snapshot_service.dart';
import 'package:ritmo/core/services/sync/rhythm_snapshot_service.dart';
import 'package:ritmo/core/services/sync/today_snapshot_context_builder.dart';

class SyncCoordinator {
  const SyncCoordinator();

  Future<void> syncAll() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    final settingsResult = await db.query('app_settings');
    final settingsMap = {
      for (final s in settingsResult) s['key']! as String: s['value']! as String,
    };

    await const RhythmSnapshotService().backfillRhythmLogs(
      db: db,
      settingsMap: settingsMap,
    );

    await const RhythmSnapshotService().syncDailyRhythmForDate(
      db: db,
      dateStr: todayStr,
      settingsMap: settingsMap,
    );

    await const OccurrenceSyncService().backfillAndGenerateAll(db);

    final state = await const TodaySnapshotContextBuilder().build(
      db: db,
      now: now,
      settingsMap: settingsMap,
    );

    await const HomeWidgetSnapshotService().sync(
      db: db,
      state: state,
    );

    await const AgendaWidgetSnapshotService().sync(
      now: now,
    );

    await const ReminderSnapshotService().sync(
      db: db,
      settingsMap: settingsMap,
    );
  }
}
