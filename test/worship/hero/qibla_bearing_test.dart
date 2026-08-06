import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/worship/logic/qibla.dart';

void main() {
  group('Qibla Azimuth Calculation', () {
    test('calculates correct Qibla azimuth for Tehran', () {
      final tehranBearing = qiblaBearing(35.6892, 51.3890);
      expect((tehranBearing - 217.0).abs(), lessThan(3.0));
    });

    test('calculates correct Qibla azimuth for Mashhad', () {
      final mashhadBearing = qiblaBearing(36.2605, 59.6168);
      expect((mashhadBearing - 234.0).abs(), lessThan(3.0));
    });
  });
}
