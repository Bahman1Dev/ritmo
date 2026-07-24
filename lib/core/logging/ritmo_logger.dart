import 'package:flutter/foundation.dart';

abstract final class RitmoLog {
  static void debug(String scope, String message) {
    if (kDebugMode) {
      debugPrint('[$scope] DEBUG: $message');
    }
  }

  static void info(String scope, String message) {
    if (kDebugMode) {
      debugPrint('[$scope] INFO: $message');
    }
  }

  static void warning(String scope, String message, [Object? error, StackTrace? st]) {
    debugPrint('[$scope] WARNING: $message${error != null ? " ($error)" : ""}');
    if (st != null && kDebugMode) {
      debugPrint(st.toString());
    }
  }

  static void error(String scope, String message, [Object? error, StackTrace? st]) {
    debugPrint('[$scope] ERROR: $message${error != null ? " ($error)" : ""}');
    if (st != null && kDebugMode) {
      debugPrint(st.toString());
    }
  }
}
