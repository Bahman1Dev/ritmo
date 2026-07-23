package ir.ritmo.app

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation

class NotificationActionReceiver : BroadcastReceiver() {

    private val TAG = "RitmoNotifReceiver"

    companion object {
        private var sBackgroundEngine: FlutterEngine? = null
        private var sMethodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        val actionType = intent.getStringExtra("actionType") ?: return
        val reminderId = intent.getStringExtra("reminderId")
        val routineId = intent.getStringExtra("routineId")
        val dateStr = intent.getStringExtra("dateStr")
        val notifId = intent.getIntExtra("notifId", 0)

        Log.d(TAG, "Notification action received: " + actionType + " (reminder: " + reminderId + ", routine: " + routineId + ")")

        // 1. Instantly dismiss the notification (if it's not the persistent notification)
        if (actionType != "COMPLETE_ROUTINE" && actionType != "CHANGE_ZONE" && actionType != "CHANGE_ENERGY") {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(notifId)
        }

        // 2. Perform direct SQLite database write for instant, sub-millisecond feedback on zone and energy changes
        if (actionType == "CHANGE_ZONE") {
            val zoneId = intent.getStringExtra("zoneId") ?: ""
            val cleanZoneId = if (zoneId == "default_zone") "" else zoneId
            val untilMs = if (cleanZoneId.isEmpty()) "0" else (System.currentTimeMillis() + 60 * 60 * 1000).toString()
            
            saveSettingToDb(context, "realm_override_id", cleanZoneId)
            saveSettingToDb(context, "realm_override_until_ms", untilMs)
            
            triggerServiceUpdate(context)
        } else if (actionType == "CHANGE_ENERGY") {
            val energyLevel = intent.getStringExtra("energyLevel") ?: "MEDIUM"
            
            saveSettingToDb(context, "default_energy_level", energyLevel)
            
            triggerServiceUpdate(context)
        }

        // 3. Go async so the broadcast receiver stays alive during Dart call
        val pendingResult = goAsync()

        // 4. Retrieve callback handle from SharedPreferences
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val handle = prefs.getLong("flutter.notification_action_callback_handle", 0L)

        if (handle == 0L) {
            Log.e(TAG, "NotificationActionReceiver: No callback handle registered.")
            pendingResult.finish()
            return
        }

        // 5. Load & run Flutter engine on main thread
        Handler(Looper.getMainLooper()).post {
            try {
                val appContext = context.applicationContext
                val flutterLoader = FlutterInjector.instance().flutterLoader()
                
                flutterLoader.startInitialization(appContext)
                flutterLoader.ensureInitializationComplete(appContext, null)

                var isEngineNew = false
                if (sBackgroundEngine == null) {
                    Log.d(TAG, "Creating new background FlutterEngine")
                    val engine = FlutterEngine(appContext)
                    
                    val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(handle)
                    if (callbackInfo == null) {
                        Log.e(TAG, "Failed to look up callback information for handle: " + handle)
                        pendingResult.finish()
                        return@post
                    }

                    engine.dartExecutor.executeDartCallback(
                        DartExecutor.DartCallback(
                            appContext.assets,
                            flutterLoader.findAppBundlePath(),
                            callbackInfo
                        )
                    )

                    sBackgroundEngine = engine
                    sMethodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.ritmo.app/notif_action_bg")
                    isEngineNew = true
                } else {
                    Log.d(TAG, "Reusing existing background FlutterEngine")
                }

                val channel = sMethodChannel!!

                val invokeAction = {
                    if (actionType == "COMPLETE_ROUTINE") {
                        Log.d(TAG, "Invoking completeRoutineDirect in Dart for routine: " + routineId)
                        channel.invokeMethod(
                            "completeRoutineDirect",
                            mapOf("routineId" to routineId, "dateStr" to dateStr),
                            object : MethodChannel.Result {
                                override fun success(res: Any?) {
                                    Log.d(TAG, "Dart processed completeRoutineDirect successfully")
                                    pendingResult.finish()
                                }

                                override fun error(code: String, msg: String?, details: Any?) {
                                    Log.e(TAG, "Dart error processing completeRoutineDirect: " + msg)
                                    pendingResult.finish()
                                }

                                override fun notImplemented() {
                                    Log.e(TAG, "Dart completeRoutineDirect not implemented")
                                    pendingResult.finish()
                                }
                            }
                        )
                    } else if (actionType == "UPDATE_PERSISTENT_STATUS") {
                        Log.d(TAG, "Invoking updatePersistentStatus in Dart")
                        channel.invokeMethod(
                            "updatePersistentStatus",
                            null,
                            object : MethodChannel.Result {
                                override fun success(res: Any?) {
                                    Log.d(TAG, "Dart processed updatePersistentStatus successfully")
                                    pendingResult.finish()
                                }

                                override fun error(code: String, msg: String?, details: Any?) {
                                    Log.e(TAG, "Dart error processing updatePersistentStatus: " + msg)
                                    pendingResult.finish()
                                }

                                override fun notImplemented() {
                                    Log.e(TAG, "Dart updatePersistentStatus not implemented")
                                    pendingResult.finish()
                                }
                            }
                        )
                    } else if (actionType == "CHANGE_ZONE") {
                        val zoneId = intent.getStringExtra("zoneId") ?: ""
                        Log.d(TAG, "Invoking changeZoneDirect in Dart for zone: " + zoneId)
                        channel.invokeMethod(
                            "changeZoneDirect",
                            mapOf("zoneId" to zoneId),
                            object : MethodChannel.Result {
                                override fun success(res: Any?) {
                                    Log.d(TAG, "Dart processed changeZoneDirect successfully")
                                    pendingResult.finish()
                                }

                                override fun error(code: String, msg: String?, details: Any?) {
                                    Log.e(TAG, "Dart error processing changeZoneDirect: " + msg)
                                    pendingResult.finish()
                                }

                                override fun notImplemented() {
                                    Log.e(TAG, "Dart changeZoneDirect not implemented")
                                    pendingResult.finish()
                                }
                            }
                        )
                    } else if (actionType == "CHANGE_ENERGY") {
                        val energy = intent.getStringExtra("energyLevel") ?: "MEDIUM"
                        Log.d(TAG, "Invoking changeEnergyDirect in Dart for energy: " + energy)
                        channel.invokeMethod(
                            "changeEnergyDirect",
                            mapOf("energy" to energy),
                            object : MethodChannel.Result {
                                override fun success(res: Any?) {
                                    Log.d(TAG, "Dart processed changeEnergyDirect successfully")
                                    pendingResult.finish()
                                }

                                override fun error(code: String, msg: String?, details: Any?) {
                                    Log.e(TAG, "Dart error processing changeEnergyDirect: " + msg)
                                    pendingResult.finish()
                                }

                                override fun notImplemented() {
                                    Log.e(TAG, "Dart changeEnergyDirect not implemented")
                                    pendingResult.finish()
                                }
                            }
                        )
                    } else {
                        Log.d(TAG, "Invoking handleAction in Dart")
                        channel.invokeMethod(
                            "handleAction",
                            mapOf("action" to actionType, "reminderId" to reminderId),
                            object : MethodChannel.Result {
                                override fun success(res: Any?) {
                                    Log.d(TAG, "Dart processed handleAction successfully")
                                    pendingResult.finish()
                                }

                                override fun error(code: String, msg: String?, details: Any?) {
                                    Log.e(TAG, "Dart error processing handleAction: " + msg)
                                    pendingResult.finish()
                                }

                                override fun notImplemented() {
                                    Log.e(TAG, "Dart handleAction not implemented")
                                    pendingResult.finish()
                                }
                            }
                        )
                    }
                }

                if (isEngineNew) {
                    channel.setMethodCallHandler { call, result ->
                        if (call.method == "dispatcherReady") {
                            Log.d(TAG, "Dart dispatcher reports ready")
                            invokeAction()
                            result.success(null)
                        } else {
                            result.notImplemented()
                        }
                    }
                } else {
                    invokeAction()
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error initializing background FlutterEngine: " + e.message, e)
                pendingResult.finish()
            }
        }
    }

    private fun saveSettingToDb(context: Context, key: String, value: String) {
        try {
            val dbPath = context.getDatabasePath("ritmo_secure.db")
            if (dbPath.exists()) {
                val db = SQLiteDatabase.openDatabase(dbPath.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
                val cv = ContentValues().apply {
                    put("value", value)
                    put("updatedAt", System.currentTimeMillis())
                }
                val affected = db.update("app_settings", cv, "key = ?", arrayOf(key))
                if (affected == 0) {
                    cv.put("key", key)
                    db.insert("app_settings", null, cv)
                }
                db.close()
                Log.d(TAG, "Saved setting to DB: " + key + " = " + value)
            } else {
                Log.e(TAG, "Database file does not exist at " + dbPath.absolutePath)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error writing DB setting " + key + ": " + e.message)
        }
    }

    private fun triggerServiceUpdate(context: Context) {
        try {
            val serviceIntent = Intent(context, RitmoForegroundService::class.java).apply {
                action = RitmoForegroundService.ACTION_START_STATUS
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error triggering service update: " + e.message)
        }
    }
}