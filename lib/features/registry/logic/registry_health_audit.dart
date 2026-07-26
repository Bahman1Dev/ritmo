// lib/features/registry/logic/registry_health_audit.dart

import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/registry/domain/registry_health_issue.dart';
import 'package:ritmo/features/registry/logic/registry_index.dart';

class RegistryHealthAudit {
  Future<List<RegistryHealthIssue>> inspectAll(
    Map<String, String> settingsMap,
  ) async {
    final results = await Future.wait([
      _inspectRoutineWithoutSchedule(),
      _inspectOrphanReminder(),
      _inspectSilentReminder(),
      _inspectExpiredAlarm(),
      _inspectOrphanSettingsKey(settingsMap),
      _inspectInvalidDuration(),
    ]);

    return results.whereType<RegistryHealthIssue>().toList();
  }

  /// Inspector 1: Routines without schedule
  Future<RegistryHealthIssue?> _inspectRoutineWithoutSchedule() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery('''
        SELECT r.id, r.title FROM routines r
        LEFT JOIN routine_schedules s ON r.id = s.routineId
        WHERE s.id IS NULL AND r.isArchived = 0 AND r.itemType != 'MEDICINE'
      ''');

      if (rows.isEmpty) return null;

      final ids = rows.map((r) => r['id'] as String).toList();
      return RegistryHealthIssue(
        kind: HealthIssueKind.routineWithoutSchedule,
        severity: HealthSeverity.warning,
        title: 'روتین بدون زمان‌بندی',
        description:
            'تعداد ${rows.length} روتین تعریف شده اما هیچ برنامه زمان‌بندی ندارند.',
        fixLabel: 'تنظیم زمان‌بندی',
        affectedIds: ids,
        fix: (context) async {
          final txDb = await DatabaseHelper.instance.database;
          final now = DateTime.now().millisecondsSinceEpoch;
          for (final id in ids) {
            await txDb.rawInsert('''
              INSERT OR REPLACE INTO routine_schedules (id, routineId, type, preferredTimeOfDay, durationMinutes, createdAt)
              VALUES (?, ?, 'DAILY', '08:00', 30, ?)
            ''', ['sched_$id', id, now]);
          }
          RegistryIndex.instance.invalidate();
          if (context.mounted) {
            RitmoToast.show(context, 'زمان‌بندی پیش‌فرض (۰۸:۰۰ صبح) برای روتین‌ها ایجاد شد.');
          }
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// Inspector 2: Orphan reminders
  Future<RegistryHealthIssue?> _inspectOrphanReminder() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery('''
        SELECT pr.id FROM pending_reminders pr
        LEFT JOIN routines r ON pr.routineId = r.id
        LEFT JOIN doctor_visits dv ON pr.id = 'visit_' || dv.id
        LEFT JOIN course_sessions cs ON pr.courseSessionId = cs.id
        WHERE r.id IS NULL AND dv.id IS NULL AND cs.id IS NULL
          AND pr.routineId != 'cycle_private_reminder'
      ''');

      if (rows.isEmpty) return null;

      final ids = rows.map((r) => r['id'] as String).toList();
      return RegistryHealthIssue(
        kind: HealthIssueKind.orphanReminder,
        severity: HealthSeverity.critical,
        title: 'یادآور بی‌صاحب',
        description:
            'تعداد ${rows.length} یادآور متعلق به روتین یا رخدادهای حذف‌شده یافت شد.',
        fixLabel: 'پاک‌سازی یادآورها',
        affectedIds: ids,
        fix: (context) async {
          final txDb = await DatabaseHelper.instance.database;
          for (final id in ids) {
            await txDb.delete('pending_reminders', where: 'id = ?', whereArgs: [id]);
          }
          RegistryIndex.instance.invalidate();
          if (context.mounted) {
            RitmoToast.show(context, 'یادآورهای بی‌صاحب پاک‌سازی شدند.');
          }
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// Inspector 3: Silent reminders
  Future<RegistryHealthIssue?> _inspectSilentReminder() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery('''
        SELECT r.id, r.title FROM routines r
        LEFT JOIN pending_reminders pr ON r.id = pr.routineId AND pr.state = 'SCHEDULED'
        WHERE r.notificationLevel != 'NONE' AND r.isArchived = 0 AND pr.id IS NULL
      ''');

      if (rows.isEmpty) return null;

      final ids = rows.map((r) => r['id'] as String).toList();
      return RegistryHealthIssue(
        kind: HealthIssueKind.silentReminder,
        severity: HealthSeverity.critical,
        title: 'یادآور بی‌صدا',
        description:
            'تعداد ${rows.length} روتین یادآور فعال دارند اما در صف یادآورهای دستگاه قرار نگرفته‌اند.',
        fixLabel: 'بازسازی آلارم‌ها',
        affectedIds: ids,
        fix: (context) async {
          final txDb = await DatabaseHelper.instance.database;
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          for (final id in ids) {
            final routineRows = await txDb.query('routines', where: 'id = ?', whereArgs: [id]);
            final title = routineRows.isNotEmpty ? (routineRows.first['title'] as String? ?? 'روتین') : 'روتین';
            await txDb.rawInsert('''
              INSERT OR REPLACE INTO pending_reminders (id, routineId, title, scheduledTime, state)
              VALUES (?, ?, ?, ?, 'SCHEDULED')
            ''', ['rem_$id', id, title, nowMs + (60 * 60 * 1000)]);
          }
          RegistryIndex.instance.invalidate();
          if (context.mounted) {
            RitmoToast.show(context, 'آلارم‌های روتین بازسازی و فعال شدند.');
          }
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// Inspector 4: Expired alarms
  Future<RegistryHealthIssue?> _inspectExpiredAlarm() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoff = nowMs - (24 * 60 * 60 * 1000);

      final rows = await db.rawQuery('''
        SELECT id FROM pending_reminders
        WHERE state = 'unknown' AND scheduledTime < ?
      ''', [cutoff]);

      if (rows.isEmpty) return null;

      final ids = rows.map((r) => r['id'] as String).toList();
      return RegistryHealthIssue(
        kind: HealthIssueKind.expiredAlarm,
        severity: HealthSeverity.warning,
        title: 'آلارم منقضی‌شده',
        description:
            'تعداد ${rows.length} یادآور از روزهای گذشته در حالت نامشخص باقی مانده‌اند.',
        fixLabel: 'به‌روزرسانی حالت',
        affectedIds: ids,
        fix: (context) async {
          final txDb = await DatabaseHelper.instance.database;
          await txDb.rawUpdate('''
            UPDATE pending_reminders SET state = 'expired'
            WHERE state = 'unknown' AND scheduledTime < ?
          ''', [cutoff]);
          RegistryIndex.instance.invalidate();
          if (context.mounted) {
            RitmoToast.show(context, 'حالت آلارم‌ها به‌روز شد.');
          }
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// Inspector 7: Orphan settings key `module_sports_enabled`
  Future<RegistryHealthIssue?> _inspectOrphanSettingsKey(
    Map<String, String> settingsMap,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'app_settings',
        where: "key = 'module_sports_enabled'",
      );

      if (rows.isEmpty) return null;

      final val = rows.first['value'] as String?;
      return RegistryHealthIssue(
        kind: HealthIssueKind.orphanSettingsKey,
        severity: HealthSeverity.info,
        title: 'کلید تنظیمات قدیمی ورزش',
        description: 'کلید تنظیمات قدیمی module_sports_enabled شناسایی شد.',
        fixLabel: 'ادغام و حذف کلید',
        affectedIds: ['module_sports_enabled'],
        fix: (context) async {
          final txDb = await DatabaseHelper.instance.database;
          if (val == 'true') {
            await txDb.rawUpdate('''
              INSERT OR REPLACE INTO app_settings (key, value, updatedAt)
              VALUES ('module_supplementary_sports_enabled', 'true', ?)
            ''', [DateTime.now().millisecondsSinceEpoch]);
          }
          await txDb.delete(
            'app_settings',
            where: "key = 'module_sports_enabled'",
          );
          RegistryIndex.instance.invalidate();
          if (context.mounted) {
            RitmoToast.show(context, 'کلید قدیمی با موفقیت ادغام و حذف شد.');
          }
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// Inspector 8: Invalid durations
  Future<RegistryHealthIssue?> _inspectInvalidDuration() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery('''
        SELECT id, title, targetDurationMinutes FROM routines
        WHERE targetDurationMinutes > ? OR targetDurationMinutes <= 0
      ''', [DurationBounds.maxMinutes]);

      if (rows.isEmpty) return null;

      final ids = rows.map((r) => r['id'] as String).toList();
      return RegistryHealthIssue(
        kind: HealthIssueKind.invalidDuration,
        severity: HealthSeverity.warning,
        title: 'مدت‌زمان غیرمنطقی روتین',
        description:
            'تعداد ${rows.length} روتین دارای مدت زمان غیرمنطقی (بزرگتر از ۸ ساعت یا کمتر از ۰) هستند.',
        fixLabel: 'اصلاح مدت‌زمان‌ها',
        affectedIds: ids,
        fix: (context) async {
          final txDb = await DatabaseHelper.instance.database;
          await txDb.execute('''
            UPDATE routines SET targetDurationMinutes = 480 WHERE targetDurationMinutes > 480;
            UPDATE routines SET targetDurationMinutes = 30 WHERE targetDurationMinutes <= 0;
          ''');
          RegistryIndex.instance.invalidate();
          if (context.mounted) {
            RitmoToast.show(context, 'مدت‌زمان روتین‌ها اصلاح شد.');
          }
        },
      );
    } catch (e) {
      return null;
    }
  }
}
