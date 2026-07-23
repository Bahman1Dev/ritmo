package ir.ritmo.app

import android.content.Intent
import android.widget.RemoteViewsService

class RitmoAgendaWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return RitmoAgendaWidgetFactory(applicationContext)
    }
}
