import 'package:flutter/foundation.dart';

@immutable
class RitmoDate {
  RitmoDate(DateTime dt)
      : dateTime = DateTime(dt.year, dt.month, dt.day),
        value =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  final DateTime dateTime;
  final String value; // Format: 'YYYY-MM-DD'

  static RitmoDate now() => RitmoDate(DateTime.now());

  static RitmoDate? parse(String raw) {
    try {
      final clean = raw.trim();
      final parts = clean.split('-');
      if (parts.length >= 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final dayStr = parts[2].split('T')[0].split(' ')[0];
        final day = int.parse(dayStr);
        return RitmoDate(DateTime(year, month, day));
      }
    } catch (_) {}
    return null;
  }

  RitmoDate addDays(int days) => RitmoDate(dateTime.add(Duration(days: days)));
  RitmoDate subtractDays(int days) =>
      RitmoDate(dateTime.subtract(Duration(days: days)));

  bool isSameDay(RitmoDate other) => value == other.value;
  bool isBefore(RitmoDate other) => dateTime.isBefore(other.dateTime);
  bool isAfter(RitmoDate other) => dateTime.isAfter(other.dateTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RitmoDate &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
