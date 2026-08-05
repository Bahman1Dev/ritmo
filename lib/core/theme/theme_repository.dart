// ریپازیتوری تنظیمات تم — ذخیره در SQLite و مدیریت state دینامیک
// جایگزین ذخیره‌سازی تک‌کلیدی قبلی

import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';
import 'package:ritmo/core/theme/theme_preferences.dart';
import 'package:sqflite/sqflite.dart';

class ThemeRepository {
  final ValueNotifier<ThemePreferences> preferencesNotifier =
      ValueNotifier<ThemePreferences>(ThemePreferences.defaults);

  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  Future<void> init() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query(
        'app_settings',
        where: 'key IN (?, ?, ?, ?)',
        whereArgs: [
          'theme_mode',
          'theme_palette',
          'theme_reduce_transparency',
          'theme_true_black',
        ],
      );

      ThemeMode mode = ThemePreferences.defaults.mode;
      RitmoPaletteId paletteId = ThemePreferences.defaults.paletteId;
      bool reduceTransparency = ThemePreferences.defaults.reduceTransparency;
      bool trueBlack = ThemePreferences.defaults.trueBlack;

      for (final row in settings) {
        final key = row['key'] as String?;
        final val = row['value'] as String?;
        if (key == null || val == null) continue;

        switch (key) {
          case 'theme_mode':
            mode = _parseThemeMode(val);
            break;
          case 'theme_palette':
            paletteId = RitmoPalette.parseId(val);
            break;
          case 'theme_reduce_transparency':
            reduceTransparency = val == '1' || val == 'true';
            break;
          case 'theme_true_black':
            trueBlack = val == '1' || val == 'true';
            break;
        }
      }

      final prefs = ThemePreferences(
        mode: mode,
        paletteId: paletteId,
        reduceTransparency: reduceTransparency,
        trueBlack: trueBlack,
      );

      preferencesNotifier.value = prefs;
      themeModeNotifier.value = mode;
    } catch (e) {
      debugPrint('[THEME_WARN] Error initializing ThemeRepository: $e');
    }
  }

  ThemeMode _parseThemeMode(String val) {
    if (val == 'light') return ThemeMode.light;
    if (val == 'system') return ThemeMode.system;
    if (val == 'dark') return ThemeMode.dark;
    debugPrint('[THEME_WARN] Unknown theme mode "$val". Falling back to system.');
    return ThemeMode.system;
  }

  String _serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<bool> updateThemeMode(ThemeMode mode) async {
    final current = preferencesNotifier.value;
    final updated = current.copyWith(mode: mode);
    return _saveAndNotify(updated, 'theme_mode', _serializeThemeMode(mode));
  }

  Future<bool> updatePalette(RitmoPaletteId paletteId) async {
    final current = preferencesNotifier.value;
    final updated = current.copyWith(paletteId: paletteId);
    return _saveAndNotify(updated, 'theme_palette', RitmoPalette.serializeId(paletteId));
  }

  Future<bool> updateReduceTransparency(bool reduceTransparency) async {
    final current = preferencesNotifier.value;
    final updated = current.copyWith(reduceTransparency: reduceTransparency);
    return _saveAndNotify(
      updated,
      'theme_reduce_transparency',
      reduceTransparency ? '1' : '0',
    );
  }

  Future<bool> updateTrueBlack(bool trueBlack) async {
    final current = preferencesNotifier.value;
    final updated = current.copyWith(trueBlack: trueBlack);
    return _saveAndNotify(updated, 'theme_true_black', trueBlack ? '1' : '0');
  }

  Future<bool> resetAppearance() async {
    const defaults = ThemePreferences.defaults;
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final batch = db.batch();

      batch.insert(
        'app_settings',
        {'key': 'theme_mode', 'value': _serializeThemeMode(defaults.mode), 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        'app_settings',
        {'key': 'theme_palette', 'value': RitmoPalette.serializeId(defaults.paletteId), 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        'app_settings',
        {'key': 'theme_reduce_transparency', 'value': '0', 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        'app_settings',
        {'key': 'theme_true_black', 'value': '0', 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await batch.commit(noResult: true);
      preferencesNotifier.value = defaults;
      themeModeNotifier.value = defaults.mode;
      return true;
    } catch (e) {
      debugPrint('[THEME_WARN] Error resetting appearance: $e');
      return false;
    }
  }

  Future<bool> _saveAndNotify(
    ThemePreferences updated,
    String key,
    String value,
  ) async {
    preferencesNotifier.value = updated;
    themeModeNotifier.value = updated.mode;

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        'app_settings',
        {'key': key, 'value': value, 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return true;
    } catch (e) {
      debugPrint('[THEME_WARN] Error updating setting $key: $e');
      return false;
    }
  }
}
