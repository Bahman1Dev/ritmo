package ir.ritmo.app

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StrikethroughSpan
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class RitmoAgendaWidgetFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private val TAG = "RitmoAgendaWidgetFact"
    private val items = mutableListOf<JSONObject>()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        items.clear()
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val raw = prefs.getString("flutter.widget_agenda_snapshot", null) ?: return
            val root = JSONObject(raw)
            val list: JSONArray = root.optJSONArray("items") ?: return
            for (i in 0 until list.length()) {
                list.optJSONObject(i)?.let { items.add(it) }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading/parsing agenda snapshot: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        items.clear()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.ritmo_agenda_widget_item)
        if (position < 0 || position >= items.size) return views

        val m = items[position]
        val isCompleted = m.optBoolean("isCompleted", false)
        val isTickable = m.optBoolean("isTickable", false)
        val domain = m.optString("domain", "routine")

        // 1. Time display
        val timeStr = m.optString("time", "")
        if (timeStr.isNotEmpty()) {
            views.setViewVisibility(R.id.item_time, View.VISIBLE)
            views.setTextViewText(R.id.item_time, timeStr)
        } else {
            views.setViewVisibility(R.id.item_time, View.GONE)
        }

        // 2. Title & strike-through formatting
        val titleText = m.optString("title", "")
        if (isCompleted) {
            val span = SpannableString(titleText)
            span.setSpan(StrikethroughSpan(), 0, titleText.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            views.setTextViewText(R.id.item_title, span)
            views.setTextColor(R.id.item_title, Color.parseColor("#6B7280")) // dimmed
            if (timeStr.isNotEmpty()) {
                views.setTextColor(R.id.item_time, Color.parseColor("#4B5563"))
            }
        } else {
            views.setTextViewText(R.id.item_title, titleText)
            views.setTextColor(R.id.item_title, Color.parseColor("#ECEEF3")) // standard white
            if (timeStr.isNotEmpty()) {
                views.setTextColor(R.id.item_time, Color.parseColor("#9AA0AE"))
            }
        }

        // 3. Domain Accent Bar Color
        val colorHex = when (domain) {
            "prayer", "mustahab", "worshipDebt" -> "#FBBF24" // Yellow
            "course" -> "#3B82F6"                           // Blue
            "goalStep" -> "#F59E0B"                         // Orange
            "konkur" -> "#8B5CF6"                           // Purple
            else -> "#10B981"                               // Green (Routine/Other)
        }
        val accentColor = Color.parseColor(colorHex)
        views.setInt(R.id.item_accent_bar, "setBackgroundColor", accentColor)

        // 4. Checkbox rendering & visibility
        if (isTickable) {
            views.setViewVisibility(R.id.item_check_btn, View.VISIBLE)
            if (isCompleted) {
                views.setImageViewResource(R.id.item_check_btn, R.drawable.ic_checkbox_checked)
            } else {
                views.setImageViewResource(R.id.item_check_btn, R.drawable.ic_checkbox_unchecked)
            }

            // Fill-in Intent for checking off the item
            val checkFillIn = Intent().apply {
                putExtra("clickAction", "TICK")
                putExtra("routineId", m.optString("routineId"))
                putExtra("dateStr", m.optString("dateStr"))
                putExtra("itemId", m.optString("id"))
            }
            views.setOnClickFillInIntent(R.id.item_check_btn, checkFillIn)
        } else {
            views.setViewVisibility(R.id.item_check_btn, View.INVISIBLE)
        }

        // 5. Click template for the whole row to open module screen in app
        val rootFillIn = Intent().apply {
            putExtra("clickAction", "OPEN")
            putExtra("domain", domain)
            putExtra("itemId", m.optString("id"))
        }
        views.setOnClickFillInIntent(R.id.item_root, rootFillIn)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
