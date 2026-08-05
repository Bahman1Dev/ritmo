import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:sqflite/sqflite.dart';

class SettingSchema {

  const SettingSchema({
    required this.type,
    this.min,
    this.max,
    this.allowed,
    required this.humanLabel,
  });
  final String type; // 'int' | 'enum' | 'bool'
  final int? min;
  final int? max;
  final List<String>? allowed;
  final String humanLabel;
}

const Map<String, SettingSchema> kAiSettingsAllowlist = {
  'gentleness_level': SettingSchema(
    type: 'enum',
    allowed: ['LOW', 'MEDIUM', 'HIGH'],
    humanLabel: 'میزان انعطاف‌پذیری برنامه‌ریزی',
  ),
  'daily_capacity_minutes': SettingSchema(
    type: 'int',
    min: 30,
    max: 720,
    humanLabel: 'سقف زمان برنامه‌ریزی روزانه',
  ),
  'snooze_minutes': SettingSchema(
    type: 'int',
    min: 1,
    max: 120,
    humanLabel: 'زمان تعویق یادآوری',
  ),
  'digest_mode': SettingSchema(
    type: 'bool',
    humanLabel: 'حالت تجمیع اعلان‌ها',
  ),
  'coalescing_window_minutes': SettingSchema(
    type: 'int',
    min: 1,
    max: 60,
    humanLabel: 'بازه زمانی تجمیع اعلان‌ها',
  ),
  'max_non_essential_per_hour': SettingSchema(
    type: 'int',
    min: 1,
    max: 20,
    humanLabel: 'حداکثر اعلان‌های غیرضروری در ساعت',
  ),
  'theme': SettingSchema(
    type: 'enum',
    allowed: ['dark', 'light', 'system'],
    humanLabel: 'پوسته اپلیکیشن',
  ),
  'theme_palette': SettingSchema(
    type: 'enum',
    allowed: ['jade_noir', 'copper_dusk', 'rosewood', 'olive_sand', 'graphite_champagne'],
    humanLabel: 'پالت رنگی',
  ),
  'max_defer_count': SettingSchema(
    type: 'int',
    min: 0,
    max: 10,
    humanLabel: 'حداکثر دفعات تعویق روتین',
  ),
  'streak_threshold': SettingSchema(
    type: 'int',
    min: 1,
    max: 30,
    humanLabel: 'آستانه تداوم روتین‌ها',
  ),
  'energy_validity_minutes': SettingSchema(
    type: 'int',
    min: 1,
    max: 1440,
    humanLabel: 'مدت اعتبار سنجش انرژی',
  ),
  'default_energy_level': SettingSchema(
    type: 'enum',
    allowed: ['LOW', 'MEDIUM', 'HIGH'],
    humanLabel: 'سطح پیش‌فرض انرژی روزانه',
  ),
  'max_grace_per_week': SettingSchema(
    type: 'int',
    min: 0,
    max: 7,
    humanLabel: 'حداکثر روزهای فرجه در هفته',
  ),
  'max_grace_per_month': SettingSchema(
    type: 'int',
    min: 0,
    max: 30,
    humanLabel: 'حداکثر روزهای فرجه در ماه',
  ),
  'prayer_calculation_method': SettingSchema(
    type: 'enum',
    allowed: [
      'UniversityOfTehran',
      'IslamicSocietyOfNorthAmerica',
      'MuslimWorldLeague',
      'EgyptianGeneralAuthorityOfSurvey',
      'UmmAlQuraUniversity',
      'Karachi',
      'Kuwait'
    ],
    humanLabel: 'فرمول محاسباتی اوقات شرعی',
  ),
  'ihtiyat_minutes': SettingSchema(
    type: 'int',
    min: 0,
    max: 60,
    humanLabel: 'زمان احتیاط اوقات شرعی',
  ),
};

// Security denylist & pattern checks
bool isSettingChangeAllowed(String key) {
  if (!kAiSettingsAllowlist.containsKey(key)) return false;
  
  // Explicit forbidden keys check
  final denylist = [
    'app_lock_mode',
    'app_lock_timeout_seconds',
    'db_encryption_key',
    'user_gender',
    'assistant_cloud_consent',
    'module_cycle_enabled',
    'module_medicine_enabled',
    'module_medical_enabled',
  ];
  if (denylist.contains(key)) return false;
  if (key.startsWith('cycle_')) return false;
  if (key.contains('medical') || key.contains('medicine') || key.contains('health') || key.contains('drug') || key.contains('dose')) return false;

  return true;
}

String? validateAndNormalize(String key, String value) {
  if (!isSettingChangeAllowed(key)) return null;
  final schema = kAiSettingsAllowlist[key]!;

  if (schema.type == 'bool') {
    final lower = value.toLowerCase().trim();
    if (lower == 'true' || lower == '1') return 'true';
    if (lower == 'false' || lower == '0') return 'false';
    return null;
  }

  if (schema.type == 'int') {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return null;
    if (schema.min != null && parsed < schema.min!) return null;
    if (schema.max != null && parsed > schema.max!) return null;
    return parsed.toString();
  }

  if (schema.type == 'enum') {
    final cleaned = value.trim();
    if (schema.allowed != null && schema.allowed!.contains(cleaned)) {
      return cleaned;
    }
    // Try case-insensitive matching
    try {
      final matched = schema.allowed?.firstWhere(
        (e) => e.toLowerCase() == cleaned.toLowerCase(),
      );
      if (matched != null && matched.isNotEmpty) {
        return matched;
      }
    } catch (_) {}
    return null;
  }

  return null;
}

Future<bool> applySettingChange(String key, String value) async {
  if (!isSettingChangeAllowed(key)) return false;
  final normalized = validateAndNormalize(key, value);
  if (normalized == null) return false;

  try {
    final db = await DatabaseHelper.instance.database;
    
    // Get old value
    final existing = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    String? oldValue;
    if (existing.isNotEmpty) {
      oldValue = existing.first['value'] as String?;
    }

    // Update app_settings
    await db.insert(
      'app_settings',
      {'key': key, 'value': normalized},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save to audit log
    final auditId = '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}';
    await db.insert(
      'assistant_audit_log',
      {
        'id': auditId,
        'actionType': 'updateSetting',
        'targetKey': key,
        'oldValue': oldValue,
        'newValue': normalized,
        'appliedAt': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // Fire event bus notification
    RitmoEventBus().fire(
      RitmoEvent(
        type: 'settings_changed',
        timestamp: DateTime.now(),
        payload: {'key': key, 'value': normalized},
      ),
    );

    return true;
  } catch (e) {
    debugPrint('Error applying setting change: $e');
    return false;
  }
}
