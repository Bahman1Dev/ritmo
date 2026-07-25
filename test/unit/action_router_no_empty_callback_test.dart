import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('action_router.dart source should contain no empty callbacks', () {
    final file = File('lib/core/domain/agenda/action_router.dart');
    expect(file.existsSync(), isTrue);

    final content = file.readAsStringSync();
    expect(content.contains('async {}'), isFalse, reason: 'Found empty async callback');
    expect(content.contains('onSnooze: () {}'), isFalse, reason: 'Found empty onSnooze callback');
    expect(content.contains('onEdit: () {}'), isFalse, reason: 'Found empty onEdit callback');
    expect(content.contains('onViewDetails: () {}'), isFalse, reason: 'Found empty onViewDetails callback');
  });
}
