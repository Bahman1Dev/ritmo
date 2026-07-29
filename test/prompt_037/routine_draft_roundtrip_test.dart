import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/routines/domain/routine_draft.dart';
import 'package:ritmo/features/routines/domain/routine_recurrence.dart';

void main() {
  group('RoutineDraft Roundtrip & Safety Tests', () {
    test('fromRow then toEditPatch does not alter or erase modifiable fields', () {
      final now = DateTime(2026, 7, 29, 10, 0);

      final routineRow = <String, dynamic>{
        'id': 'routine_123',
        'title': 'ورزش روزانه',
        'description': '۳۰ دقیقه کاردیو',
        'category': 'fitness',
        'customCategoryId': null,
        'notificationLevel': 'important',
        'isEssential': 1,
        'energyRule': 'offerLight',
        'priority': 2.0,
        'targetDurationMinutes': 30,
        'lightDurationMinutes': 15,
        'minimalDurationMinutes': 5,
        'dependsOnRoutineId': null,
        'zoneId': 'home_zone',
        'itemType': 'ROUTINE',
        'reminderOffsetMinutes': 10,
        'isEssentialLocked': 1,
        'progressionMode': 'LINEAR',
        'progressionCurrent': 5,
        'createdAt': 1000000,
      };

      final scheduleRow = <String, dynamic>{
        'scheduleType': 'SPECIFIC_DAYS',
        'timeOfDay': '07:30',
        'daysOfWeek': '1,3,5',
      };

      final draft = RoutineDraft.fromRow(routineRow, scheduleRow);

      expect(draft.id, equals('routine_123'));
      expect(draft.title, equals('ورزش روزانه'));
      expect(draft.category, equals('fitness'));
      expect(draft.isEssential, isTrue);
      expect(draft.timeOfDay, equals('07:30'));
      expect(draft.recurrence, isA<WeekdaysRecurrence>());

      final patch = draft.toEditPatch(now: now);
      final rData = patch['routineData'] as Map<String, dynamic>;

      // Verify rData does NOT contain unmodifiable/locked columns
      expect(rData.containsKey('id'), isFalse);
      expect(rData.containsKey('isEssentialLocked'), isFalse);
      expect(rData.containsKey('progressionMode'), isFalse);
      expect(rData.containsKey('progressionCurrent'), isFalse);
      expect(rData.containsKey('createdAt'), isFalse);

      // Verify values remain intact
      expect(rData['title'], equals('ورزش روزانه'));
      expect(rData['isEssential'], equals(1));
      expect(rData['targetDurationMinutes'], equals(30));
    });
  });
}
