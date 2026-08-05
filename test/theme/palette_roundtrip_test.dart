import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';

void main() {
  group('RitmoPalette roundtrip serialization', () {
    test('parseId(serializeId(id)) == id for all 5 palettes', () {
      for (final id in RitmoPaletteId.values) {
        final serialized = RitmoPalette.serializeId(id);
        final parsed = RitmoPalette.parseId(serialized);
        expect(parsed, equals(id));
      }
    });
  });
}
