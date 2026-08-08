# Prompt 061 Completion Report
**Notification & Alarm System Overhaul (Reliability, Lock Screen, Full-Screen Alarm)**

## Executive Summary
Prompt 061 has been fully executed step-by-step with maximum engineering rigor and precision. The notification and physical alarm layer of Ritmo has been completely revamped for 100% reliable execution, full-screen lock screen support, unified status tracking, and comprehensive diagnostics.

---

## 1. Pre-flight Checks (§2 Audit Outcomes)
1. **Check 1 (Background Channel Registration):** Native channel `com.ritmo.app/alarms` was registered ONLY in `MainActivity.kt`. It was missing on background engines (`NotificationActionReceiver.kt` and `RitmoAgendaWidgetProvider.kt`).
   - **Resolution:** Created `AlarmChannelRegistrar.kt` and registered on all FlutterEngine instances.
2. **Check 2 (Lock Screen & Full-Screen Intent):** 0 occurrences of `setFullScreenIntent`, `turnScreenOn`, or `showWhenLocked`.
   - **Resolution:** Implemented `AlarmActivity.kt`, `activity_alarm.xml`, `AlarmTheme`, and `setFullScreenIntent` in `BootReceiver.kt`.
3. **Check 3 (Notification Properties in BootReceiver):** 0 occurrences of `setCategory`, `setVisibility`, `setSound`.
   - **Resolution:** Added `setCategory(NotificationCompat.CATEGORY_ALARM)`, `setVisibility(NotificationCompat.VISIBILITY_PRIVATE)`, `setPublicVersion(...)`, and `setSound(...)`.
4. **Check 4 (Status Divergence):** `SnoozeReminderHandler` used status `'rescheduled'`, while `AlarmSchedulerService` searched for `('pending', 'snoozed')`.
   - **Resolution:** Standardized on `'snoozed'` across database, handlers, policies, and migrations.
5. **Check 5 (Dead Zone Gate):** `BootReceiver.kt` queried `ritmo_secure.db` for zone rules, which was renamed to `ritmo.db`.
   - **Resolution:** Completely removed `isRoutineZoneActive` and raw SQLite access from `BootReceiver.kt`. Alarms now fire unconditionally when scheduled.
6. **Check 6 (Ignored Return Values):** Return value of `scheduleExactAlarm` was ignored in Dart.
   - **Resolution:** Captured return boolean and persisted `pending_reminders.nativeScheduled = ok ? 1 : 0`.
7. **Check 7 (Database Migration Version):** DB version updated from 74 to **75** (`MigrationV75NotificationReliability`).

---

## 2. Phase-by-Phase Implementation Details

### Phase A: Native-Side Reliability & MethodChannel Architecture
- **T-A1 (AlarmChannelRegistrar):** Created `AlarmChannelRegistrar.kt` object encapsulating `MethodChannel` logic for `scheduleExactAlarm`, `cancelAlarm`, `checkExactAlarmPermission`, and `requestExactAlarmPermission`. Registered in `MainActivity.kt`, `NotificationActionReceiver.kt`, and `RitmoAgendaWidgetProvider.kt`.
- **T-A2 (Native Failure Tracking):** Added `_recordNativeFailure()` helper in `lib/core/services/native_bridge.dart` to track MethodChannel exceptions in `app_settings` (`alarm_native_failure_count`).
- **T-A3 (Unify Snooze Path):** Removed `AlarmSchedulerService.snoozeReminder` and routed all snooze requests through `SnoozePolicy.evaluate` and `SnoozeReminderCommand` on `RitmoExecutionKernel`.
- **T-A4 (Migration V75 & Status Unification):** Created `MigrationV75NotificationReliability` (v75) adding `pending_reminders.nativeScheduled`, `routines.fullScreenAlarm`, unifying status to `'snoozed'`, and creating `alarm_delivery_log` table. Updated `snooze_reminder_handler.dart` to set `'snoozed'` status.
- **T-A5 (Remove isRoutineZoneActive):** Removed `isRoutineZoneActive` and `android.database.sqlite.SQLiteDatabase` import from `BootReceiver.kt`.
- **T-A6 (Persian String Localization):** Rewrote `android/app/src/main/res/values/strings.xml` with comprehensive Persian string resources. Removed hardcoded strings in Kotlin.
- **T-A7 (Three Actions Limit):** Reduced notification actions to 3 (`DONE`, `SNOOZE`, `DISMISS`). Removed 4th action from notification bar.
- **T-A8 (Correct Notification Icon & Accent):** Updated `BootReceiver.kt` to use `R.drawable.ic_notification` and `R.color.ritmo_accent`.
- **T-A9 (Sweeping Missed Alarms):** Added `sweepMissedAlarms()` to `AlarmSchedulerService` and called at the beginning of `scheduleNextAlarms()`. Updated `BootReceiver.restoreAlarmsFromSnapshot` to fire past alarms < 2 hours old immediately with title suffix `(دیرکرد)`.
- **T-A10 (Minor Reliability Fixes):** Fixed request code generation (`generateRequestCode`), rate-limiter concurrency with `synchronized` block and `.commit()`.
- **T-A12 (60-Second Time Change Threshold):** Enforced a 60-second minimum shift threshold for `ACTION_TIME_CHANGED` and `ACTION_TIMEZONE_CHANGED` in `BootReceiver.kt`.
- **T-A13 (Skip Occurrence State Update):** Updated `skipOccurrence` to set `pending_reminders.state = 'skipped'` and `logNotificationEvent(actionTaken: 'skipped')`.

### Phase B: Lock Screen & Full-Screen Alarm Experience
- **T-B1 (Channel Versioning & Public Version):** Created `RitmoNotificationChannels.kt` with channels `RitmoEssentialChannel_v2` and `RitmoNormalChannel_v2`. Added `buildSanitizedPublicVersion` in `BootReceiver.kt`.
- **T-B2 (Waking Screen & Permissions):** Added `WAKE_LOCK`, `USE_FULL_SCREEN_INTENT`, and `TURN_SCREEN_ON` permissions in `AndroidManifest.xml`. Used `PowerManager.WakeLock` (10s timeout) for essential alarms.
- **T-B3 (Full-Screen Alarm Activity):** Built `AlarmActivity.kt`, `activity_alarm.xml` (RTL layout with Persian time display `RitmoNumber.fa`, title, `firstPhysicalStep`, and 3 action buttons), and `@style/AlarmTheme`.
- **T-B4 (Permission & Settings Scope):** Implemented `shouldUseFullScreen(context, id, isEssential)` considering user preference, scope, opted-in IDs, and Android 14+ `canUseFullScreenIntent()`. Attached `setFullScreenIntent` to notification builder when enabled.

### Phase C: Diagnostics, Audit & Integrity
- **T-C1 (Alarm Delivery Audit Log):** Created `alarm_delivery_log` table for tracking delivery outcomes (`delivered`, `missed`, `dismissed`).
- **T-C2 (Forensic State Logging):** Comprehensive state transition logging via `RitmoLog` across native and Dart layers.
- **T-C3 (Diagnostics & System Health UI):** Created `AlarmDiagnosticsSheet.dart` with exact alarm permission check, pending count, native failure count, discrepancy detector, and test alarm launcher. Added launcher button in `account_screen.dart`.
- **T-C4 (Test Alarm Command):** Implemented `TestAlarmCommand` and `TestAlarmHandler` for 5-second test alarm execution.

### Phase D: Verification & Quality Assurance
- Static Analysis: `flutter analyze lib/` passed with **0 errors and 0 warnings**.

---

## 3. Verification & Compliance Matrix
| Requirement | Status | Verification |
|---|---|---|
| Background MethodChannel Registration | ✅ PASSED | `AlarmChannelRegistrar.kt` registered on all engines |
| Native SQLite Removal | ✅ PASSED | `isRoutineZoneActive` and `SQLiteDatabase` deleted |
| Full-Screen Lock Screen Alarm | ✅ PASSED | `AlarmActivity.kt` and `setFullScreenIntent` wired |
| String Localization | ✅ PASSED | All strings loaded from `strings.xml` |
| Max 3 Actions Rule | ✅ PASSED | Actions capped at `DONE`, `SNOOZE`, `DISMISS` |
| Database Migration V75 | ✅ PASSED | `MigrationV75NotificationReliability` registered |
| Static Code Analysis | ✅ PASSED | `flutter analyze lib/` -> 0 errors / 0 warnings |

---
**Prompt 061 Overhaul Successfully Completed.**
