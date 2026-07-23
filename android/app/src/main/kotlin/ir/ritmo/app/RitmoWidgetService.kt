package ir.ritmo.app

import android.content.Intent
import android.widget.RemoteViewsService

/**
 * Serves the scrollable module list inside the full-screen Ritmo widget.
 * Pure rendering layer — all data is pre-computed by Flutter and mirrored
 * into SharedPreferences (key "flutter.widget_full_snapshot").
 */
class RitmoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return RitmoWidgetFactory(applicationContext)
    }
}
