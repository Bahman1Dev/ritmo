// lib/features/assistant/logic/day_plan_composer.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/memory/ai_memory_service.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/features/assistant/logic/day_plan_template_service.dart';
import 'package:ritmo/features/assistant/models/day_plan_models.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Result of a compose call. Can be a single-day draft, multi-day plans, or a template apply request.
class DayPlanComposeResult {

  DayPlanComposeResult({
    this.singleDraft,
    this.multiDayDrafts,
    this.applyTemplateName,
    this.applyTemplateDate,
  });
  final DayPlanDraft? singleDraft;
  final List<DayPlanDraft>? multiDayDrafts;
  final String? applyTemplateName;
  final String? applyTemplateDate;

  bool get isTemplateApply => applyTemplateName != null;
  bool get isMultiDay => multiDayDrafts != null && multiDayDrafts!.length > 1;
  bool get isSingleDay => singleDraft != null;
}

class DayPlanComposer {
  static final RegExp _jsonBlockRegex = RegExp(
    r'```(?:json)?\s*([\s\S]*?)\s*```',
    caseSensitive: false,
  );

  /// Composes a structured DayPlanDraft from user's natural language narration.
  static Future<DayPlanComposeResult?> compose({
    required String query,
    required String targetDateStr, // e.g. "2026-07-16"
    void Function(String step)? onProgress,
  }) async {
    try {
      // 1. Retrieve relevant cognitive memories to enrich context (respects privacy settings)
      onProgress?.call('🧠 در حال تحلیل حافظه شناختی و ترجیحات شما...');
      final memories = await AiMemoryService.instance.retrieve(
        domain: 'core',
        query: query,
      );
      final memoryContext = AiMemoryService.instance.buildPromptBlock(memories);

      // 2. Load template names for LLM context (only names — no content per Rule 0.5)
      onProgress?.call('🕌 در حال محاسبه اوقات شرعی و برنامه‌های موجود هفته...');
      final templates = await DayPlanTemplateService.instance.getTemplates();
      final templateNamesBlock = templates.isNotEmpty
          ? '''
### قالب‌های ذخیره‌شده کاربر (فقط نام‌ها):
${templates.map((t) => '- ${t.name}').join('\n')}

اگر کاربر از نام یکی از این قالب‌ها استفاده کرد (مثلاً «فردا روز کاریه» یا «پس‌فردا مثل روز جمعه‌ام باشه»)، به جای چیدن کامل برنامه، خروجی JSON زیر را برگردانید:
{
  "applyTemplate": {
    "templateName": "نام دقیق قالب از لیست بالا",
    "date": "YYYY-MM-DD تاریخ هدف"
  }
}
'''
          : '';

      // 3. Token Protection: build weekly agenda summaries
      final agendaSummaryContext = await _buildAgendaSummaryContext(targetDateStr);

      final systemPrompt = '''
شما یک مدیر برنامه و دستیار هوشمند ارشد به نام Ritmo هستید. وظیفه شما تبدیل روایت زبان طبیعی کاربر فارسی‌زبان درباره روزش به یک ساختار JSON خام و معتبر برای چیدن برنامه روزانه است.

تاریخ برنامه مورد نظر کاربر: $targetDateStr

شما باید اطلاعات دریافتی را تحلیل کرده و دقیقاً ساختار JSON زیر را برگردانید. هیچ متنی خارج از JSON (توضیحات، مقدمه، مؤخره) نباید ارسال شود.

### ساختار خروجی JSON مورد انتظار:

#### حالت تک‌روزه:
{
  "planDate": "$targetDateStr",
  "items": [
    {
      "title": "عنوان فعالیت به فارسی (مثلا: بیدار شدن، نماز ظهر و عصر، صبحانه، کار، ورزش)",
      "targetModule": "یکی از مقادیر روبرو: sleep | worship | routine | task | event | reminder",
      "start": {
        "kind": "clock (برای ساعت مشخص) | anchor (برای اوقات شرعی یا لنگرهای بیداری/خواب) | after_previous (به عنوان زنجیره بعد از کار قبلی)",
        "time": "HH:mm (فقط اگر kind برابر clock باشد، مثلا 05:00)",
        "anchorEvent": "یکی از مقادیر روبرو در صورت kind=anchor: FAJR | SUNRISE | DHUHR | ASR | MAGHRIB | ISHA | WAKEUP | BEDTIME",
        "offsetMin": 0,
        "bufferMin": 0
      },
      "durationMin": 45,
      "durationSource": "llm",
      "recurrence": "oneOff (برای کارهای یک‌بارمصرف) | daily (روتین روزانه) | daysOfWeek (روزهای خاص هفته)",
      "daysOfWeek": null,
      "category": "یکی از مقادیر روبرو: work | fitness | health | study | personal | worship",
      "confidence": 0.95,
      "note": "توضیحات اختیاری کوتاه یا یادداشت"
    }
  ],
  "questions": [
    {
      "id": "شناسه سوال مثل q1",
      "itemRef": 0,
      "text": "متن سوال شفاف‌سازی به فارسی برای رفع ابهام‌های پرهزینه زمان‌بندی یا تداخل",
      "quickReplies": ["پاسخ سریع ۱", "پاسخ سریع ۲"]
    }
  ],
  "suggestions": [
    {
      "text": "پیشنهاد بهبود روز مثل بهینه‌سازی خواب یا زنجیره بافر",
      "action": "نام اکشن مثلا setBedtime",
      "payload": {}
    }
  ]
}

#### حالت چندروزه (هفتگی):
اگر کاربر از الگوهای چندروزه استفاده کرد (مثلاً «شنبه تا چهارشنبه سرکارم، پنجشنبه باشگاه»)، خروجی باید آرایه‌ای از برنامه‌های روزانه باشد:
{
  "plans": [
    {"planDate": "YYYY-MM-DD", "items": [...]},
    {"planDate": "YYYY-MM-DD", "items": [...]}
  ],
  "questions": [...],
  "suggestions": [...]
}
حداکثر ۷ روز آینده. سؤال‌ها و پیشنهادها برای کل هفته مشترک هستند (حداکثر ۱ راند و ۳ سؤال).

**تمایز تکرارشونده و چندروزه:** اگر کاربر از ساختار دائمی هفته صحبت می‌کند (مثلاً «هر روز کاری سرکارم») ⇒ از recurrence=daysOfWeek استفاده کنید و فقط یک روز برنامه بدهید. اگر درباره همین هفته خاص است (مثلاً «این هفته شنبه تا چهارشنبه سرکارم») ⇒ برنامه جداگانه برای هر روز بدهید با recurrence=oneOff. اگر مشخص نیست، یک سؤال شفاف‌سازی بپرسید: «آیا این برنامه هفتگی دائمی است یا فقط برای این هفته؟»

$templateNamesBlock

$agendaSummaryContext

### قوانین بسیار مهم:
۱. برای کارهای عبادی و نمازها، حتماً نمازها را به صورت یکپارچه و مشترک قرار دهید: «نماز ظهر و عصر» با لنگر DHUHR (مدت ۲0 تا ۲۵ دقیقه) و «نماز مغرب و عشاء» با لنگر MAGHRIB (مدت ۲0 تا ۲۵ دقیقه). هرگز نماز عصر یا نماز عشا را به عنوان فعالیت مجزا و جداگانه در ساعات متفاوت برنامه نچینید، مگر این‌که کاربر صریحاً خواستار تفکیک آن‌ها باشد. برای نماز صبح از لنگر FAJR استفاده کنید.
۲. اگر کاربر پایان یک کار را صریحاً مشخص کرده بود (مثلاً «تا ۱ ظهر سرکارم»)، با محاسبه تفاضل شروع و پایان، مدت زمان (durationMin) را دقیقاً محاسبه کنید.
۳. در صورتی که ابهام بسیار بزرگ و پرهزینه‌ای وجود دارد که مانع چیدن برنامه می‌شود (مثلاً نامعلوم بودن کارهای اصلی یا تداخل شدید)، حداکثر ۳ سوال شفاف‌سازی در بخش "questions" قرار دهید. اگر ابهام کوچکی وجود دارد، خودتان بهترین تخمین را بزنید و سوالی نپرسید.
۴. پاسخ شما باید کاملاً JSON خام معتبر باشد و با براکت { شروع و با براکت } پایان یابد.

$memoryContext
''';

      final userPrompt = 'روایت کاربر:\n"$query"';

      // 4. Query AI Gateway
      onProgress?.call('✨ در حال مدل‌سازی و چیدمان هوشمند برنامه با Ritmo AI...');
      final responseContent = await AIGateway.instance.sendRawCompletion(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        responseFormatJson: true,
      );

      if (responseContent.isEmpty) {
        debugPrint('[DayPlanComposer] Raw completion returned empty response.');
        return null;
      }

      // 5. Extract JSON from potential Markdown formatting
      var cleanJson = responseContent.trim();
      final match = _jsonBlockRegex.firstMatch(cleanJson);
      if (match != null) {
        cleanJson = match.group(1)!.trim();
      }

      // 6. Parse JSON and build model
      final decoded = jsonDecode(cleanJson);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('[DayPlanComposer] Parsed JSON is not a Map structure.');
        return null;
      }

      // 6a. Check for template apply
      if (decoded.containsKey('applyTemplate')) {
        final templateInfo = decoded['applyTemplate'] as Map<String, dynamic>;
        return DayPlanComposeResult(
          applyTemplateName: templateInfo['templateName']?.toString(),
          applyTemplateDate: templateInfo['date']?.toString() ?? targetDateStr,
        );
      }

      // 6b. Check for multi-day plans
      if (decoded.containsKey('plans')) {
        final rawPlans = decoded['plans'] as List? ?? [];
        final drafts = rawPlans.map((e) => DayPlanDraft.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        // Attach shared questions/suggestions to first draft
        if (drafts.isNotEmpty) {
          final questions = (decoded['questions'] as List? ?? [])
              .map((e) => DayPlanQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          final suggestions = (decoded['suggestions'] as List? ?? [])
              .map((e) => DayPlanSuggestion.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          drafts[0] = drafts[0].copyWith(questions: questions, suggestions: suggestions);
        }
        return DayPlanComposeResult(multiDayDrafts: drafts);
      }

      // 6c. Single-day plan
      return DayPlanComposeResult(singleDraft: DayPlanDraft.fromJson(decoded));
    } catch (e, st) {
      debugPrint('[DayPlanComposer] Error composing day plan: $e\n$st');
      return null;
    }
  }

  static Future<String> _buildAgendaSummaryContext(String startDateStr) async {
    final start = DateTime.tryParse(startDateStr) ?? DateTime.now();
    final summary = StringBuffer('### خلاصه برنامه‌های موجود در هفته پیش‌رو (جهت جلوگیری از تداخل):\n');

    for (var i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final j = Jalali.fromDateTime(date);
      final dayName = _getDayName(j.weekDay);
      
      try {
        final agenda = await DayAgendaService.instance.agendaForDate(date);
        final items = agenda.items;
        if (items.isEmpty) {
          summary.writeln('- $dayName (${j.day} ${j.formatter.mN}): هیچ برنامه‌ای ثبت نشده است.');
        } else {
          final busySlots = <String>[];
          for (final item in items) {
            if (item.timeOfDay != null) {
              final startStr = item.timeOfDay!;
              final duration = item.durationMinutes ?? 30;
              final endStr = _formatTime(_parseTimeOfDay(date, startStr).add(Duration(minutes: duration)));
              busySlots.add('$startStr تا $endStr');
            }
          }
          summary.writeln('- $dayName (${j.day} ${j.formatter.mN}): ${items.length} فعالیت (بازه‌های اشغال‌شده: ${busySlots.join('، ')})');
        }
      } catch (e) {
        debugPrint('[DayPlanComposer] Failed to fetch agenda for summary: $e');
      }
    }
    return summary.toString();
  }

  static String _getDayName(int weekDay) {
    switch (weekDay) {
      case 1: return 'شنبه';
      case 2: return 'یکشنبه';
      case 3: return 'دوشنبه';
      case 4: return 'سه‌شنبه';
      case 5: return 'چهارشنبه';
      case 6: return 'پنجشنبه';
      case 7: return 'جمعه';
      default: return '';
    }
  }

  static DateTime _parseTimeOfDay(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
