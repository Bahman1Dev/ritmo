import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/supplementary_sports/data/seed/ss_exercise_animation_map.dart';

void main() {
  test('Verify all animation map assets exist on disk', () {
    for (final entry in ssExerciseAnimationMap.entries) {
      final code = entry.key;
      final animId = entry.value;
      final file = File('assets/animations/custom/$animId.json');
      expect(file.existsSync(), isTrue, reason: 'Exercise $code maps to $animId which does not exist!');
    }
    // ignore: avoid_print
    print('Verified ${ssExerciseAnimationMap.length} explicit animation mappings successfully!');
  });
}
