import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';

class IdentityGate {
  IdentityGate._();

  /// Asks for user gender if not set and not previously asked.
  /// Used by Cycle module and Sports module.
  static Future<bool> ensureGender(BuildContext context, {required String reasonFa}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final genderRow = await db.query('app_settings', where: "key = 'user_gender'", limit: 1);
      final askedRow = await db.query('app_settings', where: "key = 'identity_gender_asked'", limit: 1);

      final currentGender = genderRow.isNotEmpty ? (genderRow.first['value'] as String?) : null;
      final alreadyAsked = askedRow.isNotEmpty && askedRow.first['value'] == 'true';

      if (currentGender != null && currentGender != 'OTHER' && currentGender.isNotEmpty) {
        return true;
      }
      if (alreadyAsked) return false;

      if (!context.mounted) return false;

      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعیین جنسیت', style: TextStyle(fontFamily: 'Vazirmatn')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reasonFa, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                const SizedBox(height: 16),
                const Text('جنسیت شما:', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'SKIPPED'),
                child: const Text('رد کردن', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'MALE'),
                child: const Text('آقا', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, 'FEMALE'),
                child: const Text('خانم', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        ),
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await db.execute('''
        INSERT INTO app_settings (key, value, updatedAt)
        VALUES ('identity_gender_asked', 'true', $nowMs)
        ON CONFLICT(key) DO UPDATE SET value = 'true', updatedAt = $nowMs;
      ''');

      if (result == 'FEMALE' || result == 'MALE') {
        await db.execute('''
          INSERT INTO app_settings (key, value, updatedAt)
          VALUES ('user_gender', '$result', $nowMs)
          ON CONFLICT(key) DO UPDATE SET value = '$result', updatedAt = $nowMs;
        ''');
        return true;
      }
    } catch (e) {
      debugPrint('IdentityGate.ensureGender error: $e');
    }
    return false;
  }

  /// Asks for user age if not set and not previously asked.
  /// Used by Konkur/Study module.
  static Future<bool> ensureAge(BuildContext context, {required String reasonFa}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final ageRow = await db.query('app_settings', where: "key = 'user_age'", limit: 1);
      final askedRow = await db.query('app_settings', where: "key = 'identity_age_asked'", limit: 1);

      final currentAge = ageRow.isNotEmpty ? (ageRow.first['value'] as String?) : null;
      final alreadyAsked = askedRow.isNotEmpty && askedRow.first['value'] == 'true';

      if (currentAge != null && currentAge.isNotEmpty) {
        return true;
      }
      if (alreadyAsked) return false;

      if (!context.mounted) return false;

      int selectedAge = 25;
      final result = await showDialog<int>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDlgState) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تعیین سن', style: TextStyle(fontFamily: 'Vazirmatn')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reasonFa, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                  const SizedBox(height: 16),
                  Text('سن شما: $selectedAge سال', style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  Slider(
                    value: selectedAge.toDouble(),
                    min: 10,
                    max: 90,
                    divisions: 80,
                    label: '$selectedAge',
                    onChanged: (v) => setDlgState(() => selectedAge = v.toInt()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('رد کردن', style: TextStyle(fontFamily: 'Vazirmatn')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selectedAge),
                  child: const Text('تأیید', style: TextStyle(fontFamily: 'Vazirmatn')),
                ),
              ],
            ),
          ),
        ),
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await db.execute('''
        INSERT INTO app_settings (key, value, updatedAt)
        VALUES ('identity_age_asked', 'true', $nowMs)
        ON CONFLICT(key) DO UPDATE SET value = 'true', updatedAt = $nowMs;
      ''');

      if (result != null) {
        await db.execute('''
          INSERT INTO app_settings (key, value, updatedAt)
          VALUES ('user_age', '$result', $nowMs)
          ON CONFLICT(key) DO UPDATE SET value = '$result', updatedAt = $nowMs;
        ''');
        return true;
      }
    } catch (e) {
      debugPrint('IdentityGate.ensureAge error: $e');
    }
    return false;
  }
}
