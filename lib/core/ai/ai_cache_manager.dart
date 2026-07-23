class AICacheEntry {

  AICacheEntry(this.response, this.expireTime);
  final Map<String, dynamic> response;
  final DateTime expireTime;

  bool get isExpired => DateTime.now().isAfter(expireTime);
}

class AICacheManager {

  AICacheManager._init();
  static final AICacheManager instance = AICacheManager._init();
  final Map<String, AICacheEntry> _cacheStore = {};

  String _buildKey(String query, Map<String, dynamic> context) {
    return '${query.trim()}_${context.hashCode}';
  }

  Map<String, dynamic>? get(String query, Map<String, dynamic> context) {
    final key = _buildKey(query, context);
    final entry = _cacheStore[key];
    if (entry != null) {
      if (!entry.isExpired) {
        return entry.response;
      } else {
        _cacheStore.remove(key); // Remove expired entry
      }
    }
    return null;
  }

  void set(String query, Map<String, dynamic> context, Map<String, dynamic> response, {int ttlMinutes = 10}) {
    final key = _buildKey(query, context);
    final expireTime = DateTime.now().add(Duration(minutes: ttlMinutes));
    _cacheStore[key] = AICacheEntry(response, expireTime);
  }

  void clear() {
    _cacheStore.clear();
  }
}
