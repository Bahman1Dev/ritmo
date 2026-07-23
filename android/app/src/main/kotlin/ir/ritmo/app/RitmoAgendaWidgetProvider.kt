package ir.ritmo.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.RemoteViews
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import org.json.JSONObject

class RitmoAgendaWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "RitmoAgendaWidget"
        const val ACTION_REFRESH = "com.ritmo.app.AGENDA_WIDGET_REFRESH"
        const val ACTION_CLICK_ITEM = "com.ritmo.app.AGENDA_WIDGET_CLICK"

        private var sBackgroundEngine: FlutterEngine? = null
        private var sMethodChannel: MethodChannel? = null

        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, RitmoAgendaWidgetProvider::class.java))
            if (ids.isEmpty()) return
            mgr.notifyAppWidgetViewDataChanged(ids, R.id.agenda_list)
            for (id in ids) {
                updateAppWidget(context, mgr, id)
            }
        }

        private fun updateAppWidget(context: Context, mgr: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.ritmo_agenda_widget_layout)

            // 1. Render Header from SharedPrefs snapshot
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val rawJson = prefs.getString("flutter.widget_agenda_snapshot", null)

                if (rawJson != null) {
                    val root = JSONObject(rawJson)
                    val dateStr = root.optString("dateStr", "امروز")
                    val remainingText = root.optString("remainingText", "۰ از ۰ مانده")

                    views.setTextViewText(R.id.widget_date_text, dateStr)
                    views.setTextViewText(R.id.widget_remaining_text, remainingText)
                } else {
                    views.setTextViewText(R.id.widget_date_text, "امروز")
                    views.setTextViewText(R.id.widget_remaining_text, "برنامه‌ای یافت نشد")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error rendering header: ${e.message}", e)
                views.setTextViewText(R.id.widget_date_text, "خطا")
                views.setTextViewText(R.id.widget_remaining_text, "خطا در بارگذاری")
            }

            // 2. Set RemoteAdapter for the ListView
            val serviceIntent = Intent(context, RitmoAgendaWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.agenda_list, serviceIntent)
            views.setEmptyView(R.id.agenda_list, R.id.widget_empty)

            // 3. Set click PendingIntent Template
            val mutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
            val clickTemplate = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                Intent(context, RitmoAgendaWidgetProvider::class.java).apply {
                    action = ACTION_CLICK_ITEM
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                },
                PendingIntent.FLAG_UPDATE_CURRENT or mutableFlag
            )
            views.setPendingIntentTemplate(R.id.agenda_list, clickTemplate)

            // 4. Header click opens MainActivity (standard app entry)
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                10,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_date_text, openAppPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_remaining_text, openAppPendingIntent)

            // 5. Refresh button broadcast click
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context,
                20,
                Intent(context, RitmoAgendaWidgetProvider::class.java).apply {
                    action = ACTION_REFRESH
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refresh_btn, refreshPendingIntent)

            mgr.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "onReceive action: ${intent.action}")

        when (intent.action) {
            ACTION_REFRESH -> {
                refreshAll(context)
            }
            ACTION_CLICK_ITEM -> {
                val clickAction = intent.getStringExtra("clickAction") ?: "OPEN"
                if (clickAction == "TICK") {
                    val routineId = intent.getStringExtra("routineId")
                    val dateStr = intent.getStringExtra("dateStr")
                    val itemId = intent.getStringExtra("itemId")

                    if (routineId != null && dateStr != null) {
                        Log.d(TAG, "Ticking routine $routineId for date $dateStr in background")
                        completeRoutineInBackground(context.applicationContext, routineId, dateStr)
                    }
                } else {
                    // Open App (standard or optional deep-link details)
                    val launchIntent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        action = "com.ritmo.app.OPEN_MODULE"
                        putExtra("moduleId", intent.getStringExtra("domain") ?: "today")
                    }
                    context.startActivity(launchIntent)
                }
            }
        }
    }

    private fun completeRoutineInBackground(context: Context, routineId: String, dateStr: String) {
        val pendingResult = goAsync()

        // Get callback handle
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val handle = prefs.getLong("flutter.notification_action_callback_handle", 0L)

        if (handle == 0L) {
            Log.e(TAG, "Background execution handle not registered in SharedPrefs")
            pendingResult.finish()
            return
        }

        Handler(Looper.getMainLooper()).post {
            try {
                val flutterLoader = FlutterInjector.instance().flutterLoader()
                flutterLoader.startInitialization(context)
                flutterLoader.ensureInitializationComplete(context, null)

                var isNewEngine = false
                if (sBackgroundEngine == null) {
                    Log.d(TAG, "Starting new background FlutterEngine for widget")
                    val engine = FlutterEngine(context)
                    val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(handle)
                    if (callbackInfo == null) {
                        Log.e(TAG, "Could not find callback info for handle $handle")
                        pendingResult.finish()
                        return@post
                    }
                    engine.dartExecutor.executeDartCallback(
                        DartExecutor.DartCallback(
                            context.assets,
                            flutterLoader.findAppBundlePath(),
                            callbackInfo
                        )
                    )
                    sBackgroundEngine = engine
                    sMethodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.ritmo.app/notif_action_bg")
                    isNewEngine = true
                } else {
                    Log.d(TAG, "Reusing existing background FlutterEngine")
                }

                val channel = sMethodChannel!!
                val invokeDirect = {
                    Log.d(TAG, "Invoking completeRoutineDirect in background Dart isolate")
                    channel.invokeMethod(
                        "completeRoutineDirect",
                        mapOf("routineId" to routineId, "dateStr" to dateStr),
                        object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                Log.d(TAG, "Successfully completed routine $routineId in background")
                                // Refresh all widget copies to display updated data
                                refreshAll(context)
                                pendingResult.finish()
                            }

                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                Log.e(TAG, "Dart error completing routine: $errorMessage")
                                pendingResult.finish()
                            }

                            override fun notImplemented() {
                                Log.e(TAG, "completeRoutineDirect not implemented in Dart")
                                pendingResult.finish()
                            }
                        }
                    )
                }

                if (isNewEngine) {
                    channel.setMethodCallHandler { call, result ->
                        if (call.method == "dispatcherReady") {
                            Log.d(TAG, "Background Dart dispatcher is ready")
                            invokeDirect()
                            result.success(null)
                        } else {
                            result.notImplemented()
                        }
                    }
                } else {
                    invokeDirect()
                }

            } catch (e: Exception) {
                Log.e(TAG, "Failed to run background complete: ${e.message}", e)
                pendingResult.finish()
            }
        }
    }
}
