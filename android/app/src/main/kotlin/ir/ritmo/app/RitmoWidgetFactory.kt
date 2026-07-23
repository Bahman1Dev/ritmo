package ir.ritmo.app

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

/**
 * Builds one row per active module for the full-screen widget's ListView.
 *
 * Reads "flutter.widget_full_snapshot" from FlutterSharedPreferences. The JSON
 * is produced in Flutter (DashboardController) so Kotlin contains zero business
 * logic — it only parses the snapshot and renders rows.
 */
class RitmoWidgetFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private val TAG = "RitmoWidgetFactory"
    private val items = mutableListOf<JSONObject>()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        items.clear()
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val raw = prefs.getString("flutter.widget_full_snapshot", null) ?: return
            val root = JSONObject(raw)
            val modules: JSONArray = root.optJSONArray("modules") ?: return
            for (i in 0 until modules.length()) {
                modules.optJSONObject(i)?.let { items.add(it) }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing widget snapshot: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        items.clear()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.ritmo_full_widget_item)
        if (position < 0 || position >= items.size) return views

        val m = items[position]
        val accent = parseColor(m.optString("color", "#10B981"), Color.parseColor("#10B981"))

        views.setTextViewText(R.id.item_emoji, m.optString("emoji", "•"))
        views.setTextViewText(R.id.item_title, m.optString("title", ""))
        views.setTextViewText(R.id.item_secondary, m.optString("secondary", ""))
        views.setTextViewText(R.id.item_primary, m.optString("primary", "—"))
        views.setTextColor(R.id.item_primary, accent)
        views.setInt(R.id.item_accent_bar, "setBackgroundColor", accent)

        // Tapping any row opens the app (template is set by the provider).
        val fillIn = Intent().apply {
            putExtra("moduleId", m.optString("id", ""))
        }
        views.setOnClickFillInIntent(R.id.item_root, fillIn)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun parseColor(hex: String, fallback: Int): Int {
        return try {
            Color.parseColor(hex)
        } catch (e: Exception) {
            fallback
        }
    }
}
