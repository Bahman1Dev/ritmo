import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/supplementary_sports/data/seed/ss_exercise_animation_map.dart';
import 'package:ritmo/features/supplementary_sports/data/seed/ss_exercise_farsi_names.dart';

import '../migration_test.dart'; // Reuse MockDatabase

void main() {
  group('Supplementary Sports DB Seed & Migration Tests', () {
    test('Migration V40 creates tables and alters ss_exercise', () async {
      final mockDb = MockDatabase();

      // Trigger migration upgrade from 39 to 40
      await DatabaseHelper.instance.onUpgrade(mockDb, 39, 40);

      final sql = mockDb.executedStatements.join('\n').toLowerCase();

      // Check altered columns
      expect(sql, contains('alter table ss_exercise add column code'));
      expect(sql, contains('alter table ss_exercise add column cat_cardio'));
      expect(sql, contains('alter table ss_exercise add column cat_plyometric'));
      expect(sql, contains('alter table ss_exercise add column cat_lower_body'));
      expect(sql, contains('alter table ss_exercise add column cat_upper_body'));
      expect(sql, contains('alter table ss_exercise add column cat_shoulder_and_back'));
      expect(sql, contains('alter table ss_exercise add column cat_core'));
      expect(sql, contains('alter table ss_exercise add column cat_stretching'));
      expect(sql, contains('alter table ss_exercise add column cat_yoga'));
      expect(sql, contains('alter table ss_exercise add column cat_balance'));
      expect(sql, contains('alter table ss_exercise add column cat_warmup'));
      expect(sql, contains('alter table ss_exercise add column skill_max'));
      expect(sql, contains('alter table ss_exercise add column sexyness_m'));
      expect(sql, contains('alter table ss_exercise add column sexyness_f'));
      expect(sql, contains('alter table ss_exercise add column animation_asset'));

      // Check index creation
      expect(sql, contains('create unique index if not exists idx_ss_exercise_code'));

      // Check new tables creation
      expect(sql, contains('create table if not exists ss_workout_set'));
      expect(sql, contains('create table if not exists ss_exercise_set_suitability'));
    });

    test('Persian Names seed has exactly 268 records and no placeholders', () {
      expect(SsExerciseFarsiNames.names.length, equals(268));
      
      for (final entry in SsExerciseFarsiNames.names.entries) {
        final _ = entry.key; // key access triggers validation
        final info = entry.value;
        
        expect(info['title_fa'], isNotNull);
        expect(info['title_fa']!.isNotEmpty, isTrue);
        
        expect(info['desc_fa'], isNotNull);
        expect(info['desc_fa']!.isNotEmpty, isTrue);
        
        // Ensure no untranslated fallback placeholders
        expect(info['title_fa'], isNot(contains('TODO')));
        expect(info['desc_fa'], isNot(contains('TODO')));
      }
    });

    test('Animation Map handles known mappings', () {
      expect(ssExerciseAnimationMap['bo009_squats'], equals('hw_40'));
      expect(ssExerciseAnimationMap['bo002_mountain_climbers'], equals('hw_12'));
    });
  });
}
