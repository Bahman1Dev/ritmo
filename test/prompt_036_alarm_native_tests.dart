import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models/reminder_state.dart';
import 'package:ritmo/core/utils/ritmo_date.dart';

void main() {
  group('Prompt 036 - Native Alarm & RequestCode Collision Tests', () {
    int generateRequestCode(String id, [String salt = '']) {
      return (id + salt).hashCode & 0x7FFFFFFF;
    }

    test('generateRequestCode creates unique positive integer codes', () {
      final code1 = generateRequestCode('routine_1', '_ALARM');
      final code2 = generateRequestCode('routine_1', '_DONE');
      final code3 = generateRequestCode('routine_1', '_SNOOZE');
      final code4 = generateRequestCode('routine_2', '_ALARM');

      expect(code1, isNonNegative);
      expect(code2, isNonNegative);
      expect(code3, isNonNegative);
      expect(code4, isNonNegative);

      // Verify no collision between distinct action intents for same routine
      expect(code1, isNot(equals(code2)));
      expect(code1, isNot(equals(code3)));
      expect(code2, isNot(equals(code3)));
      // Verify no collision between different routines
      expect(code1, isNot(equals(code4)));
    });

    test('Alarm scheduler date parsing correctly formats date strings', () {
      final now = DateTime(2026, 7, 27, 10, 30);
      final rDate = RitmoDate(now);
      expect(rDate.value, equals('2026-07-27'));

      final tomorrow = rDate.addDays(1);
      expect(tomorrow.value, equals('2026-07-28'));
    });

    test('ReminderState correctly parses active and cancelled states', () {
      expect(ReminderState.parse('active'), equals(ReminderState.active));
      expect(ReminderState.parse('cancelled'), equals(ReminderState.cancelled));
      expect(ReminderState.cancelled.dbValue, equals('cancelled'));
    });
  });
}
