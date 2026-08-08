import 'dart:convert';
import 'package:ritmo/core/ai/ai_fallback_engine.dart';
import 'package:ritmo/features/assistant/logic/settings_action_guard.dart';

class AIResponseProcessor {
  static final List<String> _medicalKeywords = [
    'dose', 'dosage', 'medicine', 'medication', 'medical', 'prescription', 'health',
    'دارو', 'دوز', 'قرص', 'آمپول', 'نسخه', 'پزشکی', 'پزشک', 'سلامت', 'بیماری', 'درمان'
  ];

  static Map<String, dynamic> process(String rawOutput) {
    var sanitized = rawOutput.trim();

    // Rule 0.5: Medical concepts check
    for (final kw in _medicalKeywords) {
      if (sanitized.toLowerCase().contains(kw)) {
        return AIFallbackEngine.getFallbackResponse();
      }
    }

    // Try parsing JSON block (extracting from markdown code fences if needed)
    try {
      if (sanitized.contains('```json')) {
        final startIdx = sanitized.indexOf('```json') + 7;
        final endIdx = sanitized.lastIndexOf('```');
        if (endIdx > startIdx) {
          sanitized = sanitized.substring(startIdx, endIdx).trim();
        }
      } else if (sanitized.contains('```')) {
        final startIdx = sanitized.indexOf('```') + 3;
        final endIdx = sanitized.lastIndexOf('```');
        if (endIdx > startIdx) {
          sanitized = sanitized.substring(startIdx, endIdx).trim();
        }
      }

      final parsed = jsonDecode(sanitized);
      if (parsed is Map) {
        final response = parsed['response']?.toString() ?? '';
        final type = parsed['type']?.toString() ?? 'assistant';
        final evidenceLevel = parsed['evidence_level']?.toString() ?? 'LOW';
        final usedDataCategories = parsed['used_data_categories'] is List
            ? List<String>.from((parsed['used_data_categories'] as List).map((e) => e.toString()))
            : <String>[];
        final queryScope = parsed['query_scope']?.toString() ?? 'narrow';

        // Additional domain verification
        final allowedCategories = [
          'routines', 'goals', 'energy', 'sleep', 'planning',
          'worship', 'konkur', 'courses', 'reflection', 'daily_rhythm', 'settings'
        ];
        final filteredCategories = usedDataCategories.where((c) => allowedCategories.contains(c.toLowerCase())).toList();

        return {
          'response': response,
          'type': type,
          'evidence_level': evidenceLevel,
          'used_data_categories': filteredCategories,
          'query_scope': queryScope
         };
      }
    } catch (e) {
      // JSON Parsing failed
    }

    return AIFallbackEngine.getFallbackResponse();
  }

  static Map<String, dynamic> processCopilot(String rawOutput) {
    var sanitized = rawOutput.trim();

    // Rule 0.5 Check
    for (final kw in _medicalKeywords) {
      if (sanitized.toLowerCase().contains(kw)) {
        return {
          'reply': 'برای حفظ ایمنی، اطلاعات پزشکی و یادآورهای دارویی از طریق دستیار مدیریت نمی‌شوند.',
          'actions': []
        };
      }
    }

    try {
      if (sanitized.contains('```json')) {
        final startIdx = sanitized.indexOf('```json') + 7;
        final endIdx = sanitized.lastIndexOf('```');
        if (endIdx > startIdx) {
          sanitized = sanitized.substring(startIdx, endIdx).trim();
        }
      } else if (sanitized.contains('```')) {
        final startIdx = sanitized.indexOf('```') + 3;
        final endIdx = sanitized.lastIndexOf('```');
        if (endIdx > startIdx) {
          sanitized = sanitized.substring(startIdx, endIdx).trim();
        }
      }

      final parsed = jsonDecode(sanitized);
      if (parsed is Map) {
        final reply = parsed['reply']?.toString() ?? parsed['response']?.toString() ?? '';
        final actionsList = parsed['actions'] is List ? parsed['actions'] as List : [];
        
        final filteredActions = [];
        final allowedTypes = [
          'createRoutine', 'createGoal', 'logSleep', 'logEnergyMood', 'addKonkurItem', 'createCourse', 'openPage',
          'updateSetting', 'completeRoutine', 'skipRoutine', 'editRoutine', 'deleteRoutine', 'editGoal', 'completeGoalStep',
          'createWorshipItem', 'logReflection', 'rescheduleReminder'
        ];
        
        for (final act in actionsList) {
          if (act is Map) {
            final type = act['type']?.toString();
            if (type != null && allowedTypes.contains(type)) {
              final payload = act['payload'] is Map ? act['payload'] as Map<String, dynamic> : <String, dynamic>{};

              // 1. Settings change check
              if (type == 'updateSetting') {
                final key = payload['key']?.toString() ?? '';
                final value = payload['value']?.toString() ?? '';
                if (!isSettingChangeAllowed(key) || validateAndNormalize(key, value) == null) {
                  continue; // drop disallowed or invalid setting changes
                }
              }

              // 2. Medical category/keyword filter
              if (payload['category']?.toString().toLowerCase() == 'medical') {
                continue; // drop medical routines
              }
              var hasMedicalKeyword = false;
              final payloadStr = jsonEncode(payload).toLowerCase();
              for (final kw in _medicalKeywords) {
                if (payloadStr.contains(kw)) {
                  hasMedicalKeyword = true;
                  break;
                }
              }
              if (hasMedicalKeyword) {
                continue; // drop payloads containing medical keywords
              }

              filteredActions.add({
                'type': type,
                'title': act['title']?.toString() ?? '',
                'payload': payload,
                'targetRoute': act['targetRoute']?.toString(),
              });
            }
          }
        }

        return {
          'reply': reply,
          'actions': filteredActions,
        };
      }
    } catch (e) {
      // JSON parsing failed
    }

    return {
      'reply': 'متاسفم، در پردازش پاسخ همیار هوشمند مشکلی پیش آمد.',
      'actions': []
    };
  }

  static Map<String, dynamic>? processRawJson(String rawOutput) {
    var sanitized = rawOutput.trim();
    try {
      if (sanitized.contains('```json')) {
        final startIdx = sanitized.indexOf('```json') + 7;
        final endIdx = sanitized.lastIndexOf('```');
        if (endIdx > startIdx) {
          sanitized = sanitized.substring(startIdx, endIdx).trim();
        }
      } else if (sanitized.contains('```')) {
        final startIdx = sanitized.indexOf('```') + 3;
        final endIdx = sanitized.lastIndexOf('```');
        if (endIdx > startIdx) {
          sanitized = sanitized.substring(startIdx, endIdx).trim();
        }
      }

      final parsed = jsonDecode(sanitized);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
    } catch (e) {
      // JSON parsing failed
    }
    return null;
  }
}
