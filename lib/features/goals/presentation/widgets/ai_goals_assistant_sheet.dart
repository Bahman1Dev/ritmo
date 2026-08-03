import 'dart:async';
import 'dart:convert';
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
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/assistant/logic/assistant_action_registry.dart';
import 'package:ritmo/features/goals/logic/goals_repository.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_formatters.dart';

class AiGoalsAssistantSheet extends StatefulWidget {

  const AiGoalsAssistantSheet({
    super.key,
    required this.onSaved,
  });
  final VoidCallback onSaved;

  @override
  State<AiGoalsAssistantSheet> createState() => _AiGoalsAssistantSheetState();
}

class _AiGoalsAssistantSheetState extends State<AiGoalsAssistantSheet> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isStreaming = false;
  String _goalsContext = '';
  String? _sessionId;
  List<ChatSession> _sessions = [];
  StreamSubscription<String>? _goalsSubscription;
  final Map<String, Timer> _pendingDeleteTimers = {};
  final Map<String, Map<String, dynamic>> _pendingDeletedMsgs = {};
  OverlayEntry? _toastOverlay;

  @override
  void initState() {
    super.initState();
    _loadGoalsContext().then((_) => _loadActiveSession());
  }

  @override
  void dispose() {
    if (_sessionId != null) {
      AssistantMemoryBinding.triggerConsolidation(
        sessionId: _sessionId!,
        domain: 'goals',
      );
    }
    _toastOverlay?.remove();
    for (final timer in _pendingDeleteTimers.values) {
      timer.cancel();
    }
    for (final msgId in _pendingDeletedMsgs.keys) {
      ChatRepository.instance.deleteMessage(msgId);
    }
    _pendingDeleteTimers.clear();
    _pendingDeletedMsgs.clear();
    _goalsSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showTopToast(String msg, IconData icon, Color color, {VoidCallback? onUndo}) {
    _toastOverlay?.remove();
    _toastOverlay = OverlayEntry(
      builder: (context) => _TopToastWidget(
        message: msg,
        icon: icon,
        iconColor: color,
        onDismiss: () {
          _toastOverlay?.remove();
          _toastOverlay = null;
        },
        onUndo: onUndo,
      ),
    );
    Overlay.of(context).insert(_toastOverlay!);
  }

  Future<void> _loadGoalsContext() async {
    try {
      final repo = GoalsRepository.instance;
      final goals = await repo.getGoals();
      final activeGoals = goals.where((g) => g.status == 'ACTIVE').toList();

      final buffer = StringBuffer();
      buffer.writeln('وضعیت اهداف فعلی کاربر:');
      if (activeGoals.isEmpty) {
        buffer.writeln('- کاربر در حال حاضر هیچ هدف فعال ثبت‌شده‌ای ندارد.');
      } else {
        for (final g in activeGoals) {
          buffer.writeln('- هدف: "${g.title}" (${g.goalType.label}) · مهلت: ${g.targetDate ?? "نامشخص"}');
        }
      }

      setState(() {
        _goalsContext = buffer.toString();
      });
    } catch (e) {
      debugPrint('Error loading AI goals context: $e');
    }
  }

  Future<void> _loadActiveSession() async {
    try {
      _sessions = await ChatRepository.instance.listSessions(chatType: 'goals');
      if (_sessions.isEmpty) {
        final newSess = await ChatRepository.instance.createSession(chatType: 'goals');
        _sessions = [newSess];
        _sessionId = newSess.id;
        final initMsg = ChatMessage(
          id: 'init_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: _sessionId!,
          role: ChatRole.assistant,
          content: 'سلام! من دستیار هوشمند هدف‌گذاری و برنامه‌ریزی ریتمو هستم. 🎯\nهدف جدیدی در ذهن دارید؟ آن را با من مطرح کنید تا با هم بررسی کنیم چقدر زمان نیاز دارد، چطور می‌توان آن را به گام‌های کوچک تقسیم کرد و یک نقشه راه شخصی‌سازی‌شده برایش بسازیم! 🚀',
          timestamp: DateTime.now(),
        );
        await ChatRepository.instance.addMessage(initMsg);
      } else {
        _sessionId = _sessions.first.id;
      }
      await _loadMessages();
    } catch (e) {
      debugPrint('Error starting new session: $e');
    }
  }

  Future<void> _handleAction(ChatAction action) async {
    await HapticFeedback.mediumImpact();
    if (action.type == 'openPage') {
      final route = action.targetRoute ?? action.payload['targetRoute']?.toString();
      if (route != null && route.isNotEmpty && context.mounted) {
        unawaited(Navigator.pushNamed(context, route));
      }
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

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
              const Icon(CupertinoIcons.sparkles, color: Color(0xffD4A843), size: 20),
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
          content: Text(
            'آیا می‌خواهید عملیات "${action.label}" را با تنظیمات پیشنهادی اعمال و فعال کنید؟',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.5,
            ),
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
      _loadGoalsContext,
    );
  }

  Widget _buildActionsSection(Map<String, dynamic> msg, RitmoColors colors) {
    final actionsList = (msg['actions'] as List?)?.cast<ChatAction>() ?? const [];
    if (actionsList.isEmpty) return const SizedBox.shrink();

    final isUser = msg['role'] == 'user';

    return Padding(
      padding: EdgeInsets.only(top: 4, bottom: 8, right: isUser ? 8 : 32, left: isUser ? 32 : 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
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
              onPressed: () => _handleAction(action),
            );
          }).toList(),
        ),
      ),
    );
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
      final newSess = await ChatRepository.instance.createSession(chatType: 'goals');
      _sessionId = newSess.id;
      _sessions = await ChatRepository.instance.listSessions(chatType: 'goals');
      
      final initMsg = ChatMessage(
        id: 'init_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _sessionId!,
        role: ChatRole.assistant,
        content: 'سلام! من دستیار هوشمند هدف‌گذاری و برنامه‌ریزی ریتمو هستم. 🎯\nهدف جدیدی در ذهن دارید؟ آن را با من مطرح کنید تا با هم بررسی کنیم چقدر زمان نیاز دارد، چطور می‌توان آن را به گام‌های کوچک تقسیم کرد و یک نقشه راه شخصی‌سازی‌شده برایش بسازیم! 🚀',
        timestamp: DateTime.now(),
      );
      await ChatRepository.instance.addMessage(initMsg);
      await _loadMessages();
    } catch (e) {
      debugPrint('Error starting new session: $e');
    }
  }

  void _cancelStreaming() {
    _goalsSubscription?.cancel();
    _goalsSubscription = null;
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
شما دستیار هوشمند و مجرب برنامه‌ریزی و هدف‌گذاری برنامه ریتمو (با فونت وزیری و زبان فارسی) هستید.
وظیفه شما گفتگو با کاربر، درک اهداف او، خرد کردن اهداف بزرگ به گام‌های کوچک، پیشنهاد زمان‌بندی و ددلاین‌های شمسی و بررسی اتصالات روتین‌ها است.

قوانین گفتگو:
۱. با لحن صمیمانه، تشویق‌کننده و در عین حال حرفه‌ای با کاربر گفتگو کنید.
۲. با پرسیدن ۲ الی ۳ سوال هدف اصلی او را شفاف کنید. بفهمید هدفش چقدر بزرگ است، چه گام‌هایی در نظر دارد و چه مدت زمانی برای انجام آن می‌خواهد. از کاربر سوالات متوالی بپرسید تا جزئیات مشخص شوند.
۳. اطلاعات مربوط به اهداف فعلی کاربر را در زیر دریافت می‌کنید؛ مواظب باشید با اهداف قبلی تداخل نداشته باشد:
$_goalsContext

۴. زمانی که روی گام‌ها و مهلت انجام توافق شد، شما باید یک خلاصه یا پروپوزال نهایی برای هدف آماده کنید و در انتهای پیام خود، دقیقاً تگ زیر را با مقادیر JSON معتبر خروجی دهید:
[GOAL_PROPOSAL]
{
  "title": "عنوان هدف به فارسی",
  "goalLevel": "DAILY" | "WEEKLY" | "MONTHLY" | "YEARLY",
  "targetDate": "YYYY-MM-DD",
  "steps": [
    {"title": "عنوان گام اول", "offsetDays": 1},
    {"title": "عنوان گام دوم", "offsetDays": 3}
  ]
}
[/GOAL_PROPOSAL]

نکته بسیار مهم: مقدار "targetDate" باید به صورت میلادی YYYY-MM-DD محاسبه و قرار گیرد. برای مثال اگر کاربر هدف ماهانه انتخاب کرد، تاریخ ۳۰ روز بعد را قرار دهید. offsetDays نشان دهنده تعداد روزهای فاصله از امروز برای برنامه‌ریزی هر گام است. تگ GOAL_PROPOSAL حتماً باید دقیقاً به شکل بالا و با متغیرهای درست پر شود تا سیستم بتواند کارت ثبت تعاملی را به کاربر نمایش دهد.

قانون ویرایش اهداف:
اگر کاربر خواست عنوان، توضیحات یا دورهٔ زمانی یکی از اهداف موجود را ویرایش یا تغییر دهد، باید تگ <actions> با نوع "editGoal" تولید کنید:

<actions>
[
  {
    "type": "editGoal",
    "label": "ویرایش هدف",
    "payload": {
      "goalId": "شناسه_هدف_مورد_نظر",
      "title": "عنوان جدید هدف",
      "description": "توضیحات جدید هدف (اختیاری)",
      "goalType": "DAILY"
    }
  }
]
</actions>

قانون هدایت به سایر بخش‌های برنامه:
اگر کاربر درخواستی خارج از حوزه برنامه‌ریزی اهداف ثبت کرد (مثلا خواستار ثبت نماز قضا، یادآور مذهبی، تنظیمات سلامت، خواب، ورزش و فعالیت بدنی، یا کنکور شد)، باید در انتهای پاسخ خود کاربر را راهنمایی کرده و تگ <actions> با نوع "openPage" و مسیر مربوطه را قرار دهید تا دکمه هدایت برای وی نمایش داده شود:

<actions>
[
  {
    "type": "openPage",
    "label": "ورود به بخش عبادات",
    "targetRoute": "/worship"
  }
]
</actions>

مسیرهای معتبر برنامه:
- بخش عبادات: /worship
- بخش خواب: /sleep
- بخش سلامت و داروها: /health
- بخش ورزش و تمرینات: /sports
- برنامه‌ریزی کنکور: /konkur
- تقویم: /calendar
- روتین‌ها: /routines
- اهداف: /goals
''';

      final memorySuffix = await AssistantMemoryBinding.getSystemPromptSuffix(
        domain: 'goals',
        query: query,
      );

      final history = await ChatRepository.instance.getMessages(_sessionId!);
      final messagesPayload = <Map<String, String>>[];
      messagesPayload.add({'role': 'system', 'content': systemPrompt + memorySuffix});
      for (final m in history) {
        messagesPayload.add({'role': m.role.name, 'content': m.content});
      }

      setState(() {
        _isStreaming = true;
        _isTyping = false;
        _messages.add({
          'id': 'msg_streaming',
          'role': 'assistant',
          'content': '',
          'actions': const [],
        });
      });

      final assistantMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_a';
      final buffer = StringBuffer();
      
      _goalsSubscription = AIGateway.instance
          .sendStreamingCompletion(messages: messagesPayload)
          .listen(
        (chunk) {
          if (chunk.startsWith('error:')) {
            _cancelStreaming();
            if (mounted) {
              _showTopToast('خطا در ارتباط با هوش مصنوعی', CupertinoIcons.exclamationmark_triangle, Colors.redAccent);
            }
            return;
          }
          buffer.write(chunk);
          final tempParsed = ChatActionParser.parse(buffer.toString());
          setState(() {
            final idx = _messages.indexWhere((m) => m['id'] == 'msg_streaming');
            if (idx != -1) {
              _messages[idx]['content'] = tempParsed.cleanText;
              _messages[idx]['actions'] = tempParsed.actions;
            }
          });
          _scrollToBottom();
        },
        onDone: () async {
          final content = buffer.toString();
          
          await AssistantMemoryBinding.processResponse(
            sessionId: _sessionId!,
            domain: 'goals',
            userText: query,
            rawResponse: content,
          );

          setState(() {
            _isStreaming = false;
            _isTyping = false;
            final idx = _messages.indexWhere((m) => m['id'] == 'msg_streaming');
            if (idx != -1) {
              _messages[idx]['id'] = assistantMsgId;
              _messages[idx]['content'] = content;
            }
          });

          final assistantMsg = ChatMessage(
            id: assistantMsgId,
            sessionId: _sessionId!,
            role: ChatRole.assistant,
            content: content,
            timestamp: DateTime.now(),
          );
          await ChatRepository.instance.addMessage(assistantMsg);
          _goalsSubscription = null;
        },
        onError: (e) {
          _cancelStreaming();
          debugPrint('Stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Error sending AI message: $e');
      setState(() {
        _isTyping = false;
        _isStreaming = false;
      });
    }
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
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'تاریخچه گفتگوهای هدف‌گذاری',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        TextButton.icon(
                          icon: const Icon(CupertinoIcons.add, size: 14),
                          label: const Text('گفتگوی جدید', style: TextStyle(fontFamily: 'Vazirmatn')),
                          onPressed: () async {
                            Navigator.pop(context);
                            await _startNewSession();
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    Expanded(
                      child: _sessions.isEmpty
                          ? const Center(child: Text('هیچ گفتگویی ثبت نشده است.', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white38)))
                          : ListView.builder(
                              itemCount: _sessions.length,
                              itemBuilder: (context, index) {
                                final sess = _sessions[index];
                                final isSelected = sess.id == _sessionId;
                                return ListTile(
                                  selected: isSelected,
                                  selectedColor: colors.primary,
                                  title: Text(
                                    sess.summary ?? 'جلسه گفتگو',
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
                                      final updated = await ChatRepository.instance.listSessions(chatType: 'goals');
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

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    HapticFeedback.lightImpact();
    _showTopToast('پیام کپی شد.', CupertinoIcons.doc_on_doc, const Color(0xff10B981));
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
                      Icon(CupertinoIcons.wand_stars, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'دستیار هوشمند هدف‌گذاری',
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
                        final targetId = removedMsg['id'] as String?;

                        setState(() {
                          _messages.removeAt(removedIndex);
                        });

                        if (targetId != null) {
                          _pendingDeletedMsgs[targetId] = removedMsg;
                          final t = Timer(const Duration(seconds: 5), () async {
                            await ChatRepository.instance.deleteMessage(targetId);
                            _pendingDeleteTimers.remove(targetId);
                            _pendingDeletedMsgs.remove(targetId);
                          });
                          _pendingDeleteTimers[targetId] = t;
                        }

                        _showTopToast(
                          'پیام حذف شد.',
                          CupertinoIcons.trash,
                          Colors.redAccent,
                          onUndo: targetId != null
                              ? () {
                                  _pendingDeleteTimers[targetId]?.cancel();
                                  _pendingDeleteTimers.remove(targetId);
                                  _pendingDeletedMsgs.remove(targetId);
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GoalsMessageBubble(
                            msg: msg,
                            isStreaming: _isStreaming,
                            colors: colors,
                            onCopy: () => _copyToClipboard(msg['content'] as String),
                            onGoalSaved: widget.onSaved,
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
                      _buildQuickActionChip('🎯 برنامه‌ریزی برای یادگیری زبان انگلیسی'),
                      const SizedBox(width: 8),
                      _buildQuickActionChip('💸 هدف‌گذاری پس‌انداز خرید ماشین'),
                      const SizedBox(width: 8),
                      _buildQuickActionChip('💻 شروع یک پروژه شخصی جدید'),
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
                            hintText: _isStreaming ? 'دستیار در حال نوشتن است...' : 'هدف خود را بنویسید...',
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

class GoalsMessageBubble extends StatefulWidget {

  const GoalsMessageBubble({
    super.key,
    required this.msg,
    required this.isStreaming,
    required this.colors,
    required this.onCopy,
    required this.onGoalSaved,
  });
  final Map<String, dynamic> msg;
  final bool isStreaming;
  final RitmoColors colors;
  final VoidCallback onCopy;
  final VoidCallback onGoalSaved;

  @override
  State<GoalsMessageBubble> createState() => _GoalsMessageBubbleState();
}

class _GoalsMessageBubbleState extends State<GoalsMessageBubble> {
  bool _isCopied = false;
  Timer? _copiedTimer;
  bool _isGoalCreated = false;

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

    final rawContent = widget.msg['content'].toString();

    var displayText = rawContent;
    Map<String, dynamic>? goalProposal;
    
    if (rawContent.contains('[GOAL_PROPOSAL]') && rawContent.contains('[/GOAL_PROPOSAL]')) {
      final startIndex = rawContent.indexOf('[GOAL_PROPOSAL]');
      final endIndex = rawContent.indexOf('[/GOAL_PROPOSAL]');
      
      displayText = rawContent.substring(0, startIndex).trim();
      final jsonPart = rawContent.substring(startIndex + '[GOAL_PROPOSAL]'.length, endIndex).trim();
      
      try {
        goalProposal = jsonDecode(jsonPart);
      } catch (e) {
        debugPrint('Failed to parse proposed goal JSON: $e');
      }
    }

    final showCopy = !widget.isStreaming && displayText.isNotEmpty;

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
            color: _isCopied ? const Color(0xff10B981) : colors.textSecondary.withValues(alpha: 0.45),
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
            : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: displayText.trim().isEmpty
          ? const _TypingIndicator()
          : Text(
              displayText,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13.5,
                color: isUser ? Colors.white : colors.textPrimary,
                height: 1.4,
              ),
            ),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (displayText.isNotEmpty || !isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: isUser
                    ? [
                        Flexible(child: bubbleContainer),
                        if (showCopy) copyButton else const SizedBox(width: 32),
                      ]
                    : [
                        if (showCopy) copyButton else const SizedBox(width: 32),
                        Flexible(child: bubbleContainer),
                      ],
              ),

            if (goalProposal != null) ...[
              const SizedBox(height: 10),
              _buildProposalCard(context, goalProposal, colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProposalCard(BuildContext context, Map<String, dynamic> proposal, RitmoColors colors) {
    final title = proposal['title'] ?? 'بدون عنوان';
    final desc = proposal['description'] ?? '';
    final type = proposal['goalType'] ?? 'MONTHLY';
    final targetDate = proposal['targetDate'];
    final rawSteps = proposal['steps'] as List<dynamic>? ?? [];

    final level = GoalLevel.fromString(type);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'پیشنهاد هدف جدید',
                style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', color: colors.primary, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  level.label,
                  style: TextStyle(fontSize: 9.5, fontFamily: 'Vazirmatn', color: colors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14.5, fontFamily: 'Vazirmatn', color: colors.textPrimary, fontWeight: FontWeight.bold),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(fontSize: 11.5, fontFamily: 'Vazirmatn', color: colors.textSecondary),
            ),
          ],
          if (targetDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(CupertinoIcons.calendar, size: 12, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'مهلت: ${formatShamsiDate(targetDate as String)}',
                  style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', color: colors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],

          if (rawSteps.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 16),
            Text(
              'مراحل اجرایی پیشنهادی:',
              style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', color: colors.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...rawSteps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              final stepTitle = step['title'] ?? '';
              final offsetDays = step['offsetDays'] ?? 0;
              final dateLabel = formatShamsiDate(DateTime.now().add(Duration(days: offsetDays)).toIso8601String().substring(0, 10));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${toPersianDigits(idx + 1)}. $stepTitle ($dateLabel)',
                        style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(_isGoalCreated ? CupertinoIcons.checkmark_alt : CupertinoIcons.check_mark_circled, size: 14),
              label: Text(
                _isGoalCreated ? 'هدف با موفقیت ثبت شد' : 'تایید و ثبت هدف',
                style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isGoalCreated ? colors.success : colors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isGoalCreated
                  ? null
                  : () async {
                      final repo = GoalsRepository.instance;
                      final navigator = Navigator.of(context);
                      
                      final finalSteps = <Map<String, dynamic>>[];
                      for (final s in rawSteps) {
                        final offset = s['offsetDays'] as int? ?? 0;
                        final dateStr = DateTime.now().add(Duration(days: offset)).toIso8601String().substring(0, 10);
                        finalSteps.add({
                          'title': s['title'] ?? 'گام بدون عنوان',
                          'scheduledDate': dateStr,
                          'linkedRoutineId': null,
                        });
                      }

                      try {
                        await repo.saveGoal(
                          title: title,
                          description: desc.isNotEmpty ? desc : null,
                          goalType: type,
                          parentGoalId: null,
                          targetDate: targetDate,
                          steps: finalSteps,
                        );

                        await HapticFeedback.mediumImpact();
                        setState(() {
                          _isGoalCreated = true;
                        });
                        widget.onGoalSaved();

                        Timer(const Duration(seconds: 1), () {
                          if (mounted) {
                            navigator.pop(); // Close assistant
                          }
                        });
                      } catch (e) {
                        debugPrint('Error saving AI goal: $e');
                      }
                    },
            ),
          ),
        ],
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
    final colors = Theme.of(context).extension<RitmoColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = math.sin((_controller.value * 2 * math.pi) - delay);
            final transform = (value + 1.0) / 2.0;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.3 + (transform * 0.7)),
                shape: BoxShape.circle,
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
