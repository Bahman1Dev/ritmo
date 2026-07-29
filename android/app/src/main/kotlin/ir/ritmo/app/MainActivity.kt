package ir.ritmo.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.util.ArrayList
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

class MainActivity : FlutterFragmentActivity() {
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Keystore MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeChannels.KEYSTORE).setMethodCallHandler { call, result ->
            when (call.method) {
                KeystoreMethods.GET_OR_CREATE_KEY -> {
                    try {
                        val key = getOrCreateMasterKey()
                        result.success(key)
                    } catch (e: Exception) {
                        result.error("KEYSTORE_ERROR", e.message, null)
                    }
                }
                else -> {
                    android.util.Log.w(TAG, "Unhandled method '${call.method}' on channel ${NativeChannels.KEYSTORE} — قرارداد ناهمخوان است")
                    result.notImplemented()
                }
            }
        }

        // 2. Alarm MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeChannels.ALARMS).setMethodCallHandler { call, result ->
            when (call.method) {
                AlarmMethods.SCHEDULE_EXACT_ALARM -> {
                    val id = call.argument<String>("id")
                    val time = (call.argument<Number>("time"))?.toLong()
                    val title = call.argument<String>("title")
                    val isEssential = call.argument<Boolean>("isEssential") ?: false

                    if (id != null && time != null && title != null) {
                        scheduleAlarm(id, time, title, isEssential)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing id, time, or title", null)
                    }
                }
                AlarmMethods.CANCEL_ALARM -> {
                    val id = call.argument<String>("id")
                    if (id != null) {
                        cancelAlarm(id)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing id", null)
                    }
                }
                AlarmMethods.CHECK_EXACT_ALARM_PERMISSION -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        result.success(alarmManager.canScheduleExactAlarms())
                    } else {
                        result.success(true)
                    }
                }
                AlarmMethods.REQUEST_EXACT_ALARM_PERMISSION -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("PERMISSION_ERROR", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                else -> {
                    android.util.Log.w(TAG, "Unhandled method '${call.method}' on channel ${NativeChannels.ALARMS} — قرارداد ناهمخوان است")
                    result.notImplemented()
                }
            }
        }

        // 3. Foreground Service MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeChannels.FOREGROUND_SERVICE).setMethodCallHandler { call, result ->
            when (call.method) {
                ForegroundServiceMethods.START_STATUS_MODE -> {
                    val zone = call.argument<String>("zone") ?: "آزاد"
                    val energy = call.argument<String>("energy") ?: "متوسط"
                    val proposedTask = call.argument<String>("proposedTask") ?: "استراحت 🌿"
                    val proposedTaskId = call.argument<String>("proposedTaskId")
                    val completedRoutines = (call.argument<Number>("completedRoutines"))?.toInt() ?: 0
                    val totalRoutines = (call.argument<Number>("totalRoutines"))?.toInt() ?: 0
                    val completedPrayers = (call.argument<Number>("completedPrayers"))?.toInt() ?: 0
                    val totalPrayers = (call.argument<Number>("totalPrayers"))?.toInt() ?: 0
                    val zoneNames = call.argument<List<String>>("zoneNames")
                    val zoneIds = call.argument<List<String>>("zoneIds")

                    val intent = Intent(this, RitmoForegroundService::class.java).apply {
                        action = RitmoForegroundService.ACTION_START_STATUS
                        putExtra("zone", zone)
                        putExtra("energy", energy)
                        putExtra("proposedTask", proposedTask)
                        putExtra("proposedTaskId", proposedTaskId)
                        putExtra("completedRoutines", completedRoutines)
                        putExtra("totalRoutines", totalRoutines)
                        putExtra("completedPrayers", completedPrayers)
                        putExtra("totalPrayers", totalPrayers)
                        putStringArrayListExtra("zoneNames", if (zoneNames != null) ArrayList(zoneNames) else null)
                        putStringArrayListExtra("zoneIds", if (zoneIds != null) ArrayList(zoneIds) else null)
                    }
                    startForegroundServiceCompat(intent)
                    result.success(true)
                }
                ForegroundServiceMethods.START_TIMER_MODE -> {
                    val title = call.argument<String>("title") ?: "روتین"
                    val durationSeconds = (call.argument<Number>("durationSeconds"))?.toInt() ?: 0
                    val elapsedSeconds = (call.argument<Number>("elapsedSeconds"))?.toInt() ?: 0

                    val intent = Intent(this, RitmoForegroundService::class.java).apply {
                        action = RitmoForegroundService.ACTION_START_TIMER
                        putExtra("title", title)
                        putExtra("durationSeconds", durationSeconds)
                        putExtra("elapsedSeconds", elapsedSeconds)
                    }
                    startForegroundServiceCompat(intent)
                    result.success(true)
                }
                ForegroundServiceMethods.STOP_SERVICE -> {
                    val intent = Intent(this, RitmoForegroundService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                else -> {
                    android.util.Log.w(TAG, "Unhandled method '${call.method}' on channel ${NativeChannels.FOREGROUND_SERVICE} — قرارداد ناهمخوان است")
                    result.notImplemented()
                }
            }
        }

        // 4. Launch Intent MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeChannels.LAUNCH_INTENT).setMethodCallHandler { call, result ->
            when (call.method) {
                LaunchIntentMethods.GET_LAUNCH_INTENT -> {
                    val rId = startTimerReminderId
                    val mId = openModuleId
                    val qAdd = openQuickAdd
                    startTimerReminderId = null
                    openModuleId = null
                    openQuickAdd = false
                    if (rId != null) {
                        result.success(mapOf("action" to "START_TIMER", "reminderId" to rId))
                    } else if (mId != null) {
                        result.success(mapOf("action" to "OPEN_MODULE", "moduleId" to mId))
                    } else if (qAdd) {
                        result.success(mapOf("action" to "OPEN_QUICK_ADD"))
                    } else {
                        val launchIntent = intent
                        when (launchIntent?.action) {
                            "com.ritmo.app.START_TIMER" -> {
                                val coldId = launchIntent.getStringExtra("reminderId")
                                launchIntent.action = null // consume
                                if (coldId != null) {
                                    result.success(mapOf("action" to "START_TIMER", "reminderId" to coldId))
                                } else {
                                    result.success(null)
                                }
                            }
                            "com.ritmo.app.OPEN_MODULE" -> {
                                val coldM = launchIntent.getStringExtra("moduleId")
                                launchIntent.action = null // consume
                                if (coldM != null) {
                                    result.success(mapOf("action" to "OPEN_MODULE", "moduleId" to coldM))
                                } else {
                                    result.success(null)
                                }
                            }
                            "com.ritmo.app.OPEN_QUICK_ADD" -> {
                                launchIntent.action = null // consume
                                result.success(mapOf("action" to "OPEN_QUICK_ADD"))
                            }
                            else -> result.success(null)
                        }
                    }
                }
                else -> {
                    android.util.Log.w(TAG, "Unhandled method '${call.method}' on channel ${NativeChannels.LAUNCH_INTENT} — قرارداد ناهمخوان است")
                    result.notImplemented()
                }
            }
        }

        // 5. Home-screen Widget MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeChannels.WIDGET).setMethodCallHandler { call, result ->
            when (call.method) {
                WidgetMethods.REFRESH_WIDGETS -> {
                    try {
                        refreshWidgets()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WIDGET_REFRESH_ERROR", e.message, null)
                    }
                }
                else -> {
                    android.util.Log.w(TAG, "Unhandled method '${call.method}' on channel ${NativeChannels.WIDGET} — قرارداد ناهمخوان است")
                    result.notImplemented()
                }
            }
        }

        // 6. Myket Billing MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeChannels.MYKET_BILLING).setMethodCallHandler { call, result ->
            when (call.method) {
                MyketBillingMethods.INIT -> {
                    result.success(true)
                }
                MyketBillingMethods.GET_PRODUCT_DETAILS -> {
                    val skus = call.argument<List<String>>("skus")
                    val details = mapOf(
                        "premium_3month" to "۵۹,۰۰۰ تومان",
                        "premium_yearly" to "۱۸۹,۰۰۰ تومان",
                        "premium_lifetime" to "۳۸۹,۰۰۰ تومان"
                    )
                    result.success(details)
                }
                MyketBillingMethods.PURCHASE -> {
                    val sku = call.argument<String>("sku")
                    if (sku != null) {
                        val token = "myket_mock_token_${System.currentTimeMillis()}"
                        result.success(mapOf(
                            "success" to true,
                            "purchaseToken" to token
                        ))
                    } else {
                        result.success(mapOf(
                            "success" to false,
                            "errorMessage" to "SKU is missing"
                        ))
                    }
                }
                MyketBillingMethods.RESTORE_PURCHASES -> {
                    val list = listOf(
                        mapOf(
                            "sku" to "premium_lifetime",
                            "purchaseToken" to "myket_mock_token_restored",
                            "purchaseTime" to System.currentTimeMillis().toString()
                        )
                    )
                    result.success(list)
                }
                MyketBillingMethods.DISPOSE -> {
                    result.success(true)
                }
                else -> {
                    android.util.Log.w(TAG, "Unhandled method '${call.method}' on channel ${NativeChannels.MYKET_BILLING} — قرارداد ناهمخوان است")
                    result.notImplemented()
                }
            }
        }
    }

    /** Forces both the compact and full-screen widgets to re-read the latest snapshot. */
    private fun refreshWidgets() {
        // Full-screen widget: header + scrollable list.
        sendBroadcast(Intent(this, RitmoFullWidgetProvider::class.java).apply {
            action = RitmoFullWidgetProvider.ACTION_REFRESH
        })

        // Compact widget: standard APPWIDGET_UPDATE re-runs its onUpdate.
        val mgr = AppWidgetManager.getInstance(this)
        val compactIds = mgr.getAppWidgetIds(ComponentName(this, RitmoAppWidgetProvider::class.java))
        if (compactIds.isNotEmpty()) {
            sendBroadcast(Intent(this, RitmoAppWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, compactIds)
            })
        }

        // Agenda widget: notify list view data changed and update provider.
        val agendaIds = mgr.getAppWidgetIds(ComponentName(this, RitmoAgendaWidgetProvider::class.java))
        if (agendaIds.isNotEmpty()) {
            mgr.notifyAppWidgetViewDataChanged(agendaIds, R.id.agenda_list)
            sendBroadcast(Intent(this, RitmoAgendaWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, agendaIds)
            })
        }
    }

    private var startTimerReminderId: String? = null
    private var openModuleId: String? = null
    private var openQuickAdd: Boolean = false

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        when (intent.action) {
            "com.ritmo.app.START_TIMER" -> {
                startTimerReminderId = intent.getStringExtra("reminderId")
                android.util.Log.d("MainActivity", "onNewIntent: START_TIMER received for $startTimerReminderId")
            }
            "com.ritmo.app.OPEN_MODULE" -> {
                openModuleId = intent.getStringExtra("moduleId")
                android.util.Log.d("MainActivity", "onNewIntent: OPEN_MODULE received for $openModuleId")
            }
            "com.ritmo.app.OPEN_QUICK_ADD" -> {
                openQuickAdd = true
                android.util.Log.d("MainActivity", "onNewIntent: OPEN_QUICK_ADD received")
            }
        }
    }

    private fun startForegroundServiceCompat(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    // Android Keystore Key management
    private fun getOrCreateMasterKey(): String {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val alias = "RitmoMasterKeyAlias"

        if (!keyStore.containsAlias(alias)) {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            val spec = KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()

            keyGenerator.init(spec)
            keyGenerator.generateKey()
        }

        val secretKey = keyStore.getKey(alias, null) as SecretKey
        return Base64.encodeToString(secretKey.encoded ?: alias.toByteArray(), Base64.NO_WRAP)
    }

    private fun generateRequestCode(id: String, salt: String = ""): Int {
        return (id + salt).hashCode() and 0x7FFFFFFF
    }

    // AlarmManager Scheduling
    private fun scheduleAlarm(id: String, timeMs: Long, title: String, isEssential: Boolean) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, BootReceiver::class.java).apply {
            action = "com.ritmo.app.ACTION_TRIGGER_ALARM"
            putExtra("id", id)
            putExtra("title", title)
            putExtra("isEssential", isEssential)
        }

        val requestCode = generateRequestCode(id, "_ALARM")
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
                } else {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
            }
        } catch (e: SecurityException) {
            android.util.Log.e("MainActivity", "SecurityException scheduling exact alarm: ${e.message}. Falling back to inexact alarm.", e)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error scheduling alarm: ${e.message}", e)
        }
    }

    private fun cancelAlarm(id: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, BootReceiver::class.java).apply {
            action = "com.ritmo.app.ACTION_TRIGGER_ALARM"
        }

        val requestCode = generateRequestCode(id, "_ALARM")
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )

        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }
}
