import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV82SportsPrescription extends Migration {
  @override
  int get version => 82;

  @override
  Future<void> up(Database db) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. Create ss_session_prescription table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ss_session_prescription (
        id TEXT PRIMARY KEY,
        dateIso TEXT NOT NULL,
        cycleWeek INTEGER NOT NULL,
        slotType TEXT NOT NULL,
        focusCodes TEXT NOT NULL,
        targetMinutes INTEGER NOT NULL,
        intensityTier TEXT NOT NULL,
        targetRpe INTEGER,
        headlineFa TEXT NOT NULL,
        coachNoteFa TEXT,
        source TEXT NOT NULL,
        isLocked INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'PLANNED',
        movedToDateIso TEXT,
        legacyPlanId TEXT,
        workoutLogId TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      );
    ''');
    
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_ss_prescription_date ON ss_session_prescription(dateIso);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ss_prescription_status ON ss_session_prescription(status, dateIso);',
    );

    // 2. Create ss_muscle_group table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ss_muscle_group (
        code TEXT PRIMARY KEY,
        titleFa TEXT NOT NULL,
        region TEXT NOT NULL,
        emoji TEXT,
        sortOrder INTEGER NOT NULL
      );
    ''');

    // Seed 12 muscle group rows
    final muscleGroups = [
      ['CHEST', 'سینه', 'UPPER', '🫁', 1],
      ['SHOULDER', 'سرشانه', 'UPPER', '🎯', 2],
      ['BICEPS', 'جلوبازو', 'UPPER', '💪', 3],
      ['TRICEPS', 'پشت‌بازو', 'UPPER', '🦾', 4],
      ['BACK', 'زیربغل و پشت', 'UPPER', '🪽', 5],
      ['CORE', 'شکم و مرکز', 'CORE', '🎽', 6],
      ['QUADS_GLUTES', 'ران و باسن', 'LOWER', '🦵', 7],
      ['HAMSTRINGS', 'پشت ران', 'LOWER', '🦿', 8],
      ['CALVES', 'ساق پا', 'LOWER', '🎯', 9], // using target emoji as fallback for ساق پا
      ['CARDIO', 'هوازی', 'CARDIO', '🫀', 10],
      ['MOBILITY', 'تحرک و کشش', 'MOBILITY', '🧘', 11],
      ['FULL_BODY', 'کل بدن', 'FULL', '🔥', 12],
    ];

    for (final m in muscleGroups) {
      await db.insert(
        'ss_muscle_group',
        {
          'code': m[0],
          'titleFa': m[1],
          'region': m[2],
          'emoji': m[3],
          'sortOrder': m[4],
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // 3. Alter ss_user_profile safely
    for (final col in [
      "ALTER TABLE ss_user_profile ADD COLUMN programStartDate TEXT",
      "ALTER TABLE ss_user_profile ADD COLUMN trainingDays TEXT",
      "ALTER TABLE ss_user_profile ADD COLUMN splitPattern TEXT NOT NULL DEFAULT 'AUTO'",
      "ALTER TABLE ss_user_profile ADD COLUMN deloadEveryNWeeks INTEGER NOT NULL DEFAULT 4",
      "ALTER TABLE ss_user_profile ADD COLUMN defaultIntensity TEXT NOT NULL DEFAULT 'MODERATE'",
      "ALTER TABLE ss_user_profile ADD COLUMN usesExternalApp INTEGER NOT NULL DEFAULT 0",
    ]) {
      try {
        await db.execute(col);
      } catch (_) {}
    }

    // 4. Default settings keys
    final defaults = {
      'sports_detail_mode': 'false',
      'sports_reminder_enabled': 'false',
      'sports_reminder_time': '18:00',
      'sports_reminder_offset_minutes': '30',
      'sports_weekly_met_target': '500',
      'sports_show_readiness': 'true',
      'sports_autoregen_enabled': 'false',
      'sports_units_metric': 'true',
      'sports_tts_enabled': 'true',
      'sports_audio_cues_enabled': 'true',
      'sports_default_rest_seconds': '90',
    };

    for (final e in defaults.entries) {
      await db.insert(
        'app_settings',
        {'key': e.key, 'value': e.value, 'updatedAt': nowMs},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // 5. Data Migration (T-A5)
    // 5.1 Initialize programStartDate
    final profiles = await db.query('ss_user_profile', limit: 1);
    if (profiles.isNotEmpty) {
      final p = profiles.first;
      String? startDate = p['programStartDate'] as String?;
      if (startDate == null || startDate.isEmpty) {
        final dateStr = DateTime.now().toIso8601String().substring(0, 10);
        await db.update(
          'ss_user_profile',
          {'programStartDate': dateStr},
          where: "id = ?",
          whereArgs: [p['id']],
        );
        startDate = dateStr;
      }

      // 5.2 Initialize trainingDays
      String? trDays = p['trainingDays'] as String?;
      if (trDays == null || trDays.isEmpty) {
        final daysCount = (p['daysPerWeek'] as int?) ?? 3;
        final list = <int>[];
        if (daysCount == 1) list.addAll([6]); // Sat
        else if (daysCount == 2) list.addAll([6, 2]); // Sat, Tue
        else if (daysCount == 3) list.addAll([6, 1, 3]); // Sat, Mon, Wed
        else if (daysCount == 4) list.addAll([6, 1, 3, 4]); // Sat, Mon, Wed, Thu
        else if (daysCount == 5) list.addAll([6, 1, 2, 3, 4]);
        else if (daysCount == 6) list.addAll([6, 7, 1, 2, 3, 4]);
        else list.addAll([6, 7, 1, 2, 3, 4, 5]);

        await db.update(
          'ss_user_profile',
          {'trainingDays': '[${list.join(',')}]'},
          where: "id = ?",
          whereArgs: [p['id']],
        );
      }
    }

    // 5.3 Convert ss_workout_plan to ss_session_prescription
    try {
      final plans = await db.query('ss_workout_plan');
      for (final plan in plans) {
        final id = plan['id'] as String;
        final week = (plan['week'] as int?) ?? 1;
        final dayOfWeek = (plan['dayOfWeek'] as int?) ?? 1; // 1 = شنبه (ss mapping)
        final category = plan['category'] as String? ?? 'STRENGTH';
        final estimatedMins = (plan['estimatedMinutes'] as int?) ?? 45;

        // Convert ss dayOfWeek to Ritmo dayOfWeek
        // Sat = 1 in ss -> Sat = 6 in Ritmo -> date offset = 0
        // Sun = 2 in ss -> Sun = 7 in Ritmo -> date offset = 1
        // Mon = 3 in ss -> Mon = 1 in Ritmo -> date offset = 2
        // Tue = 4 in ss -> Tue = 2 in Ritmo -> date offset = 3
        // Wed = 5 in ss -> Wed = 3 in Ritmo -> date offset = 4
        // Thu = 6 in ss -> Thu = 4 in Ritmo -> date offset = 5
        // Fri = 7 in ss -> Fri = 5 in Ritmo -> date offset = 6
        final int offset;
        switch (dayOfWeek) {
          case 1: offset = 0; break;
          case 2: offset = 1; break;
          case 3: offset = 2; break;
          case 4: offset = 3; break;
          case 5: offset = 4; break;
          case 6: offset = 5; break;
          case 7: offset = 6; break;
          default: offset = 0;
        }

        // Calculate dateIso
        final startDateStr = profiles.isNotEmpty ? (profiles.first['programStartDate'] as String? ?? '') : '';
        DateTime start = DateTime.now();
        if (startDateStr.isNotEmpty) {
          try {
            start = DateTime.parse(startDateStr);
          } catch (_) {}
        }
        final planDate = start.add(Duration(days: (week - 1) * 7 + offset));
        final dateIso = planDate.toIso8601String().substring(0, 10);

        // Map category and title
        final String slotType = (category == 'REST' || category == 'ACTIVE_REST') ? category : 'STRENGTH';
        final String headline = slotType == 'REST' ? 'روز استراحت' : '$estimatedMins دقیقه تمرین قدرتی';

        // Check if there is already a prescription for this date
        final exist = await db.query('ss_session_prescription', where: 'dateIso = ?', whereArgs: [dateIso]);
        if (exist.isEmpty) {
          await db.insert(
            'ss_session_prescription',
            {
              'id': 'pres_${id}_$nowMs',
              'dateIso': dateIso,
              'cycleWeek': week,
              'slotType': slotType,
              'focusCodes': '[]',
              'targetMinutes': estimatedMins,
              'intensityTier': 'MODERATE',
              'headlineFa': headline,
              'source': 'GENERATED',
              'isLocked': 0,
              'status': 'PLANNED',
              'legacyPlanId': id,
              'createdAt': nowMs,
              'updatedAt': nowMs,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> down(Database db) async {}
}
