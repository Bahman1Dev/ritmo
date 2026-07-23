import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class LocaleRepository {
  final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(const Locale('fa', 'IR'));

  Future<void> init() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['locale'],
      );

      if (settings.isNotEmpty) {
        final localeVal = settings.first['value']! as String;
        if (localeVal.startsWith('fa')) {
          localeNotifier.value = const Locale('fa', 'IR');
        } else if (localeVal.startsWith('en')) {
          localeNotifier.value = const Locale('en', 'US');
        } else {
          localeNotifier.value = Locale(localeVal);
        }
      }
    } catch (e) {
      debugPrint('Error initializing locale repository: $e');
    }
  }

  Future<void> updateLocale(Locale locale) async {
    try {
      localeNotifier.value = locale;

      final db = await DatabaseHelper.instance.database;
      final value = locale.languageCode;

      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'app_settings',
        {'key': 'locale', 'value': value, 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error updating locale: $e');
    }
  }
}
