package ir.ritmo.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build

object RitmoNotificationChannels {
    const val ESSENTIAL = "RitmoEssentialChannel_v2"
    const val NORMAL = "RitmoNormalChannel_v2"

    private val LEGACY = listOf("RitmoEssentialChannel", "RitmoNormalChannel")

    fun ensure(context: Context, nm: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        LEGACY.forEach { legacyId ->
            try {
                nm.deleteNotificationChannel(legacyId)
            } catch (_) {}
        }

        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val alarmAttrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val essential = NotificationChannel(
            ESSENTIAL,
            context.getString(R.string.notif_essential_channel_name),
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = context.getString(R.string.notif_essential_channel_desc)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 500, 200, 500)
            setSound(alarmUri, alarmAttrs)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                setBypassDnd(true)
            }
            setShowBadge(true)
        }
        nm.createNotificationChannel(essential)

        val normalUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val normalAttrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val normal = NotificationChannel(
            NORMAL,
            context.getString(R.string.notif_normal_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = context.getString(R.string.notif_normal_channel_desc)
            enableVibration(true)
            setSound(normalUri, normalAttrs)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            setShowBadge(true)
        }
        nm.createNotificationChannel(normal)
    }
}
