import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/ai/chat/chat_repository.dart';
import 'package:ritmo/core/ai/memory/ai_memory_service.dart';
import 'package:ritmo/core/ai/memory/memory_models.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class MemoryConsolidator {
  /// Consolidate conversation session into long-term memories (implicit learning)
  static Future<void> consolidateSession(String sessionId, String domain) async {
    try {
      // 1. Safety checks: system enabled, implicit enabled
      if (!await AiMemoryService.instance.isMemoryEnabled() ||
          !await AiMemoryService.instance.isImplicitEnabled()) {
        return;
      }

      final db = await DatabaseHelper.instance.database;

      // 2. Idempotency check: verify if session is already consolidated
      final checkKey = 'memory_consolidated_$sessionId';
      final consolidatedQuery = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [checkKey],
      );
      if (consolidatedQuery.isNotEmpty && consolidatedQuery.first['value'].toString() == 'true') {
        return;
      }

      // 3. Load messages and verify minimum user messages count (>= 4 user turns)
      final messages = await ChatRepository.instance.getMessages(sessionId);
      final userMessages = messages.where((m) => m.role == ChatRole.user).toList();
      if (userMessages.length < 4) {
        return;
      }

      // 4. Construct transcript text
      final transcript = messages.map((m) {
        final roleName = m.role == ChatRole.user ? 'کاربر' : 'دستیار';
        return '$roleName: ${m.content}';
      }).join('\n');

      // 5. Fetch existing active memories for this domain to avoid duplication/contradictions
      final activeRows = await db.query(
        'ai_memory',
        where: "status = 'active' AND domain = ?",
        whereArgs: [domain],
      );
      final existingMemories = activeRows.map(MemoryEntry.fromMap).toList();
      final existingMemoriesStr = existingMemories.map((m) {
        return 'ID: ${m.id} | نوع: ${m.type.name} | محتوا: ${m.content}';
      }).join('\n');

      // 6. Call LLM for memory consolidation
      final systemPrompt = '''
شما موتور پردازش و یکپارچه‌سازی حافظه بلندمدت کاربر در اپلیکیشن ریتمو هستید.
وظیفه شما این است که گفتگوی اخیر کاربر و دستیار را تحلیل کرده و اطلاعات، علایق، اهداف، محدودیت‌ها یا رویدادهای پایدار و آینده‌دار (نه موقت و گذرا) درباره کاربر را استخراج کنید.

همچنین باید این اطلاعات جدید را با حافظه‌های فعال موجود مقایسه کنید تا از تکرار یا تناقض جلوگیری شود.

خروجی شما باید دقیقاً یک آرایه JSON شامل دستورالعمل‌های عملیاتی (ADD, UPDATE, DELETE, NOOP) باشد. هر دستورالعمل باید دارای ساختار زیر باشد:
- op: یکی از مقادیر "ADD" (برای ذخیره فکت جدید)، "UPDATE" (برای به‌روزرسانی فکت قبلی به علت تغییر شرایط یا اصلاح تناقض)، "DELETE" (برای حذف فکت که دیگر معتبر نیست) یا "NOOP".
- id: شناسه فکت قبلی (فقط برای UPDATE و DELETE الزامی است).
- content: فکت استخراج‌شده به صورت یک جمله کوتاه، خبری و به زبان سوم شخص فارسی (مثال: "کاربر به بادام‌زمینی آلرژی شدید دارد").
- type: یکی از مقادیر "identity" (هویت پایدار)، "preference" (علاقه‌مندی‌ها)، "constraint" (محدودیت‌ها مانند بیماری یا زانو درد)، "goal" (اهداف بلندمدت)، "episode" (رویداد مهم مقطعی).
- domain: حوزه مربوطه (مقدار فعلی: "$domain").
- importance: درجه اهمیت بین 1 تا 9 (مقدار 10 فقط برای ذخیره صریح توسط کاربر است).
- sensitive: مقدار true یا false (اگر مربوط به سلامت یا چرخه قاعدگی است true، در غیر این صورت false).
- expiresAt: زمان انقضای فکت به میلی‌ثانیه (در صورت وجود، مثلاً برای آزمون‌های هفته آینده).

فهرست حافظه‌های فعال موجود:
$existingMemoriesStr

قوانین مهم:
۱. فقط فکت‌های پایدار و آینده‌دار را استخراج کنید. اطلاعات موقت مانند "کاربر امروز خسته است" یا "کاربر در حال انجام کار است" را ذخیره نکنید.
۲. حداکثر ۵ عملیات در هر سشن استخراج کنید.
۳. در صورت بروز تناقض بین پیام جدید کاربر و حافظه قبلی، حافظه قبلی را UPDATE یا DELETE کنید.
۴. خروجی را فقط به صورت معتبر و در قالب JSON برگردانید و از توضیحات اضافه خودداری کنید.
''';

      final userPrompt = 'گفتگو جهت پردازش:\n$transcript';

      final llmResponse = await AIGateway.instance.sendCustomChat(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        responseFormatJson: true,
      );

      // Parse JSON operations
      final cleanedResponse = _cleanJsonResponse(llmResponse);
      final decoded = jsonDecode(cleanedResponse);

      if (decoded is List) {
        final ops = <MemoryOp>[];
        for (final item in decoded) {
          if (item is Map) {
            ops.add(MemoryOp.fromJson(item.cast<String, dynamic>()));
          }
        }

        if (ops.isNotEmpty) {
          await AiMemoryService.instance.applyOperations(ops);
        }
      }

      // Mark session as consolidated in settings (idempotent tag)
      await db.insert(
        'app_settings',
        {
          'key': checkKey,
          'value': 'true',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 7. Check for Reflection
      await _runReflectionIfNeeded(domain);
    } catch (e, stack) {
      debugPrint('[MEMORY] Consolidation error (non-fatal): $e\n$stack');
    }
  }

  /// Run Reflection logic when there are 10 or more active episodes for a domain
  static Future<void> _runReflectionIfNeeded(String domain) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final List<Map<String, dynamic>> episodes = await db.query(
        'ai_memory',
        where: "status = 'active' AND type = 'episode' AND domain = ?",
        whereArgs: [domain],
      );

      if (episodes.length < 10) return;

      final episodesStr = episodes.map((e) {
        return 'ID: ${e['id']} | محتوا: ${e['content']} | زمان: ${DateTime.fromMillisecondsSinceEpoch(e['createdAt'] as int)}';
      }).join('\n');

      final systemPrompt = '''
شما موتور یکپارچه‌سازی و خلاصه‌سازی حافظه ریتمو هستید.
تعداد رویدادهای مقطعی (episode) کاربر در حوزه "$domain" به حد نصاب رسیده است.
وظیفه شما این است که این رویدادها را تحلیل کرده و آن‌ها را به ۱ الی ۲ بینش (insight) عمیق و بلندمدت خلاصه کنید و رویدادهای قدیمی را حذف نمایید.

خروجی شما باید دقیقاً یک آرایه JSON شامل دستورالعمل‌های ADD (برای بینش‌های جدید با نوع "insight") و DELETE (برای حذف رویدادهای ادغام شده) باشد.

هر دستورالعمل در خروجی باید به این شکل باشد:
- op: مقدار "ADD" یا "DELETE"
- id: شناسه رویداد حذف شونده (فقط برای DELETE)
- content: متن بینش جدید (فقط برای ADD؛ به صورت سوم شخص کوتاه و خبری)
- type: برای ADD مقدار "insight"
- domain: مقدار "$domain"
- importance: درجه اهمیت بینش بین 1 تا 9
- sensitive: مقدار true یا false

رویدادهای مقطعی موجود برای ادغام:
$episodesStr

قوانین:
۱. هر بینش جدید باید خلاصه منطقی از چند رویداد باشد.
۲. خروجی را فقط به صورت معتبر و در قالب JSON برگردانید و از ارائه هرگونه توضیح فارسی یا انگلیسی خارج از قالب آرایه JSON خودداری کنید.
''';

      final llmResponse = await AIGateway.instance.sendCustomChat(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': 'لطفاً رویدادهای فوق را یکپارچه‌سازی کنید.'},
        ],
        responseFormatJson: true,
      );

      final cleanedResponse = _cleanJsonResponse(llmResponse);
      final decoded = jsonDecode(cleanedResponse);

      if (decoded is List) {
        final ops = <MemoryOp>[];
        for (final item in decoded) {
          if (item is Map) {
            ops.add(MemoryOp.fromJson(item.cast<String, dynamic>()));
          }
        }

        if (ops.isNotEmpty) {
          await AiMemoryService.instance.applyOperations(ops);
        }
      }
    } catch (e, stack) {
      debugPrint('[MEMORY] Reflection error (non-fatal): $e\n$stack');
    }
  }

  /// Helper to strip markdown JSON formatting from LLM raw response
  static String _cleanJsonResponse(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.first.startsWith('```')) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.startsWith('```')) {
        lines.removeLast();
      }
      cleaned = lines.join('\n').trim();
    }
    return cleaned;
  }
}
