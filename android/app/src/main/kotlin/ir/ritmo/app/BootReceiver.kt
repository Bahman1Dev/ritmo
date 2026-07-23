package ir.ritmo.app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import android.database.sqlite.SQLiteDatabase
import java.util.Calendar

class BootReceiver : BroadcastReceiver() {

    private val TAG = "RitmoBootReceiver"
    private val ALARM_TRIGGER_ACTION = "com.ritmo.app.ACTION_TRIGGER_ALARM"
    private val GROUP_KEY_NON_ESSENTIAL = "ritmo_non_essential"
    private val SUMMARY_NOTIF_ID = 8888

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received broadcast action: $action")

        if (action == Intent.ACTION_BOOT_COMPLETED || 
            action == Intent.ACTION_MY_PACKAGE_REPLACED || 
            action == Intent.ACTION_TIMEZONE_CHANGED || 
            action == Intent.ACTION_TIME_CHANGED) {
            // Restore alarms using the SharedPreferences snapshot without touching SQLite
            restoreAlarmsFromSnapshot(context)
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
                if (isRoutineZoneActive(context, id)) {
                    showAlarmNotification(context, id, title, isEssential)
                } else {
                    Log.d(TAG, "Skipping alarm notification $id: routine zone is not active.")
                }
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

                // Only reschedule future alarms
                if (scheduledTime > System.currentTimeMillis()) {
                    val alarmIntent = Intent(context, BootReceiver::class.java).apply {
                        action = ALARM_TRIGGER_ACTION
                        putExtra("id", id)
                        putExtra("title", title)
                        putExtra("isEssential", isEssential)
                    }

                    val requestCode = id.hashCode()
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
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error restoring alarms from SharedPreferences: ${e.message}", e)
        }
    }

    private fun showAlarmNotification(context: Context, id: String, title: String, isEssential: Boolean) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = if (isEssential) "RitmoEssentialChannel" else "RitmoNormalChannel"
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = if (isEssential) "یادآوری‌های حیاتی (دارو/نماز)" else "یادآوری‌های معمولی"
            val importance = if (isEssential) NotificationManager.IMPORTANCE_HIGH else NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(channelId, name, importance).apply {
                if (isEssential) {
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 500, 200, 500)
                }
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Open app when notification clicked
        val launchIntent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            id.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val startTimerIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.ritmo.app.START_TIMER"
            putExtra("reminderId", id)
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val startTimerPendingIntent = PendingIntent.getActivity(
            context,
            (id + "START_TIMER").hashCode(),
            startTimerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (isEssential) {
            val doneIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = "com.ritmo.app.NOTIF_ACTION"
                putExtra("actionType", "DONE")
                putExtra("reminderId", id)
                putExtra("notifId", id.hashCode())
            }
            val donePendingIntent = PendingIntent.getBroadcast(
                context,
                (id + "DONE").hashCode(),
                doneIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val snoozeIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = "com.ritmo.app.NOTIF_ACTION"
                putExtra("actionType", "SNOOZE")
                putExtra("reminderId", id)
                putExtra("notifId", id.hashCode())
            }
            val snoozePendingIntent = PendingIntent.getBroadcast(
                context,
                (id + "SNOOZE").hashCode(),
                snoozeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val dismissIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = "com.ritmo.app.NOTIF_ACTION"
                putExtra("actionType", "DISMISS")
                putExtra("reminderId", id)
                putExtra("notifId", id.hashCode())
            }
            val dismissPendingIntent = PendingIntent.getBroadcast(
                context,
                (id + "DISMISS").hashCode(),
                dismissIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle("⏰ روتین حیاتی")
                .setContentText(title)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .addAction(0, "انجام شد ✅", donePendingIntent)
                .addAction(0, "تعویق ⏰", snoozePendingIntent)
                .addAction(0, "رد کردن", dismissPendingIntent)
                .addAction(0, "الان انجام می‌دهم ⏱️", startTimerPendingIntent)

            notificationManager.notify(id.hashCode(), builder.build())
        } else {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val digestMode = prefs.getString("flutter.notif_digest_mode", "false") == "true"
            val maxNonEssential = prefs.getInt("flutter.notif_max_non_essential_per_hour", 3)

            // Sliding window rate limiter
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

            prefs.edit().putString("flutter.non_essential_fire_timestamps", newJsonArray.toString()).apply()

            val isRateLimited = fireCountInLastHour > maxNonEssential

            if (!digestMode) {
                val doneIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                    action = "com.ritmo.app.NOTIF_ACTION"
                    putExtra("actionType", "DONE")
                    putExtra("reminderId", id)
                    putExtra("notifId", id.hashCode())
                }
                val donePendingIntent = PendingIntent.getBroadcast(
                    context,
                    (id + "DONE").hashCode(),
                    doneIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val snoozeIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                    action = "com.ritmo.app.NOTIF_ACTION"
                    putExtra("actionType", "SNOOZE")
                    putExtra("reminderId", id)
                    putExtra("notifId", id.hashCode())
                }
                val snoozePendingIntent = PendingIntent.getBroadcast(
                    context,
                    (id + "SNOOZE").hashCode(),
                    snoozeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val dismissIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                    action = "com.ritmo.app.NOTIF_ACTION"
                    putExtra("actionType", "DISMISS")
                    putExtra("reminderId", id)
                    putExtra("notifId", id.hashCode())
                }
                val dismissPendingIntent = PendingIntent.getBroadcast(
                    context,
                    (id + "DISMISS").hashCode(),
                    dismissIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val builder = NotificationCompat.Builder(context, channelId)
                    .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                    .setContentTitle("🌿 روتین روزانه")
                    .setContentText(title)
                    .setContentIntent(pendingIntent)
                    .setAutoCancel(true)
                    .setGroup(GROUP_KEY_NON_ESSENTIAL)
                    .addAction(0, "انجام شد ✅", donePendingIntent)
                    .addAction(0, "تعویق ⏰", snoozePendingIntent)
                    .addAction(0, "رد کردن", dismissPendingIntent)
                    .addAction(0, "الان انجام می‌دهم ⏱️", startTimerPendingIntent)

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

                notificationManager.notify(id.hashCode(), builder.build())
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

    private fun isRoutineZoneActive(context: Context, alarmId: String): Boolean {
        if (!alarmId.startsWith("rem_")) return true

        var routineZoneId: String? = null
        try {
            val dbPath = context.getDatabasePath("ritmo_secure.db")
            if (!dbPath.exists()) return true

            val db = SQLiteDatabase.openDatabase(dbPath.absolutePath, null, SQLiteDatabase.OPEN_READONLY)

            // 1. Look up routineId and courseSessionId from pending_reminders table using the alarm ID
            var routineId: String? = null
            var courseSessionId: String? = null
            val pendingCursor = db.query("pending_reminders", arrayOf("routineId", "courseSessionId"), "id = ?", arrayOf(alarmId), null, null, null)
            if (pendingCursor.moveToFirst()) {
                routineId = pendingCursor.getString(0)
                courseSessionId = pendingCursor.getString(1)
            } else {
                pendingCursor.close()
                db.close()
                return true // alarm not in pending_reminders; show it
            }
            pendingCursor.close()

            if (routineId.isNullOrEmpty() && courseSessionId.isNullOrEmpty()) {
                db.close()
                return true
            }

            // 2. Get zoneId from routines or courses
            if (!routineId.isNullOrEmpty()) {
                val routineCursor = db.query("routines", arrayOf("zoneId"), "id = ?", arrayOf(routineId), null, null, null)
                if (routineCursor.moveToFirst()) {
                    routineZoneId = routineCursor.getString(0)
                }
                routineCursor.close()
            } else if (!courseSessionId.isNullOrEmpty()) {
                val queryStr = "SELECT c.zoneId FROM course_sessions cs JOIN courses c ON cs.courseId = c.id WHERE cs.id = ?"
                val courseCursor = db.rawQuery(queryStr, arrayOf(courseSessionId))
                if (courseCursor.moveToFirst()) {
                    routineZoneId = courseCursor.getString(0)
                }
                courseCursor.close()
            }

            // If routine has no zone, it's public/global and always active
            if (routineZoneId.isNullOrEmpty()) {
                db.close()
                return true
            }

            // 2. Resolve current active zone ID
            var activeZoneId: String? = null

            // A. Check manual override
            var overrideId: String? = null
            var overrideUntilMs: Long = 0
            
            val overrideIdCursor = db.query("app_settings", arrayOf("value"), "key = ?", arrayOf("realm_override_id"), null, null, null)
            if (overrideIdCursor.moveToFirst()) {
                overrideId = overrideIdCursor.getString(0)
            }
            overrideIdCursor.close()

            val overrideUntilCursor = db.query("app_settings", arrayOf("value"), "key = ?", arrayOf("realm_override_until_ms"), null, null, null)
            if (overrideUntilCursor.moveToFirst()) {
                val untilStr = overrideUntilCursor.getString(0)
                if (!untilStr.isNullOrEmpty()) {
                    overrideUntilMs = untilStr.toLongOrNull() ?: 0
                }
            }
            overrideUntilCursor.close()

            val nowMs = System.currentTimeMillis()
            if (!overrideId.isNullOrEmpty() && nowMs < overrideUntilMs) {
                activeZoneId = overrideId
            } else {
                // B. Check scheduled zones
                val calendar = Calendar.getInstance()
                val calendarDay = calendar.get(Calendar.DAY_OF_WEEK)
                val appDay = when (calendarDay) {
                    Calendar.MONDAY -> 1
                    Calendar.TUESDAY -> 2
                    Calendar.WEDNESDAY -> 3
                    Calendar.THURSDAY -> 4
                    Calendar.FRIDAY -> 5
                    Calendar.SATURDAY -> 6
                    Calendar.SUNDAY -> 7
                    else -> 1
                }
                val currentMinutes = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)

                val scheduleCursor = db.query("zone_schedules", arrayOf("zoneId", "daysOfWeek", "startTime", "endTime"), null, null, null, null, null)
                while (scheduleCursor.moveToNext()) {
                    val zoneId = scheduleCursor.getString(0)
                    val daysStr = scheduleCursor.getString(1) ?: ""
                    val startStr = scheduleCursor.getString(2) ?: "00:00"
                    val endStr = scheduleCursor.getString(3) ?: "23:59"

                    val days = daysStr.split(",").map { it.trim() }
                    if (days.contains(appDay.toString())) {
                        val startParts = startStr.split(":")
                        val endParts = endStr.split(":")
                        if (startParts.size == 2 && endParts.size == 2) {
                            val startMin = (startParts[0].toIntOrNull() ?: 0) * 60 + (startParts[1].toIntOrNull() ?: 0)
                            val endMin = (endParts[0].toIntOrNull() ?: 0) * 60 + (endParts[1].toIntOrNull() ?: 0)
                            if (currentMinutes in startMin..endMin) {
                                activeZoneId = zoneId
                                break
                            }
                        }
                    }
                }
                scheduleCursor.close()
            }

            db.close()

            // Compare zoneId
            return routineZoneId == activeZoneId

        } catch (e: Exception) {
            Log.e(TAG, "Error checking routine zone active status: " + e.message)
            return true // Fallback to show reminder in case of DB error
        }
    }
}
