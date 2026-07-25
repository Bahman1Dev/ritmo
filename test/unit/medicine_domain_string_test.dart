import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';

void main() {
  test('MedicationTake completion request holds valid properties and AgendaDomain medicine string', () {
    const req = MedicationTake(
      medicationId: 'med_001',
      dateStr: '2026-07-26',
      doseTime: '08:00',
    );

    expect(req.medicationId, equals('med_001'));
    expect(req.dateStr, equals('2026-07-26'));
    expect(req.doseTime, equals('08:00'));

    expect(AgendaDomain.medicine.name, equals('medicine'));
  });
}
