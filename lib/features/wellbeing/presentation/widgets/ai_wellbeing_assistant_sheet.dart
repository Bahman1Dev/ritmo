import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/ai/ai_context_builder.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/chat/chat_action_parser.dart';
import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/ai/chat/chat_repository.dart';
import 'package:ritmo/core/ai/memory/assistant_memory_binding.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/markdown_parser.dart';
import 'package:ritmo/features/assistant/logic/assistant_action_registry.dart';
import 'package:ritmo/features/energy/models/energy_mood_models.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:ritmo/features/today/presentation/widgets/daily_reflection_sheet.dart';
import 'package:sqflite/sqflite.dart';

class AiWellbeingAssistantSheet extends StatefulWidget {

  const AiWellbeingAssistantSheet({
    super.key,
    required this.energyEnabled,
    required this.sleepEnabled,
    this.currentEnergy,
    this.explanations,
    this.dominantMood,
    this.correlationInsight,
    this.isUserMenstruating = false,
    this.isEnergyTuned = false,
    this.sleepTarget,
    this.sleepLogs,
    required this.todayCheckinDone,
    required this.todayReflectionDone,
    required this.onSaved,
  });
  final bool energyEnabled;
  final bool sleepEnabled;

  // Energy parameters
  final double? currentEnergy;
  final List<String>? explanations;
  final Mood? dominantMood;
  final String? correlationInsight;
  final bool isUserMenstruating;
  final bool isEnergyTuned;

  // Sleep parameters
  final SleepTarget? sleepTarget;
  final List<SleepLog>? sleepLogs;

  // Reflection parameters
  final bool todayCheckinDone;
  final bool todayReflectionDone;

  final VoidCallback onSaved;

  @override
  State<AiWellbeingAssistantSheet> createState() => _AiWellbeingAssistantSheetState();
}

class _AiWellbeingAssistantSheetState extends State<AiWellbeingAssistantSheet> {
  // Navigation tab: 0 = Chat, 1 = Reflection Draft
  int _activeTab = 0;

  // Chat tab state
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isStreaming = false;
  String _wellbeingContext = '';
  String? _sessionId;
  List<ChatSession> _sessions = [];
  StreamSubscription<String>? _chatSubscription;
  final Map<String, Timer> _pendingDeleteTimers = {};
  final Map<String, Map<String, dynamic>> _pendingDeletedMsgs = {};

  // Reflection draft tab state
  bool _isDraftLoading = false;
  String? _suggestionQuestion;
  String? _suggestionAnalysis;
  int? _proposedMoodScore;
  String? _proposedWins;
  String? _proposedGratitude;
  String? _proposedChallenges;
  String? _proposedLearnings;
  String? _proposedTomorrowFocus;

  @override
  void initState() {
    super.initState();
    _buildContext();
    _loadActiveSession();
    _fetchAISuggestions();
  }

  @override
  void dispose() {
    if (_sessionId != null) {
      AssistantMemoryBinding.triggerConsolidation(
        sessionId: _sessionId!,
        domain: 'wellbeing',
      );
    }
    for (final timer in _pendingDeleteTimers.values) {
      timer.cancel();
    }
    for (final msgId in _pendingDeletedMsgs.keys) {
      ChatRepository.instance.deleteMessage(msgId);
    }
    _pendingDeleteTimers.clear();
    _pendingDeletedMsgs.clear();
    _chatSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _buildContext() {
    final buffer = StringBuffer();
    buffer.writeln('شما دستیار هوشمند یکپارچه «حال و تعادل» در برنامه ریتمو هستید که به داده‌های هر سه حوزه انرژی، خواب و خودارزیابی دسترسی دارد.');
    buffer.writeln('توصیه‌های خودمراقبتی، تحلیل الگوها و بهبود سبک زندگی را به صورت محترمانه، علمی، تشویق‌کننده و صمیمی به زبان فارسی ارائه دهید.');
    buffer.writeln('قوانین و محدودیت‌های بسیار سخت‌گیرانه:');
    buffer.writeln('۱. شما تحت هیچ شرایطی نباید کلماتی مانند «قاعدگی»، «پریود»، «عادت ماهیانه»، «سیکل»، «چرخه»، «تخمک‌گذاری» یا ارجاعات مستقیم بیولوژیک زنانه را بنویسید.');
    buffer.writeln('۲. اگر کاربر در دوره استراحت طبیعی بدن خود قرار دارد (که در بخش وضعیت ویژه ذکر شده)، فقط با عباراتی غیرمستقیم مانند «بر اساس ریتم طبیعی بدن شما در این روزها» یا «بر اساس الگوی نوسان زیستی بدنتان» به آن اشاره کنید و پیشنهادهای بازسازی و استراحت ملایم بدهید.');
    buffer.writeln('۳. در سوالات پزشکی تخصصی، کاربر را به پزشک متخصص ارجاع دهید.');
    buffer.writeln('۴. اعداد و مقادیر خروجی را با قلم فارسی نمایش دهید.');
    buffer.writeln();
    buffer.writeln('اطلاعات زیستی و تعادل کاربر:');

    if (widget.energyEnabled) {
      buffer.writeln('--- حوزه انرژی و حال روحی ---');
      buffer.writeln('- سطح انرژی پویای فعلی: ${widget.currentEnergy?.toInt()}%');
      if (widget.explanations != null && widget.explanations!.isNotEmpty) {
        buffer.writeln('- عوامل مؤثر بر انرژی: ${widget.explanations!.join(", ")}');
      }
      buffer.writeln('- احساس غالب کاربر: ${widget.dominantMood?.label ?? "ثبت نشده"}');
      buffer.writeln('- تحلیل همبستگی حال و انرژی: ${widget.correlationInsight}');
      if (widget.isEnergyTuned && widget.isUserMenstruating) {
        buffer.writeln('- وضعیت ویژه زیستی: بدن کاربر امروز بر اساس ریتم طبیعی زیستی نیاز به استراحت و فعالیت‌های ملایم‌تر دارد. بار سنگین کاری پیشنهاد نشود.');
      }
    }

    if (widget.sleepEnabled) {
      buffer.writeln('--- حوزه خواب و بیداری ---');
      if (widget.sleepTarget != null) {
        buffer.writeln('- هدف زمان خوابیدن: ${widget.sleepTarget!.bedtime}');
        buffer.writeln('- هدف زمان بیداری: ${widget.sleepTarget!.wake}');
        buffer.writeln('- مدت زمان خواب هدف: ${widget.sleepTarget!.durationMinutes} دقیقه (${widget.sleepTarget!.durationMinutes ~/ 60} ساعت)');
      }
      if (widget.sleepLogs != null && widget.sleepLogs!.isNotEmpty) {
        final recent = widget.sleepLogs!.take(7).toList();
        buffer.writeln('- سوابق خواب اخیر:');
        for (final log in recent) {
          buffer.writeln('  * تاریخ: ${log.date}، مدت: ${log.durationMinutes} دقیقه، کیفیت: ${log.quality.label}، بیداری شبانه: ${log.awakenings} بار');
        }
      } else {
        buffer.writeln('- سابقه ثبت شده: هیچ سابقه خوابی ثبت نشده است.');
      }
    }

    buffer.writeln('--- حوزه خودارزیابی و بازتاب روزانه ---');
    buffer.writeln('- وضعیت چک‌این امروز: ${widget.todayCheckinDone ? "ثبت شده" : "ثبت نشده"}');
    buffer.writeln('- وضعیت تأمل امروز: ${widget.todayReflectionDone ? "ثبت شده" : "ثبت نشده"}');

    _wellbeingContext = buffer.toString();
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  Future<void> _loadActiveSession() async {
    try {
      _sessions = await ChatRepository.instance.listSessions(chatType: 'wellbeing');
      if (_sessions.isEmpty) {
        final newSess = await ChatRepository.instance.createSession(chatType: 'wellbeing');
        _sessions = [newSess];
        _sessionId = newSess.id;
        final initMsg = ChatMessage(
          id: 'init_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: _sessionId!,
          role: ChatRole.assistant,
          content: 'سلام! من دستیار هوشمند یکپارچه «حال و تعادل» ریتمو هستم. چطور می‌توانم در تحلیل نوسانات انرژی، بهبود خواب و یا بازتاب‌های روزانه به شما کمک کنم؟ ⚡🌙📓',
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
        });
      }
    });
    _scrollToBottom();
  }

  Future<void> _startNewSession() async {
    try {
      final newSess = await ChatRepository.instance.createSession(chatType: 'wellbeing');
      _sessionId = newSess.id;
      _sessions = await ChatRepository.instance.listSessions(chatType: 'wellbeing');
      
      final initMsg = ChatMessage(
        id: 'init_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _sessionId!,
        role: ChatRole.assistant,
        content: 'سلام! من دستیار هوشمند یکپارچه «حال و تعادل» ریتمو هستم. چطور می‌توانم در تحلیل نوسانات انرژی، بهبود خواب و یا بازتاب‌های روزانه به شما کمک کنم؟ ⚡🌙📓',
        timestamp: DateTime.now(),
      );
      await ChatRepository.instance.addMessage(initMsg);
      await _loadMessages();
    } catch (e) {
      debugPrint('Error starting new session: $e');
    }
  }

  void _cancelStreaming() {
    _chatSubscription?.cancel();
    _chatSubscription = null;
    setState(() {
      _isStreaming = false;
      _isTyping = false;
    });
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
شما دستیار هوشمند زیستی و تحلیل‌گر یکپارچه «حال و تعادل» (انرژی، خواب و خودارزیابی) در برنامه ریتمو (با فونت وزیری و زبان فارسی) هستید.
وظیفه شما ارائه توصیه‌های خودمراقبتی و بهینه‌سازی ریتم‌های روزانه کاربر به صورت محترمانه، علمی، تشویق‌کننده و صمیمی است.

قوانین و محدودیت‌های بسیار سخت‌گیرانه:
۱. شما تحت هیچ شرایطی نباید کلماتی مانند «قاعدگی»، «پریود»، «عادت ماهیانه»، «سیکل»، «چرخه»، «تخمک‌گذاری» یا ارجاعات مستقیم بیولوژیک زنانه را بنویسید.
۲. اگر کاربر در دوره استراحت طبیعی بدن خود قرار دارد (که در بخش وضعیت ویژه ذکر شده)، فقط با عباراتی غیرمستقیم مانند «بر اساس ریتم طبیعی بدن شما در این روزها» یا «بر اساس الگوی نوسان زیستی بدنتان» به آن اشاره کنید و پیشنهادهای بازسازی و استراحت ملایم بدهید.
۳. در سوالات پزشکی تخصصی، کاربر را به پزشک متخصص ارجاع دهید.
۴. اعداد و مقادیر خروجی را با قلم فارسی نمایش دهید.

قانون هدایت به سایر بخش‌های برنامه (بسیار مهم):
اگر کاربر درخواستی خارج از حوزه تعادل و زیستی (خواب، انرژی، بازتاب) ثبت کرد (مثلا خواستار ثبت نماز قضا، یادآور مذهبی، اهداف، ورزش و فعالیت بدنی، یا کنکور شد)، باید در انتهای پاسخ خود کاربر را راهنمایی کرده و تگ <actions> با نوع "openPage" و مسیر مربوطه را قرار دهید تا دکمه هدایت برای وی نمایش داده شود:

<actions>
[
  {
    "type": "openPage",
    "label": "ورود به بخش عبادات",
    "targetRoute": "/worship"
  }
]
</actions>

مسیرهای معتبر برنامه جهت هدایت:
- بخش عبادات: /worship
- بخش خواب: /sleep
- بخش سلامت و داروها: /health
- بخش ورزش و تمرینات: /sports
- برنامه‌ریزی کنکور: /konkur
- تقویم: /calendar
- روتین‌ها: /routines
- اهداف: /goals

اطلاعات تعادل و زیستی کاربر:
$_wellbeingContext
''';

      final memorySuffix = await AssistantMemoryBinding.getSystemPromptSuffix(
        domain: 'wellbeing',
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
        
        _chatSubscription = stream.listen(
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
                  final formatted = _toPersianDigits(currentText);
                  _messages[msgIndex]['content'] = '$formatted\n\n⚠️ [اتصال قطع شد. لطفاً در صورت نیاز مجدداً تلاش کنید]';
                }
              });
              _cancelStreaming();
              return;
            }
            
            currentText += chunk;
            setState(() {
              _messages[msgIndex]['content'] = _toPersianDigits(currentText);
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
                domain: 'wellbeing',
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
              
              final assistantMsg = ChatMessage(
                id: assistantMsgId,
                sessionId: _sessionId!,
                role: ChatRole.assistant,
                content: parsed.cleanText,
                timestamp: DateTime.now(),
                actions: parsed.actions,
              );
              await ChatRepository.instance.addMessage(assistantMsg);

              final updated = await ChatRepository.instance.listSessions(chatType: 'wellbeing');
              setState(() {
                _sessions = updated;
              });
            }
          },
          cancelOnError: true,
        );
      }
    } catch (e) {
      debugPrint('Error calling AI Wellbeing API: $e');
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

  // Reflection suggestions load
  Future<void> _fetchAISuggestions() async {
    if (!mounted) return;
    setState(() {
      _isDraftLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      
      final checkinMaps = await db.query('daily_checkins', where: 'date = ?', whereArgs: [todayStr]);
      final reflectionMaps = await db.query('daily_reflections', where: 'date = ?', whereArgs: [todayStr]);
      
      final startOfDayMs = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).millisecondsSinceEpoch;
      final energyMaps = await db.query(
        'energy_logs',
        where: 'loggedAt >= ?',
        whereArgs: [startOfDayMs],
        orderBy: 'loggedAt DESC',
      );

      final consent = await ConsentProfile.loadFromDb();

      var contextSummary = "Today's check-in status: ${checkinMaps.isNotEmpty ? 'Check-in recorded: ${checkinMaps.first['mood'] ?? ''}' : 'No check-in'}.\n";
      if (energyMaps.isNotEmpty) {
        contextSummary += "Recent logged energy levels: ${energyMaps.map((e) => e['energyLevel']).join(', ')}.\n";
      }
      if (reflectionMaps.isNotEmpty) {
        contextSummary += "Current reflection drafts: ${reflectionMaps.first['reflection_text'] ?? ''}.\n";
      }

      final query = 'تحلیل روزانه و ارائه پیشنهاد بازتاب: $contextSummary\nلطفاً یک سوال تامل‌برانگیز کوتاه فارسی متناسب با انرژی و وضعیت امروز بپرسید و یک خلاصه الگوی ملایم به همراه فیلدهای پیشنهادی با فرمت JSON ارائه دهید که شامل کلیدهای زیر باشد:\n'
          '{\n'
          '  "question": "سوال تامل‌برانگیز",\n'
          '  "analysis": "خلاصه الگوهای امروز",\n'
          '  "wins": "برد پیشنهادی",\n'
          '  "gratitude": "شکرگزاری پیشنهادی",\n'
          '  "challenges": "چالش پیشنهادی",\n'
          '  "learnings": "درس آموخته پیشنهادی",\n'
          '  "tomorrowFocus": "تمرکز فردا",\n'
          '  "moodScore": 4\n'
          '}';

      final response = await AIGateway.instance.sendCopilotQuery(
        query: query,
        consent: consent,
      );

      final reply = response['reply'] as String? ?? '';
      
      Map<String, dynamic>? jsonSuggested;
      try {
        var cleanJson = reply.trim();
        if (cleanJson.contains('{')) {
          cleanJson = cleanJson.substring(cleanJson.indexOf('{'), cleanJson.lastIndexOf('}') + 1);
          jsonSuggested = jsonDecode(cleanJson) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Error parsing AI reflection response to JSON: $e');
      }

      if (jsonSuggested != null && mounted) {
        setState(() {
          _suggestionQuestion = jsonSuggested?['question'] ?? 'امروز چه درسی برایت داشت؟';
          _suggestionAnalysis = jsonSuggested?['analysis'] ?? 'آماده ثبت تأمل و بازتاب روزانه‌اید.';
          _proposedMoodScore = jsonSuggested?['moodScore'] as int?;
          _proposedWins = jsonSuggested?['wins'] as String?;
          _proposedGratitude = jsonSuggested?['gratitude'] as String?;
          _proposedChallenges = jsonSuggested?['challenges'] as String?;
          _proposedLearnings = jsonSuggested?['learnings'] as String?;
          _proposedTomorrowFocus = jsonSuggested?['tomorrowFocus'] as String?;
        });
      } else if (mounted) {
        setState(() {
          _suggestionQuestion = 'امروز چه درسی برایت داشت و چه چیزی حالِ تو را بهتر کرد؟';
          _suggestionAnalysis = reply.isNotEmpty ? reply : 'آماده ثبت تأمل روزانه‌اید.';
        });
      }
    } catch (e) {
      debugPrint('Error loading AI reflection suggestion: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDraftLoading = false;
        });
      }
    }
  }

  Future<void> _applySuggestion() async {
    Navigator.pop(context);
    unawaited(showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DailyReflectionSheet(
        onSaved: widget.onSaved,
      ),
    ));
    
    if (_proposedWins != null || _proposedGratitude != null || _proposedChallenges != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        final existing = await db.query('daily_reflections', where: 'date = ?', whereArgs: [todayStr]);
        var merged = <String, dynamic>{};
        if (existing.isNotEmpty) {
          merged = Map<String, dynamic>.from(existing.first);
        }

        merged['id'] = 'reflection_$todayStr';
        merged['date'] = todayStr;
        merged['wins'] = merged['wins'] ?? _proposedWins;
        merged['goodThing'] = merged['goodThing'] ?? _proposedWins;
        merged['gratitude'] = merged['gratitude'] ?? _proposedGratitude;
        merged['challenges'] = merged['challenges'] ?? _proposedChallenges;
        merged['learnings'] = merged['learnings'] ?? _proposedLearnings;
        merged['tomorrowFocus'] = merged['tomorrowFocus'] ?? _proposedTomorrowFocus;
        merged['mood_score'] = merged['mood_score'] ?? _proposedMoodScore ?? 3;
        merged['createdAt'] = merged['createdAt'] ?? nowMs;

        await db.insert('daily_reflections', merged, conflictAlgorithm: ConflictAlgorithm.replace);
        widget.onSaved();
      } catch (e) {
        debugPrint('Error saving AI draft reflection: $e');
      }
    }
  }

  Widget _buildActionsSection(Map<String, dynamic> msg, RitmoColors colors) {
    final actionsList = (msg['actions'] as List?)?.cast<ChatAction>() ?? const [];
    if (actionsList.isEmpty) return const SizedBox.shrink();
    return Padding(
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: Icon(icon, size: 16),
            label: Text(
              assistantAction.title,
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              await AssistantActionRegistry.executeAction(
                context,
                assistantAction,
                _loadMessages,
              );
            },
          );
        }).toList(),
      ),
    );
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    _showTopToast(
      'متن پیام کپی شد.',
      Icons.check_circle_rounded,
      const Color(0xff8B5CF6),
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
        onDismiss: () { overlayEntry.remove(); },
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
                          'تاریخچه گفتگوهای دستیار تعادل',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.add, color: Color(0xff8B5CF6), size: 22),
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
                                  selectedColor: const Color(0xff8B5CF6),
                                  title: Text(
                                    sess.summary ?? 'گفتگوی دستیار تعادل',
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
                                      final updated = await ChatRepository.instance.listSessions(chatType: 'wellbeing');
                                      setSheetState(() {
                                        _sessions = updated;
                                      });
                                      if (sess.id == _sessionId) {
                                        if (updated.isNotEmpty) {
                                          _sessionId = updated.first.id;
                                          await _loadMessages();
                                        } else {
                                          await _loadActiveSession();
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
    const primaryColor = Color(0xff8B5CF6);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          height: MediaQuery.of(context).size.height * 0.88,
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(CupertinoIcons.sparkles, color: primaryColor, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'دستیار هوشمند حال و تعادل',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_activeTab == 0)
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
              const SizedBox(height: 8),

              // Segmented tab switch
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 0 ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'گفتگو با دستیار',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 1 ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'پیش‌نویس خودارزیابی',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 24),

              Expanded(
                child: _activeTab == 0 ? _buildChatTab(colors, isDark, primaryColor) : _buildDraftTab(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTab(RitmoColors colors, bool isDark, Color primaryColor) {
    return Column(
      children: [
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
                  setState(() { _messages.removeAt(removedIndex); });
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
                    onUndo: msgId != null ? () {
                      _pendingDeleteTimers[msgId]?.cancel();
                      _pendingDeleteTimers.remove(msgId);
                      _pendingDeletedMsgs.remove(msgId);
                      setState(() {
                        if (removedIndex <= _messages.length) {
                          _messages.insert(removedIndex, removedMsg);
                        } else { _messages.add(removedMsg); }
                      });
                      _scrollToBottom();
                    } : null,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WellbeingMessageBubble(
                      msg: msg,
                      isStreaming: _isStreaming,
                      colors: colors,
                      onCopy: () => _copyToClipboard(msg['content'] as String),
                    ),
                    _buildActionsSection(msg, colors),
                  ],
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
                  const SizedBox(width: 32),
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

        if (_messages.length == 1 && !_isTyping) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                _buildQuickActionChip('⚡ چرا وقتی بد می‌خوابم انرژیم کم است؟'),
                const SizedBox(width: 8),
                _buildQuickActionChip('🧘 چند پیشنهاد خودمراقبتی برای امروز'),
                const SizedBox(width: 8),
                _buildQuickActionChip('🌙 راه‌های بهبود کیفیت خواب و ثبات بیداری چیست؟'),
                const SizedBox(width: 8),
                _buildQuickActionChip('📓 بازتاب روزانه چطور به تعادل زندگی کمک می‌کند؟'),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

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
                      hintText: _isStreaming ? 'دستیار در حال نوشتن است...' : 'سوالی درباره انرژی، خواب یا وضعیت روحی بپرسید...',
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
                  backgroundColor: _isStreaming ? const Color(0xffEF4444) : primaryColor,
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
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }

  Widget _buildDraftTab(RitmoColors colors) {
    if (_isDraftLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'دستیار هوشمند در حال مرور امروز شماست...',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_suggestionQuestion != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💬 سوال تأمل امروز:',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _suggestionQuestion!,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_suggestionAnalysis != null) ...[
            Text(
              '🔍 تحلیل امروز:',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _suggestionAnalysis!,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12.5,
                color: colors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (_proposedWins != null || _proposedGratitude != null || _proposedChallenges != null) ...[
            Text(
              '💡 پیشنهاد پیش‌نویس خودارزیابی:',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_proposedWins != null && _proposedWins!.isNotEmpty)
                    _buildPreviewItem('🏆 دستاورد پیشنهادی:', _proposedWins!, colors),
                  if (_proposedGratitude != null && _proposedGratitude!.isNotEmpty)
                    _buildPreviewItem('💖 شکرگزاری پیشنهادی:', _proposedGratitude!, colors),
                  if (_proposedChallenges != null && _proposedChallenges!.isNotEmpty)
                    _buildPreviewItem('⚡ چالش پیشنهادی:', _proposedChallenges!, colors),
                  if (_proposedLearnings != null && _proposedLearnings!.isNotEmpty)
                    _buildPreviewItem('📚 یادگیری پیشنهادی:', _proposedLearnings!, colors),
                  if (_proposedTomorrowFocus != null && _proposedTomorrowFocus!.isNotEmpty)
                    _buildPreviewItem('🎯 تمرکز فردا پیشنهادی:', _proposedTomorrowFocus!, colors),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _applySuggestion,
                  icon: const Icon(CupertinoIcons.checkmark_alt, size: 18),
                  label: const Text(
                    'اعمال پیش‌نویس و ویرایش',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'انصراف',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String text, RitmoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xff8B5CF6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class WellbeingMessageBubble extends StatefulWidget {

  const WellbeingMessageBubble({
    super.key,
    required this.msg,
    required this.isStreaming,
    required this.colors,
    required this.onCopy,
  });
  final Map<String, dynamic> msg;
  final bool isStreaming;
  final RitmoColors colors;
  final VoidCallback onCopy;

  @override
  State<WellbeingMessageBubble> createState() => _WellbeingMessageBubbleState();
}

class _WellbeingMessageBubbleState extends State<WellbeingMessageBubble> {
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
    const primaryColor = Color(0xff8B5CF6);

    final bubbleBg = isUser
        ? primaryColor
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

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    final ms = widget.onUndo != null ? 5200 : 2200;
    _dismissTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted) _controller.reverse().then((_) => widget.onDismiss());
    });
    if (widget.onUndo != null) {
      _secondsLeft = 5;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) { setState(() { _secondsLeft--; }); if (_secondsLeft <= 0) t.cancel(); } else { t.cancel(); }
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
      top: 64, left: 0, right: 0,
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
                    color: isDark ? const Color(0xff1E2235).withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 12, offset: const Offset(0, 3))],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: widget.iconColor, size: 16),
                        const SizedBox(width: 6),
                        Text(widget.message, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11.5, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                        if (widget.onUndo != null) ...[const SizedBox(width: 10), Container(width: 1, height: 16, color: colors.textSecondary.withValues(alpha: 0.25)), const SizedBox(width: 10),
                          GestureDetector(onTap: _handleUndo, child: Text('لغو ($_secondsLeft)', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xff60A5FA)))),
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
