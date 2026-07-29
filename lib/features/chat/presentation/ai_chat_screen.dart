import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ritmo/core/ai/ai_context_builder.dart';
import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/ai/chat/chat_repository.dart';
import 'package:ritmo/core/ai/chat/streaming_chat_service.dart';
import 'package:ritmo/core/ai/memory/ai_memory_service.dart';
import 'package:ritmo/core/ai/memory/memory_models.dart';
import 'package:ritmo/core/analytics/assistant_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/cycle_consent_bridge.dart';
import 'package:ritmo/core/ux/ritmo_directional_icon.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/assistant/logic/assistant_action_registry.dart';
import 'package:ritmo/features/assistant/logic/day_plan_composer.dart';
import 'package:ritmo/features/assistant/logic/day_plan_template_service.dart';
import 'package:ritmo/features/assistant/logic/day_plan_validator.dart';
import 'package:ritmo/features/assistant/logic/settings_action_guard.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';
import 'package:ritmo/features/assistant/models/day_plan_models.dart';
import 'package:ritmo/features/assistant/presentation/widgets/ai_day_planner_preview_sheet.dart';
import 'package:ritmo/features/assistant/presentation/widgets/ai_weekly_planner_preview_sheet.dart';
import 'package:ritmo/features/assistant/presentation/widgets/assistant_briefing_section.dart';
import 'package:ritmo/features/chat/presentation/chat_session_list_screen.dart';
import 'package:ritmo/features/chat/presentation/widgets/streaming_message_bubble.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:sqflite/sqflite.dart';

class AiChatScreen extends StatefulWidget {

  const AiChatScreen({super.key, this.sessionId, this.isTab = false});
  final String? sessionId;
  final bool isTab;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  String? _sessionId;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  StreamSubscription<StreamingChatEvent>? _sub;
  String? _streamingId;
  final Map<String, Timer> _pendingDeleteTimers = {};
  final Map<String, ChatMessage> _pendingDeletedMsgs = {};

  DailyBriefing? _briefing;
  List<NextAction> _nextActions = [];
  bool _isLoadingBriefing = false;

  bool get _isStreaming => _sub != null;

  DayPlanDraft? _pendingDayPlanDraft;
  List<String> _currentQuickReplies = [];
  bool _hasActiveDayPlanCommit = false;
  String? _dayPlanningStepMessage;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
    if (_sessionId != null) {
      _loadMessages();
    }
    _loadBriefingData();
    _checkLastCommit();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'notListening' && mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
        },
      );
      if (mounted) {
        setState(() {
          _isSpeechAvailable = available;
        });
      }
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_isSpeechAvailable) {
      await _initSpeech();
    }
    if (_isSpeechAvailable) {
      setState(() {
        _isListening = true;
      });
      unawaited(HapticFeedback.mediumImpact());
      try {
        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _textController.text = result.recognizedWords;
              });
            }
          },
          listenOptions: stt.SpeechListenOptions(localeId: 'fa_IR'),
        );
      } catch (e) {
        debugPrint('Speech listen error: $e');
      }
    } else {
      if (mounted) {
        unawaited(showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('دسترسی میکروفون', textAlign: TextAlign.right),
            content: const Text(
              'تشخیص گفتار فعال نیست یا دسترسی میکروفون داده نشده است. لطفاً در تنظیمات دستگاه دسترسی را بررسی کنید.',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('فهمیدم'),
              ),
            ],
          ),
        ));
      }
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      unawaited(HapticFeedback.lightImpact());
      
      final text = _textController.text.trim();
      if (text.isNotEmpty) {
        _send(text);
      }
    }
  }

  Future<void> _loadBriefingData() async {
    if (mounted) setState(() => _isLoadingBriefing = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final today = DateTime.now();

      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      
      final briefingEnabled = settingsMap['assistant_briefing_enabled'] != 'false';
      final proactiveEnabled = settingsMap['assistant_proactive_enabled'] != 'false';
      final gender = settingsMap['user_gender'] ?? 'UNSET';
      final isFemale = gender.toUpperCase() == 'FEMALE';
      final cycleConsent = settingsMap['cycle_consent_energy'] == 'true';

      final routines = await db.query('routines');
      final routineCompletions = await db.query('routine_completions');
      final sleepLogs = await db.query('bedtime_diagnostics');
      final energyLogs = await db.query('energy_logs');
      final moodLogs = await db.query('mood_logs');
      final goals = await db.query('goals');
      final goalSteps = await db.query('goal_steps');
      final konkurStudySessions = await db.query('konkur_study_sessions');

      final isEnergyTuned = await CycleConsentBridge.isEnergyTuned();

      final input = AssistantEngineInput(
        routines: routines,
        routineCompletions: routineCompletions,
        sleepLogs: sleepLogs,
        energyLogs: energyLogs,
        moodLogs: moodLogs,
        goals: goals,
        goalSteps: goalSteps,
        konkurStudySessions: konkurStudySessions,
        today: today,
        isBriefingEnabled: briefingEnabled,
        isProactiveEnabled: proactiveEnabled,
        isUserFemale: isFemale,
        cycleConsent: cycleConsent,
        isEnergyTuned: isEnergyTuned,
      );

      RitmoEngineBus.instance.invalidate(AssistantEngine);

      final output = await RitmoEngineBus.instance.execute<AssistantEngineInput, AssistantEngineOutput>(
        AssistantEngine,
        input,
      );

      if (mounted) {
        setState(() {
          _briefing = output.dailyBriefing;
          _nextActions = output.nextActions;
          _isLoadingBriefing = false;
        });
        _checkLastCommit();
        unawaited(_runLearningLoop());
      }
    } catch (e) {
      debugPrint('Error loading assistant engine data in chat screen: $e');
      if (mounted) {
        setState(() => _isLoadingBriefing = false);
      }
    }
  }

  bool _isDayPlanQuery(String text) {
    final clean = text.trim().toLowerCase();
    if (clean.contains('روزم رو بچین') || clean.contains('برنامه روز') || clean.contains('بچین روزم را')) {
      return true;
    }

    final planningKeywords = [
      'بیدار', 'خواب', 'نماز', 'صبحونه', 'صبحانه', 'ناهار', 'شام', 'کار', 'سرکار', 'بانک', 'درس', 'کتاب',
      'ورزش', 'باشگاه', 'پیاده', 'دعا', 'قرآن', 'دوش', 'حمام', 'خرید', 'کافه', 'ملاقات', 'جلسه'
    ];
    var count = 0;
    for (final kw in planningKeywords) {
      if (clean.contains(kw)) {
        count++;
      }
    }
    return count >= 3;
  }

  Future<void> _saveSystemConfirmationMessage(String text) async {
    if (_sessionId != null) {
      await ChatRepository.instance.addMessage(ChatMessage(
        id: 'dp_sys_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _sessionId!,
        role: ChatRole.assistant,
        content: text,
        timestamp: DateTime.now(),
      ));
      await _loadMessages();
    }
  }

  Future<void> _checkLastCommit() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final oneDayAgo = nowMs - (24 * 3600 * 1000);
      final lastCommits = await db.query(
        'day_plan_commits',
        where: 'createdAt >= ?',
        whereArgs: [oneDayAgo],
        limit: 1,
      );
      if (mounted) {
        setState(() {
          _hasActiveDayPlanCommit = lastCommits.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error checking last commit in chat screen: $e');
    }
  }

  Future<void> _runLearningLoop() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final sevenDaysAgo = now - (7 * 24 * 3600 * 1000);

      final completions = await db.rawQuery('''
        SELECT r.title, r.category, r.targetDurationMinutes, rc.durationMinutes
        FROM routine_completions rc
        JOIN routines r ON rc.routineId = r.id
        WHERE rc.createdAt >= ? AND rc.durationMinutes IS NOT NULL AND r.targetDurationMinutes IS NOT NULL
      ''', [sevenDaysAgo]);

      if (completions.isEmpty) return;

      final actualsByTitle = <String, List<int>>{};
      final targetsByTitle = <String, int>{};
      final categoryByTitle = <String, String>{};

      for (final c in completions) {
        final title = c['title']! as String;
        final target = c['targetDurationMinutes']! as int;
        final actual = c['durationMinutes']! as int;
        final category = c['category']! as String;

        if (target == 0 || actual == 0) continue;

        actualsByTitle.putIfAbsent(title, () => []).add(actual);
        targetsByTitle[title] = target;
        categoryByTitle[title] = category;
      }

      for (final title in actualsByTitle.keys) {
        final list = actualsByTitle[title]!;
        if (list.length < 3) continue;

        final avgActual = list.reduce((a, b) => a + b) ~/ list.length;
        final target = targetsByTitle[title]!;

        if ((avgActual - target).abs() >= 15) {
          final cleanTitle = title.trim();
          final fact = 'کار "$cleanTitle" معمولاً $avgActual دقیقه طول می‌کشد';

          final existing = await AiMemoryService.instance.retrieve(domain: 'core', query: cleanTitle);
          final hasFact = existing.any((m) => m.content.contains(cleanTitle) && m.content.contains('دقیقه'));

          if (!hasFact) {
            await AiMemoryService.instance.applyOperations([
              MemoryOp(
                op: 'ADD',
                content: fact,
                type: MemoryType.preference,
                domain: 'core',
                importance: 5,
                sensitive: false,
              )
            ]);
            debugPrint('[AI Learning Loop] Learned new fact: $fact');
          }
        }
      }
    } catch (e) {
      debugPrint('[AI Learning Loop] Error running learning loop: $e');
    }
  }

  void _showTodayBriefingSheet(BuildContext context) {
    if (_isLoadingBriefing && _briefing == null) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => const Center(child: CupertinoActivityIndicator(radius: 15)),
      );
      return;
    }

    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return RitmoTheme.glassCardLight(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _briefing == null
                          ? Center(
                              child: Text(
                                'در حال بارگذاری تحلیل امروز...',
                                style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary),
                              ),
                            )
                          : AssistantBriefingSection(
                              briefing: _briefing!,
                              nextActions: _nextActions,
                              onActionComplete: () async {
                                await _loadBriefingData();
                                setModalState(() {});
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

  void _showAuditLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colors = context.colors;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.database.then((db) => db.query('assistant_audit_log', orderBy: 'appliedAt DESC', limit: 20)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return RitmoTheme.glassCardLight(
                    child: const SizedBox(
                      height: 400,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                
                final logs = snapshot.data ?? [];
                
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: RitmoTheme.glassCardLight(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'دفتر ممیزی و تغییرات دستیار',
                                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary),
                              ),
                              IconButton(
                                icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (logs.isEmpty)
                            Expanded(
                              child: Center(
                                child: Text(
                                  'هیچ تغییری توسط دستیار ثبت نشده است.',
                                  style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final log = logs[index];
                                  final type = log['actionType']?.toString() ?? '';
                                  final key = log['targetKey']?.toString() ?? '';
                                  final oldValue = log['oldValue']?.toString() ?? '';
                                  final newValue = log['newValue']?.toString() ?? '';
                                  final appliedAt = log['appliedAt'] as int;
                                  
                                  final date = DateTime.fromMillisecondsSinceEpoch(appliedAt);
                                  final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                                  
                                  var actionLabel = type;
                                  if (type == 'updateSetting') actionLabel = 'تغییر تنظیمات';
                                  if (type == 'completeRoutine') actionLabel = 'انجام روتین';
                                  if (type == 'skipRoutine') actionLabel = 'تعویق روتین';
                                  if (type == 'editRoutine') actionLabel = 'ویرایش روتین';
                                  if (type == 'deleteRoutine') actionLabel = 'حذف روتین';
                                  if (type == 'editGoal') actionLabel = 'ویرایش هدف';
                                  if (type == 'completeGoalStep') actionLabel = 'تکمیل گام هدف';
                                  
                                  return Card(
                                    color: colors.card,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      title: Text(
                                        '$actionLabel - $key',
                                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                                      ),
                                      subtitle: Text(
                                        type == 'updateSetting'
                                            ? 'مقدار قبلی: $oldValue ➔ مقدار جدید: $newValue\nساعت: $timeStr'
                                            : 'تغییر: $newValue\nساعت: $timeStr',
                                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
                                      ),
                                      trailing: type == 'updateSetting' && oldValue.isNotEmpty && oldValue != 'null'
                                          ? TextButton(
                                              onPressed: () async {
                                                final success = await applySettingChange(key, oldValue);
                                                if (success) {
                                                  setModalState(() {});
                                                }
                                              },
                                              child: const Text('بازگردانی', style: TextStyle(fontFamily: 'Vazirmatn', color: Color(0xff06B6D4))),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    for (final timer in _pendingDeleteTimers.values) {
      timer.cancel();
    }
    for (final msgId in _pendingDeletedMsgs.keys) {
      ChatRepository.instance.deleteMessage(msgId);
    }
    _pendingDeleteTimers.clear();
    _pendingDeletedMsgs.clear();
    _cancelStreamSilent();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_sessionId == null) return;
    setState(() => _isLoading = true);
    try {
      final list = await ChatRepository.instance.getMessages(_sessionId!);
      if (mounted) {
        setState(() {
          _messages = list;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _ensureCloudConsent() async {
    final db = await DatabaseHelper.instance.database;
    final consentCheck = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['assistant_cloud_consent'],
    );
    
    if (consentCheck.isNotEmpty && consentCheck.first['value'] == 'true') {
      return true;
    }

    final genderCheck = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['user_gender'],
    );
    final gender = (genderCheck.isNotEmpty ? genderCheck.first['value'] : 'UNSET').toString().toUpperCase();
    final isMale = gender == 'MALE';

    final contentText = isMale
        ? 'دستیار هوشمند برای ارائه راهکارها و پاسخ‌های دقیق‌تر، نیاز دارد اطلاعات برنامه‌ریزی، روتین‌ها، اهداف، آمار خواب و انرژی و برخی تنظیمات رفتاری شما را به سرورهای ابری ارسال کند.\n\n'
            '🚨 توجه مهم:\n'
            '۱. اطلاعات پزشکی، داروها، دوز مصرفی و یادآورهای درمانی کاملاً ممنوع بوده و هرگز ارسال نمی‌شوند.\n'
            '۲. هر آیتمی که توسط شما به صورت «خصوصی» علامت‌گذاری شود، از دید دستیار پنهان خواهد ماند.\n\n'
            'آیا با ارسال این اطلاعات موافقید؟'
        : 'دستیار هوشمند برای ارائه راهکارها و پاسخ‌های دقیق‌تر، نیاز دارد اطلاعات برنامه‌ریزی، روتین‌ها، اهداف، آمار خواب و انرژی و برخی تنظیمات رفتاری شما را به سرورهای ابری ارسال کند.\n\n'
            '🚨 توجه مهم:\n'
            '۱. اطلاعات چرخه قاعدگی و هورمونی به هیچ وجه ارسال نمی‌شوند.\n'
            '۲. اطلاعات پزشکی، داروها، دوز مصرفی و یادآورهای درمانی کاملاً ممنوع بوده و هرگز ارسال نمی‌شوند.\n'
            '۳. هر آیتمی که توسط شما به صورت «خصوصی» علامت‌گذاری شود، از دید دستیار پنهان خواهد ماند.\n\n'
            'آیا با ارسال این اطلاعات موافقید؟';
    
    if (!mounted) return false;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final titleColor = isDark ? Colors.white : const Color(0xff1C1F2E);
        final textColor = isDark ? Colors.white70 : Colors.black87;
        final disagreeColor = isDark ? Colors.grey : Colors.black54;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: RitmoTheme.glassCardLight(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'رضایت‌نامه ارسال اطلاعات به هوش مصنوعی ابری',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      contentText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        height: 1.6,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'عدم موافقت',
                            style: TextStyle(fontFamily: 'Vazirmatn', color: disagreeColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff06B6D4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'موافقت و پذیرش',
                            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    
    if (accepted ?? false) {
      await db.insert(
        'app_settings',
        {
          'key': 'assistant_cloud_consent',
          'value': 'true',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    }
    return false;
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isStreaming) return;
    
    final consentGranted = await _ensureCloudConsent();
    if (!consentGranted) return;

    if (_sessionId == null) {
      final s = await ChatRepository.instance.createSession();
      _sessionId = s.id;
    }

    // Intercept Day Planning query
    if (_isDayPlanQuery(text) || _pendingDayPlanDraft != null) {
      setState(() {
        _isLoading = true;
        _dayPlanningStepMessage = '🧠 در حال تحلیل و آغاز چیدمان برنامه...';
      });
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final tomorrowStr = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final targetDateStr = text.contains('فردا') ? tomorrowStr : todayStr;

      try {
        var queryToCompose = text;
        if (_pendingDayPlanDraft != null) {
          queryToCompose = 'بر اساس سوال قبل که پاسخش این است: "$text"، کل برنامه روز را کامل کن و سوال دیگری نپرس.';
        }

        final result = await DayPlanComposer.compose(
          query: queryToCompose,
          targetDateStr: targetDateStr,
          onProgress: (step) {
            if (mounted) {
              setState(() {
                _dayPlanningStepMessage = step;
              });
            }
          },
        );
        if (result != null) {
          if (result.isTemplateApply) {
            final templateName = result.applyTemplateName!;
            final templateDate = result.applyTemplateDate!;
            final template = await DayPlanTemplateService.instance.getTemplateByName(templateName);
            if (template != null) {
              final draft = DayPlanDraft(
                planDate: templateDate,
                items: template.items,
                questions: [],
                suggestions: [],
              );
              final enriched = await DayPlanValidator.validateAndEnrich(draft: draft);
              await DayPlanTemplateService.instance.recordTemplateUsage(template.id);
              if (mounted) {
                AiDayPlannerPreviewSheet.show(
                  context,
                  initialDraft: enriched,
                  onSaved: () {
                    _loadBriefingData();
                    _checkLastCommit();
                    _saveSystemConfirmationMessage('برنامه روز شما با موفقیت ثبت شد ⚡');
                    _showTopToast(
                      'برنامه روز با موفقیت چیده شد 🗓',
                      CupertinoIcons.checkmark_circle,
                      context.colors.primary,
                      onUndo: () async {
                        await AssistantActionRegistry.undoLastDayPlanCommit(context);
                        unawaited(_loadBriefingData());
                        unawaited(_checkLastCommit());
                      }
                    );
                  },
                );
              }
            } else {
              _showTopToast(
                'قالب "$templateName" یافت نشد ❌',
                CupertinoIcons.exclamationmark_triangle,
                Colors.redAccent,
              );
            }
            setState(() {
              _isLoading = false;
              _dayPlanningStepMessage = null;
            });
            return;
          }

          if (result.isMultiDay) {
            setState(() {
              _pendingDayPlanDraft = null;
              _currentQuickReplies = [];
              _isLoading = false;
              _dayPlanningStepMessage = null;
            });

            // Save user query to session
            await ChatRepository.instance.addMessage(ChatMessage(
              id: 'dp_usr_multi_${DateTime.now().millisecondsSinceEpoch}',
              sessionId: _sessionId!,
              role: ChatRole.user,
              content: text,
              timestamp: DateTime.now(),
            ));
            await _loadMessages();

            if (mounted) {
              AiWeeklyPlannerPreviewSheet.show(
                context,
                initialDrafts: result.multiDayDrafts!,
                onSaved: () {
                  _loadBriefingData();
                  _checkLastCommit();
                  _saveSystemConfirmationMessage('برنامه هفتگی شما با موفقیت ثبت شد ⚡');
                  _showTopToast(
                    'برنامه هفتگی با موفقیت ثبت شد 🗓',
                    CupertinoIcons.checkmark_circle,
                    context.colors.primary,
                    onUndo: () async {
                      await AssistantActionRegistry.undoLastDayPlanCommit(context);
                      unawaited(_loadBriefingData());
                      unawaited(_checkLastCommit());
                    }
                  );
                },
              );
            }
            return;
          }

          final draft = result.singleDraft;
          if (draft != null) {
            if (draft.questions.isNotEmpty && _pendingDayPlanDraft == null) {
              // Save query and response to session first
              await ChatRepository.instance.addMessage(ChatMessage(
                id: 'dp_usr_${DateTime.now().millisecondsSinceEpoch}',
                sessionId: _sessionId!,
                role: ChatRole.user,
                content: text,
                timestamp: DateTime.now(),
              ));
              final question = draft.questions.first;
              await ChatRepository.instance.addMessage(ChatMessage(
                id: 'dp_ast_${DateTime.now().millisecondsSinceEpoch}',
                sessionId: _sessionId!,
                role: ChatRole.assistant,
                content: question.text,
                timestamp: DateTime.now(),
              ));
              await _loadMessages();

              setState(() {
                _pendingDayPlanDraft = draft;
                _currentQuickReplies = question.quickReplies;
                _isLoading = false;
                _dayPlanningStepMessage = null;
              });
              _scrollToBottom();
              return;
            } else if (draft.items.isNotEmpty) {
              // Clear pending draft/replies
              setState(() {
                _pendingDayPlanDraft = null;
                _currentQuickReplies = [];
                _isLoading = false;
                _dayPlanningStepMessage = null;
              });

              // Save user query to session
              await ChatRepository.instance.addMessage(ChatMessage(
                id: 'dp_usr2_${DateTime.now().millisecondsSinceEpoch}',
                sessionId: _sessionId!,
                role: ChatRole.user,
                content: text,
                timestamp: DateTime.now(),
              ));
              await _loadMessages();

              if (mounted) {
                AiDayPlannerPreviewSheet.show(
                  context,
                  initialDraft: draft,
                  onSaved: () {
                    _loadBriefingData();
                    _checkLastCommit();
                    _saveSystemConfirmationMessage('برنامه روز شما با موفقیت ثبت شد ⚡');
                    _showTopToast(
                      'برنامه روز با موفقیت چیده شد 🗓',
                      CupertinoIcons.checkmark_circle,
                      context.colors.primary,
                      onUndo: () async {
                        await AssistantActionRegistry.undoLastDayPlanCommit(context);
                        unawaited(_loadBriefingData());
                        unawaited(_checkLastCommit());
                      }
                    );
                  },
                );
              }
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('[AiChatScreen] DayPlanComposer error: $e');
      }

      setState(() {
        _isLoading = false;
        _dayPlanningStepMessage = null;
      });

      if (!mounted) return;

      _showTopToast(
        'برای چیدمان برنامه روز، لطفاً کارهای امروزتان را بنویسید (مثلاً: ۹ تا ۱۷ سرکارم)',
        CupertinoIcons.info,
        context.colors.primary,
      );
      return;
    }

    _textController.clear();
    final consent = await ConsentProfile.loadFromDb();

    _sub = StreamingChatService().send(
      sessionId: _sessionId!,
      userText: text,
      consent: consent,
    ).listen(_onEvent, onError: (err) {
      _onError(err.toString());
    }, onDone: () {
      setState(() {
        _sub = null;
        _streamingId = null;
      });
    });

    setState(() {});
  }

  void _onEvent(StreamingChatEvent e) {
    if (e is UserMessageSaved) {
      setState(() {
        _messages.add(e.message);
      });
      _scrollToBottom();
    } else if (e is AssistantStarted) {
      setState(() {
        _streamingId = e.messageId;
        _messages.add(ChatMessage(
          id: e.messageId,
          sessionId: _sessionId!,
          role: ChatRole.assistant,
          content: '',
          timestamp: DateTime.now(),
          isStreaming: true,
        ));
      });
      _scrollToBottom();
    } else if (e is ChatChunk) {
      final idx = _messages.indexWhere((m) => m.id == _streamingId);
      if (idx != -1) {
        setState(() {
          _messages[idx] = _messages[idx].copyWith(content: e.accumulated);
        });
      }
      _scrollToBottom();
    } else if (e is ChatComplete) {
      final idx = _messages.indexWhere((m) => m.id == e.messageId);
      if (idx != -1) {
        setState(() {
          _messages[idx] = _messages[idx].copyWith(
            content: e.content,
            actions: e.actions,
            isStreaming: false,
          );
        });
      }
      setState(() {
        _sub = null;
        _streamingId = null;
      });
      _scrollToBottom();
    } else if (e is ChatErrorEvent) {
      _onError(e.message.isEmpty ? 'خطایی در ارتباط با دستیار رخ داد.' : e.message);
    } else if (e is ChatCancelled) {
      _cancelStream();
    }
  }

  void _onError(String errorText) {
    final idx = _messages.indexWhere((m) => m.id == _streamingId);
    if (idx != -1) {
      setState(() {
        final currentContent = _messages[idx].content;
        final errorMsg = currentContent.isEmpty
            ? 'خطا در ارتباط با سرور هوش مصنوعی.'
            : '$currentContent\n\n[خطا در ارتباط: $errorText]';
        _messages[idx] = _messages[idx].copyWith(content: errorMsg, isStreaming: false);
      });
    }
    setState(() {
      _sub = null;
      _streamingId = null;
    });
    _scrollToBottom();
  }

  Future<void> _cancelStream() async {
    if (_sub == null) return;
    await _sub!.cancel();
    
    final idx = _messages.indexWhere((m) => m.id == _streamingId);
    if (idx != -1) {
      final current = _messages[idx];
      if (current.content.trim().isNotEmpty) {
        final saved = current.copyWith(
          content: '${current.content}\n\n[قطع شد]',
          isStreaming: false,
        );
        await ChatRepository.instance.addMessage(saved);
        setState(() {
          _messages[idx] = saved;
        });
      } else {
        setState(() {
          _messages.removeAt(idx);
        });
      }
    }
    
    setState(() {
      _sub = null;
      _streamingId = null;
    });
  }

  void _cancelStreamSilent() {
    if (_sub == null) return;
    _sub!.cancel();
    final idx = _messages.indexWhere((m) => m.id == _streamingId);
    if (idx != -1) {
      final current = _messages[idx];
      if (current.content.trim().isNotEmpty) {
        final saved = current.copyWith(
          content: '${current.content}\n\n[قطع شد]',
          isStreaming: false,
        );
        ChatRepository.instance.addMessage(saved);
      }
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

  Future<void> _handleAction(ChatAction action) async {
    RitmoHaptics.confirm();
    if (action.type == 'openPage' && action.targetRoute != null) {
      Navigator.pushNamed(context, action.targetRoute!);
    } else {
      await AssistantActionRegistry.executeAction(
        context,
        action.toAssistantAction(),
        () {},
      );
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    _showTopToast(
      'متن پیام کپی شد.',
      Icons.check_circle_rounded,
      const Color(0xff10B981),
    );
  }

  void _showTopToast(String message, IconData icon, Color iconColor, {VoidCallback? onUndo}) {
    OverlayState? overlayState;
    try {
      overlayState = Overlay.of(context, rootOverlay: true);
    } catch (_) {}
    if (overlayState == null) {
      try {
        overlayState = Overlay.of(context);
      } catch (_) {}
    }
    if (overlayState == null) return;
    
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.buildBackgroundContainer(
        context: context,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: widget.isTab
                ? null
                : IconButton(
                    icon: RitmoIcons.back(context, color: colors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'دستیار هوشمند',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showTodayBriefingSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xff06B6D4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xff06B6D4).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.calendar, size: 13, color: Color(0xff06B6D4)),
                        SizedBox(width: 4),
                        Text(
                          'امروز',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            color: Color(0xff06B6D4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.clock, size: 20),
                tooltip: 'تغییرات اخیر',
                onPressed: () => _showAuditLogSheet(context),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.chat_bubble_2, size: 20),
                tooltip: 'تاریخچه گفتگوها',
                onPressed: () {
                  Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatSessionListScreen(),
                    ),
                  ).then((selectedId) {
                    if (selectedId != null) {
                      setState(() {
                        _sessionId = selectedId;
                      });
                      _loadMessages();
                    }
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (_hasActiveDayPlanCommit)
                Container(
                  width: double.infinity,
                  color: colors.primary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.info_circle, size: 16, color: colors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'برنامه جدید چیده شده است. مایلید تغییرات ۲۴ ساعت گذشته را بازگردانید؟',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await AssistantActionRegistry.undoLastDayPlanCommit(context);
                          unawaited(_loadBriefingData());
                          unawaited(_checkLastCommit());
                        },
                        child: Text(
                          'بازگردانی (Undo)',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Chat messages stream
              Expanded(
                child: _isLoading
                    ? _buildDayPlanningLoadingState(colors)
                    : _messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.sparkles,
                                    size: 44,
                                    color: colors.textSecondary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'چگونه می‌توانم به ارتقای ریتم روزانه‌ات کمک کنم؟',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 13.5,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () => _send('روزم رو بچین'),
                                    icon: const Icon(CupertinoIcons.calendar_badge_plus, size: 18),
                                    label: const Text(
                                      'روزم رو بچین ✨',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final msgId = msg.id;
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
                                  final removedMsg = msg;
                                  final removedIndex = index;
                                  setState(() {
                                    _messages.removeAt(removedIndex);
                                  });

                                  // Defer DB deletion for 5s
                                  _pendingDeletedMsgs[msgId] = removedMsg;
                                  final t = Timer(const Duration(seconds: 5), () async {
                                    await ChatRepository.instance.deleteMessage(msgId);
                                    _pendingDeleteTimers.remove(msgId);
                                    _pendingDeletedMsgs.remove(msgId);
                                  });
                                  _pendingDeleteTimers[msgId] = t;

                                  _showTopToast(
                                    'پیام حذف شد.',
                                    CupertinoIcons.trash,
                                    Colors.redAccent,
                                    onUndo: () {
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
                                    },
                                  );
                                },
                                child: StreamingMessageBubble(
                                  message: msg,
                                  isLast: index == _messages.length - 1,
                                  onAction: _handleAction,
                                  onCopy: _copyToClipboard,
                                ),
                              );
                            },
                          ),
              ),


              if (_currentQuickReplies.isNotEmpty)
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentQuickReplies.length,
                    itemBuilder: (context, index) {
                      final text = _currentQuickReplies[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ActionChip(
                          label: Text(
                            text,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: colors.primary.withValues(alpha: 0.1),
                          onPressed: () => _send(text),
                        ),
                      );
                    },
                  ),
                ),

              // Chat Input row
              SafeArea(
                bottom: !widget.isTab,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    widget.isTab ? 84.0 : 12.0,
                  ),
                  child: Row(
                    children: [
                      if (!_isStreaming) ...[
                        GestureDetector(
                          onLongPressStart: (_) => _startListening(),
                          onLongPressEnd: (_) => _stopListening(),
                          onLongPressCancel: _stopListening,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: _isListening ? Colors.redAccent : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                            child: Icon(
                              _isListening ? CupertinoIcons.mic_fill : CupertinoIcons.mic,
                              color: _isListening ? Colors.white : colors.textPrimary,
                              size: 18,
                            ),
                          )
                          .animate(target: _isListening ? 1.0 : 0.0)
                          .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 150.ms)
                          .then()
                          .shake(hz: 3, curve: Curves.easeInOut),
                        ),
                        const SizedBox(width: 8),
                      ],
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
                            controller: _textController,
                            minLines: 1,
                            maxLines: 4,
                            enabled: !_isStreaming,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              color: colors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: InputBorder.none,
                              hintText: _isStreaming ? 'دستیار در حال نوشتن است...' : 'گفتگو با دستیار ریتمو...',
                              hintStyle: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                color: colors.textSecondary.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isStreaming ? _cancelStream : () => _send(_textController.text),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: _isStreaming
                              ? const Color(0xffEF4444)
                              : const Color(0xff5B8AF5),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayPlanningLoadingState(RitmoColors colors) {
    final stepMsg = _dayPlanningStepMessage ?? 'در حال پردازش و استخراج لایه‌ها...';
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xff06B6D4).withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff06B6D4).withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 4,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xff06B6D4).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff06B6D4)),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'در حال تنظیم هوشمند برنامه روز',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                stepMsg,
                key: ValueKey<String>(stepMsg),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xff06B6D4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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
                            color: isDark ? Colors.white : colors.textPrimary,
                          ),
                        ),
                        if (widget.onUndo != null) ...[
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
