import 'package:ritmo/core/utils/snapshot_helper.dart';
import 'package:sqflite/sqflite.dart';

class ReminderSnapshotService {
  const ReminderSnapshotService();

  Future<void> sync({
    required Database db,
    required Map<String, String> settingsMap,
  }) async {
    // Include both routine-linked reminders, standalone alarms (doctor visits),
    // and course session reminders.
    final activeReminders = await db.rawQuery('''
      SELECT pr.id, pr.routineId, pr.scheduledTime,
             COALESCE(
               r.title, 
               'نوبت پزشک: ' || dv.doctorName, 
               'کلاس: ' || c.title, 
               pr.id
             ) AS title,
             CASE 
               WHEN r.isEssential IS NOT NULL THEN r.isEssential
               WHEN dv.id IS NOT NULL THEN 1
               ELSE 0
             END AS isEssential
      FROM pending_reminders pr
      LEFT JOIN routines r ON pr.routineId = r.id
      LEFT JOIN doctor_visits dv ON pr.id = 'visit_' || dv.id
      LEFT JOIN course_sessions cs ON pr.courseSessionId = cs.id
      LEFT JOIN courses c ON cs.courseId = c.id
      WHERE (pr.state = 'unknown' OR pr.state = 'delayed' OR pr.state = 'SCHEDULED')
        AND (r.isArchived = 0 OR r.id IS NULL)
    ''');

    await SnapshotHelper.updateActiveAlarmsSnapshot(activeReminders);
    await SnapshotHelper.updateNotificationSettingsSnapshot(settingsMap);
  }
}
