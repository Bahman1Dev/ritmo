enum ReminderState {
  unknown('unknown'),
  active('active'),
  delayed('delayed'),
  opened('opened'),
  expired('expired'),
  cancelled('cancelled');

  const ReminderState(this.dbValue);
  final String dbValue;

  static ReminderState parse(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final state in ReminderState.values) {
      if (state.dbValue == clean) {
        return state;
      }
    }
    return ReminderState.unknown;
  }

  @override
  String toString() => dbValue;
}
