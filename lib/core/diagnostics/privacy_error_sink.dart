import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Privacy-first rotating local error sink with mandatory redaction layer.
class PrivacyErrorSink {
  PrivacyErrorSink._();
  static final PrivacyErrorSink instance = PrivacyErrorSink._();

  File? _logFile;
  final List<String> _inMemoryBuffer = [];

  static const _sensitivePatterns = [
    r'title:\s*[^,\n\}]+',
    r'description:\s*[^,\n\}]+',
    r'note:\s*[^,\n\}]+',
    r'medication:\s*[^,\n\}]+',
    r'reflection:\s*[^,\n\}]+',
    r'cycle:\s*[^,\n\}]+',
    r'gratitude:\s*[^,\n\}]+',
    r'learnings:\s*[^,\n\}]+',
  ];

  /// Mandatory redaction layer that strips sensitive user health & personal fields.
  static String redact(String message) {
    var clean = message;
    for (final pattern in _sensitivePatterns) {
      clean = clean.replaceAll(RegExp(pattern, caseSensitive: false), '[REDACTED]');
    }
    return clean;
  }

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/ritmo_error_logs.txt');
      if (await _logFile!.exists()) {
        final len = await _logFile!.length();
        // Rotate if log exceeds 2MB
        if (len > 2 * 1024 * 1024) {
          await _logFile!.delete();
        }
      }
    } catch (_) {}
  }

  Future<void> logError(String source, String errorMsg, [Object? error, StackTrace? stack]) async {
    final redactedMsg = redact(errorMsg);
    final redactedStack = stack != null ? redact(stack.toString()) : '';

    final logEntry = '${DateTime.now().toIso8601String()} [$source] $redactedMsg\n$redactedStack\n---\n';

    _inMemoryBuffer.add(logEntry);
    if (_inMemoryBuffer.length > 50) {
      _inMemoryBuffer.removeAt(0);
    }

    try {
      if (_logFile != null) {
        await _logFile!.writeAsString(logEntry, mode: FileMode.append, flush: true);
      }
    } catch (_) {}
  }
}
