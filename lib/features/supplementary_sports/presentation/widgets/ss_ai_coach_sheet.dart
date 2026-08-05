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
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/assistant/logic/assistant_action_registry.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';

class SSAiCoachSheet extends StatefulWidget {
  const SSAiCoachSheet({super.key});
  static String? prefilledMessage;

  @override
  State<SSAiCoachSheet> createState() => _SSAiCoachSheetState();
}

class _SSAiCoachSheetState extends State<SSAiCoachSheet> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isStreaming = false;
  String _sportsContext = '';
  String? _sessionId;
  List<ChatSession> _sessions = [];
  StreamSubscription<String>? _sportsSubscription;
  final Map<String, Timer> _pendingDeleteTimers = {};
  final Map<String, Map<String, dynamic>> _pendingDeletedMsgs = {};

  @override
  void initState() {
    super.initState();
    _loadSportsContext().then((_) => _loadActiveSession()).then((_) {
      if (SSAiCoachSheet.prefilledMessage != null) {
        final msg = SSAiCoachSheet.prefilledMessage!;
        SSAiCoachSheet.prefilledMessage = null;
        _sendMessage(msg);
      }
    });
  }

  @override
  void dispose() {
    if (_sessionId != null) {
      AssistantMemoryBinding.triggerConsolidation(
        sessionId: _sessionId!,
        domain: 'sports',
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
    _sportsSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSportsContext() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Fetch user profile
      final profileMapList = await db.query('ss_user_profile', limit: 1);
      if (profileMapList.isEmpty) return;
      final profile = SsUserProfile.fromMap(profileMapList.first);

      // 2. Fetch plans & exercises crossref
      final plans = await db.query('ss_workout_plan');
      final crossRefs = await db.query('ss_workout_exercise_crossref');
      final exercises = await db.query('ss_exercise');
      final exMap = {for (final ex in exercises) ex['id'].toString(): ex};

      final buffer = StringBuffer();
      buffer.writeln('پرونده ورزشی کاربر:');
      buffer.writeln('- هدف فیتنس: ${profile.goal.name}');
      buffer.writeln('- سطح تجربه: ${profile.experienceLevel.name}');
      buffer.writeln('- محل تمرین: ${profile.trainingLocation.name}');
      buffer.writeln('- تجهیزات در دسترس: ${profile.availableEquipment.map((e) => e.name).join(', ')}');
      buffer.writeln('- روزهای تمرین در هفته: ${profile.daysPerWeek}');
      var durationStr = 'نامشخص';
      switch (profile.sessionDuration) {
        case SessionDuration.short30: durationStr = '۳۰';
        case SessionDuration.medium45: durationStr = '۴۵';
        case SessionDuration.long60: durationStr = '۶۰';
        case SessionDuration.flexible: durationStr = 'منعطف';
      }
      buffer.writeln('- مدت زمان هر جلسه: $durationStr دقیقه');
      buffer.writeln('- محدودیت‌های بدنی: ${profile.physicalLimitations.map((e) => e.name).join(', ')}');
      if (profile.limitationNote != null && profile.limitationNote!.isNotEmpty) {
        buffer.writeln('- یادداشت محدودیت: ${profile.limitationNote}');
      }
      buffer.writeln('- وضعیت تمرین بی‌صدا (آپارتمانی): ${profile.neighborFriendly ? "فعال" : "غیرفعال"}');

      buffer.writeln('\nبرنامه تمرینی فعلی کاربر (هفته فعال):');
      if (plans.isEmpty) {
        buffer.writeln('هیچ برنامه تمرینی فعالی ثبت نشده است.');
      } else {
        for (final p in plans) {
          final planId = p['id'].toString();
          final dayOfWeek = p['dayOfWeek']! as int;
          final muscleGroups = p['muscleGroups'].toString();
          final estMin = p['estimatedMinutes'] as int? ?? 30;
          
          buffer.writeln('روز $dayOfWeek - تمرکز عضلانی: $muscleGroups ($estMin دقیقه):');
          
          final dayCrossRefs = crossRefs.where((c) => c['planId'] == planId).toList()
            ..sort((a, b) => (a['orderIndex']! as int).compareTo(b['orderIndex']! as int));
            
          if (dayCrossRefs.isEmpty) {
            buffer.writeln('  بدون حرکت تمرینی.');
          } else {
            for (final c in dayCrossRefs) {
              final exId = c['exerciseId'].toString();
              final ex = exMap[exId];
              final name = ex != null ? ex['name']! as String : 'حرکت ناشناخته';
              final sets = c['targetSets'] as int? ?? 3;
              final reps = c['targetReps'] as int? ?? 10;
              final weight = c['targetWeight'] as double?;
              final weightStr = weight != null ? ' با وزنه $weight کیلوگرم' : '';
              buffer.writeln('  - $name (شناسه حرکت: $exId) - $sets ست، $reps تکرار$weightStr');
            }
          }
        }
      }

      // 3. Cognitive memory prompt suffix is appended dynamically when sending messages.

      setState(() {
        _sportsContext = buffer.toString();
      });
    } catch (e) {
      debugPrint('Error loading AI sports context: $e');
    }
  }

  Future<void> _loadActiveSession() async {
    try {
      _sessions = await ChatRepository.instance.listSessions(chatType: 'sports');
      if (_sessions.isEmpty) {
        final newSess = await ChatRepository.instance.createSession(chatType: 'sports');
        _sessions = [newSess];
        _sessionId = newSess.id;
        final initMsg = ChatMessage(
          id: 'init_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: _sessionId!,
          role: ChatRole.assistant,
          content: 'سلام! من مربی هوشمند ریتمو هستم. چطور می‌توانم در تنظیم حرکات ورزشی، بهبود برنامه تمرینی، تغذیه ورزشی یا بهینه‌سازی مدت جلسات کمکتان کنم؟ 🏃‍♂️',
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
      final newSess = await ChatRepository.instance.createSession(chatType: 'sports');
      _sessionId = newSess.id;
      _sessions = await ChatRepository.instance.listSessions(chatType: 'sports');
      
      final initMsg = ChatMessage(
        id: 'init_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _sessionId!,
        role: ChatRole.assistant,
        content: 'سلام! من مربی هوشمند ریتمو هستم. چطور می‌توانم در تنظیم حرکات ورزشی، بهبود برنامه تمرینی، تغذیه ورزشی یا بهینه‌سازی مدت جلسات کمکتان کنم؟ 🏃‍♂️',
        timestamp: DateTime.now(),
      );
      await ChatRepository.instance.addMessage(initMsg);
      await _loadMessages();
    } catch (e) {
      debugPrint('Error starting new session: $e');
    }
  }

  void _cancelStreaming() {
    _sportsSubscription?.cancel();
    _sportsSubscription = null;
    setState(() {
      _isStreaming = false;
      _isTyping = false;
    });
  }

  Future<void> _handleAction(ChatAction action) async {
    await HapticFeedback.mediumImpact();
    if (action.type == 'openPage' && action.targetRoute != null && context.mounted) {
      unawaited(Navigator.pushNamed(context, action.targetRoute!));
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    var detailText = '';
    if (action.type == 'swapExercise') {
      final oldId = action.payload['oldExerciseId']?.toString() ?? '';
      final newId = action.payload['newExerciseId']?.toString() ?? '';
      final db = await DatabaseHelper.instance.database;
      final oldEx = await db.query('ss_exercise', where: 'id = ?', whereArgs: [oldId], limit: 1);
      final newEx = await db.query('ss_exercise', where: 'id = ?', whereArgs: [newId], limit: 1);
      final oldName = oldEx.isNotEmpty ? oldEx.first['name']! as String : 'حرکت قدیمی';
      final newName = newEx.isNotEmpty ? newEx.first['name']! as String : 'حرکت جدید';
      detailText = 'تعویض حرکت "$oldName" با حرکت مشابه "$newName"';
    } else if (action.type == 'adjustWorkoutIntensity') {
      final dur = action.payload['sessionDuration']?.toString();
      final intensity = action.payload['intensity']?.toString();
      final parts = <String>[];
      if (dur != null) parts.add('مدت زمان جلسه: $dur دقیقه');
      if (intensity != null) parts.add('شدت/سطح برنامه: $intensity');
      detailText = 'به‌روزرسانی تنظیمات برنامه (${parts.join(' و ')})';
    } else {
      detailText = action.label;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: isDark
                ? BorderSide(color: colors.primary.withValues(alpha: 0.2), width: 1.5)
                : BorderSide.none,
          ),
          backgroundColor: isDark ? const Color(0xff08090C) : Colors.white,
          title: Row(
            children: [
              Icon(
                CupertinoIcons.sparkles,
                color: colors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'تایید نهایی تغییرات',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'آیا می‌خواهید تغییرات پیشنهادی مربی هوشمند را روی برنامه تمرینی خود اعمال کنید؟',
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
                child: Text(
                  detailText,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                    height: 1.4,
                  ),
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
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
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

    if (!mounted || confirmed != true) return;

    await AssistantActionRegistry.executeAction(
      context,
      action.toAssistantAction(),
      _loadSportsContext,
    );
  }

  // Removed legacy _processMemoryTags

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
شما مربی هوشمند، دلسوز و مجرب ورزشی در برنامه ریتمو (با فونت وزیری و زبان فارسی) هستید.
وظیفه شما پاسخ‌گویی به سوالات ورزشی، تناسب اندام، تغذیه ورزشی و کمک به کاربر در بهبود و تنظیم برنامه‌های ورزشی و حرکات تکمیلی است.
لحن شما باید بسیار مشوق، گرم، باانگیزه و مثبت باشد.

    قوانین سخت‌گیرانه ایمنی و سلامتی:
۱. در صورت بروز هرگونه درد حاد، سوزش، مصدومیت یا احساس ناراحتی شدید در مفاصل و عضلات، بلافاصله از کاربر بخواهید تمرین را متوقف کرده و به پزشک مراجعه کند. از ارائه هرگونه تشخیص پزشکی، تجویز دارو یا درمان‌های تخصصی خودداری فرمایید.
۲. شما اجازه تجویز رژیم‌های دارویی، استروئیدی، پپتیدها یا مکمل‌های تخصصی پزشکی را ندارید؛ صرفاً می‌توانید توصیه‌های کلی و عمومی در مورد تغذیه ورزشی (مانند پروتئین کافی، کربوهیدرات برای انرژی و هیدراتاسیون) ارائه دهید.
۳. پیشنهاد تعویض حرکات یا تنظیم سختی فقط و فقط باید روی شناسه‌های حرکتی واقعی که در "پرونده ورزشی کاربر" در زیر آمده است انجام شود. از شناسه‌های فرضی استفاده نکنید.


    عملیات هوشمند (Actions):
هر زمان کاربر از شما خواست حرکتی را تعویض کند یا سختی تمرین را افزایش/کاهش دهد، باید در انتهای پاسخ خود تگ <actions> حاوی یک آرایه JSON شامل عملیات مناسب را تولید کنید.

قوانین ساخت تگ <actions> برای ورزش:
۱. تعویض حرکت (swapExercise):
اگر کاربر خواست حرکتی را با حرکت دیگری تعویض کند (مثلاً "حرکت شنا را با شنای سوئدی یا حرکت ساده‌تری جایگزین کن")، تگ <actions> با نوع "swapExercise" تولید کنید:
<actions>
[
  {
    "type": "swapExercise",
    "label": "جایگزینی حرکت شنا با شنا زانو",
    "payload": {
      "oldExerciseId": "<شناسه حرکت قدیمی از لیست کاربر>",
      "newExerciseId": "<شناسه حرکت جدید و مشابه از دیتابیس>"
    }
  }
]
</actions>

۲. تنظیم شدت و مدت جلسه (adjustWorkoutIntensity):
اگر کاربر خواست زمان تمرین را تغییر دهد یا سطح سختی را بالا/پایین ببرد (مثلاً "زمان تمرینم رو بکن ۴۵ دقیقه" یا "شدت برنامه‌ام را سبک‌تر کن")، تگ <actions> با نوع "adjustWorkoutIntensity" تولید کنید:
<actions>
[
  {
    "type": "adjustWorkoutIntensity",
    "label": "تعدیل تنظیمات شدت برنامه تمرینی",
    "payload": {
      "sessionDuration": "45",
      "intensity": "LIGHT/MEDIUM/HARD"
    }
  }
]
</actions>
فیلدهای payload برای adjustWorkoutIntensity اختیاری هستند و فقط در صورت درخواست کاربر ارسال می‌شوند (مثلاً sessionDuration می‌تواند "15", "30", "45", "60" باشد و intensity می‌تواند "LIGHT", "MEDIUM", "HARD" باشد).

۳. هدایت به سایر بخش‌های برنامه (openPage):
اگر کاربر درخواستی خارج از حوزه ورزش داشت، او را راهنمایی کرده و تگ <actions> با نوع "openPage" و مسیر مربوطه را قرار دهید:
<actions>
[
  {
    "type": "openPage",
    "label": "ورود به بخش خواب",
    "targetRoute": "/sleep"
  }
]
</actions>
مسیرهای معتبر برنامه جهت هدایت:
- بخش عبادت و معنویت: /worship
- بخش چرخه بدنی و قاعدگی: /cycle
- بخش خواب: /sleep
- بخش سلامت و داروها: /health
- برنامه‌ریزی کنکور: /konkur
- تقویم: /calendar
- روتین‌ها: /routines
- اهداف: /goals

تگ <actions> را دقیقاً به همین فرمت تولید کنید و فقط زمانی استفاده کنید که کاربر صراحتاً درخواست اعمال تغییر دارد.

پرونده ورزشی کاربر:
$_sportsContext
''';

      final memorySuffix = await AssistantMemoryBinding.getSystemPromptSuffix(
        domain: 'sports',
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
        
        _sportsSubscription = stream.listen(
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
              
              // Process cognitive memory updates
              // Process cognitive memory updates using shared binding helper
              await AssistantMemoryBinding.processResponse(
                sessionId: _sessionId!,
                domain: 'sports',
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

              // Reload sports context to ensure next turn includes updated memories
              await _loadSportsContext();

              final updated = await ChatRepository.instance.listSessions(chatType: 'sports');
              setState(() {
                _sessions = updated;
              });
            }
          },
          cancelOnError: true,
        );
      }
    } catch (e) {
      debugPrint('Error calling AI Sports API: $e');
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
      context.colors.primary,
    );
  }

  void _showTopToast(String message, IconData icon, Color iconColor, {VoidCallback? onUndo}) {
    RitmoToast.show(context, message, icon: icon, iconColor: iconColor, onUndo: onUndo);
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
                          'تاریخچه گفتگوهای مربیگری',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.add, color: colors.primary, size: 22),
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
                                  selectedColor: colors.primary,
                                  title: Text(
                                    sess.summary ?? 'گفتگوی مربیگری',
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
                                      final updated = await ChatRepository.instance.listSessions(chatType: 'sports');
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
                  Row(
                    children: [
                      Icon(CupertinoIcons.heart_circle_fill, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'مربی هوشمند ریتمو',
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

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final msgId = (msg['id'] ?? 'temp_${index}_${msg['role']}').toString();
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
                      child: SportsMessageBubble(
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
                      _buildQuickActionChip('📉 این هفته را سبک‌تر کن'),
                      const SizedBox(width: 8),
                      _buildQuickActionChip('🔄 یک حرکت جایگزین بده'),
                      const SizedBox(width: 8),
                      _buildQuickActionChip('🍎 تغذیه بعد تمرین چی باشه؟'),
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
                            hintText: _isStreaming ? 'مربی در حال تایپ است...' : 'سوالی درباره ورزش بپرسید یا برنامه‌ای بخواهید...',
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
                        backgroundColor: _isStreaming ? const Color(0xffEF4444) : colors.primary,
                        child: Icon(
                          _isStreaming ? CupertinoIcons.stop_fill : CupertinoIcons.arrow_up,
                          color: Colors.white,
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

class SportsMessageBubble extends StatefulWidget {

  const SportsMessageBubble({
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
  State<SportsMessageBubble> createState() => _SportsMessageBubbleState();
}

class _SportsMessageBubbleState extends State<SportsMessageBubble> {
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
        ? colors.primary
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
                    color: isUser ? Colors.white : colors.textPrimary,
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
