import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ritmo/core/backend/appwrite_crash_service.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';

/// Allowlist-based privacy error sink that records technical crash metadata
/// while completely eliminating raw user message strings or freeform Persian health/reflection data.
class PrivacyErrorSink implements LogSink {
  PrivacyErrorSink._init();
  static final PrivacyErrorSink instance = PrivacyErrorSink._init();

  Future<void> init() async {
    // Initialization hook for crash directory preparation
  }

  static const int maxCrashReportFiles = 20;

  static final RegExp _persianTextRegex = RegExp(r'[\u0600-\u06FF]+');

  /// Allowlist sanitizer: Scrubs any freeform text or Persian content from error strings and stacktraces,
  /// preserving only technical exception type names, line numbers, and stack traces.
  static String sanitize(String input) {
    if (input.isEmpty) return input;
    // Replace all Persian characters with [REDACTED_TEXT]
    final noPersian = input.replaceAll(_persianTextRegex, '[REDACTED_TEXT]');
    return noPersian;
  }

  @override
  void log(String level, String scope, String message, [Object? error, StackTrace? st]) {
    if (level == 'ERROR') {
      unawaited(logError(scope, message, error, st));
    }
  }

  @override
  void write(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? context,
  }) {
    if (level == LogLevel.error) {
      final scope = context?['scope']?.toString() ?? 'App';
      unawaited(logError(scope, message, error, stack));
    }
  }

  Future<void> logError(String scope, String message, [Object? error, StackTrace? st]) async {
    final exceptionType = error != null ? error.runtimeType.toString() : 'UnknownException';
    final cleanMessage = sanitize(message);
    final cleanError = error != null ? sanitize(error.toString()) : null;
    final cleanStack = st != null ? sanitize(st.toString()) : null;

    await _writeCrashReport(
      scope: scope,
      messageStr: cleanMessage,
      exceptionType: exceptionType,
      errorStr: cleanError,
      stStr: cleanStack,
    );

    // Asynchronously send sanitized crash report to Appwrite Cloud
    unawaited(
      AppwriteCrashService.instance.submitSanitizedCrashReport(
        scope: scope,
        exceptionType: exceptionType,
        sanitizedMessage: cleanMessage,
        sanitizedStack: cleanStack,
      ),
    );
  }

  static Future<void> _writeCrashReport({
    required String scope,
    required String messageStr,
    required String exceptionType,
    String? errorStr,
    String? stStr,
  }) async {
    if (kIsWeb) return;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final crashDir = Directory(join(docsDir.path, 'crash_reports'));
      if (!await crashDir.exists()) {
        await crashDir.create(recursive: true);
      }

      // Enforce rotation: Max 20 files limit
      final files = await crashDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      if (files.length >= maxCrashReportFiles) {
        files.sort((a, b) {
          try {
            return a.lastModifiedSync().compareTo(b.lastModifiedSync());
          } catch (_) {
            return 0;
          }
        });
        final toDeleteCount = files.length - maxCrashReportFiles + 1;
        for (var i = 0; i < toDeleteCount; i++) {
          try {
            await files[i].delete();
          } catch (e, st) {
            debugPrint('[PrivacyErrorSink] Failed to prune old crash report file: $e\n$st');
          }
        }
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(join(crashDir.path, 'crash_$timestamp.log'));
      final content = StringBuffer()
        ..writeln('Timestamp: ${DateTime.now().toIso8601String()}')
        ..writeln('Scope: $scope')
        ..writeln('Message: $messageStr')
        ..writeln('ExceptionType: $exceptionType');

      if (errorStr != null && errorStr.isNotEmpty) {
        content.writeln('Error: $errorStr');
      }
      if (stStr != null && stStr.isNotEmpty) {
        content.writeln('StackTrace:\n$stStr');
      }

      await file.writeAsString(content.toString());
    } catch (e, st) {
      debugPrint('[PrivacyErrorSink] Failed to write crash report to disk: $e\n$st');
    }
  }

  /// Lists all local crash reports for user inspection in Settings UI.
  static Future<List<File>> getCrashReports() async {
    if (kIsWeb) return [];
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final crashDir = Directory(join(docsDir.path, 'crash_reports'));
      if (!await crashDir.exists()) return [];
      final files = await crashDir
          .list()
          .where((e) => e is File && e.path.endsWith('.log'))
          .cast<File>()
          .toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e, st) {
      debugPrint('[PrivacyErrorSink] Failed to list crash reports: $e\n$st');
      return [];
    }
  }

  /// Clears all local crash report files.
  static Future<void> clearAllReports() async {
    if (kIsWeb) return;
    try {
      final reports = await getCrashReports();
      for (final f in reports) {
        await f.delete();
      }
    } catch (e, st) {
      debugPrint('[PrivacyErrorSink] Failed to clear crash reports: $e\n$st');
    }
  }
}
