/// خواندن امن از ردیف‌های sqflite (T-0.3). هیچ‌جا مستقیم as int ننویس.
extension SafeMapRead on Map<String, Object?> {
  int? readInt(String key) {
    final v = this[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? readDouble(String key) {
    final v = this[key];
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  String? readString(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    return v.toString();
  }

  bool readBool(String key, {bool fallback = false}) {
    final v = this[key];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return fallback;
  }
}
