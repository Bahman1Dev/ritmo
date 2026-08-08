package ir.ritmo.app

/**
 * Single Source of Truth for Native Method Channels and Method Names in Kotlin.
 * Any changes here MUST be mirrored in native_channel_contract.dart.
 * Enforced by `test/platform/channel_contract_parity_test.dart`.
 */
object NativeChannels {
    const val ALARMS = "com.ritmo.app/alarms"
    const val KEYSTORE = "com.ritmo.app/keystore"
    const val FOREGROUND_SERVICE = "com.ritmo.app/foreground_service"
    const val WIDGET = "com.ritmo.app/widget"
    const val LAUNCH_INTENT = "com.ritmo.app/launch_intent"
    const val MYKET_BILLING = "com.ritmo.app/myket_billing"
    const val NOTIF_ACTION_BG = "com.ritmo.app/notif_action_bg"
}

object DatabaseConfig {
    const val DATABASE_NAME = "ritmo.db"
}

object AlarmMethods {
    const val SCHEDULE_EXACT_ALARM = "scheduleExactAlarm"
    const val CANCEL_ALARM = "cancelAlarm"
    const val CHECK_EXACT_ALARM_PERMISSION = "checkExactAlarmPermission"
    const val REQUEST_EXACT_ALARM_PERMISSION = "requestExactAlarmPermission"
}

object KeystoreMethods {
    const val GET_OR_CREATE_KEY = "getOrCreateKey"
}

object ForegroundServiceMethods {
    const val START_STATUS_MODE = "startStatusMode"
    const val START_TIMER_MODE = "startTimerMode"
    const val STOP_SERVICE = "stopService"
}

object WidgetMethods {
    const val REFRESH_WIDGETS = "refreshWidgets"
}

object LaunchIntentMethods {
    const val GET_LAUNCH_INTENT = "getLaunchIntent"
}

object MyketBillingMethods {
    const val INIT = "init"
    const val GET_PRODUCT_DETAILS = "getProductDetails"
    const val PURCHASE = "purchase"
    const val RESTORE_PURCHASES = "restorePurchases"
    const val DISPOSE = "dispose"
}

object NotifActionBgMethods {
    const val DISPATCHER_READY = "dispatcherReady"
    const val COMPLETE_ROUTINE_DIRECT = "completeRoutineDirect"
    const val UPDATE_PERSISTENT_STATUS = "updatePersistentStatus"
    const val CHANGE_ZONE_DIRECT = "changeZoneDirect"
    const val CHANGE_ENERGY_DIRECT = "changeEnergyDirect"
    const val HANDLE_ACTION = "handleAction"
}
