/// Single Source of Truth for Native Method Channels and Method Names in Dart.
/// Any changes here MUST be mirrored in NativeChannelContract.kt.
/// Enforced by `test/platform/channel_contract_parity_test.dart`.
abstract class NativeChannels {
  static const alarms = 'com.ritmo.app/alarms';
  static const keystore = 'com.ritmo.app/keystore';
  static const foregroundService = 'com.ritmo.app/foreground_service';
  static const widget = 'com.ritmo.app/widget';
  static const launchIntent = 'com.ritmo.app/launch_intent';
  static const myketBilling = 'com.ritmo.app/myket_billing';
  static const notifActionBg = 'com.ritmo.app/notif_action_bg';
}

abstract class AlarmMethods {
  static const scheduleExactAlarm = 'scheduleExactAlarm';
  static const cancelAlarm = 'cancelAlarm';
  static const checkExactAlarmPermission = 'checkExactAlarmPermission';
  static const requestExactAlarmPermission = 'requestExactAlarmPermission';
}

abstract class KeystoreMethods {
  static const getOrCreateKey = 'getOrCreateKey';
}

abstract class ForegroundServiceMethods {
  static const startStatusMode = 'startStatusMode';
  static const startTimerMode = 'startTimerMode';
  static const stopService = 'stopService';
}

abstract class WidgetMethods {
  static const refreshWidgets = 'refreshWidgets';
}

abstract class LaunchIntentMethods {
  static const getLaunchIntent = 'getLaunchIntent';
}

abstract class MyketBillingMethods {
  static const init = 'init';
  static const getProductDetails = 'getProductDetails';
  static const purchase = 'purchase';
  static const restorePurchases = 'restorePurchases';
  static const dispose = 'dispose';
}

abstract class NotifActionBgMethods {
  static const dispatcherReady = 'dispatcherReady';
  static const completeRoutineDirect = 'completeRoutineDirect';
  static const updatePersistentStatus = 'updatePersistentStatus';
  static const changeZoneDirect = 'changeZoneDirect';
  static const changeEnergyDirect = 'changeEnergyDirect';
  static const handleAction = 'handleAction';
}
