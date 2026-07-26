import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class OnboardingDraft {
  const OnboardingDraft({
    required this.stepIndex,
    required this.state,
    required this.savedAt,
  });

  final int stepIndex;
  final Map<String, dynamic> state;
  final int savedAt;

  Map<String, dynamic> toJson() => {
        'stepIndex': stepIndex,
        'state': state,
        'savedAt': savedAt,
      };

  static OnboardingDraft? fromJson(Map<String, dynamic> json) {
    try {
      final stepIndex = json['stepIndex'] as int? ?? 0;
      final state = Map<String, dynamic>.from(json['state'] as Map? ?? {});
      final savedAt = json['savedAt'] as int? ?? 0;
      return OnboardingDraft(stepIndex: stepIndex, state: state, savedAt: savedAt);
    } catch (e) {
      return null;
    }
  }
}

class OnboardingDraftStore {
  const OnboardingDraftStore._();

  static const String _key = 'onboarding_draft';

  static Future<void> save(OnboardingDraft draft) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final jsonStr = jsonEncode(draft.toJson());
      await db.insert(
        'app_settings',
        {
          'key': _key,
          'value': jsonStr,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[OnboardingDraftStore] Error saving draft: $e');
    }
  }

  static Future<OnboardingDraft?> load() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [_key],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final val = rows.first['value']! as String;
        final map = jsonDecode(val) as Map<String, dynamic>;
        final draft = OnboardingDraft.fromJson(map);

        if (draft != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - draft.savedAt < 7 * 24 * 3600 * 1000) {
            return draft;
          }
        }
      }
    } catch (e) {
      debugPrint('[OnboardingDraftStore] Error loading draft: $e');
    }
    return null;
  }

  static Future<void> clear() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('app_settings', where: 'key = ?', whereArgs: [_key]);
    } catch (_) {}
  }
}
