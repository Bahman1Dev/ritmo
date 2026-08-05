import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/util/ritmo_number.dart';

void main() {
  test('percent uses persian glyphs', () {
    expect(RitmoNumber.faPercent(62), '۶۲٪');
  });
}
