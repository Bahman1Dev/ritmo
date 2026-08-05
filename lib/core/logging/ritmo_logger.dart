import 'package:ritmo/core/observability/ritmo_logger.dart';

export 'package:ritmo/core/observability/ritmo_logger.dart';

/// Legacy alias bridge for backwards compatibility with pre-existing RitmoLog calls.
abstract final class RitmoLog {
  static void addSink(LogSink sink) => RitmoLogger.addSink(sink);

  static void debug(String scope, String message) {
    RitmoLogger.debug('[$scope] $message');
  }

  static void info(String scope, String message) {
    RitmoLogger.info('[$scope] $message');
  }

  static void warning(String scope, String message, [Object? error, StackTrace? st]) {
    RitmoLogger.warning('[$scope] $message', error: error, stack: st);
  }

  static void error(String scope, String message, [Object? error, StackTrace? st]) {
    RitmoLogger.error('[$scope] $message', error: error, stack: st);
  }
}
