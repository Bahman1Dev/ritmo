class CacheEntry<T> {
  CacheEntry({
    required this.data,
    required this.fingerprint,
    required this.computedAt,
    required this.dayStamp,
    required this.ttl,
  });

  T? data; // In invalidated state set to null (E-07)
  final String fingerprint;
  final DateTime computedAt;
  final String dayStamp; // Local 'YYYY-MM-DD'
  final Duration ttl;
  bool manuallyInvalidated = false;

  /// Data exists and is fresh
  bool isFresh(String todayKey, DateTime now) =>
      data != null &&
      !manuallyInvalidated &&
      dayStamp == todayKey &&
      now.difference(computedAt) < ttl;

  /// Data exists but may be stale
  bool get hasStale => data != null;
}
