abstract class CalendarClock {
  DateTime now();
  static CalendarClock system = const _SystemClock();
}

class _SystemClock implements CalendarClock {
  const _SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements CalendarClock {
  const FixedClock(this._value);

  final DateTime _value;

  @override
  DateTime now() => _value;
}
