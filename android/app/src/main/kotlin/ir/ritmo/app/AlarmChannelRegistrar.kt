package ir.ritmo.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

object AlarmChannelRegistrar {
    private const val TAG = "AlarmChannelRegistrar"

    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, NativeChannels.ALARMS).setMethodCallHandler { call, result ->
            when (call.method) {
                AlarmMethods.SCHEDULE_EXACT_ALARM -> {
                    val id = call.argument<String>("id")
                    val time = (call.argument<Number>("time"))?.toLong()
                    val title = call.argument<String>("title")
                    val isEssential = call.argument<Boolean>("isEssential") ?: false

                    if (id != null && time != null && title != null) {
                        val ok = scheduleAlarm(context, id, time, title, isEssential)
                        result.success(ok)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing id, time, or title", null)
                    }
                }
                AlarmMethods.CANCEL_ALARM -> {
                    val id = call.argument<String>("id")
                    if (id != null) {
                        val ok = cancelAlarm(context, id)
                        result.success(ok)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing id", null)
                    }
                }
                AlarmMethods.CHECK_EXACT_ALARM_PERMISSION -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                        result.success(alarmManager?.canScheduleExactAlarms() ?: true)
                    } else {
                        result.success(true)
                    }
                }
                AlarmMethods.REQUEST_EXACT_ALARM_PERMISSION -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:${context.packageName}")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("NO_ACTIVITY", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                else -> {
                    Log.w(TAG, "Unhandled method '${call.method}' on channel ${NativeChannels.ALARMS}")
                    result.notImplemented()
                }
            }
        }
    }

    private fun scheduleAlarm(
        context: Context,
        id: String,
        timeMsUTC: Long,
        title: String,
        isEssential: Boolean
    ): Boolean {
        return try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
            val intent = Intent(context, BootReceiver::class.java).apply {
                action = BootReceiver.ACTION_TRIGGER_ALARM
                putExtra("reminderId", id)
                putExtra("title", title)
                putExtra("isEssential", isEssential)
                putExtra("scheduledTime", timeMsUTC)
            }

            val requestCode = generateRequestCode(id)
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMsUTC, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMsUTC, pendingIntent)
            }

            Log.d(TAG, "Successfully scheduled alarm for $id at $timeMsUTC (essential=$isEssential)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule alarm $id: ${e.message}", e)
            false
        }
    }

    private fun cancelAlarm(context: Context, id: String): Boolean {
        return try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
            val intent = Intent(context, BootReceiver::class.java).apply {
                action = BootReceiver.ACTION_TRIGGER_ALARM
            }

            val requestCode = generateRequestCode(id)
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
            Log.d(TAG, "Successfully cancelled alarm $id")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel alarm $id: ${e.message}", e)
            false
        }
    }

    private fun generateRequestCode(id: String): Int {
        val hash = id.hashCode()
        return if (hash == Int.MIN_VALUE) 0 else Math.abs(hash)
    }
}
