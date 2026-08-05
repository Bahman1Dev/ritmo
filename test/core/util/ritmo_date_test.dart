import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/util/ritmo_date.dart';

void main() {
  test('lastNDayKeys length matches request', () {
    final now = DateTime(2026, 1, 3);
    final keys = RitmoDate.lastNDayKeys(now, 3);
    expect(keys.length, 3);
    expect(keys, ['2026-01-01', '2026-01-02', '2026-01-03']);
  });
}
