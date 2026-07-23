class AIRateLimiter {

  AIRateLimiter._init();
  static final AIRateLimiter instance = AIRateLimiter._init();

  final List<DateTime> _requestTimestamps = [];
  final int _maxRequestsPerMinute = 20;

  bool isRateLimited() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    // Clear old timestamps
    _requestTimestamps.removeWhere((t) => t.isBefore(oneMinuteAgo));

    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      return true;
    }

    _requestTimestamps.add(now);
    return false;
  }

  void reset() {
    _requestTimestamps.clear();
  }
}
