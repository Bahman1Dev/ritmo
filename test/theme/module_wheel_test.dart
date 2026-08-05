import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/palettes/jade_noir.dart';

void main() {
  group('RitmoModuleColors', () {
    test('bySlot(0..7) returns 8 distinct colors and handles overflow safely', () {
      final modules = kJadeNoirModulesLight;
      final set = <int>{};

      for (int i = 0; i < 8; i++) {
        final color = modules.bySlot(i);
        set.add(color.toARGB32());
      }
      expect(set.length, equals(8));

      expect(() => modules.bySlot(8), returnsNormally);
      expect(modules.bySlot(8), equals(modules.bySlot(0)));
      expect(modules.bySlot(15), equals(modules.bySlot(7)));
    });

    test('byModuleId returns expected slots and falls back to insights for unknown', () {
      final modules = kJadeNoirModulesLight;

      expect(modules.byModuleId('planner'), equals(modules.planner));
      expect(modules.byModuleId('calendar'), equals(modules.planner));
      expect(modules.byModuleId('routines'), equals(modules.routines));
      expect(modules.byModuleId('goals'), equals(modules.goals));
      expect(modules.byModuleId('study'), equals(modules.study));
      expect(modules.byModuleId('worship'), equals(modules.worship));
      expect(modules.byModuleId('health'), equals(modules.health));
      expect(modules.byModuleId('sports'), equals(modules.sports));
      expect(modules.byModuleId('insights'), equals(modules.insights));

      expect(modules.byModuleId('unknown_module_xyz'), equals(modules.insights));
    });
  });
}
