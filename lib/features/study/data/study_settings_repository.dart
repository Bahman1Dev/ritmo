import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class StudySettings {
  const StudySettings({
    required this.moduleEnabled,
    required this.konkurMode,
    required this.konkurSetupDone,
    required this.dailyTargetMinutes,
    required this.focusBlockMinutes,
    required this.reviewEnabled,
    required this.showInDashboard,
  });

  final bool moduleEnabled;
  final bool konkurMode;
  final bool konkurSetupDone;
  final int dailyTargetMinutes;
  final int focusBlockMinutes;
  final bool reviewEnabled;
  final bool showInDashboard;
}

class StudySettingsRepository {
  StudySettingsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static final StudySettingsRepository instance = StudySettingsRepository();

  final DatabaseHelper _dbHelper;

  Future<StudySettings> load() async {
    final db = await _dbHelper.database;
    final rows = await db.query('app_settings', where: "key LIKE 'study_%' OR key = 'module_study_enabled'");
    final map = {for (final r in rows) r['key'] as String: r['value'] as String};

    final moduleEnabled = map['module_study_enabled'] == 'true';
    final konkurMode = map['study_konkur_mode'] == 'true';
    final konkurSetupDone = map['study_konkur_setup_done'] == 'true';
    final dailyTargetMinutes = int.tryParse(map['study_daily_target_minutes'] ?? '90') ?? 90;
    final focusBlockMinutes = int.tryParse(map['study_focus_block_minutes'] ?? '50') ?? 50;
    final reviewEnabled = map['study_review_enabled'] != 'false';
    final showInDashboard = map['study_show_in_dashboard'] != 'false';

    return StudySettings(
      moduleEnabled: moduleEnabled,
      konkurMode: konkurMode,
      konkurSetupDone: konkurSetupDone,
      dailyTargetMinutes: dailyTargetMinutes,
      focusBlockMinutes: focusBlockMinutes,
      reviewEnabled: reviewEnabled,
      showInDashboard: showInDashboard,
    );
  }

  Future<void> setKonkurMode(bool enabled) async {
    final db = await _dbHelper.database;
    await db.insert(
      'app_settings',
      {
        'key': 'study_konkur_mode',
        'value': enabled.toString(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setModuleEnabled(bool enabled) async {
    final db = await _dbHelper.database;
    await db.insert(
      'app_settings',
      {
        'key': 'module_study_enabled',
        'value': enabled.toString(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSetting(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
