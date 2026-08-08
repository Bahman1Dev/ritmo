import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/routines/presentation/quick_add_parser.dart';

void main() {
  test('Shared text passes through QuickAddParser and extracts title and dates', () {
    const sharedText = 'جلسه با تیم فردا ساعت ۱۵:۳۰';
    final result = QuickAddParser.parse(sharedText);

    expect(result.daysOffset, equals(1));
    expect(result.timeOfDay?.hour, equals(15));
    expect(result.timeOfDay?.minute, equals(30));
    expect(result.title, contains('جلسه با تیم'));
  });
}
