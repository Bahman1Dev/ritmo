package ir.ritmo.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import java.util.Calendar

class BootReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_TRIGGER_ALARM = "com.ritmo.app.ACTION_TRIGGER_ALARM"
    }

    private val TAG = "RitmoBootReceiver"
    private val ALARM_TRIGGER_ACTION = ACTION_TRIGGER_ALARM
    private val GROUP_KEY_NON_ESSENTIAL = "ritmo_non_essential"
    private val SUMMARY_NOTIF_ID = 8888

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received broadcast action: $action")

        if (action == Intent.ACTION_BOOT_COMPLETED || action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            restoreAlarmsFromSnapshot(context)
        } else if (action == Intent.ACTION_TIMEZONE_CHANGED || action == Intent.ACTION_TIME_CHANGED) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val lastRestoreMs = prefs.getLong("flutter.last_alarm_restore_ms", 0L)
            val nowMs = System.currentTimeMillis()
            if (Math.abs(nowMs - lastRestoreMs) > 60_000L) {
                prefs.edit().putLong("flutter.last_alarm_restore_ms", nowMs).commit()
                restoreAlarmsFromSnapshot(context)
            } else {
                Log.d(TAG, "Skipping alarm restore on time change: shift < 60 seconds")
            }
        } else if (action == ALARM_TRIGGER_ACTION) {
            // An alarm fired. Check if it's a status update refresh or a normal routine alarm.
            val id = intent.getStringExtra("id") ?: "default_id"
            val title = intent.getStringExtra("title") ?: "یادآوری روتین"
            val isEssential = intent.getBooleanExtra("isEssential", false)
            
            if (id.startsWith("status_update_") || title == "REFRESH_STATUS") {
                Log.d(TAG, "Status update alarm fired, refreshing persistent notification")
                val updateIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                    this.action = "com.ritmo.app.NOTIF_ACTION"
                    putExtra("actionType", "UPDATE_PERSISTENT_STATUS")
                    putExtra("reminderId", "dummy_id")
                }
                context.sendBroadcast(updateIntent)
            } else {
                showAlarmNotification(context, id, title, isEssential)
                // Also trigger status notification refresh to show the next proposed task!
                val updateIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                    this.action = "com.ritmo.app.NOTIF_ACTION"
                    putExtra("actionType", "UPDATE_PERSISTENT_STATUS")
                    putExtra("reminderId", "dummy_id")
                }
                context.sendBroadcast(updateIntent)
            }
        }
    }

    private fun generateRequestCode(id: String, salt: String = ""): Int {
        return (id + salt).hashCode() and 0x7FFFFFFF
    }

    private fun restoreAlarmsFromSnapshot(context: Context) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val snapshotJson = prefs.getString("flutter.active_reminders_snapshot", null)

            if (snapshotJson == null) {
                Log.d(TAG, "No active alarms snapshot found in SharedPreferences.")
                return
            }

            Log.d(TAG, "Restoring alarms from snapshot JSON: $snapshotJson")
            val alarmArray = JSONArray(snapshotJson)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            for (i in 0 until alarmArray.length()) {
                val alarmObj = alarmArray.getJSONObject(i)
                val id = alarmObj.getString("id")
                val title = alarmObj.getString("title")
                val scheduledTime = alarmObj.getLong("scheduledTime")
                val isEssential = alarmObj.optBoolean("isEssential", false)

                val nowMs = System.currentTimeMillis()
                if (scheduledTime > nowMs) {
                    val alarmIntent = Intent(context, BootReceiver::class.java).apply {
                        action = ALARM_TRIGGER_ACTION
                        putExtra("id", id)
                        putExtra("title", title)
                        putExtra("isEssential", isEssential)
                    }

                    val requestCode = generateRequestCode(id, "_ALARM")
                    val pendingIntent = PendingIntent.getBroadcast(
                        context,
                        requestCode,
                        alarmIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )

                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (alarmManager.canScheduleExactAlarms()) {
                                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, scheduledTime, pendingIntent)
                            } else {
                                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, scheduledTime, pendingIntent)
                            }
                        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, scheduledTime, pendingIntent)
                        } else {
                            alarmManager.setExact(AlarmManager.RTC_WAKEUP, scheduledTime, pendingIntent)
                        }
                    } catch (e: SecurityException) {
                        Log.e(TAG, "SecurityException rescheduling exact alarm for '$title': ${e.message}. Falling back to inexact alarm.", e)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, scheduledTime, pendingIntent)
                        } else {
                            alarmManager.set(AlarmManager.RTC_WAKEUP, scheduledTime, pendingIntent)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error rescheduling alarm for '$title': ${e.message}", e)
                    }
                    Log.d(TAG, "Rescheduled alarm for '$title' (ID: $id) at $scheduledTime")
                } else if (nowMs - scheduledTime < 2 * 3600 * 1000L) {
                    // Missed alarm within 2 hours: fire immediately with late indicator
                    Log.d(TAG, "Firing missed alarm ($id) with late indicator (was scheduled at $scheduledTime)")
                    showAlarmNotification(context, id, "$title (دیرکرد)", isEssential)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error restoring alarms from SharedPreferences: ${e.message}", e)
        }
    }

    private fun shouldUseFullScreen(context: Context, id: String, isEssential: Boolean): Boolean {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (prefs.getString("flutter.notif_fullscreen_enabled", "true") != "true") return false

        val scope = prefs.getString("flutter.notif_fullscreen_scope", "essential")
        val optedIn = prefs.getStringSet("flutter.notif_fullscreen_ids", emptySet())?.contains(id) == true
        if (scope == "essential" && !isEssential && !optedIn) return false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            if (nm != null && !nm.canUseFullScreenIntent()) return false
        }
        return true
    }

    private fun buildSanitizedPublicVersion(context: Context, isEssential: Boolean): Notification {
        val channelId = if (isEssential) RitmoNotificationChannels.ESSENTIAL else RitmoNotificationChannels.NORMAL
        return NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(context, R.color.ritmo_accent))
            .setContentTitle(context.getString(if (isEssential) R.string.notif_vital_routine_title else R.string.notif_daily_routine_title))
            .setContentText(context.getString(R.string.notif_vital_routine_title))
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    private fun showAlarmNotification(context: Context, id: String, title: String, isEssential: Boolean) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        RitmoNotificationChannels.ensure(context, notificationManager)

        val channelId = if (isEssential) RitmoNotificationChannels.ESSENTIAL else RitmoNotificationChannels.NORMAL

        if (isEssential) {
            try {
                val pm = context.getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
                @Suppress("DEPRECATION")
                val wakeLock = pm?.newWakeLock(
                    android.os.PowerManager.FULL_WAKE_LOCK or
                    android.os.PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    android.os.PowerManager.ON_AFTER_RELEASE,
                    "Ritmo:AlarmWakeLock"
                )
                wakeLock?.acquire(10_000L)
            } catch (e: Exception) {
                Log.e(TAG, "Error acquiring WakeLock: ${e.message}")
            }
        }

        // Open app when notification clicked
        val notifNumericId = generateRequestCode(id, "_NOTIF")
        val launchIntent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            notifNumericId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (isEssential) {
            val doneIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = "com.ritmo.app.NOTIF_ACTION"
                putExtra("actionType", "DONE")
                putExtra("reminderId", id)
                putExtra("notifId", notifNumericId)
            }
            val donePendingIntent = PendingIntent.getBroadcast(
                context,
                generateRequestCode(id, "_DONE"),
                doneIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val snoozeIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = "com.ritmo.app.NOTIF_ACTION"
                putExtra("actionType", "SNOOZE")
                putExtra("reminderId", id)
                putExtra("notifId", notifNumericId)
            }
            val snoozePendingIntent = PendingIntent.getBroadcast(
                context,
                generateRequestCode(id, "_SNOOZE"),
                snoozeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val dismissIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = "com.ritmo.app.NOTIF_ACTION"
                putExtra("actionType", "DISMISS")
                putExtra("reminderId", id)
                putExtra("notifId", notifNumericId)
            }
            val dismissPendingIntent = PendingIntent.getBroadcast(
                context,
                generateRequestCode(id, "_DISMISS"),
                dismissIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.drawable.ic_notification)
                .setColor(ContextCompat.getColor(context, R.color.ritmo_accent))
                .setContentTitle(context.getString(R.string.notif_vital_routine_title))
                .setContentText(title)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
                .setPublicVersion(buildSanitizedPublicVersion(context, isEssential))
                .setOnlyAlertOnce(false)
                .setWhen(System.currentTimeMillis())
                .setShowWhen(true)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .addAction(0, context.getString(R.string.notif_action_done), donePendingIntent)
                .addAction(0, context.getString(R.string.notif_action_snooze), snoozePendingIntent)
                .addAction(0, context.getString(R.string.notif_action_dismiss), dismissPendingIntent)

            if (shouldUseFullScreen(context, id, isEssential)) {
                val alarmActivityIntent = Intent(context, AlarmActivity::class.java).apply {
                    putExtra("reminderId", id)
                    putExtra("title", title)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val fullScreenPendingIntent = PendingIntent.getActivity(
                    context,
                    generateRequestCode(id, "_FULLSCREEN"),
                    alarmActivityIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                builder.setFullScreenIntent(fullScreenPendingIntent, true)
            }

            notificationManager.notify(notifNumericId, builder.build())
        } else {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val digestMode = prefs.getString("flutter.notif_digest_mode", "false") == "true"
            val maxNonEssential = prefs.getInt("flutter.notif_max_non_essential_per_hour", 3)

            var isRateLimited = false
            synchronized(BootReceiver::class.java) {
                val nowMs = System.currentTimeMillis()
                val oneHourAgo = nowMs - 3600 * 1000
                val fireTimestampsJson = prefs.getString("flutter.non_essential_fire_timestamps", "[]") ?: "[]"

                val inputJsonArray = org.json.JSONArray(fireTimestampsJson)
                val newJsonArray = org.json.JSONArray()
                var fireCountInLastHour = 0

                for (i in 0 until inputJsonArray.length()) {
                    val ts = inputJsonArray.getLong(i)
                    if (ts > oneHourAgo) {
                        newJsonArray.put(ts)
                        fireCountInLastHour++
                    }
                }

                newJsonArray.put(nowMs)
                fireCountInLastHour++

                prefs.edit().putString("flutter.non_essential_fire_timestamps", newJsonArray.toString()).commit()
                isRateLimited = fireCountInLastHour > maxNonEssential
            }

            if (!digestMode) {
                val nonEssentialNotifId = generateRequestCode(id, "_NOTIF")
                val doneIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                    action = "com.ritmo.app.NOTIF_ACTION"
                    putExtra("actionType", "DONE")
                    putExtra("reminderId", id)
                    putExtra("notifId", nonEssentialNotifId)
                }
                val donePendingIntent = PendingIntent.getBroadcast(
                    context,
                    generateRequestCode(id, "_DONE"),
                    doneIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val snoozeIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                    action = "com.ritmo.app.NOTIF_ACTION"
                    putExtra("actionType", "SNOOZE")
                    putExtra("reminderId", id)
                    putExtra("notifId", nonEssentialNotifId)
                }
                val snoozePendingIntent = PendingIntent.getBroadcast(
                    context,
                    generateRequestCode(id, "_SNOOZE"),
                    snoozeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val dismissIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                    action = "com.ritmo.app.NOTIF_ACTION"
                    putExtra("actionType", "DISMISS")
                    putExtra("reminderId", id)
                    putExtra("notifId", nonEssentialNotifId)
                }
                val dismissPendingIntent = PendingIntent.getBroadcast(
                    context,
                    generateRequestCode(id, "_DISMISS"),
                    dismissIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val builder = NotificationCompat.Builder(context, channelId)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setColor(ContextCompat.getColor(context, R.color.ritmo_accent))
                    .setContentTitle(context.getString(R.string.notif_daily_routine_title))
                    .setContentText(title)
                    .setContentIntent(pendingIntent)
                    .setAutoCancel(true)
                    .setGroup(GROUP_KEY_NON_ESSENTIAL)
                    .addAction(0, context.getString(R.string.notif_action_done), donePendingIntent)
                    .addAction(0, context.getString(R.string.notif_action_snooze), snoozePendingIntent)
                    .addAction(0, context.getString(R.string.notif_action_dismiss), dismissPendingIntent)

                if (isRateLimited) {
                    builder.setPriority(NotificationCompat.PRIORITY_LOW)
                    builder.setSound(null)
                    builder.setVibrate(null)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        builder.setGroupAlertBehavior(NotificationCompat.GROUP_ALERT_SUMMARY)
                    }
                } else {
                    builder.setPriority(NotificationCompat.PRIORITY_DEFAULT)
                }

                notificationManager.notify(nonEssentialNotifId, builder.build())
            } else {
                // Digest mode active: Increment digest counter in prefs
                var digestCount = prefs.getInt("flutter.digest_notif_count", 0)
                digestCount++
                prefs.edit().putInt("flutter.digest_notif_count", digestCount).apply()
            }

            // Calculate total count for the summary
            val summaryCount = if (digestMode) {
                prefs.getInt("flutter.digest_notif_count", 1)
            } else {
                var count = 1
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val activeNotifs = notificationManager.activeNotifications
                    var foundCurrent = false
                    var activeCount = 0
                    for (n in activeNotifs) {
                        if (n.notification.group == GROUP_KEY_NON_ESSENTIAL && n.id != SUMMARY_NOTIF_ID) {
                            activeCount++
                            if (n.id == id.hashCode()) {
                                foundCurrent = true
                            }
                        }
                    }
                    count = activeCount
                    if (!foundCurrent) {
                        count++
                    }
                }
                count
            }

            // Post/Update Summary Notification
            val summaryTitle = if (digestMode) "خلاصه‌ی این بازه" else "یادآوری‌های این بازه"
            val summaryText = "$summaryCount یادآوری جدید"

            val summaryIntent = Intent(context, MainActivity::class.java)
            val summaryPendingIntent = PendingIntent.getActivity(
                context,
                SUMMARY_NOTIF_ID,
                summaryIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val summaryBuilder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle(summaryTitle)
                .setContentText(summaryText)
                .setContentIntent(summaryPendingIntent)
                .setAutoCancel(true)
                .setGroup(GROUP_KEY_NON_ESSENTIAL)
                .setGroupSummary(true)

            if (isRateLimited || digestMode) {
                summaryBuilder.setPriority(NotificationCompat.PRIORITY_LOW)
                summaryBuilder.setSound(null)
                summaryBuilder.setVibrate(null)
            } else {
                summaryBuilder.setPriority(NotificationCompat.PRIORITY_DEFAULT)
            }

            notificationManager.notify(SUMMARY_NOTIF_ID, summaryBuilder.build())
        }
    }
}
