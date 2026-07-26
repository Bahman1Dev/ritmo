import 'dart:collection';
import 'package:flutter/foundation.dart';

abstract class LogSink {
  void log(String level, String scope, String message, [Object? error, StackTrace? st]);
}

class ConsoleSink implements LogSink {
  @override
  void log(String level, String scope, String message, [Object? error, StackTrace? st]) {
    final formatted = '[$scope] $level: $message${error != null ? " ($error)" : ""}';
    debugPrint(formatted);
    if (st != null && kDebugMode) {
      debugPrint(st.toString());
    }
  }
}

class RingBufferSink implements LogSink {
  RingBufferSink({this.capacity = 500});
  final int capacity;
  final Queue<String> _buffer = Queue<String>();

  @override
  void log(String level, String scope, String message, [Object? error, StackTrace? st]) {
    final now = DateTime.now().toIso8601String();
    final line = '$now [$scope] $level: $message${error != null ? " ($error)" : ""}';
    if (_buffer.length >= capacity) {
      _buffer.removeFirst();
    }
    _buffer.addLast(line);
  }

  List<String> getLogs() => _buffer.toList();
  void clear() => _buffer.clear();
}

abstract final class RitmoLog {
  static final List<LogSink> _sinks = [
    ConsoleSink(),
    RingBufferSink(),
  ];

  static final RingBufferSink ringBuffer = _sinks.whereType<RingBufferSink>().first;

  static void addSink(LogSink sink) => _sinks.add(sink);

  static void debug(String scope, String message) {
    if (kDebugMode) {
      for (final sink in _sinks) {
        sink.log('DEBUG', scope, message);
      }
    }
  }

  static void info(String scope, String message) {
    for (final sink in _sinks) {
      sink.log('INFO', scope, message);
    }
  }

  static void warning(String scope, String message, [Object? error, StackTrace? st]) {
    for (final sink in _sinks) {
      sink.log('WARNING', scope, message, error, st);
    }
  }

  static void error(String scope, String message, [Object? error, StackTrace? st]) {
    for (final sink in _sinks) {
      sink.log('ERROR', scope, message, error, st);
    }
  }
}
