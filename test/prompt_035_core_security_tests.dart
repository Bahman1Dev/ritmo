import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models/reminder_state.dart';
import 'package:ritmo/core/utils/ritmo_date.dart';

void main() {
  group('Prompt 035 - RitmoDate & Core Infrastructure Tests', () {
    test('RitmoDate formats DateTime to YYYY-MM-DD correctly', () {
      final dt = DateTime(2026, 7, 27);
      final rDate = RitmoDate(dt);
      expect(rDate.value, equals('2026-07-27'));
      expect(rDate.toString(), equals('2026-07-27'));
    });

    test('RitmoDate parses valid and ISO string dates accurately', () {
      final parsed = RitmoDate.parse('2026-07-27T01:23:01');
      expect(parsed, isNotNull);
      expect(parsed!.value, equals('2026-07-27'));
      expect(parsed.dateTime.year, equals(2026));
      expect(parsed.dateTime.month, equals(7));
      expect(parsed.dateTime.day, equals(27));
    });

    test('RitmoDate date comparison and addition helpers work', () {
      final d1 = RitmoDate(DateTime(2026, 7, 27));
      final d2 = d1.addDays(1);
      final d3 = d1.subtractDays(1);

      expect(d2.value, equals('2026-07-28'));
      expect(d3.value, equals('2026-07-26'));
      expect(d1.isBefore(d2), isTrue);
      expect(d2.isAfter(d1), isTrue);
      expect(d1.isSameDay(RitmoDate(DateTime(2026, 7, 27))), isTrue);
    });

    test('ReminderState enum parses strings cleanly', () {
      expect(ReminderState.parse('CANCELLED'), equals(ReminderState.cancelled));
      expect(ReminderState.parse('cancelled'), equals(ReminderState.cancelled));
      expect(ReminderState.parse('ACTIVE'), equals(ReminderState.active));
      expect(ReminderState.parse('delayed'), equals(ReminderState.delayed));
      expect(ReminderState.parse('expired'), equals(ReminderState.expired));
      expect(ReminderState.parse('invalid_state'), equals(ReminderState.unknown));
    });

    test('ReminderState dbValue output is consistent lowercase', () {
      expect(ReminderState.cancelled.dbValue, equals('cancelled'));
      expect(ReminderState.expired.dbValue, equals('expired'));
      expect(ReminderState.active.dbValue, equals('active'));
    });
  });
}
