import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/worship/logic/worship_engine.dart';

void main() {
  group('Obligatory Prayers Core Engine & Data Contract', () {
    test('WorshipLogOk carries valid undo token', () {
      final ok = WorshipLogOk('wc_wp_fajr_2026-08-06');
      expect(ok.undoToken, equals('wc_wp_fajr_2026-08-06'));
    });

    test('WorshipLogBlocked carries Persian error message', () {
      final blocked = WorshipLogBlocked('SUSPENDED_BY_CYCLE', 'امروز معاف از نماز هستید.');
      expect(blocked.reasonCode, equals('SUSPENDED_BY_CYCLE'));
      expect(blocked.userMessage, contains('معاف'));
    });
  });
}
