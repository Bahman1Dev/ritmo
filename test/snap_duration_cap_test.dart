import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';

void main() {
  group('TimelineSnappingHelper Duration Cap Tests', () {
    test('snapDurationMinutes cannot exceed DurationBounds.maxMinutes (480)', () {
      final snapped = TimelineSnappingHelper.snapDurationMinutes(
        1200, // Attempt 20 hours
        startMinutes: 60,
      );

      expect(snapped, DurationBounds.maxMinutes);
    });
  });
}
