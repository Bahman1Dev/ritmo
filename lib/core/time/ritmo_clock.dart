import 'package:flutter/foundation.dart';

/// Immutable value object representing a single calendar date in YYYY-MM-DD format.
@immutable
class DayKey implements Comparable<DayKey> {
  const DayKey._(this.value);

  final String value; // Format: YYYY-MM-DD

  factory DayKey.from(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return DayKey._('$year-$month-$day');
  }

  factory DayKey.parse(String input) {
    final trimmed = input.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
      throw FormatException('Invalid DayKey format: "$input". Expected YYYY-MM-DD.');
    }
    return DayKey._(trimmed);
  }

  DayKey addDays(int days) {
    final dt = toDateTime();
    final newDt = dt.add(Duration(days: days));
    return DayKey.from(newDt);
  }

  int differenceInDays(DayKey other) {
    final a = toDateTime();
    final b = other.toDateTime();
    return a.difference(b).inDays;
  }

  bool isBefore(DayKey other) => value.compareTo(other.value) < 0;
  bool isAfter(DayKey other) => value.compareTo(other.value) > 0;

  DateTime toDateTime() {
    final parts = value.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  int compareTo(DayKey other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DayKey && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Abstract clock interface for deterministic time access across engines and tests.
abstract class RitmoClock {
  DateTime now();
  DayKey today() => DayKey.from(now());
}

/// Real system clock for production environment.
class SystemClock implements RitmoClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  DayKey today() => DayKey.from(DateTime.now());
}

/// Deterministic fake clock for unit and integration testing.
class FakeClock implements RitmoClock {
  FakeClock(this._now);

  DateTime _now;

  void setCurrentTime(DateTime dt) {
    _now = dt;
  }

  void advanceBy(Duration duration) {
    _now = _now.add(duration);
  }

  @override
  DateTime now() => _now;

  @override
  DayKey today() => DayKey.from(_now);
}
