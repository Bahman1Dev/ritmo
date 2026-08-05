import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum LogLevel { debug, info, warning, error }

abstract class LogSink {
  void write(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? context,
  });
}

/// Redaction and privacy helper ensuring user personal data (reflection text,
/// health/cycle notes, routine titles, etc.) are redacted from production logs.
class LogRedactor {
  static final RegExp _persianTextRegex = RegExp(r'[\u0600-\u06FF]+');

  /// Redacts freeform Persian text or sensitive fields from log messages.
  static String redact(String input) {
    if (input.isEmpty) return input;
    return input.replaceAll(_persianTextRegex, '[REDACTED_TEXT]');
  }

  /// Sanitizes context map values, redacting String values that contain user text.
  static Map<String, Object?> sanitizeContext(Map<String, Object?>? context) {
    if (context == null || context.isEmpty) return {};
    final cleanMap = <String, Object?>{};
    for (final entry in context.entries) {
      final val = entry.value;
      if (val is String) {
        cleanMap[entry.key] = redact(val);
      } else {
        cleanMap[entry.key] = val;
      }
    }
    return cleanMap;
  }
}

/// Sink for printing to console in debug mode.
class ConsoleLogSink implements LogSink {
  @override
  void write(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? context,
  }) {
    if (!kDebugMode) return;
    final ctxStr = context != null && context.isNotEmpty ? ' | Context: $context' : '';
    final errStr = error != null ? ' | Error: $error' : '';
    final formatted = '[${level.name.toUpperCase()}] $message$ctxStr$errStr';
    debugPrint(formatted);
    if (stack != null) {
      debugPrint(stack.toString());
    }
  }
}

/// Circular in-memory ring buffer sink for diagnostics.
class RingBufferLogSink implements LogSink {
  RingBufferLogSink({this.capacity = 500});
  final int capacity;
  final Queue<String> _buffer = Queue<String>();

  @override
  void write(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? context,
  }) {
    final cleanMsg = LogRedactor.redact(message);
    final cleanContext = LogRedactor.sanitizeContext(context);
    final now = DateTime.now().toIso8601String();
    final ctxStr = cleanContext.isNotEmpty ? ' | $cleanContext' : '';
    final errStr = error != null ? ' | Error: ${LogRedactor.redact(error.toString())}' : '';
    final line = '$now [${level.name.toUpperCase()}] $cleanMsg$ctxStr$errStr';

    if (_buffer.length >= capacity) {
      _buffer.removeFirst();
    }
    _buffer.addLast(line);
  }

  List<String> getLogs() => _buffer.toList();
  void clear() => _buffer.clear();
}

/// Local file sink writing rotated log files to disk (max 2 MB total cap).
class LocalFileLogSink implements LogSink {
  LocalFileLogSink({this.maxSizeBytes = 2 * 1024 * 1024});
  final int maxSizeBytes;

  @override
  void write(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? context,
  }) {
    if (kIsWeb) return;
    final cleanMsg = LogRedactor.redact(message);
    final cleanContext = LogRedactor.sanitizeContext(context);
    final cleanError = error != null ? LogRedactor.redact(error.toString()) : null;

    _appendToFile(
      level: level.name.toUpperCase(),
      message: cleanMsg,
      context: cleanContext,
      errorStr: cleanError,
      stackStr: stack?.toString(),
    );
  }

  Future<void> _appendToFile({
    required String level,
    required String message,
    required Map<String, Object?> context,
    String? errorStr,
    String? stackStr,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory(p.join(dir.path, 'ritmo_logs'));
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final logFile = File(p.join(logDir.path, 'ritmo_app.log'));
      if (await logFile.exists()) {
        final length = await logFile.length();
        if (length > maxSizeBytes) {
          final backupFile = File(p.join(logDir.path, 'ritmo_app.log.old'));
          if (await backupFile.exists()) {
            await backupFile.delete();
          }
          await logFile.rename(backupFile.path);
        }
      }

      final sb = StringBuffer()
        ..write('${DateTime.now().toIso8601String()} [$level] $message');

      if (context.isNotEmpty) {
        sb.write(' | Context: $context');
      }
      if (errorStr != null && errorStr.isNotEmpty) {
        sb.write(' | Error: $errorStr');
      }
      sb.writeln();

      if (stackStr != null && stackStr.isNotEmpty) {
        sb.writeln('StackTrace:\n$stackStr');
      }

      await logFile.writeAsString(sb.toString(), mode: FileMode.append);
    } catch (e) {
      debugPrint('[LocalFileLogSink] Write failed: $e');
    }
  }
}

/// Primary Observability Logger for Ritmo application (R-3 requirement).
class RitmoLogger {
  static final List<LogSink> _sinks = [
    ConsoleLogSink(),
    RingBufferLogSink(),
    LocalFileLogSink(),
  ];

  static RingBufferLogSink get ringBuffer =>
      _sinks.whereType<RingBufferLogSink>().first;

  static void addSink(LogSink sink) => _sinks.add(sink);

  static void debug(
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? context,
  }) {
    _dispatch(LogLevel.debug, message, error: error, stack: stack, context: context);
  }

  static void info(
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? context,
  }) {
    _dispatch(LogLevel.info, message, error: error, stack: stack, context: context);
  }

  static void warning(
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? context,
  }) {
    _dispatch(LogLevel.warning, message, error: error, stack: stack, context: context);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? context,
  }) {
    _dispatch(LogLevel.error, message, error: error, stack: stack, context: context);
  }

  static void _dispatch(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? context,
  }) {
    for (final sink in _sinks) {
      try {
        sink.write(level, message, error: error, stack: stack, context: context);
      } catch (e) {
        debugPrint('[RitmoLogger] Sink write failed: $e');
      }
    }
  }
}
