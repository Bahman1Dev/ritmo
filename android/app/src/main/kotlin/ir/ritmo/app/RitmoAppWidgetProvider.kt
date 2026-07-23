package ir.ritmo.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONObject

class RitmoAppWidgetProvider : AppWidgetProvider() {

    private val TAG = "RitmoAppWidget"

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "onUpdate called for widgets")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.ritmo_widget_layout)

        try {
            // Load widget state from SharedPreferences (Rethink SQLite decoupling)
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val widgetJsonStr = prefs.getString("flutter.widget_snapshot", null)

            if (widgetJsonStr != null) {
                val jsonObj = JSONObject(widgetJsonStr)
                val nextActionTitle = jsonObj.optString("nextActionTitle", "استراحت 🌿")
                val rhythmScore = jsonObj.optInt("rhythmScore", 0)
                val currentEnergyLevel = jsonObj.optString("currentEnergyLevel", "متوسط")

                views.setTextViewText(R.id.widget_next_action_title, "کار بعدی: $nextActionTitle")
                views.setTextViewText(R.id.widget_rhythm_score, "نبض امروز: %$rhythmScore")
                
                val energyFa = when (currentEnergyLevel.uppercase()) {
                    "LOW" -> "کم ⚡"
                    "HIGH" -> "زیاد 🔥"
                    else -> "متوسط 🔋"
                }
                views.setTextViewText(R.id.widget_energy_level, "انرژی: $energyFa")
            } else {
                views.setTextViewText(R.id.widget_next_action_title, "کار بعدی: استراحت 🌿")
                views.setTextViewText(R.id.widget_rhythm_score, "نبض امروز: %۰")
                views.setTextViewText(R.id.widget_energy_level, "انرژی: متوسط 🔋")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget UI: ${e.message}", e)
            views.setTextViewText(R.id.widget_next_action_title, "خطا در بارگذاری")
        }

        // Open app when widget is tapped
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_next_action_title, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
