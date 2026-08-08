import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:ritmo/core/database/migration/migrations_registry.dart';
import 'package:sqflite/sqflite.dart';

import 'package:ritmo/core/logging/ritmo_logger.dart';

import 'package:ritmo/core/database/migration/migrations/migration_v66_worship_seed.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v67_worship_schema.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v68_worship_backfill.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v69_calendar_occurrence_overrides.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v70_course_skip_reason.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v71_motivation_cognitive.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v72_cleanup.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v73_study_schema.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v74_psych_layer_settings.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v75_notification_reliability.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v76_simple_mode.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v77_ai_connection.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v78_settings_profile.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v79_task_upgrade.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v80_ai_opencode_defaults.dart';

class MigrationRunner {
  static final List<Migration> _migrations = [
    MigrationV2(),
    MigrationV3(),
    MigrationV4(),
    MigrationV5(),
    MigrationV6(),
    MigrationV7(),
    MigrationV8(),
    MigrationV9(),
    MigrationV10(),
    MigrationV11(),
    MigrationV12(),
    MigrationV13(),
    MigrationV14(),
    MigrationV15(),
    MigrationV16(),
    MigrationV17(),
    MigrationV18(),
    MigrationV19(),
    MigrationV20(),
    MigrationV21(),
    MigrationV22(),
    MigrationV23(),
    MigrationV24(),
    MigrationV25(),
    MigrationV26(),
    MigrationV27(),
    MigrationV28(),
    MigrationV29(),
    MigrationV30(),
    MigrationV31(),
    MigrationV32(),
    MigrationV33(),
    MigrationV34(),
    MigrationV35(),
    MigrationV36(),
    MigrationV37(),
    MigrationV38(),
    MigrationV39(),
    MigrationV40(),
    MigrationV41(),
    MigrationV42(),
    MigrationV43(),
    MigrationV44(),
    MigrationV45(),
    MigrationV46(),
    MigrationV47(),
    MigrationV48(),
    MigrationV49(),
    MigrationV50(),
    MigrationV51(),
    MigrationV52(),
    MigrationV53(),
    MigrationV54(),
    MigrationV55(),
    MigrationV56(),
    MigrationV57(),
    MigrationV58(),
    MigrationV59(),
    MigrationV60(),
    MigrationV61(),
    MigrationV62(), // T3(p045): deduplicate routine_completions for non-interval routines
    MigrationV63(), // Fix active_timers schema alignment & legacy NOT NULL constraint compatibility
    MigrationV64(), // Prompt 046 goals schema migration M1-M4
    MigrationV65(), // Prompt 049 wellbeing daily table and performance indexes
    MigrationV66(), // Prompt 048 M1: Move seeding into migration
    MigrationV67(), // Prompt 048 M2: Additive schema for worship
    MigrationV68(), // Prompt 048 M3: Backfill completions
    MigrationV69(), // Prompt 050 M1, M2: Occurrence overrides and incremental columns
    MigrationV70CourseSkipReason(), // Prompt 056: Add skipReason column to course_sessions
    MigrationV71MotivationCognitive(), // Prompt 059: Motivation diagnosis, cognitive load & identity habit columns
    MigrationV72Cleanup(), // Prompt 055: Drop deprecated zones, zone_schedules & worship_seasons tables
    MigrationV73StudySchema(), // Prompt 056: Study module schema refactoring
    MigrationV74PsychLayerSettings(), // Prompt 060: Psychology layer settings
    MigrationV75NotificationReliability(), // Prompt 061: Notification reliability & full-screen alarm
    MigrationV76SimpleMode(), // Prompt 057: Simple Mode & tasks table
    MigrationV77AiConnection(), // Prompt 062: AI Connection mode, presets, timeout and model cleanups
    MigrationV78SettingsProfile(), // Prompt 058: Settings registry, quiet hours, PIN split, dead keys cleanup
    MigrationV79TaskUpgrade(), // Prompt 063: Task steps, importance, attachments
    MigrationV80AiOpencodeDefaults(), // OpenCode AI default configuration
  ];

  static Future<void> run(Database db, int oldVersion, int newVersion) async {
    RitmoLog.info('MigrationRunner', 'Running migrations from v$oldVersion to v$newVersion');
    for (final migration in _migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        try {
          await migration.up(db);
          RitmoLog.info('MigrationRunner', 'Successfully applied migration v${migration.version}');
        } catch (e, st) {
          RitmoLog.error('MigrationRunner', 'Failed to apply migration v${migration.version}', e, st);
          rethrow;
        }
      }
    }
  }
}
