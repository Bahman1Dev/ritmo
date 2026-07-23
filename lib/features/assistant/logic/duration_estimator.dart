// lib/features/assistant/logic/duration_estimator.dart

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/ai/memory/ai_memory_service.dart';
import 'package:ritmo/core/ai/memory/memory_models.dart';
import 'package:ritmo/core/database/database_helper.dart';

class DurationEstimator {
  // Iranian daily defaults (in minutes)
  static const Map<String, int> _iranianDefaults = {
    'نماز': 15,
    'دعا': 15,
    'قرآن': 15,
    'صبحانه': 20,
    'ناهار': 30,
    'شام': 30,
    'بانک': 45,
    'دوش': 20,
    'حمام': 20,
    'رفت': 30,
    'برگشت': 30,
    'ترافیک': 30,
    'خرید': 40,
    'سرکار': 240,
    'کار': 240,
    'مطالعه': 60,
    'درس': 60,
    'کتاب': 60,
    'ورزش': 60,
    'باشگاه': 60,
    'پیاده': 30,
    'استراحت': 30,
    'نظافت': 45,
    'تمیز': 45,
    'آشپزی': 60,
    'پزشک': 60,
    'دکتر': 60,
  };

  /// Estimates the duration of a DayPlanItemDraft in minutes, returning both the duration and its source.
  static Future<({int duration, String source})> estimate({
    required String title,
    required String category,
    required String userQuery,
    int? llmDuration,
    List<MemoryEntry>? preloadedMemories,
  }) async {
    // 1. Explicit user statement in query (e.g. "تا ۱ اونجام" -> handled by LLM duration)
    // We detect if LLM successfully parsed a duration and the query contains explicit time constraints.
    if (llmDuration != null && llmDuration > 0) {
      final explicitKeywords = ['دقیقه', 'ساعت', 'تا ساعت', 'تا ساعت', 'مدت', 'طول بکشد'];
      final hasExplicitMention = explicitKeywords.any((kw) => userQuery.contains(kw));
      if (hasExplicitMention) {
        return (duration: llmDuration, source: 'user');
      }
    }

    // 2. User history: Median completed duration for routines/tasks with similar title/category
    try {
      final historyDuration = await _getMedianDurationFromHistory(title, category);
      if (historyDuration != null) {
        return (duration: historyDuration, source: 'history');
      }
    } catch (e) {
      debugPrint('[DurationEstimator] History fetch error: $e');
    }

    // 3. Cognitive memory (facts like "رفت‌وآمد تا سرکار ۳۰ دقیقه است")
    try {
      final memories = preloadedMemories ?? await AiMemoryService.instance.retrieve(domain: 'core', query: title);
      final memoryDuration = _getDurationFromMemories(title, memories);
      if (memoryDuration != null) {
        return (duration: memoryDuration, source: 'memory');
      }
    } catch (e) {
      debugPrint('[DurationEstimator] Cognitive memory check error: $e');
    }

    // 4. Iranian Defaults Table
    final defaultDuration = _getIranianDefaultDuration(title);
    if (defaultDuration != null) {
      return (duration: defaultDuration, source: 'default');
    }

    // 5. LLM Fallback (if present)
    if (llmDuration != null && llmDuration > 0) {
      return (duration: llmDuration, source: 'llm');
    }

    // Standard fallback (30 minutes)
    return (duration: 30, source: 'llm');
  }

  /// Calculates the median completion duration from sqlite history.
  static Future<int?> _getMedianDurationFromHistory(String title, String category) async {
    final db = await DatabaseHelper.instance.database;

    // Retrieve all completion times for routines with matching titles or same category
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT rc.durationMinutes 
      FROM routine_completions rc
      JOIN routines r ON rc.routineId = r.id
      WHERE (r.title LIKE ? OR r.category = ?) AND rc.durationMinutes IS NOT NULL AND rc.durationMinutes > 0
    ''', ['%$title%', category]);

    if (results.isEmpty) return null;

    final durations = results.map((r) => r['durationMinutes'] as int).toList()..sort();
    final middle = durations.length ~/ 2;
    if (durations.length % 2 == 1) {
      return durations[middle];
    } else {
      return ((durations[middle - 1] + durations[middle]) / 2).round();
    }
  }

  /// Extracts duration from cognitive memory statement (e.g. "۳۰ دقیقه" or "۲ ساعت").
  static int? _getDurationFromMemories(String title, List<MemoryEntry> memories) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return null;

    final numberPattern = RegExp(r'(\d+)\s*(دقیقه|ساعت)');
    for (final memory in memories) {
      if (memory.content.contains(cleanTitle)) {
        final match = numberPattern.firstMatch(memory.content);
        if (match != null) {
          final val = int.tryParse(match.group(1)!) ?? 0;
          final unit = match.group(2)!;
          if (unit == 'ساعت') {
            return val * 60;
          } else {
            return val;
          }
        }
      }
    }
    return null;
  }

  /// Checks the Iranian default durations table based on title matches.
  static int? _getIranianDefaultDuration(String title) {
    final cleanTitle = title.trim();
    for (final entry in _iranianDefaults.entries) {
      if (cleanTitle.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Public accessor for Iranian default durations (for testing).
  static int? getIranianDefaultMinutes(String title) => _getIranianDefaultDuration(title);
}
