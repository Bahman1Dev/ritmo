import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/ai_response_processor.dart';
import 'package:ritmo/core/ai/ai_shared_rules.dart';
import 'package:ritmo/core/ai/memory/assistant_memory_binding.dart';
import 'package:ritmo/core/database/database_helper.dart';

class CoursesAiHelper {
  static Future<Map<String, dynamic>?> getCourseSuggestion(String inputText) async {
    var activeCoursesCount = 0;
    var activeRoutinesCount = 0;
    var isKonkurActive = false;

    try {
      final db = await DatabaseHelper.instance.database;
      final coursesRes = await db.query('courses', where: 'status = ?', whereArgs: ['ACTIVE']);
      activeCoursesCount = coursesRes.length;

      final routinesRes = await db.query('routines', where: 'isArchived = 0');
      activeRoutinesCount = routinesRes.length;

      final settingsList = await db.query('app_settings', where: 'key = ?', whereArgs: ['module_konkur_enabled']);
      if (settingsList.isNotEmpty) {
        isKonkurActive = settingsList.first['value'] == 'true';
      }
    } catch (e) {
      debugPrint('Error getting user context in CoursesAiHelper: $e');
    }

    try {
      const systemPrompt = '''
You are the Ritmo Courses AI Assistant. Your task is to split the user's study topic or book/syllabus into a structured learning course.

RULES:
${AnalyticsPromptRules.core}

You MUST output ONLY a valid JSON object matching the schema below. Do not include markdown code fences or explanation text outside the JSON.
Farsi texts and Persian values are preferred for title, unitLabel, provider, and explanation.

VALID SAMPLE JSON OUTPUT:
{
  "title": "مقدمه‌ای بر هوش مصنوعی",
  "courseType": "VIDEO",
  "unitLabel": "جلسه",
  "totalSessions": 12,
  "sessionDurationMinutes": 45,
  "weeklyTargetSessions": 3,
  "preferredDays": [6, 1, 3],
  "provider": "مکتب‌خونه",
  "explanation": "با توجه به اهمیت موضوع و مدت زمان هر ویدیو، پیشنهاد می‌شود این دوره را به صورت ۳ جلسه در هفته مطالعه کنید."
}

EXPLANATION OF FIELDS:
- title: Farsi name of the course or book.
- courseType: Must be exactly one of: "VIDEO", "BOOK", "SKILL", "CUSTOM".
- unitLabel: Must be exactly one of: "جلسه", "فصل", "تمرین", "واحد".
- totalSessions: Total estimated number of chapters/sessions/practices (Integer).
- sessionDurationMinutes: Estimated duration of each session in minutes (Integer).
- weeklyTargetSessions: Target sessions per week (Integer, typically 1 to 7).
- preferredDays: List of preferred weekdays as Integers: Saturday=6, Sunday=0, Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5.
- provider: Platform/publisher/author name in Farsi.
- explanation: A short, encouraging Farsi explanation of why this structuring was chosen.
''';

      final userPrompt = '''
User Input Course Topic/Book: "$inputText"

User Context:
- Active courses count: $activeCoursesCount
- Active routines count: $activeRoutinesCount
- Is Konkur Mode Active?: ${isKonkurActive ? "Yes" : "No"}

Please adapt your suggested total sessions, weekly target sessions, and preferred days to be realistic given the user's context (e.g. if they have many active courses or routines, suggest a lighter weekly target).
''';

      final memorySuffix = await AssistantMemoryBinding.getSystemPromptSuffix(
        domain: 'courses',
        query: inputText,
      );

      final messagesToSent = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt + memorySuffix},
        {'role': 'user', 'content': userPrompt}
      ];

      final aiContent = await AIGateway.instance.sendCustomChat(messages: messagesToSent);

      await AssistantMemoryBinding.processResponse(
        sessionId: 'courses_session',
        domain: 'courses',
        userText: inputText,
        rawResponse: aiContent,
      );

      await AssistantMemoryBinding.triggerConsolidation(
        sessionId: 'courses_session',
        domain: 'courses',
      );
      final parsed = AIResponseProcessor.processRawJson(aiContent);

      if (parsed != null) {
        // Validation & normalization with safe fallbacks
        final title = parsed['title']?.toString() ?? 'دوره جدید';
        
        var courseType = (parsed['courseType']?.toString() ?? 'CUSTOM').toUpperCase();
        if (!['VIDEO', 'BOOK', 'SKILL', 'CUSTOM'].contains(courseType)) {
          courseType = 'CUSTOM';
        }

        var unitLabel = parsed['unitLabel']?.toString() ?? 'جلسه';
        if (!['جلسه', 'فصل', 'تمرین', 'واحد'].contains(unitLabel)) {
          unitLabel = 'جلسه';
        }

        var totalSessions = int.tryParse(parsed['totalSessions']?.toString() ?? '') ?? 10;
        if (totalSessions < 1 || totalSessions > 100) {
          totalSessions = 10;
        }

        var sessionDurationMinutes = int.tryParse(parsed['sessionDurationMinutes']?.toString() ?? '') ?? 45;
        if (sessionDurationMinutes < 5 || sessionDurationMinutes > 300) {
          sessionDurationMinutes = 45;
        }

        var weeklyTargetSessions = int.tryParse(parsed['weeklyTargetSessions']?.toString() ?? '') ?? 3;
        if (weeklyTargetSessions < 1 || weeklyTargetSessions > 21) {
          weeklyTargetSessions = 3;
        }

        final preferredDaysRaw = parsed['preferredDays'];
        var preferredDays = <int>[6, 1, 3]; // Default Sat, Mon, Wed
        if (preferredDaysRaw is List) {
          final parsedDays = preferredDaysRaw
              .map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .where((d) => d >= 0 && d <= 6)
              .toList();
          if (parsedDays.isNotEmpty) {
            preferredDays = parsedDays;
          }
        }

        final provider = parsed['provider']?.toString() ?? 'سفارشی';
        final explanation = parsed['explanation']?.toString() ?? '';

        return {
          'title': title,
          'courseType': courseType,
          'unitLabel': unitLabel,
          'totalSessions': totalSessions,
          'sessionDurationMinutes': sessionDurationMinutes,
          'weeklyTargetSessions': weeklyTargetSessions,
          'preferredDays': preferredDays,
          'provider': provider,
          'explanation': explanation,
        };
      }
    } catch (e) {
      debugPrint('CoursesAiHelper Exception: $e');
    }
    return null;
  }
}
