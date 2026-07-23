package ir.ritmo.app

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.sqlite.SQLiteDatabase
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class RitmoForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "RitmoForegroundServiceChannel"
        const val NOTIFICATION_ID = 9999

        const val ACTION_START_STATUS = "com.ritmo.app.ACTION_START_STATUS"
        const val ACTION_START_TIMER = "com.ritmo.app.ACTION_START_TIMER"

        const val ACTION_TIMER_TICK = "com.ritmo.app.ACTION_TIMER_TICK"
        const val ACTION_TIMER_COMPLETE = "com.ritmo.app.ACTION_TIMER_COMPLETE"
    }

    private var mode = "STATUS" // STATUS or TIMER
    private var timerTitle = ""
    private var durationSeconds = 0
    private var elapsedSeconds = 0

    // Cached status metrics
    private var lastZone = "آزاد"
    private var lastEnergy = "متوسط"
    private var lastProposedTask = "استراحت 🌿"
    private var lastProposedTaskId: String? = null
    private var lastCompletedRoutines = 0
    private var lastTotalRoutines = 0
    private var lastCompletedPrayers = 0
    private var lastTotalPrayers = 0
    private var lastZoneNames = ArrayList<String>()
    private var lastZoneIds = ArrayList<String>()

    private val handler = Handler(Looper.getMainLooper())
    private val timerRunnable = object : Runnable {
        override fun run() {
            if (elapsedSeconds < durationSeconds) {
                elapsedSeconds++
                updateTimerNotification()
                sendTimerBroadcast(ACTION_TIMER_TICK)
                handler.postDelayed(this, 1000)
            } else {
                sendTimerBroadcast(ACTION_TIMER_COMPLETE)
                stopSelf()
            }
        }
    }

    // Screen State Receiver for Smart Privacy Lockscreen Shield
    private val screenStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (mode == "STATUS") {
                updateStatusNotification()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        
        // Register screen locking/unlocking receivers
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenStateReceiver, filter)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            val action = intent.action
            if (action == ACTION_START_STATUS) {
                handler.removeCallbacks(timerRunnable)
                mode = "STATUS"
                
                lastZone = intent.getStringExtra("zone") ?: "آزاد"
                lastEnergy = intent.getStringExtra("energy") ?: "متوسط"
                lastProposedTask = intent.getStringExtra("proposedTask") ?: "استراحت 🌿"
                lastProposedTaskId = intent.getStringExtra("proposedTaskId")
                lastCompletedRoutines = intent.getIntExtra("completedRoutines", 0)
                lastTotalRoutines = intent.getIntExtra("totalRoutines", 0)
                lastCompletedPrayers = intent.getIntExtra("completedPrayers", 0)
                lastTotalPrayers = intent.getIntExtra("totalPrayers", 0)
                
                val names = intent.getStringArrayListExtra("zoneNames")
                val ids = intent.getStringArrayListExtra("zoneIds")
                if (names != null && ids != null) {
                    lastZoneNames = names
                    lastZoneIds = ids
                }
                
                startStatusForeground()
            } else if (action == ACTION_START_TIMER) {
                mode = "TIMER"
                timerTitle = intent.getStringExtra("title") ?: "روتین"
                durationSeconds = intent.getIntExtra("durationSeconds", 0)
                elapsedSeconds = intent.getIntExtra("elapsedSeconds", 0)

                startTimerForeground()
                handler.removeCallbacks(timerRunnable)
                handler.postDelayed(timerRunnable, 1000)
            }
        }
        return START_NOT_STICKY
    }

    private fun isDeviceLocked(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isKeyguardLocked
    }

    private fun getSettingFromDb(key: String, defaultValue: String): String {
        var value = defaultValue
        try {
            val dbPath = getDatabasePath("ritmo_secure.db")
            if (dbPath.exists()) {
                val db = SQLiteDatabase.openDatabase(dbPath.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
                val cursor = db.query("app_settings", arrayOf("value"), "key = ?", arrayOf(key), null, null, null)
                if (cursor.moveToFirst()) {
                    value = cursor.getString(0) ?: defaultValue
                }
                cursor.close()
                db.close()
            }
        } catch (e: Exception) {
            Log.e("RitmoForegroundService", "Error reading DB setting " + key + ": " + e.message)
        }
        return value
    }

    private fun startStatusForeground() {
        val collapsedViews = buildCollapsedStatusRemoteViews()
        val expandedViews = buildExpandedStatusRemoteViews()

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setCustomContentView(collapsedViews)
            .setCustomBigContentView(expandedViews)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)

        startForeground(NOTIFICATION_ID, builder.build())
    }

    fun updateStatusNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val collapsedViews = buildCollapsedStatusRemoteViews()
        val expandedViews = buildExpandedStatusRemoteViews()

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setCustomContentView(collapsedViews)
            .setCustomBigContentView(expandedViews)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    private fun buildCollapsedStatusRemoteViews(): RemoteViews {
        val views = RemoteViews(packageName, R.layout.ritmo_notification_status_collapsed)
        val isLocked = isDeviceLocked()

        if (isLocked) {
            views.setTextViewText(R.id.txt_collapsed_status, "ریتمو فعال است 🌿")
            views.setTextViewText(R.id.txt_collapsed_task, "برای مشاهده جزئیات قفل را باز کنید")
            views.setViewVisibility(R.id.btn_collapsed_done, View.GONE)
        } else {
            // Read active zone override name
            val overrideId = getSettingFromDb("realm_override_id", "")
            val activeZoneName = if (overrideId.isEmpty() || overrideId == "default_zone") "آزاد" else lastZone
            val activeEnergy = getSettingFromDb("default_energy_level", "MEDIUM")
            val energyStr = when (activeEnergy.uppercase()) {
                "LOW" -> "پایین"
                "HIGH" -> "بالا"
                else -> "متوسط"
            }

            views.setTextViewText(R.id.txt_collapsed_status, "زون: " + activeZoneName + " | انرژی: " + energyStr)
            views.setTextViewText(R.id.txt_collapsed_task, "پیشنهاد: " + lastProposedTask)

            if (lastProposedTaskId != null && lastProposedTaskId!!.isNotEmpty() &&
                !lastProposedTaskId.equals("REST", ignoreCase = true) &&
                !lastProposedTaskId.equals("REST_TIME", ignoreCase = true)) {
                
                views.setViewVisibility(R.id.btn_collapsed_done, View.VISIBLE)
                
                val doneIntent = Intent(this, NotificationActionReceiver::class.java).apply {
                    putExtra("actionType", "COMPLETE_ROUTINE")
                    putExtra("routineId", lastProposedTaskId)
                    val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                    putExtra("dateStr", sdf.format(Date()))
                    putExtra("notifId", NOTIFICATION_ID)
                }
                val donePendingIntent = PendingIntent.getBroadcast(
                    this,
                    3,
                    doneIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_collapsed_done, donePendingIntent)
            } else {
                views.setViewVisibility(R.id.btn_collapsed_done, View.GONE)
            }
        }

        return views
    }

    private fun buildExpandedStatusRemoteViews(): RemoteViews {
        val views = RemoteViews(packageName, R.layout.ritmo_notification_status_expanded)
        val isLocked = isDeviceLocked()

        if (isLocked) {
            views.setTextViewText(R.id.txt_expanded_task_title, "ریتمو فعال است 🌿")
            views.setTextViewText(R.id.txt_expanded_task_desc, "برای دسترسی سریع قفل را باز کنید")
            views.setViewVisibility(R.id.btn_expanded_done, View.GONE)
            views.setViewVisibility(R.id.progressBar_today, View.GONE)
            views.setTextViewText(R.id.txt_expanded_stats, "")
            
            // Hide control buttons
            views.setViewVisibility(R.id.btn_zone_1, View.GONE)
            views.setViewVisibility(R.id.btn_zone_2, View.GONE)
            views.setViewVisibility(R.id.btn_zone_3, View.GONE)
            views.setViewVisibility(R.id.btn_energy_high, View.GONE)
            views.setViewVisibility(R.id.btn_energy_med, View.GONE)
            views.setViewVisibility(R.id.btn_energy_low, View.GONE)
        } else {
            views.setViewVisibility(R.id.progressBar_today, View.VISIBLE)
            views.setViewVisibility(R.id.btn_zone_1, View.VISIBLE)
            views.setViewVisibility(R.id.btn_zone_2, View.VISIBLE)
            views.setViewVisibility(R.id.btn_zone_3, View.VISIBLE)
            views.setViewVisibility(R.id.btn_energy_high, View.VISIBLE)
            views.setViewVisibility(R.id.btn_energy_med, View.VISIBLE)
            views.setViewVisibility(R.id.btn_energy_low, View.VISIBLE)

            // 1. Calculate and bind progress stats
            val completed = lastCompletedRoutines + lastCompletedPrayers
            val total = lastTotalRoutines + lastTotalPrayers
            val progressPercent = if (total > 0) (completed * 100) / total else 0
            views.setProgressBar(R.id.progressBar_today, 100, progressPercent, false)
            views.setTextViewText(R.id.txt_expanded_stats, "کارهای امروز: " + completed + " از " + total)

            // 2. Set next proposed task
            views.setTextViewText(R.id.txt_expanded_task_title, "پیشنهاد بعدی: " + lastProposedTask)
            
            val activeEnergy = getSettingFromDb("default_energy_level", "MEDIUM")
            val energyStr = when (activeEnergy.uppercase()) {
                "LOW" -> "پایین"
                "HIGH" -> "بالا"
                else -> "متوسط"
            }
            val overrideId = getSettingFromDb("realm_override_id", "")
            val activeZoneName = if (overrideId.isEmpty() || overrideId == "default_zone") "آزاد" else lastZone
            views.setTextViewText(R.id.txt_expanded_task_desc, "زون: " + activeZoneName + " | انرژی: " + energyStr)

            // 3. Recommended task Done action
            if (lastProposedTaskId != null && lastProposedTaskId!!.isNotEmpty() &&
                !lastProposedTaskId.equals("REST", ignoreCase = true) &&
                !lastProposedTaskId.equals("REST_TIME", ignoreCase = true)) {
                
                views.setViewVisibility(R.id.btn_expanded_done, View.VISIBLE)
                
                val doneIntent = Intent(this, NotificationActionReceiver::class.java).apply {
                    putExtra("actionType", "COMPLETE_ROUTINE")
                    putExtra("routineId", lastProposedTaskId)
                    val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                    putExtra("dateStr", sdf.format(Date()))
                    putExtra("notifId", NOTIFICATION_ID)
                }
                val donePendingIntent = PendingIntent.getBroadcast(
                    this,
                    4,
                    doneIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_expanded_done, donePendingIntent)
            } else {
                views.setViewVisibility(R.id.btn_expanded_done, View.GONE)
            }

            // 4. Bind Zone Buttons (RTL Order)
            val activeTextColor = androidx.core.content.ContextCompat.getColor(this, R.color.notif_btn_active_text)
            val inactiveTextColor = androidx.core.content.ContextCompat.getColor(this, R.color.notif_btn_inactive_text)

            var z1Id = "work"
            var z1Name = "💼 کار"
            if (lastZoneIds.size > 0) {
                z1Id = lastZoneIds[0]
                z1Name = lastZoneNames[0]
            }
            views.setTextViewText(R.id.btn_zone_1, z1Name)
            val isZ1Active = overrideId == z1Id
            views.setInt(R.id.btn_zone_1, "setBackgroundResource", if (isZ1Active) R.drawable.bg_notification_button_active else R.drawable.bg_notification_button_inactive)
            views.setTextColor(R.id.btn_zone_1, if (isZ1Active) activeTextColor else inactiveTextColor)
            views.setOnClickPendingIntent(R.id.btn_zone_1, getZonePendingIntent(z1Id))

            var z2Id = "study"
            var z2Name = "📚 درس"
            if (lastZoneIds.size > 1) {
                z2Id = lastZoneIds[1]
                z2Name = lastZoneNames[1]
            }
            views.setTextViewText(R.id.btn_zone_2, z2Name)
            val isZ2Active = overrideId == z2Id
            views.setInt(R.id.btn_zone_2, "setBackgroundResource", if (isZ2Active) R.drawable.bg_notification_button_active else R.drawable.bg_notification_button_inactive)
            views.setTextColor(R.id.btn_zone_2, if (isZ2Active) activeTextColor else inactiveTextColor)
            views.setOnClickPendingIntent(R.id.btn_zone_2, getZonePendingIntent(z2Id))

            val z3Id = "default_zone"
            val z3Name = "🌿 آزاد"
            val isZ3Active = overrideId.isEmpty() || overrideId == "default_zone"
            views.setTextViewText(R.id.btn_zone_3, z3Name)
            views.setInt(R.id.btn_zone_3, "setBackgroundResource", if (isZ3Active) R.drawable.bg_notification_button_active else R.drawable.bg_notification_button_inactive)
            views.setTextColor(R.id.btn_zone_3, if (isZ3Active) activeTextColor else inactiveTextColor)
            views.setOnClickPendingIntent(R.id.btn_zone_3, getZonePendingIntent(z3Id))

            // 5. Bind Energy Buttons (RTL Order)
            val isHigh = activeEnergy.equals("HIGH", ignoreCase = true)
            val isMed = activeEnergy.equals("MEDIUM", ignoreCase = true)
            val isLow = activeEnergy.equals("LOW", ignoreCase = true)

            views.setInt(R.id.btn_energy_high, "setBackgroundResource", if (isHigh) R.drawable.bg_notification_button_active else R.drawable.bg_notification_button_inactive)
            views.setTextColor(R.id.btn_energy_high, if (isHigh) activeTextColor else inactiveTextColor)
            views.setOnClickPendingIntent(R.id.btn_energy_high, getEnergyPendingIntent("HIGH"))

            views.setInt(R.id.btn_energy_med, "setBackgroundResource", if (isMed) R.drawable.bg_notification_button_active else R.drawable.bg_notification_button_inactive)
            views.setTextColor(R.id.btn_energy_med, if (isMed) activeTextColor else inactiveTextColor)
            views.setOnClickPendingIntent(R.id.btn_energy_med, getEnergyPendingIntent("MEDIUM"))

            views.setInt(R.id.btn_energy_low, "setBackgroundResource", if (isLow) R.drawable.bg_notification_button_active else R.drawable.bg_notification_button_inactive)
            views.setTextColor(R.id.btn_energy_low, if (isLow) activeTextColor else inactiveTextColor)
            views.setOnClickPendingIntent(R.id.btn_energy_low, getEnergyPendingIntent("LOW"))
        }

        return views
    }

    private fun getZonePendingIntent(zoneId: String): PendingIntent {
        val intent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "CHANGE_ZONE"
            putExtra("actionType", "CHANGE_ZONE")
            putExtra("zoneId", zoneId)
        }
        return PendingIntent.getBroadcast(
            this,
            zoneId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun getEnergyPendingIntent(level: String): PendingIntent {
        val intent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "CHANGE_ENERGY"
            putExtra("actionType", "CHANGE_ENERGY")
            putExtra("energyLevel", level)
        }
        return PendingIntent.getBroadcast(
            this,
            level.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun startTimerForeground() {
        val notification = buildTimerNotification()
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun updateTimerNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, buildTimerNotification())
    }

    private fun buildTimerNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val remaining = durationSeconds - elapsedSeconds
        val min = remaining / 60
        val sec = remaining % 60
        val timeStr = String.format("%02d:%02d", min, sec)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("تایمر روتین: " + timerTitle)
            .setContentText("زمان باقی‌مانده: " + timeStr)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun sendTimerBroadcast(action: String) {
        val intent = Intent(action).apply {
            putExtra("title", timerTitle)
            putExtra("durationSeconds", durationSeconds)
            putExtra("elapsedSeconds", elapsedSeconds)
        }
        sendBroadcast(intent)
    }

    override fun onDestroy() {
        handler.removeCallbacks(timerRunnable)
        try {
            unregisterReceiver(screenStateReceiver)
        } catch (e: Exception) {}
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Ritmo Persistent Engine Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}