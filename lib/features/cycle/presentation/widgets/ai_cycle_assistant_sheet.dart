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
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/markdown_parser.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/assistant/logic/assistant_action_registry.dart';
import 'package:sqflite/sqflite.dart';

/// Helper function to check and display the consent sheet before starting AI chat.
void showCycleAiConsentSheet(
  BuildContext context, {
  required CycleEngineOutput? engineOutput,
  required List<Map<String, dynamic>> dayLogs,
  required Map<String, String> settings,
  required VoidCallback onConsentGranted,
  bool isPregnancyMode = false,
}) {
  final hasConsent = settings['cycle_consent_ai'] == 'true';
  if (hasConsent) {
    onConsentGranted();
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CycleAiConsentSheet(
      engineOutput: engineOutput,
      dayLogs: dayLogs,
      settings: settings,
      onConsentGranted: onConsentGranted,
      isPregnancyMode: isPregnancyMode,
    ),
  );
}

/// Consent gate widget that explains privacy and gets explicit consent.
class CycleAiConsentSheet extends StatefulWidget {

  const CycleAiConsentSheet({
    super.key,
    required this.engineOutput,
    required this.dayLogs,
    required this.settings,
    required this.onConsentGranted,
    this.isPregnancyMode = false,
  });
  final CycleEngineOutput? engineOutput;
  final List<Map<String, dynamic>> dayLogs;
  final Map<String, String> settings;
  final VoidCallback onConsentGranted;
  final bool isPregnancyMode;

  @override
  State<CycleAiConsentSheet> createState() => _CycleAiConsentSheetState();
}

class _CycleAiConsentSheetState extends State<CycleAiConsentSheet> {
  bool _isSaving = false;

  Future<void> _grantConsent() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'app_settings',
        {
          'key': 'cycle_consent_ai',
          'value': 'true',
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      widget.settings['cycle_consent_ai'] = 'true';

      if (mounted) {
        Navigator.pop(context); // close consent sheet
        widget.onConsentGranted(); // open assistant chat sheet
      }
    } catch (e) {
      debugPrint('Error saving consent: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.60,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.65),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.sparkles, color: Color(0xffEC4899), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    widget.isPregnancyMode
                        ? 'فعالسازی دستیار هوشمند بارداری ریتمو ✨'
                        : 'فعالسازی دستیار هوشمند چرخه بدنی ✨',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulletPoint(
                        CupertinoIcons.lock_shield_fill,
                        'امنیت و قفل محلی:',
                        'این گفتگو کاملاً خصوصی بوده و پشت قفل امنیتی دستگاه شما (PIN/بیومتریک) محافظت می‌شود.',
                      ),
                      const SizedBox(height: 16),
                      _buildBulletPoint(
                        CupertinoIcons.heart_fill,
                        'ماهیت خودمراقبتی:',
                        widget.isPregnancyMode
                            ? 'پاسخ‌های این دستیار توصیه‌های خودمراقبتی و بهداشت بارداری هستند و هرگز جایگزین تشخیص یا درمان پزشک متخصص نمی‌باشند.'
                            : 'پاسخ‌های این دستیار توصیه‌های خودمراقبتی و بهداشت قاعدگی هستند و هرگز جایگزین تشخیص یا درمان پزشک متخصص نمی‌باشند.',
                      ),
                      const SizedBox(height: 16),
                      _buildBulletPoint(
                        CupertinoIcons.eye_slash_fill,
                        'کنترل کامل داده‌ها:',
                        widget.isPregnancyMode
                            ? 'اطلاعات بارداری شما در دستگاه می‌ماند. تنها در صورتی که خودتان کلید ارسال داده را روشن کنید، خلاصه‌ای از وضعیت فیزیکی شما برای تحلیل بهتر به سرور ارسال می‌شود.'
                            : 'اطلاعات چرخه شما در دستگاه می‌ماند. تنها در صورتی که خودتان کلید ارسال داده را روشن کنید، خلاصه‌ای از وضعیت فیزیکی شما برای تحلیل بهتر به سرور ارسال می‌شود (بدون ارسال داده‌های مربوط به باروری).',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isSaving)
                const Center(child: CircularProgressIndicator(color: Color(0xffEC4899)))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _grantConsent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffEC4899),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'متوجه شدم، ادامه گفتگو',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'انصراف',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: colors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(IconData icon, String title, String description) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xffEC4899), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AiCycleAssistantSheet extends StatefulWidget {

  const AiCycleAssistantSheet({
    super.key,
    required this.engineOutput,
    required this.dayLogs,
    required this.settings,
    this.isPregnancyMode = false,
    this.pregnancyWeek,
  });
  final CycleEngineOutput? engineOutput;
  final List<Map<String, dynamic>> dayLogs;
  final Map<String, String> settings;
  final bool isPregnancyMode;
  final int? pregnancyWeek;

  @override
  State<AiCycleAssistantSheet> createState() => _AiCycleAssistantSheetState();
}

class _AiCycleAssistantSheetState extends State<AiCycleAssistantSheet> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isStreaming = false;
  bool _shareData = false;
  bool _shareFertilityData = false;
  String _personalContext = '';
  String? _sessionId;
  List<ChatSession> _sessions = [];
  StreamSubscription<String>? _cycleSubscription;
  final Map<String, Timer> _pendingDeleteTimers = {};
  final Map<String, Map<String, dynamic>> _pendingDeletedMsgs = {};

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _shareData = widget.settings['cycle_ai_share_data'] == 'true';
    _shareFertilityData = widget.settings['cycle_ai_share_fertility_data'] == 'true';
    _updateContext();
    _loadActiveSession();
  }

  @override
  void dispose() {
    if (_sessionId != null) {
      AssistantMemoryBinding.triggerConsolidation(
        sessionId: _sessionId!,
        domain: 'cycle',
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
    _cycleSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateContext() {
    if (!_shareData) {
      _personalContext = '';
      return;
    }

    final buffer = StringBuffer();
    if (widget.isPregnancyMode) {
      buffer.writeln('وضعیت کاربر: بارداری');
      buffer.writeln('هفته بارداری فعلی: ${widget.pregnancyWeek}');
    } else {
      buffer.writeln('خلاصه چرخه کاربر:');
      
      if (widget.engineOutput != null) {
        final out = widget.engineOutput!;
        buffer.writeln('- فاز چرخه: ${_getPhaseLabel(out.currentPhase)}');
        buffer.writeln('- روز چرخه: ${out.dayOfCycle}');
        if (out.dayOfPeriod > 0) {
          buffer.writeln('- روز خونریزی: ${out.dayOfPeriod}');
        }
        buffer.writeln('- وضعیت منظم بودن: ${out.isIrregular ? "نامنظم" : "منظم"}');
        buffer.writeln('- بلوغ داده‌های ثبت شده: ${out.dataMaturity}');
        final startStr = out.nextPeriodWindowStart.toIso8601String().substring(0, 10);
        final endStr = out.nextPeriodWindowEnd.toIso8601String().substring(0, 10);
        buffer.writeln('- بازه تقریبی قاعدگی بعدی: $startStr تا $endStr');

        if (_shareFertilityData) {
          final ovStr = out.ovulationDay.toIso8601String().substring(0, 10);
          final fertStartStr = out.fertileWindowStart.toIso8601String().substring(0, 10);
          final fertEndStr = out.fertileWindowEnd.toIso8601String().substring(0, 10);
          buffer.writeln('- روز تخمک‌گذاری پیش‌بینی شده: $ovStr');
          buffer.writeln('- پنجره باروری پیش‌بینی شده: $fertStartStr تا $fertEndStr');
        }
      }

      final avgLength = widget.settings['cycle_avg_length'] ?? '28';
      final avgPeriod = widget.settings['cycle_avg_period'] ?? '5';
      buffer.writeln('- طول دوره چرخه متوسط: $avgLength روز');
      buffer.writeln('- طول قاعدگی متوسط: $avgPeriod روز');

      final isPregMode = widget.settings['cycle_pregnancy_mode'] == 'true';
      if (_shareFertilityData && isPregMode) {
        final pregStart = widget.settings['cycle_pregnancy_start_date'] ?? '';
        final pregDue = widget.settings['cycle_pregnancy_due_date'] ?? '';
        buffer.writeln('- در حال حاضر در حالت بارداری فعال قرار دارد.');
        if (pregStart.isNotEmpty) buffer.writeln('  * تاریخ شروع بارداری (LMP): $pregStart');
        if (pregDue.isNotEmpty) buffer.writeln('  * تاریخ تقریبی زایمان (EDD): $pregDue');
      }

      if (widget.dayLogs.isNotEmpty) {
        buffer.writeln('- علائم ثبت شده در ۷ روز اخیر:');
        final recent = widget.dayLogs.take(7);
        for (final log in recent) {
          final date = log['logDate'] ?? '';
          final flow = log['flowLevel'] ?? 'نامشخص';
          final mood = log['mood'] ?? 'نامشخص';
          final energy = log['energyTag'] ?? 'نامشخص';
          final symptoms = log['symptomsJson'] ?? '[]';
          buffer.writeln('  * تاریخ: $date، خونریزی: $flow، خلق: $mood، انرژی: $energy، علائم: $symptoms');
        }
      }
    }

    _personalContext = buffer.toString();
  }

  String _getPhaseLabel(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'قاعدگی (خونریزی)';
      case CyclePhase.follicular:
        return 'فولیکولار (رشد)';
      case CyclePhase.ovulation:
        return 'تخمک‌گذاری';
      case CyclePhase.luteal:
        return 'لوتئال (پیش از قاعدگی)';
      case CyclePhase.noData:
        return 'نامشخص (داده ناکافی)';
    }
  }

  Future<void> _toggleShareData(bool val) async {
    setState(() {
      _shareData = val;
      if (!val) {
        _shareFertilityData = false;
      }
    });
    _updateContext();

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'app_settings',
        {
          'key': 'cycle_ai_share_data',
          'value': val ? 'true' : 'false',
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      widget.settings['cycle_ai_share_data'] = val ? 'true' : 'false';

      if (!val) {
        await db.insert(
          'app_settings',
          {
            'key': 'cycle_ai_share_fertility_data',
            'value': 'false',
            'updatedAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        widget.settings['cycle_ai_share_fertility_data'] = 'false';
      }
    } catch (e) {
      debugPrint('Error updating share data preference: $e');
    }
  }

  Future<void> _toggleShareFertilityData(bool val) async {
    setState(() {
      _shareFertilityData = val;
    });
    _updateContext();

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'app_settings',
        {
          'key': 'cycle_ai_share_fertility_data',
          'value': val ? 'true' : 'false',
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      widget.settings['cycle_ai_share_fertility_data'] = val ? 'true' : 'false';
    } catch (e) {
      debugPrint('Error updating share fertility data preference: $e');
    }
  }

  Future<void> _loadActiveSession() async {
    try {
      _sessions = await ChatRepository.instance.listSessions(chatType: 'cycle');
      if (_sessions.isEmpty) {
        final newSess = await ChatRepository.instance.createSession(chatType: 'cycle');
        _sessions = [newSess];
        _sessionId = newSess.id;
        final initMsg = ChatMessage(
          id: 'init_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: _sessionId!,
          role: ChatRole.assistant,
          content: widget.isPregnancyMode
              ? 'سلام! من دستیار هوشمند خودمراقبتی دوران بارداری ریتمو هستم. شما در هفته ${_toPersianDigits(widget.pregnancyWeek.toString())} بارداری هستید. چطور می‌توانم در زمینه خودمراقبتی، تغییرات بدنی، رشد جنین و مدیریت علائم این هفته به شما کمک کنم؟ 🤰✨'
              : 'سلام! من دستیار هوشمند چرخه بدنی ریتمو هستم. چطور می‌توانم در زمینه بهبود دردهای قاعدگی، خودمراقبتی و بهداشت این فاز به شما کمک کنم؟ 🌸',
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
      () {
        // Refresh context if applicable
      },
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
      final newSess = await ChatRepository.instance.createSession(chatType: 'cycle');
      _sessionId = newSess.id;
      _sessions = await ChatRepository.instance.listSessions(chatType: 'cycle');
      
      final initMsg = ChatMessage(
        id: 'init_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _sessionId!,
        role: ChatRole.assistant,
        content: widget.isPregnancyMode
            ? 'سلام! من دستیار هوشمند خودمراقبتی دوران بارداری ریتمو هستم. شما در هفته ${_toPersianDigits(widget.pregnancyWeek.toString())} بارداری هستید. چطور می‌توانم در زمینه خودمراقبتی، تغییرات بدنی، رشد جنین و مدیریت علائم این هفته به شما کمک کنم? 🤰✨'
            : 'سلام! من دستیار هوشمند چرخه بدنی ریتمو هستم. چطور می‌توانم در زمینه بهبود دردهای قاعدگی، خودمراقبتی و بهداشت این فاز به شما کمک کنم؟ 🌸',
        timestamp: DateTime.now(),
      );
      await ChatRepository.instance.addMessage(initMsg);
      await _loadMessages();
    } catch (e) {
      debugPrint('Error starting new session: $e');
    }
  }

  void _cancelStreaming() {
    _cycleSubscription?.cancel();
    _cycleSubscription = null;
    setState(() {
      _isStreaming = false;
      _isTyping = false;
    });
  }
  Future<void> _sendMessage() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    _chatController.clear();
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
      final systemPrompt = widget.isPregnancyMode
          ? '''
شما یک دستیار هوشمند، همدل و مجرب در زمینه بهداشت بارداری، رشد جنین و خودمراقبتی دوران بارداری (با فونت وزیری و زبان فارسی) در برنامه ریتمو هستید.
وظیفه شما راهنمایی کاربر درباره خودمراقبتی‌های فیزیکی و روحی در دوران بارداری، مدیریت تهوع صبحگاهی، خستگی، ورزش‌های بارداری ملایم، و سوالات متداول دوران بارداری متناسب با هفتهٔ بارداری کاربر است.

قوانین سخت‌گیرانه بهداشتی، شرعی، قانونی و حریم خصوصی:
۱. شما به هیچ وجه حق تجویز دارو، قرص، مکمل (شیمیایی یا گیاهی) یا معرفی برندهای دارویی را ندارید. حتی ویتامین‌ها یا مکمل‌ها نظیر آهن، اسید فولیک، مولتی ویتامین یا کلسیم را نباید تجویز یا دوز دهی کنید. در صورت وجود علائم خطرناک (درد شدید شکم، انقباضات زودهنگام، لکه‌بینی، خونریزی، سردرد شدید یا ورم ناگهانی)، کاربر را با همدلی به پزشک متخصص زنان و زایمان ارجاع دهید.
۲. با لحنی آرامش‌بخش، محترمانه، به دور از قضاوت و بسیار محتاط با کاربر گفتگو کنید.

${_shareData ? 'اطلاعات بارداری کاربر برای شخصی‌سازی گفتگو:\nکاربر در هفتهٔ ${widget.pregnancyWeek} بارداری قرار دارد.' : 'کاربر تمایل به ارسال اطلاعات بارداری خود ندارد؛ پاسخ‌ها را به شکل عمومی و بهداشت کلی بارداری بنویسید.'}

قانون هدایت به سایر بخش‌های برنامه:
اگر کاربر درخواستی خارج از حوزه بهداشت بارداری ثبت کرد (مثلا خواستار ثبت نماز قضا، یادآور مذهبی، تنظیمات خواب، اهداف، ورزش و فعالیت بدنی، یا کنکور شد)، باید در انتهای پاسخ خود کاربر را راهنمایی کرده و تگ <actions> با نوع "openPage" و مسیر مربوطه را قرار دهید تا دکمه هدایت برای وی نمایش داده شود:

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
'''
          : '''
شما یک دستیار هوشمند، همدل و مجرب در زمینه بهداشت چرخه بدنی و قاعدگی (با فونت وزیری و زبان فارسی) در برنامه ریتمو هستید.
وظیفه شما راهنمایی کاربر درباره تسکین دردهای قاعدگی، علائم سندروم پیش از قاعدگی (PMS)، خودمراقبتی‌های فیزیکی و روحی در فازهای مختلف چرخه است.

قوانین سخت‌گیرانه بهداشتی، شرعی، قانونی و حریم خصوصی:
۱. شما به هیچ وجه حق تجویز دارو، قرص یا معرفی برندهای دارویی (شیمیایی یا گیاهی) را ندارید. در صورت وجود علائم خطرناک (درد بسیار شدید و غیرعادی، خونریزی بسیار شدید، تب یا علائم اورژانسی)، کاربر را با همدلی به پزشک متخصص ارجاع دهید.
۲. ${_shareFertilityData ? 'شما اجازه دارید با توجه به اطلاعات ارسالی تخمک‌گذاری، پنجره باروری و یا بارداری کاربر، او را در جهت خودمراقبتی و آگاهی بیشتر راهنمایی کنید. اما از تشخیص پزشکی، تجویز هرگونه دارو یا ارائه نظر قطعی اکیداً خودداری نمایید.' : 'قانون ممنوعیت باروری (بسیار مهم): از آنجا که کاربر اجازه دسترسی به داده‌های باروری/تخمک‌گذاری را نداده است، شما تحت هیچ شرایطی حق صحبت در مورد پنجره باروری، تخمک‌گذاری، برنامه‌ریزی برای بارداری یا جلوگیری از بارداری را ندارید و نباید هیچ داده یا تحلیلی در این باره ارائه دهید. تمرکز شما صرفاً روی سلامت قاعدگی، تسکین درد و خودمراقبتی باشد.'}
۳. شما به هیچ وجه حق ارائه توصیه، راهکار یا معرفی دارو برای سقط جنین، توصیه به خودارضایی یا هرگونه عمل خلاف شرع اسلام و قوانین جاری کشور را ندارید.
۴. با لحنی آرامش‌بخش، محترمانه و به دور از قضاوت با کاربر گفتگو کنید.

${_shareData ? 'اطلاعات چرخه کاربر برای شخصی‌سازی گفتگو:\n$_personalContext' : 'کاربر تمایل به ارسال اطلاعات چرخه خود ندارد؛ پاسخ‌ها را به شکل عمومی و بهداشت کلی قاعدگی بنویسید.'}

قانون هدایت به سایر بخش‌های برنامه:
اگر کاربر درخواستی خارج از حوزه چرخه بدنی و قاعدگی ثبت کرد (مثلا خواستار ثبت نماز قضا، یادآور مذهبی، تنظیمات خواب، اهداف، ورزش و فعالیت بدنی، یا کنکور شد)، باید در انتهای پاسخ خود کاربر را راهنمایی کرده و تگ <actions> با نوع "openPage" و مسیر مربوطه را قرار دهید تا دکمه هدایت برای وی نمایش داده شود:

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
        domain: 'cycle',
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
        
        _cycleSubscription = stream.listen(
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
                domain: 'cycle',
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

              final updated = await ChatRepository.instance.listSessions(chatType: 'cycle');
              setState(() {
                _sessions = updated;
              });
            }
          },
          cancelOnError: true,
        );
      }
    } catch (e) {
      debugPrint('Error calling AI API: $e');
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
      const Color(0xffEC4899),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return RitmoTheme.glassCardLight(
              color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.65),
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
                          'تاریخچه گفتگوهای دستیار چرخه بدنی',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.add, color: Color(0xffEC4899), size: 22),
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
                                  selectedColor: const Color(0xffEC4899),
                                  title: Text(
                                    sess.summary ?? 'گفتگوی دستیار چرخه بدنی',
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
                                      final updated = await ChatRepository.instance.listSessions(chatType: 'cycle');
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
        color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.65),
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
                      const Icon(CupertinoIcons.sparkles, color: Color(0xffEC4899), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.isPregnancyMode
                            ? 'دستیار هوشمند بارداری'
                            : 'دستیار خودمراقبتی و بهداشت قاعدگی',
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

              if (widget.isPregnancyMode)
                SwitchListTile(
                  value: _shareData,
                  onChanged: _toggleShareData,
                  activeThumbColor: const Color(0xffEC4899),
                  activeTrackColor: const Color(0xffEC4899).withValues(alpha: 0.5),
                  title: Text(
                    'ارسال وضعیت بارداری به دستیار (اختیاری)',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13.5,
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'شامل هفتهٔ فعلی بارداری (${_toPersianDigits(widget.pregnancyWeek?.toString() ?? '۰')}) و اطلاعات پایه',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                )
              else ...[
                SwitchListTile(
                  value: _shareData,
                  onChanged: _toggleShareData,
                  activeThumbColor: const Color(0xffEC4899),
                  activeTrackColor: const Color(0xffEC4899).withValues(alpha: 0.5),
                  title: Text(
                    'ارسال وضعیت چرخه بدنی به دستیار (اختیاری)',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13.5,
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'شامل فاز فعلی، روز خونریزی و علائم روزهای اخیر',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_shareData)
                  SwitchListTile(
                    value: _shareFertilityData,
                    onChanged: _toggleShareFertilityData,
                    activeThumbColor: const Color(0xffEC4899),
                    activeTrackColor: const Color(0xffEC4899).withValues(alpha: 0.5),
                    title: Text(
                      'ارسال داده‌های تخمک‌گذاری و باروری (اختیاری)',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13.5,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'شامل تخمین روز تخمک‌گذاری و پنجره باروری',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
              Divider(color: colors.border),

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
                          CycleMessageBubble(
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
                            hintText: _isStreaming ? 'دستیار در حال نوشتن است...' : 'سوالی درباره تسکین درد، علائم یا خودمراقبتی بپرسید...',
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
                        backgroundColor: _isStreaming ? const Color(0xffEF4444) : const Color(0xffEC4899),
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
}

class CycleMessageBubble extends StatefulWidget {

  const CycleMessageBubble({
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
  State<CycleMessageBubble> createState() => _CycleMessageBubbleState();
}

class _CycleMessageBubbleState extends State<CycleMessageBubble> {
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
        ? const Color(0xffEC4899)
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


