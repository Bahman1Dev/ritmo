import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/chat/chat_action_parser.dart';
import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/ai/memory/assistant_memory_binding.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/ritmo_command_bus.dart';
import 'package:ritmo/core/domain/personas/assistant_persona.dart';
import 'package:ritmo/core/domain/personas/persona_registry.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';

/// Unified Assistant Sheet replacing all 11 repetitive assistant sheet implementations.
class AssistantSheet extends StatefulWidget {
  const AssistantSheet({
    super.key,
    required this.persona,
    this.initialQuery,
  });

  final AssistantPersona persona;
  final String? initialQuery;

  static Future<void> show(
    BuildContext context, {
    required AssistantPersona persona,
    String? initialQuery,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssistantSheet(
        persona: persona,
        initialQuery: initialQuery,
      ),
    );
  }

  @override
  State<AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<AssistantSheet> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  bool _isTyping = false;
  bool _isStreaming = false;
  String _domainContext = '';
  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _loadDomainContext();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDomainContext() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final buffer = StringBuffer();

      // Enforce zero-leak privacy rules
      final p = widget.persona;

      if (p.canReadDomain(DataDomain.worship)) {
        final debts = await db.query('worship_debts', where: 'isArchived = 0 AND remainingCount > 0');
        if (debts.isNotEmpty) {
          buffer.writeln('- بدهی‌های عبادی: ${debts.map((d) => "${d['title']}: ${d['remainingCount']}").join(', ')}');
        }
      }

      if (p.canReadDomain(DataDomain.goals)) {
        final goals = await db.query('goals', where: "status = 'ACTIVE'");
        if (goals.isNotEmpty) {
          buffer.writeln('- اهداف فعال: ${goals.map((g) => g['title']).join(', ')}');
        }
      }

      if (p.canReadDomain(DataDomain.courses)) {
        final courses = await db.query('courses');
        if (courses.isNotEmpty) {
          buffer.writeln('- دوره‌های فعال: ${courses.map((c) => c['title']).join(', ')}');
        }
      }

      if (p.canReadDomain(DataDomain.konkur)) {
        final plans = await db.query('konkur_plans');
        if (plans.isNotEmpty) {
          buffer.writeln('- برنامه‌های کنکور: ${plans.map((k) => k['topicName']).join(', ')}');
        }
      }

      // PRIVACY PROTECTED: Only cycle persona can read cycle domain
      if (p.id == 'cycle' && p.canReadDomain(DataDomain.cycle)) {
        final logs = await db.query('cycle_day_logs', orderBy: 'logDate DESC', limit: 7);
        if (logs.isNotEmpty) {
          buffer.writeln('- علائم اخیر چرخه بدنی ثبت شده است.');
        }
      }

      // PRIVACY PROTECTED: Only health persona can read medical domain
      if (p.id == 'health' && p.canReadDomain(DataDomain.medical)) {
        final meds = await db.query('routines', where: "category = 'medical' AND isArchived = 0");
        if (meds.isNotEmpty) {
          buffer.writeln('- داروهای ثبت‌شده: ${meds.map((m) => m['title']).join(', ')}');
        }
      }

      setState(() {
        _domainContext = buffer.toString();
      });
    } catch (e) {
      debugPrint('[AssistantSheet] Error loading context for persona ${widget.persona.id}: $e');
    }
  }

  Future<void> _sendMessage([String? quickQuery]) async {
    final query = (quickQuery ?? _chatController.text).trim();
    if (query.isEmpty) return;

    if (quickQuery == null) _chatController.clear();

    setState(() {
      _isTyping = true;
      _messages.add({
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
        'role': 'user',
        'content': query,
      });
    });

    _scrollToBottom();

    try {
      final systemPrompt = '''
شما ${widget.persona.displayName} در برنامه ریتمو هستید.
پاسخ‌ها را صمیمی، محترمانه، علمی و تشویق‌کننده به زبان فارسی ارائه دهید.

${_domainContext.isNotEmpty ? 'اطلاعات پر پرونده کاربر:\n$_domainContext' : ''}
''';

      final memorySuffix = await AssistantMemoryBinding.getSystemPromptSuffix(
        domain: widget.persona.id,
        query: query,
      );

      final messagesToSent = <Map<String, String>>[
        {'role': 'system', 'content': '$systemPrompt\n$memorySuffix'},
        ..._messages.map((m) => {'role': m['role'] as String, 'content': m['content'] as String})
      ];

      final stream = AIGateway.instance.sendCustomChatStream(messages: messagesToSent);

      final assistantMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_a';
      setState(() {
        _messages.add({
          'id': assistantMsgId,
          'role': 'assistant',
          'content': '',
        });
        _isTyping = false;
        _isStreaming = true;
      });

      var fullResponse = '';
      _streamSubscription = stream.listen(
        (chunk) {
          fullResponse += chunk;
          setState(() {
            _messages.last['content'] = fullResponse;
          });
          _scrollToBottom();
        },
        onDone: () {
          setState(() {
            _isStreaming = false;
          });
          _parseAndExecuteActions(fullResponse);
        },
        onError: (err) {
          setState(() {
            _isStreaming = false;
            _messages.last['content'] = 'خطا در دریافت پاسخ از هوش مصنوعی: $err';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isTyping = false;
        _isStreaming = false;
      });
    }
  }

  Future<void> _parseAndExecuteActions(String response) async {
    final parsed = ChatActionParser.parse(response);
    if (parsed.actionsJson != null && parsed.actionsJson!.isNotEmpty) {
      try {
        final actions = ChatActionParser.parseActions(parsed.actionsJson!);
        for (final act in actions) {
          final actionType = AssistantActionType.tryFromString(act.type);
          if (actionType != null) {
            await RitmoCommandBus.instance.dispatch(
              commandId: actionType.name,
              ctx: CommandContext(
                payload: act.payload,
                resultSource: 'AI',
                assistantId: widget.persona.id,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[AssistantSheet] Action parsing/dispatch error: $e');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Handoff / switch between specialty personas cleanly
  void handoffTo(String targetPersonaId) {
    final targetPersona = PersonaRegistry.instance.getPersona(targetPersonaId);
    if (targetPersona == null) return;

    Navigator.of(context).pop();
    AssistantSheet.show(
      context,
      persona: targetPersona,
      initialQuery: 'سلام، از دستیار ${widget.persona.displayName} به این بخش منتقل شدم.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.sparkles, color: RitmoTheme.primaryColor),
                const SizedBox(width: 10),
                Text(
                  widget.persona.displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? RitmoTheme.primaryColor
                          : (isDark ? const Color(0xFF2C2C3E) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['content'] as String,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: isUser ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isTyping || _isStreaming)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CupertinoActivityIndicator(),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: 'پیام خود را بنویسید...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.arrow_up_circle_fill, color: Colors.blueAccent),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
