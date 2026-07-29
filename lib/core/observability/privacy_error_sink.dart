import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';

/// Privacy-focused error logging sink that redacts sensitive health, cycle, worship,
/// and personal user data before writing crash reports to offline storage.
class PrivacyErrorSink implements LogSink {
  PrivacyErrorSink._init();
  static final PrivacyErrorSink instance = PrivacyErrorSink._init();

  static final RegExp _persianTextRegex = RegExp(r'[\u0600-\u06FF]+');
  static final RegExp _healthDataRegex = RegExp(
    r'(sys|dia|systolic|diastolic|pulse|blood_sugar|glucose|weight|height|cycle_start|pregnancy|menstruation|medication)\s*:\s*[^\s,]+',
    caseSensitive: false,
  );

  /// Redacts sensitive personal or health information from a log message string.
  static String sanitize(String input) {
    if (input.isEmpty) return input;
    var result = input.replaceAll(_healthDataRegex, r'$1: [REDACTED_HEALTH_DATA]');
    // Mask raw long Persian user inputs or titles inside logs
    if (result.length > 50 && _persianTextRegex.hasMatch(result)) {
      result = result.replaceAll(_persianTextRegex, '[REDACTED_TEXT]');
    }
    return result;
  }

  @override
  void log(String level, String scope, String message, [Object? error, StackTrace? st]) {
    final cleanMessage = sanitize(message);
    final cleanError = error != null ? sanitize(error.toString()) : null;
    
    // Log to RitmoLog RingBuffer
    if (level == 'ERROR') {
      _writeCrashReport(scope, cleanMessage, cleanError, st);
    }
  }

  Future<void> logError(String scope, String message, [Object? error, StackTrace? st]) async {
    log('ERROR', scope, message, error, st);
  }

  static Future<void> _writeCrashReport(String scope, String message, String? errorStr, StackTrace? st) async {
    if (kIsWeb) return;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final crashDir = Directory(join(docsDir.path, 'crash_reports'));
      if (!await crashDir.exists()) {
        await crashDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(join(crashDir.path, 'crash_$timestamp.log'));
      final content = StringBuffer()
        ..writeln('Timestamp: ${DateTime.now().toIso8601String()}')
        ..writeln('Scope: $scope')
        ..writeln('Message: $message');
      if (errorStr != null) {
        content.writeln('Error: $errorStr');
      }
      if (st != null) {
        content.writeln('StackTrace:\n$st');
      }
      await file.writeAsString(content.toString());
    } catch (_) {}
  }
}
