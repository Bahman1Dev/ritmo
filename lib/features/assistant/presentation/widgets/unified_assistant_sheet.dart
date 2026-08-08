import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/chat/chat_action_parser.dart';
import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/ai/memory/assistant_memory_binding.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/command_plan.dart';
import 'package:ritmo/core/domain/commands/command_audit.dart';
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

  bool _canUndoLast = false;
  String? _lastPlanId;

  @override
  void initState() {
    super.initState();
    _loadDomainContext();
    _checkLastPlan();
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

  Future<void> _checkLastPlan() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final recent = await db.query(
        'assistant_plans',
        where: 'status = ?',
        whereArgs: ['applied'],
        orderBy: 'createdAt DESC',
        limit: 1,
      );
      if (recent.isNotEmpty) {
        final plan = recent.first;
        final createdAt = plan['createdAt'] as int;
        final settingsRows = await db.query('app_settings', where: 'key = ?', whereArgs: ['ai_undo_window_hours'], limit: 1);
        final hours = settingsRows.isNotEmpty ? (int.tryParse(settingsRows.first['value']?.toString() ?? '24') ?? 24) : 24;
        final limit = DateTime.now().subtract(Duration(hours: hours)).millisecondsSinceEpoch;
        if (createdAt >= limit) {
          setState(() {
            _canUndoLast = true;
            _lastPlanId = plan['id'] as String;
          });
        }
      } else {
        setState(() {
          _canUndoLast = false;
          _lastPlanId = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDomainContext() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final buffer = StringBuffer();
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

      if (p.id == 'cycle' && p.canReadDomain(DataDomain.cycle)) {
        final logs = await db.query('cycle_day_logs', orderBy: 'logDate DESC', limit: 7);
        if (logs.isNotEmpty) {
          buffer.writeln('- علائم اخیر چرخه بدنی ثبت شده است.');
        }
      }

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

${_domainContext.isNotEmpty ? 'اطلاعات پرونده کاربر:\n$_domainContext' : ''}
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
          if (chunk.startsWith('error:')) {
            final errorMsg = chunk.substring(6);
            setState(() {
              _isStreaming = false;
              if (fullResponse.isEmpty) {
                if (errorMsg == 'quota_exceeded') {
                  _messages.last['content'] =
                      'سهمیه رایگان روزانه ۱۰,۰۰۰ نورون هوش مصنوعی کلادفلر شما برای امروز به پایان رسیده است ⚠️\n\nمی‌توانید فردا مجدداً تلاش کنید یا در تنظیمات پروفایل ارائه‌دهنده را روی OpenRouter یا Zhipu AI تنظیم نمایید 🔌';
                } else {
                  _messages.last['content'] =
                      'متأسفانه در حال حاضر خطایی در برقراری ارتباط با سرور هوش مصنوعی رخ داده است. لطفاً اتصال فیلترشکن یا اینترنت خود را بررسی کنید. همچنین می‌توانید در تنظیمات پروفایل، ارائه‌دهنده را روی OpenRouter یا Zhipu AI تنظیم نمایید 🔌';
                }
              } else {
                _messages.last['content'] =
                    '$fullResponse\n\n⚠️ [اتصال به هوش مصنوعی قطع شد]';
              }
            });
            return;
          }

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
          if (fullResponse.isNotEmpty && !fullResponse.startsWith('error:')) {
            _parseAndExecuteActions(fullResponse);
          }
        },
        onError: (err) {
          setState(() {
            _isStreaming = false;
            if (fullResponse.isEmpty) {
              _messages.last['content'] =
                  'خطا در برقراری ارتباط با سرور هوش مصنوعی. لطفاً اتصال اینترنت/فیلترشکن را بررسی کنید 🔌';
            }
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

  String? _mapActionTypeToNewCommandId(AssistantActionType type) {
    switch (type) {
      case AssistantActionType.createRoutine: return 'routine.create';
      case AssistantActionType.createGoal: return 'goal.create';
      case AssistantActionType.logSleep: return 'sleep.log';
      case AssistantActionType.logEnergyMood: return 'energy.log';
      case AssistantActionType.addKonkurItem: return 'konkur.createTopic';
      case AssistantActionType.createCourse: return 'course.create';
      case AssistantActionType.openPage: return 'app.openPage';
      case AssistantActionType.updateSetting: return 'setting.update';
      case AssistantActionType.completeRoutine: return 'routine.complete';
      case AssistantActionType.skipRoutine: return 'routine.skip';
      case AssistantActionType.editRoutine: return 'routine.edit';
      case AssistantActionType.deleteRoutine: return 'routine.delete';
      case AssistantActionType.editGoal: return 'goal.edit';
      case AssistantActionType.completeGoalStep: return 'goal.completeStep';
      case AssistantActionType.createWorshipItem: return 'worship.create';
      case AssistantActionType.deleteWorshipItem: return 'worship.delete';
      case AssistantActionType.logReflection: return 'reflection.log';
      case AssistantActionType.rescheduleReminder: return 'routine.reschedule';
      default: return null;
    }
  }

  Future<void> _parseAndExecuteActions(String response) async {
    final parsed = ChatActionParser.parse(response);
    if (parsed.actions.isNotEmpty) {
      try {
        final steps = <PlanStep>[];
        for (final act in parsed.actions) {
          String? commandId = act.type;
          if (!commandId.contains('.')) {
            final actionType = AssistantActionType.tryFromString(act.type);
            if (actionType != null) {
              commandId = _mapActionTypeToNewCommandId(actionType);
            }
          }
          if (commandId != null) {
            steps.add(PlanStep(commandId: commandId, payload: act.payload));
          }
        }

        if (steps.isNotEmpty) {
          final plan = CommandPlan(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            titleFa: 'برنامه پیشنهادی دستیار',
            steps: steps,
          );

          final preview = await RitmoCommandBus.instance.preview(plan, personaId: widget.persona.id);

          if (preview.blockers.isNotEmpty) {
            setState(() {
              _messages.add({
                'id': 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
                'role': 'assistant',
                'content': 'تعدادی خطا مانع اجرای این اقدام شد:\n${preview.blockers.join('\n')}',
              });
            });
            return;
          }

          final db = await DatabaseHelper.instance.database;
          final settingsRows = await db.query('app_settings', where: 'key = ?', whereArgs: ['ai_agent_mode'], limit: 1);
          final agentMode = settingsRows.isNotEmpty ? settingsRows.first['value']?.toString() : 'confirm';

          if (agentMode == 'suggest' || agentMode == 'confirm' || preview.needsBiometric) {
            _showPreviewSheet(plan, preview);
          } else {
            // Auto Mode
            final result = await RitmoCommandBus.instance.execute(
              plan,
              personaId: widget.persona.id,
              source: CommandSource.assistant,
            );
            if (result.success) {
              setState(() {
                _messages.add({
                  'id': 'msg_ok_${DateTime.now().millisecondsSinceEpoch}',
                  'role': 'assistant',
                  'content': 'اقدامات زیر با موفقیت اجرا شد:\n' + plan.steps.map((s) => '- ${RitmoCommandBus.instance.getCommand(s.commandId)?.humanTitle ?? s.commandId}').join('\n'),
                });
              });
              _checkLastPlan();

              // Handle post-execution actions
              for (final res in result.results) {
                if (res.commandId == 'app.openPage' && res.outputData?['route'] != null) {
                  final route = res.outputData!['route']!.toString();
                  unawaited(Navigator.of(context).pushNamed(route));
                }
                if (res.commandId == 'assistant.handoff' && res.outputData?['personaId'] != null) {
                  final target = res.outputData!['personaId']!.toString();
                  handoffTo(target);
                }
              }
            } else {
              setState(() {
                _messages.add({
                  'id': 'msg_fail_${DateTime.now().millisecondsSinceEpoch}',
                  'role': 'assistant',
                  'content': 'خطا در اجرای اقدام: ${result.errorMessage}',
                });
              });
            }
          }
        }
      } catch (e) {
        debugPrint('[AssistantSheet] Action parsing/dispatch error: $e');
      }
    }
  }

  void _showPreviewSheet(CommandPlan plan, PlanPreview preview) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(sheetCtx).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'بررسی اقدامات پیشنهادی دستیار',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: preview.diffs.length,
                  itemBuilder: (context, index) {
                    final diff = preview.diffs[index];
                    return Card(
                      color: isDark ? const Color(0xFF2C2C3E) : Colors.grey[50],
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              diff.entityLabelFa,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                            ),
                            if (diff.beforeFa != null || diff.afterFa != null) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  if (diff.beforeFa != null) ...[
                                    Text(diff.beforeFa!, style: const TextStyle(color: Colors.red, fontFamily: 'Vazirmatn')),
                                    const Icon(Icons.arrow_left),
                                  ],
                                  if (diff.afterFa != null)
                                    Text(diff.afterFa!, style: const TextStyle(color: Colors.green, fontFamily: 'Vazirmatn')),
                                ],
                              ),
                            ],
                            if (diff.warningFa != null) ...[
                              const SizedBox(height: 5),
                              Text(
                                '⚠️ ${diff.warningFa}',
                                style: const TextStyle(color: Colors.orange, fontSize: 12, fontFamily: 'Vazirmatn'),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
              if (preview.needsBiometric)
                const Text(
                  '🔒 این اقدام حساس است و نیاز به تایید هویت بیومتریک دارد.',
                  style: TextStyle(color: Colors.redAccent, fontFamily: 'Vazirmatn', fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.of(sheetCtx).pop();
                        final result = await RitmoCommandBus.instance.execute(
                          plan,
                          personaId: widget.persona.id,
                          source: CommandSource.assistant,
                        );
                        if (result.success) {
                          setState(() {
                            _messages.add({
                              'id': 'msg_ok_${DateTime.now().millisecondsSinceEpoch}',
                              'role': 'assistant',
                              'content': 'اقدامات با موفقیت اجرا شد:\n' + plan.steps.map((s) => '- ${RitmoCommandBus.instance.getCommand(s.commandId)?.humanTitle ?? s.commandId}').join('\n'),
                            });
                          });
                          _checkLastPlan();

                          for (final res in result.results) {
                            if (res.commandId == 'app.openPage' && res.outputData?['route'] != null) {
                              final route = res.outputData!['route']!.toString();
                              unawaited(Navigator.of(context).pushNamed(route));
                            }
                            if (res.commandId == 'assistant.handoff' && res.outputData?['personaId'] != null) {
                              final target = res.outputData!['personaId']!.toString();
                              handoffTo(target);
                            }
                          }
                        } else {
                          setState(() {
                            _messages.add({
                              'id': 'msg_fail_${DateTime.now().millisecondsSinceEpoch}',
                              'role': 'assistant',
                              'content': 'خطا در اجرای اقدام: ${result.errorMessage}',
                            });
                          });
                        }
                      },
                      child: const Text('تایید و اجرا', style: TextStyle(fontFamily: 'Vazirmatn')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                      child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _undoLastAction() async {
    if (_lastPlanId == null) return;
    setState(() {
      _isTyping = true;
    });
    final result = await RitmoCommandBus.instance.undoPlan(_lastPlanId!);
    setState(() {
      _isTyping = false;
    });

    if (result.success) {
      setState(() {
        _messages.add({
          'id': 'msg_undo_ok_${DateTime.now().millisecondsSinceEpoch}',
          'role': 'assistant',
          'content': 'آخرین اقدام با موفقیت لغو و بازیابی شد 🔄',
        });
      });
      _checkLastPlan();
    } else {
      setState(() {
        _messages.add({
          'id': 'msg_undo_fail_${DateTime.now().millisecondsSinceEpoch}',
          'role': 'assistant',
          'content': 'لغو آخرین اقدام با شکست مواجه شد: ${result.errorMessage}',
        });
      });
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.sparkles, color: context.colors.primary),
                const SizedBox(width: 10),
                Text(
                  widget.persona.displayName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_canUndoLast)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 16),
                    label: const Text(
                      'لغو اقدام اخیر',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _undoLastAction,
                  ),
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
                final theme = Theme.of(context);
                final msg = _messages[idx];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.colorScheme.primary
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
                      hintStyle: TextStyle(fontFamily: 'Vazirmatn'),
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
