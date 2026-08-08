import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/utils/persian_text.dart';

void main() {
  test('normalizeFa unifies Persian characters, removes diacritics and compresses spaces', () {
    expect(normalizeFa('تستي كارساز'), equals('تستی کارساز'));
    expect(normalizeFa('سلام\u200cدنیا'), equals('سلام دنیا'));
    expect(normalizeFa('فُوراً'), equals('فورا'));
    expect(normalizeFa('  خرید   نان  '), equals('خرید نان'));
  });
}
