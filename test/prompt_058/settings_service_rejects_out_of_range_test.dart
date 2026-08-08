import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/settings/settings_service.dart';

void main() {
  test('SettingsService rejects out-of-range integer values and preserves previous state', () async {
    final s = SettingsService.instance;
    final initial = s.get<int>('coalescing_window_minutes');

    // Setting 999 is outside allowed min: 1, max: 60
    final result = await s.set('coalescing_window_minutes', 999);
    expect(result, isFalse);

    // Verify value was NOT modified
    final current = s.get<int>('coalescing_window_minutes');
    expect(current, equals(initial));
  });
}
