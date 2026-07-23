import 'package:flutter/widgets.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/services/backup_passcode_manager.dart';
import 'package:ritmo/core/services/cycle_notification_service.dart';
import 'package:ritmo/core/services/google_drive_backup_service.dart';
import 'package:workmanager/workmanager.dart';

/// Top-level callback dispatcher entry-point for background tasks (Workmanager).
@pragma('vm:entry-point')
void ritmoCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (taskName == 'weekly_backup_task') {
      try {
        final passcodeManager = BackupPasscodeManager();
        final hasCode = await passcodeManager.hasPasscode();
        if (!hasCode) {
          await CycleNotificationService.showImmediateNotification(
            id: 3001,
            title: 'پشتیبان‌گیری خودکار ریتمو ☁️',
            body:
                'برای فعالسازی بکاپ خودکار، یک رمز عبور (passcode) در '
                'تنظیمات پروفایل خود تنظیم کنید.',
          );
          debugPrint('Weekly backup task aborted: passcode not set.');
          return true; // Return true as we handled the scenario
        }

        final passcode = await passcodeManager.getPasscode();
        if (passcode == null) return true;

        final driveService = GoogleDriveBackupService.instance;
        final signedIn = await driveService.signIn();
        if (!signedIn) {
          debugPrint(
            'Weekly backup task aborted: not signed in to Google Drive.',
          );
          return false; // Retry later
        }

        await driveService.uploadBackup(passcode);
        await driveService.pruneOldBackups();
        return true;
      } catch (e) {
        debugPrint('Weekly backup background task execution failed: $e');
        return false; // Retry later
      }
    } else {
      try {
        await AlarmSchedulerService.scheduleNextAlarms();
        return true;
      } catch (e) {
        return false;
      }
    }
  });
}
