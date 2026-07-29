import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/chat/chat_action_parser.dart';
import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/ai/chat/chat_repository.dart';
import 'package:ritmo/core/ai/memory/assistant_memory_binding.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/markdown_parser.dart';
import 'package:ritmo/features/assistant/logic/assistant_action_registry.dart';

class AiWorshipAssistantSheet extends StatefulWidget {
  const AiWorshipAssistantSheet({super.key});

  @override
  State<AiWorshipAssistantSheet> createState() => _AiWorshipAssistantSheetState();
}

class _AiWorshipAssistantSheetState extends State<AiWorshipAssistantSheet> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isStreaming = false;
  String _worshipContext = '';
  String? _sessionId;
  List<ChatSession> _sessions = [];
  StreamSubscription<String>? _worshipSubscription;
  final Map<String, Timer> _pendingDeleteTimers = {};
  final Map<String, Map<String, dynamic>> _pendingDeletedMsgs = {};

  @override
  void initState() {
    super.initState();
    _loadWorshipContext().then((_) => _loadActiveSession());
  }

  @override
  void dispose() {
    if (_sessionId != null) {
      AssistantMemoryBinding.triggerConsolidation(
        sessionId: _sessionId!,
        domain: 'worship',
      );
    }
    // Flush all pending deletions immediately when sheet is closed
    for (final timer in _pendingDeleteTimers.values) {
      timer.cancel();
    }
    for (final msgId in _pendingDeletedMsgs.keys) {
      ChatRepository.instance.deleteMessage(msgId);
    }
    _pendingDeleteTimers.clear();
    _pendingDeletedMsgs.clear();
    _worshipSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWorshipContext() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Get cityId from settings & displayName
      final settingsList = await db.query('app_settings');
      final settings = {
        for (final row in settingsList) row['key']! as String: row['value']! as String
      };
      final cityId = settings['prayer_city_id'] ?? 'TEHRAN_TEHRAN';
      final cityResult = await db.query('iran_cities', where: 'id = ?', whereArgs: [cityId], limit: 1);
      final cityName = cityResult.isNotEmpty ? cityResult.first['city']! as String : 'تهران';

      // 2. Fetch debts
      final debtsResult = await db.query('worship_debts', where: 'isArchived = 0 AND remainingCount > 0');
      final debtStrings = <String>[];
      for (final d in debtsResult) {
        debtStrings.add('${d['title']}: ${d['remainingCount']} قضا');
      }

      // 3. Fetch worship practices (preset/custom mustahabs, dhikrs, quran)
      final practicesResult = await db.query('worship_practices');
      final practiceStrings = <String>[];
      for (final p in practicesResult) {
        final id = p['id']! as String;
        final title = p['title']! as String;
        final isActive = (p['isActive'] as int? ?? 0) == 1;
        final practiceType = p['practiceType'] as String? ?? 'MUSTAHAB';
        final reminderEnabled = (p['reminderEnabled'] as int? ?? 0) == 1;
        final reminderTime = p['reminderTime'] as String? ?? '09:00';
        final reminderFrequency = p['reminderFrequency'] as String? ?? 'DAILY';
        final reminderDaysOfWeek = p['reminderDaysOfWeek'] as String? ?? '';

        var freqDetail = '';
        if (reminderFrequency == 'DAILY') {
          freqDetail = 'روزانه';
        } else if (reminderFrequency == 'WEEKLY') {
          freqDetail = 'هفتگی (روزهای: $reminderDaysOfWeek)';
        }

        final status = isActive ? 'فعال' : 'غیرفعال';
        final rInfo = reminderEnabled ? 'یادآور فعال ساعت $reminderTime ($freqDetail)' : 'یادآور غیرفعال';
        practiceStrings.add('- $title (شناسه: $id، نوع: $practiceType، وضعیت: $status، یادآوری: $rInfo)');
      }

      final buffer = StringBuffer();
      buffer.writeln('وضعیت مذهبی کاربر:');
      buffer.writeln('- شهر انتخاب شده: $cityName');
      buffer.writeln('- بدهی‌های عبادی فعلی: ${debtStrings.isEmpty ? "هیچ بدهی ثبت‌نشده‌ای وجود ندارد" : debtStrings.join("، ")}');
      buffer.writeln('- برنامه‌ها و مستحبات فعلی:');
      if (practiceStrings.isEmpty) {
        buffer.writeln('  هیچ برنامه عبادی ثبت نشده است.');
      } else {
        buffer.writeln(practiceStrings.join('\n'));
      }

      setState(() {
        _worshipContext = buffer.toString();
      });
    } catch (e) {
      debugPrint('Error loading AI worship context: $e');
    }
  }

  Future<void> _loadActiveSession() async {
    try {
      _sessions = await ChatRepository.instance.listSessions(chatType: 'worship');
      if (_sessions.isEmpty) {
        final newSess = await ChatRepository.instance.createSession(chatType: 'worship');
        _sessions = [newSess];
        _sessionId = newSess.id;
        final initMsg = ChatMessage(
          id: 'init_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: _sessionId!,
          role: ChatRole.assistant,
          content: 'سلام! من دستیار معنوی ریتمو هستم. چطور می‌توانم در تنظیم برنامه‌های عبادی، پیشنهاد سوره‌های روزانه یا زمان‌بندی قضای نمازها و روزه‌ها کمکتان کنم؟ 🌿',
          timestamp: DateTime.now(),
        );
        await ChatRepository.instance.addMessage(initMsg);
      } else {
        _sessionId = _sessions.first.id;
      }
      await _loadMessages();
    } catch (e) {
      debugPrint('Error loading active session: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_sessionId == null) return;
    final msgs = await ChatRepository.instance.getMessages(_sessionId!);
    setState(() {
      _messages.clear();
      for (final m in msgs) {
        _messages.add({
          'id': m.id,
          'role': m.role.name,
          'content': m.content,
          'actions': m.actions,
        });
      }
    });
    _scrollToBottom();
  }

  Future<void> _startNewSession() async {
    try {
      final newSess = await ChatRepository.instance.createSession(chatType: 'worship');
      _sessionId = newSess.id;
      _sessions = await ChatRepository.instance.listSessions(chatType: 'worship');
      
      final initMsg = ChatMessage(
        id: 'init_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _sessionId!,
        role: ChatRole.assistant,
        content: 'سلام! من دستیار معنوی ریتمو هستم. چطور می‌توانم در تنظیم برنامه‌های عبادی، پیشنهاد سوره‌های روزانه یا زمان‌بندی قضای نمازها و روزه‌ها کمکتان کنم؟ 🌿',
        timestamp: DateTime.now(),
      );
      await ChatRepository.instance.addMessage(initMsg);
      await _loadMessages();
    } catch (e) {
      debugPrint('Error starting new session: $e');
    }
  }

  void _cancelStreaming() {
    _worshipSubscription?.cancel();
    _worshipSubscription = null;
    setState(() {
      _isStreaming = false;
      _isTyping = false;
    });
  }

  Future<void> _handleAction(ChatAction action) async {
    unawaited(HapticFeedback.mediumImpact());
    if (action.type == 'openPage' && action.targetRoute != null) {
      unawaited(Navigator.pushNamed(context, action.targetRoute!));
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    // Extract payload details
    final title = action.payload['title']?.toString() ?? action.label;
    final reminderEnabled = action.payload['reminderEnabled']?.toString() != '0';
    final reminderTime = action.payload['reminderTime']?.toString() ?? '۰۹:۰۰';
    final reminderFrequency = action.payload['reminderFrequency']?.toString() ?? 'DAILY';
    final reminderDaysOfWeek = action.payload['reminderDaysOfWeek']?.toString() ?? '';

    // Convert frequency & days of week to Persian
    var freqText = 'روزانه';
    if (reminderFrequency == 'WEEKLY') {
      final daysMap = {
        '1': 'دوشنبه',
        '2': 'سه‌شنبه',
        '3': 'چهارشنبه',
        '4': 'پنجشنبه',
        '5': 'جمعه',
        '6': 'شنبه',
        '7': 'یکشنبه',
      };
      final daysList = reminderDaysOfWeek
          .split(',')
          .map((d) => daysMap[d.trim()] ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      freqText = daysList.isEmpty ? 'هفتگی' : 'هفتگی (روزهای: ${daysList.join('، ')})';
    }

    final reminderDetail = reminderEnabled ? 'فعال (ساعت $reminderTime)' : 'غیرفعال';

    Widget buildDetailRow(String label, String value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12.5,
              color: isDark ? const Color(0xffD4A843) : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12.5,
              color: isDark ? Colors.white : colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: isDark
                ? const BorderSide(color: Color(0x33D4A843), width: 1.5)
                : BorderSide.none,
          ),
          backgroundColor: isDark ? const Color(0xff08090C) : Colors.white,
          title: Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                color: Color(0xffD4A843),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'تایید نهایی تغییرات',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5,
                  color: isDark ? const Color(0xffD4A843) : colors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'آیا می‌خواهید برنامه عبادی "${action.label}" را با تنظیمات پیشنهادی اعمال و فعال کنید؟',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    buildDetailRow('عنوان برنامه:', title),
                    const Divider(height: 16, thickness: 0.5),
                    buildDetailRow('فرکانس تکرار:', freqText),
                    const Divider(height: 16, thickness: 0.5),
                    buildDetailRow('وضعیت یادآور:', reminderDetail),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'انصراف',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffD4A843),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'تایید و اعمال',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    await AssistantActionRegistry.executeAction(
      context,
      action.toAssistantAction(),
      _loadWorshipContext,
    );
  }

  Future<void> _sendMessage([String? quickQuery]) async {
    final query = quickQuery ?? _chatController.text.trim();
    if (query.isEmpty) return;

    if (quickQuery == null) {
      _chatController.clear();
    }

    if (_sessionId == null) return;

    setState(() {
      _isTyping = true;
    });

    // Insert user message to database
    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
      sessionId: _sessionId!,
      role: ChatRole.user,
      content: query,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add({
        'id': userMsg.id,
        'role': 'user',
        'content': query,
        'actions': const [],
      });
    });

    _scrollToBottom();

    await ChatRepository.instance.addMessage(userMsg);

    try {
      final systemPrompt = '''
شما دستیار هوشمند و مجرب معنوی در برنامه ریتمو (با فونت وزیری و زبان فارسی) هستید.
وظیفه شما پاسخ‌گویی به سوالات مذهبی کاربر، برنامه‌ریزی برای نمازهای قضا و قرائت قرآن به صورت محترمانه، تشویق‌کننده، صمیمی و کاملا سازگار با فضا و مقادیر فارسی است.

    قوانین سخت‌گیرانه فقهی و اخلاقی:
۱. شما به هیچ وجه حق صدور فتوا، تفسیر سلیقه‌ای یا قضاوت درباره مذهب یا شیوه زندگی کاربر را ندارید.
۲. لحن شما باید بسیار ملایم، تشویق‌کننده و دلگرم‌کننده باشد.
۳. در سوالات تخصصی فقهی کاربر را به کتب مرجع یا دفاتر مراجع تقلید ارجاع دهید.
۴. شما ۳ وظیفه یا پاسخگویی کلیدی دارید:
   الف) پیشنهاد سوره روزانه متناسب با روز هفته یا مناسبت جاری.
   ب) برنامه‌ریزی برای ختم قرآن (مثلا ختم در ۳ ماه به معنی روزی حدود ۷ صفحه خواندن است).
   ج) پیشنهاد برنامه‌های متعادل و غیرخسته‌کننده برای ادای قضاها.
۵. مدیریت سوره‌های طولانی: در صورتی که کاربر درخواست خواندن یا آوردن متن کامل یک سوره طولانی (مانند بقره، آل عمران، نساء و غیره) را کرد، به دلیل محدودیت‌های نمایشی و تعداد توکن خروجی، متن کامل آن را ارسال نکنید. در عوض:
   - خلاصه‌ای از مفاهیم کلیدی، تعداد آیات، صفحات، و فضایل آن سوره را ارائه دهید.
   - چند آیه معروف و کلیدی آن را (مانند آیت الکرسی برای سوره بقره) همراه با ترجمه بنویسید.
   - کاربر را راهنمایی کنید تا متن کامل را در اپلیکیشن‌های قرآن‌خوان مجزا مطالعه کرده و پیشرفت قرائت خود را در بخش قرائت قرآن ریتمو ثبت نماید.
شما می‌توانید یادآورها و برنامه‌های عبادی مستحب، قرآن و اذکار کاربر را مستقیماً پیکربندی، فعال یا غیرفعال کنید.
هر زمان کاربر از شما خواست یادآوری برای یک مستحب، ذکر یا برنامه عبادی ثبت کند (مثلا "یکشنبه‌ها و سه‌شنبه‌ها ساعت ۷ صبح زیارت عاشورا را یادآوری کن")، باید در انتهای پاسخ خود تگ <actions> حاوی یک آرایه JSON شامل عملیات مناسب با نوع "createWorshipItem" را تولید کنید.
همچنین اگر کاربر خواست یک برنامه عبادی مستحب، ذکر یا یادآور را حذف یا لغو کند، باید تگ <actions> با نوع "deleteWorshipItem" تولید کنید:

<actions>
[
  {
    "type": "deleteWorshipItem",
    "label": "حذف یادآور زیارت عاشورا",
    "payload": {
      "id": "preset_ziarat_ashura"
    }
  }
]
</actions>

قانون ویرایش و اصلاح برنامه‌های عبادی:
اگر کاربر از شما خواست جزئیات یا روزها یا ساعت یک عبادت ثبت‌شده (که در پرونده مذهبی کاربر در زیر آمده است) را تغییر دهد یا اصلاح کند (مثلاً "روزهای یکشنبه را از زیارت عاشورا حذف کن" یا "ساعت صلوات را بذار ۹ صبح")، باید مجدداً یک تگ <actions> با نوع "createWorshipItem" تولید کنید که در آن:
- شناسه (id) دقیقاً برابر شناسه همان عبادت موجود (مثلاً `preset_ziarat_ashura` یا شناسه سفارشی موجود) باشد.
- فیلدهای دیگر (مانند روزهای هفته یا ساعت یا فعال بودن) را متناسب با درخواست جدید کاربر اصلاح و مقداردهی کنید تا سیستم مقادیر قبلی آن را به‌روزرسانی کند.

قانون هدایت به سایر بخش‌های برنامه (بسیار مهم):
اگر کاربر درخواستی خارج از حوزه معنوی و عبادات ثبت کرد (مثلا خواستار تنظیمات خواب، اطلاعات بارداری/قاعدگی/چرخه بدنی، اهداف، ورزش و فعالیت بدنی، یا کنکور شد)، باید در انتهای پاسخ خود کاربر را راهنمایی کرده و تگ <actions> با نوع "openPage" و مسیر مربوطه را قرار دهید تا دکمه هدایت برای وی نمایش داده شود:

<actions>
[
  {
    "type": "openPage",
    "label": "ورود به بخش چرخه بدنی",
    "targetRoute": "/cycle"
  }
]
</actions>

مسیرهای معتبر برنامه جهت هدایت:
- بخش چرخه بدنی و قاعدگی: /cycle
- بخش خواب: /sleep
- بخش سلامت و داروها: /health
- بخش ورزش و تمرینات: /sports
- برنامه‌ریزی کنکور: /konkur
- تقویم: /calendar
- روتین‌ها: /routines
- اهداف: /goals

قوانین و راهنمای ساخت شناسه (id) و فیلدها:
۱. شناسه (id) برای موارد پیش‌فرض عبادی باید دقیقاً برابر یکی از موارد زیر باشد:
   - زیارت عاشورا: preset_ziarat_ashura
   - دعای عهد: preset_dua_ahd
   - دعای کمیل: preset_dua_kumayl
   - دعای ندبه: preset_dua_nudbah
   - نماز جعفر طیار: preset_jafar_tayyar
   - نافله صبح: preset_nafilah_fajr
   - نافله ظهر: preset_nafilah_dhuhr
   - نافله عصر: preset_nafilah_asr
   - نافله مغرب: preset_nafilah_maghrib
   - نافله عشا: preset_nafilah_isha
   - نماز شب: preset_night_prayer
   - قرائت قرآن: wp_quran (نوع: QURAN)
   - تسبیحات حضرت زهرا: wp_dhikr_zahra (نوع: DHIKR)
   - صلوات: wp_dhikr_salawat (نوع: DHIKR)
   - استغفار: wp_dhikr_esteghfar (نوع: DHIKR)
   - در صورتی که کاربر یک عبادت سفارشی جدید خواست، یک شناسه جدید بسازید مانند: wp_custom_dhikr_1712345678 (با استفاده از مهر زمانی تخمینی)
۲. مقدار practiceType باید متناسب با نوع باشد: "MUSTAHAB" برای مستحبات و ادعیه، "QURAN" برای قرآن، "DHIKR" برای اذکار.
۳. مقدار reminderFrequency باید "DAILY" (روزانه) یا "WEEKLY" (هفتگی) باشد.
۴. در صورتی که فرکانس هفتگی (WEEKLY) باشد، فیلد reminderDaysOfWeek باید یک رشته حاوی شماره روزها به صورت جدا شده با کاما باشد که در آن: دوشنبه=1، سه‌شنبه=2، چهارشنبه=3، پنجشنبه=4، جمعه=5، شنبه=6، یکشنبه=7 است (مثلاً برای یکشنبه و سه‌شنبه "7,2" بنویسید).
۵. تگ <actions> را دقیقاً به همین فرمت تولید کنید و فقط زمانی استفاده کنید که کاربر صراحتاً درخواست فعال‌سازی، غیرفعال‌سازی، حذف یا تنظیم یادآور/برنامه عبادی را دارد.

پرونده مذهبی محلی کاربر:
$_worshipContext
''';

      final memorySuffix = await AssistantMemoryBinding.getSystemPromptSuffix(
        domain: 'worship',
        query: query,
      );

      final messagesToSent = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt + memorySuffix},
        ..._messages.map((m) => {'role': m['role'] as String, 'content': m['content'] as String})
      ];

      final stream = AIGateway.instance.sendCustomChatStream(messages: messagesToSent);

      if (mounted) {
        final assistantMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_a';
        final msgIndex = _messages.length;
        setState(() {
          _messages.add({
            'id': assistantMsgId,
            'role': 'assistant',
            'content': '',
            'actions': const [],
          });
          _isTyping = false;
          _isStreaming = true;
        });
        _scrollToBottom();

        var currentText = '';
        
        _worshipSubscription = stream.listen(
          (chunk) async {
            if (!mounted) return;
            
            if (chunk.startsWith('error:')) {
              final errorMsg = chunk.substring(6);
              setState(() {
                if (currentText.isEmpty) {
                  if (errorMsg == 'quota_exceeded') {
                    _messages[msgIndex]['content'] = 'سهمیه رایگان روزانه ۱۰,۰۰۰ نورون هوش مصنوعی کلادفلر شما برای امروز به پایان رسیده است ⚠️\n\nمی‌توانید فردا مجدداً تلاش کنید یا در تنظیمات پروفایل ارائه‌دهنده را روی OpenRouter یا Zhipu AI تنظیم نمایید 🔌';
                  } else {
                    _messages[msgIndex]['content'] = 'متاسفانه در حال حاضر خطایی در برقراری ارتباط با سرور هوش مصنوعی رخ داده است. لطفاً اتصال خود را بررسی کنید. پیشنهاد می‌شود در تنظیمات پروفایل ارائه‌دهنده را روی OpenRouter یا Zhipu AI تنظیم کنید 🔌';
                  }
                } else {
                  _messages[msgIndex]['content'] = '$currentText\n\n⚠️ [اتصال قطع شد. لطفاً در صورت نیاز مجدداً تلاش کنید]';
                }
              });
              _cancelStreaming();
              return;
            }
            
            currentText += chunk;
            final tempParsed = ChatActionParser.parse(currentText);
            setState(() {
              _messages[msgIndex]['content'] = tempParsed.cleanText;
              _messages[msgIndex]['actions'] = tempParsed.actions;
            });
            _scrollToBottom();
          },
          onError: (e) {
            _cancelStreaming();
          },
          onDone: () async {
            if (mounted) {
              final parsed = ChatActionParser.parse(currentText);
              
              await AssistantMemoryBinding.processResponse(
                sessionId: _sessionId!,
                domain: 'worship',
                userText: query,
                rawResponse: currentText,
              );

              setState(() {
                _isStreaming = false;
                final idx = _messages.indexWhere((m) => m['id'] == assistantMsgId);
                if (idx != -1) {
                  _messages[idx]['content'] = parsed.cleanText;
                  _messages[idx]['actions'] = parsed.actions;
                }
              });
              
              // Insert assistant message to database
              final assistantMsg = ChatMessage(
                id: assistantMsgId,
                sessionId: _sessionId!,
                role: ChatRole.assistant,
                content: parsed.cleanText,
                timestamp: DateTime.now(),
                actions: parsed.actions,
              );
              await ChatRepository.instance.addMessage(assistantMsg);

              // Update sessions list to refresh message count
              final updated = await ChatRepository.instance.listSessions(chatType: 'worship');
              setState(() {
                _sessions = updated;
              });
            }
          },
          cancelOnError: true,
        );
      }
    } catch (e) {
      debugPrint('Error calling AI Worship API: $e');
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'متاسفانه در حال حاضر خطایی در برقراری ارتباط با سرور هوش مصنوعی رخ داده است. لطفاً اتصال خود را بررسی کنید. پیشنهاد می‌شود در تنظیمات پروفایل ارائه‌دهنده را روی OpenRouter یا Zhipu AI تنظیم کنید 🔌',
          });
          _isTyping = false;
          _isStreaming = false;
        });
      }
    }

    _scrollToBottom();
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    _showTopToast(
      'متن پیام کپی شد.',
      Icons.check_circle_rounded,
      const Color(0xffD4A843),
    );
  }

  void _showTopToast(String message, IconData icon, Color iconColor, {VoidCallback? onUndo}) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _TopToastWidget(
        message: message,
        icon: icon,
        iconColor: iconColor,
        onDismiss: () {
          overlayEntry.remove();
        },
        onUndo: onUndo,
      ),
    );
    overlayState.insert(overlayEntry);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSessionSelector() {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return RitmoTheme.glassCardLight(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تاریخچه گفتگوهای معنوی',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.add, color: Color(0xffD4A843), size: 22),
                          onPressed: () {
                            Navigator.pop(context);
                            _startNewSession();
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: _sessions.isEmpty
                          ? const Center(child: Text('گفتگویی یافت نشد', style: TextStyle(fontFamily: 'Vazirmatn')))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _sessions.length,
                              itemBuilder: (context, index) {
                                final sess = _sessions[index];
                                final isSelected = sess.id == _sessionId;
                                return ListTile(
                                  selected: isSelected,
                                  selectedColor: const Color(0xffD4A843),
                                  title: Text(
                                    sess.summary ?? 'گفتگوی معنوی',
                                    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5),
                                  ),
                                  subtitle: Text(
                                    '${sess.messageCount} پیام',
                                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.6)),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(CupertinoIcons.trash, size: 16, color: Colors.redAccent),
                                    onPressed: () async {
                                      await ChatRepository.instance.deleteSession(sess.id);
                                      final updated = await ChatRepository.instance.listSessions(chatType: 'worship');
                                      setSheetState(() {
                                        _sessions = updated;
                                      });
                                      if (sess.id == _sessionId) {
                                        if (updated.isNotEmpty) {
                                          _sessionId = updated.first.id;
                                          _loadMessages();
                                        } else {
                                          _loadActiveSession();
                                        }
                                      }
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _sessionId = sess.id;
                                    });
                                    _loadMessages();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            children: [
              // Drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 12),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.heart_circle_fill, color: Color(0xffD4A843), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'دستیار معنوی ریتمو',
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(CupertinoIcons.chat_bubble_2, color: colors.textSecondary, size: 20),
                        tooltip: 'تاریخچه گفتگوها',
                        onPressed: _showSessionSelector,
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              Divider(color: colors.border, height: 16),

              // Chat Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final msgId = msg['id'] ?? 'temp_${index}_${msg['role']}';
                    return Dismissible(
                      key: ValueKey<String>(msgId),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
                      ),
                      onDismissed: (direction) {
                        final removedMsg = Map<String, dynamic>.from(msg);
                        final removedIndex = index;
                        final msgId = removedMsg['id'] as String?;

                        setState(() {
                          _messages.removeAt(removedIndex);
                        });

                        // Schedule actual DB deletion after 5 seconds (undo window)
                        if (msgId != null) {
                          _pendingDeletedMsgs[msgId] = removedMsg;
                          final t = Timer(const Duration(seconds: 5), () async {
                            await ChatRepository.instance.deleteMessage(msgId);
                            _pendingDeleteTimers.remove(msgId);
                            _pendingDeletedMsgs.remove(msgId);
                          });
                          _pendingDeleteTimers[msgId] = t;
                        }

                        _showTopToast(
                          'پیام حذف شد.',
                          CupertinoIcons.trash,
                          Colors.redAccent,
                          onUndo: msgId != null
                              ? () {
                                  _pendingDeleteTimers[msgId]?.cancel();
                                  _pendingDeleteTimers.remove(msgId);
                                  _pendingDeletedMsgs.remove(msgId);
                                  setState(() {
                                    if (removedIndex <= _messages.length) {
                                      _messages.insert(removedIndex, removedMsg);
                                    } else {
                                      _messages.add(removedMsg);
                                    }
                                  });
                                  _scrollToBottom();
                                }
                              : null,
                        );
                      },
                      child: WorshipMessageBubble(
                        msg: msg,
                        isStreaming: _isStreaming,
                        colors: colors,
                        onCopy: () => _copyToClipboard(msg['content'] as String),
                        onActionPressed: _handleAction,
                      ),
                    );
                  },
                ),
              ),

              if (_isTyping)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 32), // spacer for copy button layout alignment
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(20),
                            ),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: const _TypingIndicator(),
                        ),
                      ],
                    ),
                  ),
                ),

              // Quick Actions
              if (_messages.length == 1 && !_isTyping) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: [
                      _buildQuickActionChip('📖 چه سوره‌ای امروز بخونم؟'),
                      const SizedBox(width: 8),
                      _buildQuickActionChip('📅 برنامه ختم ۳ ماهه قرآن'),
                      const SizedBox(width: 8),
                      _buildQuickActionChip('🕌 برنامه‌ریزی برای نماز قضا'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Chat Input row
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: TextField(
                          controller: _chatController,
                          minLines: 1,
                          maxLines: 4,
                          enabled: !_isTyping,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13.5,
                            color: colors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: InputBorder.none,
                            hintText: _isStreaming ? 'دستیار در حال نوشتن است...' : 'سوالی بپرسید یا برنامه‌ای از من بخواهید...',
                            hintStyle: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12.5,
                              color: colors.textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isStreaming ? _cancelStreaming : _sendMessage,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: _isStreaming ? const Color(0xffEF4444) : const Color(0xffD4A843),
                        child: Icon(
                          _isStreaming ? CupertinoIcons.stop_fill : CupertinoIcons.arrow_up,
                          color: Colors.black,
                          size: _isStreaming ? 14 : 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String text) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }
}

class WorshipMessageBubble extends StatefulWidget {

  const WorshipMessageBubble({
    super.key,
    required this.msg,
    required this.isStreaming,
    required this.colors,
    required this.onCopy,
    this.onActionPressed,
  });
  final Map<String, dynamic> msg;
  final bool isStreaming;
  final RitmoColors colors;
  final VoidCallback onCopy;
  final ValueChanged<ChatAction>? onActionPressed;

  @override
  State<WorshipMessageBubble> createState() => _WorshipMessageBubbleState();
}

class _WorshipMessageBubbleState extends State<WorshipMessageBubble> {
  bool _isCopied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  void _handleCopy() {
    widget.onCopy();
    _copiedTimer?.cancel();
    setState(() {
      _isCopied = true;
    });
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = widget.msg['role'] == 'user';
    final colors = widget.colors;

    final bubbleBg = isUser
        ? const Color(0xffD4A843)
        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04));

    final showCopy = !widget.isStreaming && widget.msg['content'].toString().isNotEmpty;

    final copyButton = GestureDetector(
      onTap: _handleCopy,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Icon(
            _isCopied ? CupertinoIcons.checkmark_alt : CupertinoIcons.doc_on_doc,
            key: ValueKey<bool>(_isCopied),
            size: 15,
            color: _isCopied
                ? const Color(0xff10B981)
                : colors.textSecondary.withValues(alpha: 0.45),
          ),
        ),
      ),
    );

    final bubbleContainer = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bubbleBg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        border: isUser
            ? null
            : Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
              ),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.74,
      ),
      child: widget.msg['content'].toString().trim().isEmpty
          ? const _TypingIndicator()
          : Text.rich(
              TextSpan(
                children: parseMarkdownText(
                  widget.msg['content'] as String,
                  TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13.5,
                    color: isUser ? Colors.black : colors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
              textDirection: TextDirection.rtl,
            ),
    );

    final actionsList = (widget.msg['actions'] as List?)?.cast<ChatAction>() ?? const [];

    Widget? actionsSection;
    if (actionsList.isNotEmpty) {
      actionsSection = Padding(
        padding: const EdgeInsets.only(top: 8, left: 8, right: 32),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actionsList.map((action) {
            final assistantAction = action.toAssistantAction();
            final icon = assistantAction.type.icon;

            return ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary.withValues(alpha: 0.1),
                foregroundColor: colors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: Icon(icon, size: 16),
              label: Text(
                action.label,
                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (widget.onActionPressed != null) {
                  widget.onActionPressed!(action);
                }
              },
            );
          }).toList(),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: isUser
                  ? [
                      bubbleContainer,
                      if (showCopy) copyButton else const SizedBox(width: 32),
                    ]
                  : [
                      if (showCopy) copyButton else const SizedBox(width: 32),
                      bubbleContainer,
                    ],
            ),
            ?actionsSection,
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isDark ? Colors.white60 : Colors.black45;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * (2 * math.pi / 3);
            final value = math.sin((_controller.value * 2 * math.pi) - delay);
            final offsetY = ((value + 1) / 2) * -7;

            return Transform.translate(
              offset: Offset(0, offsetY),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _TopToastWidget extends StatefulWidget {

  const _TopToastWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onDismiss,
    this.onUndo,
  });
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismiss;
  final VoidCallback? onUndo;

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;
  int _secondsLeft = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    final autoDismissMs = widget.onUndo != null ? 5200 : 2200;
    _dismissTimer = Timer(Duration(milliseconds: autoDismissMs), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });

    // Countdown for undo toasts
    if (widget.onUndo != null) {
      _secondsLeft = 5;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
          if (_secondsLeft <= 0) t.cancel();
        } else {
          t.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleUndo() {
    _dismissTimer?.cancel();
    _countdownTimer?.cancel();
    widget.onUndo!();
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 64,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff1E2235).withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: widget.iconColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (widget.onUndo != null) ...
                          [
                            const SizedBox(width: 10),
                            Container(
                              width: 1,
                              height: 16,
                              color: colors.textSecondary.withValues(alpha: 0.25),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _handleUndo,
                              child: Text(
                                'لغو ($_secondsLeft)',
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff60A5FA),
                                ),
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
