import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ThemeRepository {
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  Future<void> init() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['theme_mode'],
      );

      if (settings.isNotEmpty) {
        final themeVal = settings.first['value']! as String;
        themeModeNotifier.value = _parseThemeMode(themeVal);
      }
    } catch (e) {
      debugPrint('Error initializing theme repository: $e');
    }
  }

  ThemeMode _parseThemeMode(String val) {
    if (val == 'light') return ThemeMode.light;
    if (val == 'system') return ThemeMode.system;
    return ThemeMode.dark;
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    try {
      themeModeNotifier.value = mode;

      final db = await DatabaseHelper.instance.database;
      final value = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.system
              ? 'system'
              : 'dark';

      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'app_settings',
        {'key': 'theme_mode', 'value': value, 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error updating theme mode: $e');
    }
  }
}
