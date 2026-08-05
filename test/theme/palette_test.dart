import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';

void main() {
  group('RitmoPalette.parseId', () {
    test('parses valid palette identifiers correctly', () {
      expect(RitmoPalette.parseId('jade_noir'), equals(RitmoPaletteId.jadeNoir));
      expect(RitmoPalette.parseId('copper_dusk'), equals(RitmoPaletteId.copperDusk));
      expect(RitmoPalette.parseId('rosewood'), equals(RitmoPaletteId.rosewood));
      expect(RitmoPalette.parseId('olive_sand'), equals(RitmoPaletteId.oliveSand));
      expect(RitmoPalette.parseId('graphite_champagne'), equals(RitmoPaletteId.graphiteChampagne));
    });

    test('falls back to jadeNoir for null, empty, or invalid input without throwing', () {
      expect(RitmoPalette.parseId(null), equals(RitmoPaletteId.jadeNoir));
      expect(RitmoPalette.parseId(''), equals(RitmoPaletteId.jadeNoir));
      expect(RitmoPalette.parseId('   '), equals(RitmoPaletteId.jadeNoir));
      expect(RitmoPalette.parseId('invalid_palette_name'), equals(RitmoPaletteId.jadeNoir));
    });
  });
}
