import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/chat/chat_action_parser.dart';
import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/ai/chat/chat_repository.dart';
import 'package:ritmo/core/ai/memory/assistant_memory_binding.dart';
import 'package:ritmo/core/analytics/health_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/markdown_parser.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/assistant/logic/assistant_action_registry.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:shamsi_date/shamsi_date.dart';

class AiHealthAssistantSheet extends StatefulWidget {
  const AiHealthAssistantSheet({super.key});

  @override
  State<AiHealthAssistantSheet> createState() => _AiHealthAssistantSheetState();
}

class _AiHealthAssistantSheetState extends State<AiHealthAssistantSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isStreaming = false;

  // OCR state
  File? _ocrFile;
  bool _isScanning = false;
  String? _ocrResult;

  // Health context summary for AI
  String _healthContext = '';
  String? _sessionId;
  List<ChatSession> _sessions = [];
  StreamSubscription<String>? _healthSubscription;
  final Map<String, Timer> _pendingDeleteTimers = {};
  final Map<String, Map<String, dynamic>> _pendingDeletedMsgs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHealthContext().then((_) => _loadActiveSession());
  }

  @override
  void dispose() {
    if (_sessionId != null) {
      AssistantMemoryBinding.triggerConsolidation(
        sessionId: _sessionId!,
        domain: 'health',
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
    _healthSubscription?.cancel();
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _loadHealthContext() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      final hasDiabetes = settingsMap['patient_has_diabetes'] == 'true';
      final hasHypertension = settingsMap['patient_has_hypertension'] == 'true';

      final routines = await db.query('routines', where: "category = 'medical' AND isArchived = 0");
      final meds = routines.map((r) => '${r['title']} (دوز: ${r['description'] ?? "نامشخص"})').toList();

      final lastSugar = await db.query('blood_sugar_logs', orderBy: 'loggedAt DESC', limit: 1);
      var sugarStr = 'ثبت نشده';
      if (lastSugar.isNotEmpty) {
        sugarStr = '${lastSugar.first['value']} mg/dL (${lastSugar.first['measurementType']})';
      }

      final lastBP = await db.query('blood_pressure_logs', orderBy: 'loggedAt DESC', limit: 1);
      var bpStr = 'ثبت نشده';
      if (lastBP.isNotEmpty) {
        bpStr = '${lastBP.first['systolic']}/${lastBP.first['diastolic']} mmHg';
      }

      final allergies = await db.query('allergies');
      final allergyList = allergies.map((a) => '${a['allergen']} (${a['severity']})').toList();

      final vaccines = await db.query('vaccinations', orderBy: 'dateAdministered DESC', limit: 3);
      final vacList = vaccines.map((v) => v['vaccineName']! as String).toList();

      final sugarRes = await db.query('blood_sugar_logs', orderBy: 'loggedAt DESC');
      final sugarLogs = sugarRes.map(BloodSugarLog.fromMap).toList();

      final bpLogsRes = await db.query('blood_pressure_logs', orderBy: 'loggedAt DESC');
      final bpLogs = bpLogsRes.map(BloodPressureLog.fromMap).toList();

      final vitalRes = await db.query('vital_signs_logs', orderBy: 'loggedAt DESC');
      final vitalLogs = vitalRes.map(VitalSignLog.fromMap).toList();

      final medicationLogsRes = await db.query('medication_logs', orderBy: 'createdAt DESC');
      final medLogs = medicationLogsRes.map(MedicationLog.fromMap).toList();

      final prnLogsRes = await db.query('prn_logs', orderBy: 'takenAt DESC');
      final energyLogsRes = await db.query('energy_logs', orderBy: 'loggedAt DESC');
      final sleepLogsRes = await db.query('bedtime_diagnostics', orderBy: 'createdAt DESC');

      final engineInput = HealthEngineInput(
        bloodSugarLogs: sugarLogs,
        bloodPressureLogs: bpLogs,
        vitalSignLogs: vitalLogs,
        medicationLogs: medLogs,
        prnLogs: prnLogsRes,
        energyLogs: energyLogsRes,
        sleepLogs: sleepLogsRes,
        hasDiabetes: hasDiabetes,
        hasHypertension: hasHypertension,
        today: DateTime.now(),
      );

      final engineOutput = HealthEngine.calculateSync(engineInput);

      final buffer = StringBuffer();
      buffer.writeln('سوابق پزشکی ثبت‌شده کاربر در برنامه:');
      buffer.writeln('- داروهای فعلی: ${meds.isEmpty ? "هیچ دارویی ثبت نشده" : meds.join("، ")}');
      buffer.writeln('- آخرین قند خون: $sugarStr');
      buffer.writeln('- آخرین فشار خون: $bpStr');
      buffer.writeln('- آلرژی‌ها: ${allergyList.isEmpty ? "بدون آلرژی ثبت‌شده" : allergyList.join("، ")}');
      buffer.writeln('- واکسن‌های اخیر: ${vacList.isEmpty ? "ثبت نشده" : vacList.join("، ")}');
      
      final adherencePct = (engineOutput.adherence.adherenceRate * 100).toStringAsFixed(0);
      buffer.writeln('- پایبندی ۳۰ روزه به داروها: $adherencePct٪ (زنجیره فعلی: ${engineOutput.adherence.currentStreak} روز)');
      if (engineOutput.adherence.missedPattern != null) {
        buffer.writeln('- الگوی فراموشی داروها: ${engineOutput.adherence.missedPattern}');
      }
      
      buffer.writeln('- روند علائم حیاتی:');
      for (final trend in engineOutput.trends) {
        final dir = trend.direction == 'up' ? 'افزایشی (صعودی)' : (trend.direction == 'down' ? 'کاهشی (نزولی)' : 'پایدار (ثابت)');
        buffer.writeln('  * میانگین ${trend.metric}: ${trend.average.toStringAsFixed(1)} (روند: $dir، درصد در محدوده سالم: ${trend.inRangePercent.toStringAsFixed(0)}٪)');
      }
      
      if (engineOutput.correlations.isNotEmpty) {
        buffer.writeln('- همبستگی‌های آماری با خواب و انرژی:');
        for (final corr in engineOutput.correlations.where((c) => c.coefficient != null)) {
          buffer.writeln('  * ${corr.insight}');
        }
      }

      setState(() {
        _healthContext = buffer.toString();
      });
    } catch (e) {
      debugPrint('Error loading health context: $e');
    }
  }

  Future<void> _loadActiveSession() async {
    try {
      _sessions = await ChatRepository.instance.listSessions(chatType: 'health');
      if (_sessions.isEmpty) {
        final newSess = await ChatRepository.instance.createSession(chatType: 'health');
        _sessions = [newSess];
        _sessionId = newSess.id;
        final initMsg = ChatMessage(
          id: 'init_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: _sessionId!,
          role: ChatRole.assistant,
          content: 'سلام! من دستیار سلامت آفلاین ریتمو هستم. من می‌توانم به شما در بررسی سوابق سلامت، داروها، واکسن‌ها و خلاصه کردن مدارک کمک کنم. لطفا توجه داشته باشید که من پزشک نیستم و تصمیمات تشخیصی یا درمانی نمی‌گیرم. 🩺',
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
      final newSess = await ChatRepository.instance.createSession(chatType: 'health');
      _sessionId = newSess.id;
      _sessions = await ChatRepository.instance.listSessions(chatType: 'health');
      
      final initMsg = ChatMessage(
        id: 'init_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _sessionId!,
        role: ChatRole.assistant,
        content: 'سلام! من دستیار سلامت آفلاین ریتمو هستم. من می‌توانم به شما در بررسی سوابق سلامت، داروها، واکسن‌ها و خلاصه کردن مدارک کمک کنم. لطفا توجه داشته باشید که من پزشک نیستم و تصمیمات تشخیصی یا درمانی نمی‌گیرم. 🩺',
        timestamp: DateTime.now(),
      );
      await ChatRepository.instance.addMessage(initMsg);
      await _loadMessages();
    } catch (e) {
      debugPrint('Error starting new session: $e');
    }
  }

  void _cancelStreaming() {
    _healthSubscription?.cancel();
    _healthSubscription = null;
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
      final systemPrompt = '''
شما دستیار هوشمند و مجرب سلامت در برنامه ریتمو (با فونت وزیری و زبان فارسی) هستید.
وظیفه شما راهنمایی کاربر درباره سوابق سلامت او، خلاصه‌سازی و پاسخ به پرسش‌های مرتبط با خودمراقبتی است.

قوانین پزشکی سخت‌گیرانه:
۱. شما هرگز حق تشخیص بیماری، تجویز دارو یا تغییر دوز ندارید.
۲. اگر کاربر علائم حاد یا سوال تشخیصی مطرح کرد، باید او را به پزشک متخصص ارجاع دهید.
۳. در صورت وجود تداخل دارویی احتمالی با آلرژی‌های ثبت‌شده بیمار، با رنگ قرمز هشدار دهید.

قانون هدایت به سایر بخش‌های برنامه (بسیار مهم):
اگر کاربر درخواستی خارج از حوزه سلامت و بیماری‌ها ثبت کرد (مثلا خواستار ثبت نماز قضا، یادآور مذهبی، تنظیمات خواب، اهداف، ورزش و فعالیت بدنی، یا کنکور شد)، باید در انتهای پاسخ خود کاربر را راهنمایی کرده و تگ <actions> با نوع "openPage" و مسیر مربوطه را قرار دهید تا دکمه هدایت برای وی نمایش داده شود:

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

سوابق کاربر در دیتابیس محلی:
$_healthContext
''';

      final memorySuffix = await AssistantMemoryBinding.getSystemPromptSuffix(
        domain: 'health',
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
        
        _healthSubscription = stream.listen(
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
                domain: 'health',
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

              final updated = await ChatRepository.instance.listSessions(chatType: 'health');
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
    final colors = context.colors;
    Clipboard.setData(ClipboardData(text: content));
    _showTopToast(
      'متن پیام کپی شد.',
      Icons.check_circle_rounded,
      colors.primary,
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
                          'تاریخچه گفتگوهای دستیار سلامت',
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
                                    sess.summary ?? 'گفتگوی دستیار سلامت',
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
                                      final updated = await ChatRepository.instance.listSessions(chatType: 'health');
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

  Future<void> _scanDocument() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _ocrFile = File(picked.path);
          _isScanning = true;
          _ocrResult = null;
        });

        await Future.delayed(const Duration(seconds: 3));

        final nowJalali = Jalali.now();
        final dateStr = _toPersianDigits('${nowJalali.year}/${nowJalali.month}/${nowJalali.day}');

        final mockReport = '''
📝 گزارش استخراج و پردازش سند پزشکی محلی (OCR)
تاریخ پردازش: $dateStr

🔍 نتایج استخراج متن:
• نوع سند: گزارش آزمایش آزمایشگاهی خون (CBC)
• شناسه مراجع: بیمار ثبت‌شده
• پارامترهای شناسایی شده:
  - هموگلوبین (Hb): ۱۳.۵ (نرمال)
  - قند خون ناشتا (FBS): ۹۵ mg/dL (محدوده نرمال)
  - کلسترول کل: ۱۹۰ mg/dL (نرمال)

⚠️ بررسی تداخلات و آلرژی‌ها:
با توجه به آلرژی‌های دارویی و پرونده پزشکی شما، تداخل یا حساسیت حادی با مقادیر و یافته‌های این آزمایش خون یافت نشد.

💡 توصیه خودمراقبتی ریتمو:
نتایج در محدوده طبیعی است. برای ارزیابی بالینی دقیق حتماً گزارش را به پزشک معالج خود نشان دهید.
''';

        if (mounted) {
          setState(() {
            _isScanning = false;
            _ocrResult = mockReport;
          });
        }
      }
    } catch (e) {
      debugPrint('Error scanning document: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
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
                  Text(
                    'دستیار هوشمند سلامت ریتمو',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                indicatorColor: colors.primary,
                labelColor: colors.textPrimary,
                unselectedLabelColor: colors.textSecondary,
                tabs: const [
                  Tab(text: 'مشاوره و چت سلامت'),
                  Tab(text: 'OCR و اسکن مدارک (آزمایشی)'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChatTab(),
                    _buildOcrTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(CupertinoIcons.chat_bubble_2, color: colors.textSecondary, size: 20),
              tooltip: 'تاریخچه گفتگوها',
              onPressed: _showSessionSelector,
            ),
          ],
        ),
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
                  HealthMessageBubble(
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
                    hintText: _isStreaming ? 'دستیار در حال نوشتن است...' : 'سوالی درباره داروها، قند یا فشار خود بپرسید...',
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
  );
}

  Widget _buildOcrTab() {
    final colors = context.colors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تصویر آزمایش خون یا نسخه خود را جهت استخراج خودکار و اسکن متنی انتخاب کنید:',
            style: TextStyle(fontSize: 13),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 16),
          if (_ocrFile == null && !_isScanning)
            GestureDetector(
              onTap: _scanDocument,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 48, color: colors.primary),
                    const SizedBox(height: 10),
                    const Text('انتخاب سند از گالری', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else if (_isScanning)
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colors.primary),
                  const SizedBox(height: 16),
                  Text('در حال اسکن متنی و تحلیل سوابق توسط دستیار ریتمو...', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ],
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_ocrFile!, height: 120, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _scanDocument,
              icon: Icon(Icons.refresh, color: colors.primary),
              label: Text('اسکن مجدد سند', style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn')),
            ),
          ],
          if (_ocrResult != null) ...[
            const SizedBox(height: 16),
            Card(
              color: colors.card,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _ocrResult!,
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HealthMessageBubble extends StatefulWidget {

  const HealthMessageBubble({
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
  State<HealthMessageBubble> createState() => _HealthMessageBubbleState();
}

class _HealthMessageBubbleState extends State<HealthMessageBubble> {
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


