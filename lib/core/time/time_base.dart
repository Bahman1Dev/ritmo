class TimeBase {
  static DateTime? _mockNow;

  /// Single time source across application domain logic
  static DateTime get now => _mockNow ?? DateTime.now();

  /// Inject mock time for reproducible testing
  static void setMock(DateTime? mock) {
    _mockNow = mock;
  }

  /// Format local YYYY-MM-DD
  static String get todayStamp => now.toIso8601String().substring(0, 10);
}
