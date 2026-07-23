package ir.ritmo.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Full-screen Ritmo widget: a glass dashboard card with the rhythm score,
 * energy, next action, and a scrollable list of every active module.
 *
 * Data flows one way: Flutter computes everything (DashboardController) and
 * mirrors it into SharedPreferences ("flutter.widget_full_snapshot"); this
 * provider only renders. Kotlin holds no business logic.
 */
class RitmoFullWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "RitmoFullWidget"
        const val ACTION_REFRESH = "com.ritmo.app.WIDGET_REFRESH"

        /** Re-render header + reload the module list for every placed instance. */
        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, RitmoFullWidgetProvider::class.java))
            if (ids.isEmpty()) return
            mgr.notifyAppWidgetViewDataChanged(ids, R.id.widget_module_list)
            for (id in ids) updateAppWidget(context, mgr, id)
        }

        private fun updateAppWidget(context: Context, mgr: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.ritmo_full_widget_layout)

            // ── Header from snapshot ──
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val raw = prefs.getString("flutter.widget_full_snapshot", null)
                if (raw != null) {
                    val json = JSONObject(raw)
                    val score = json.optInt("rhythmScore", 0)
                    val energy = json.optString("energyLabel", "متوسط")
                    val next = json.optString("nextActionTitle", "استراحت 🌿")
                    views.setTextViewText(R.id.widget_rhythm_score, "%" + toPersianDigits(score.toString()))
                    views.setTextViewText(R.id.widget_energy, energy)
                    views.setTextViewText(R.id.widget_next_action, "کار بعدی: $next")
                } else {
                    views.setTextViewText(R.id.widget_rhythm_score, "%۰")
                    views.setTextViewText(R.id.widget_energy, "متوسط")
                    views.setTextViewText(R.id.widget_next_action, "کار بعدی: استراحت 🌿")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error rendering header: ${e.message}", e)
            }

            // ── Scrollable module list (collection) ──
            val serviceIntent = Intent(context, RitmoWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                // Unique data URI so the host treats each widget's adapter separately.
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widget_module_list, serviceIntent)
            views.setEmptyView(R.id.widget_module_list, R.id.widget_empty)

            // ── Click targets ──
            val mutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0

            // List rows deep-link into the tapped module's screen. The factory
            // supplies the per-row "moduleId" via a fill-in intent; this template
            // carries the action that MainActivity routes on.
            val template = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java).apply {
                    action = "com.ritmo.app.OPEN_MODULE"
                },
                PendingIntent.FLAG_UPDATE_CURRENT or mutableFlag
            )
            views.setPendingIntentTemplate(R.id.widget_module_list, template)

            // Header taps open the app.
            val openApp = PendingIntent.getActivity(
                context, 1,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_title, openApp)
            views.setOnClickPendingIntent(R.id.widget_rhythm_score, openApp)
            views.setOnClickPendingIntent(R.id.widget_next_action, openApp)

            // Refresh button re-reads the snapshot.
            val refresh = PendingIntent.getBroadcast(
                context, 2,
                Intent(context, RitmoFullWidgetProvider::class.java).apply { action = ACTION_REFRESH },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refresh_btn, refresh)

            mgr.updateAppWidget(appWidgetId, views)
        }

        private fun toPersianDigits(input: String): String {
            val fa = charArrayOf('۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹')
            val sb = StringBuilder(input.length)
            for (c in input) {
                if (c in '0'..'9') sb.append(fa[c - '0']) else sb.append(c)
            }
            return sb.toString()
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            refreshAll(context)
        }
    }
}
