import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/palettes/copper_dusk.dart';
import 'package:ritmo/core/theme/palettes/jade_noir.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_module_colors.dart';

void main() {
  group('Theme lerp tests', () {
    test('RitmoColors.lerp gives exact start at t=0 and end at t=1', () {
      final start = kJadeNoirLight;
      final end = kCopperDuskLight;

      final lerp0 = start.lerp(end, 0.0);
      final lerp1 = start.lerp(end, 1.0);

      expect(lerp0.primary, equals(start.primary));
      expect(lerp0.background, equals(start.background));

      expect(lerp1.primary, equals(end.primary));
      expect(lerp1.background, equals(end.background));
    });

    test('RitmoModuleColors.lerp gives exact start at t=0 and end at t=1', () {
      final start = kJadeNoirModulesLight;
      final end = kCopperDuskModulesLight;

      final lerp0 = RitmoModuleColors.lerp(start, end, 0.0);
      final lerp1 = RitmoModuleColors.lerp(start, end, 1.0);

      expect(lerp0.planner, equals(start.planner));
      expect(lerp1.planner, equals(end.planner));
    });
  });
}
