import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart';
import 'package:sqflite/sqflite.dart';

class CyclePregnancyModeView extends StatefulWidget {

  const CyclePregnancyModeView({
    super.key,
    required this.pregnancyStartDate,
    required this.pregnancyDueDate,
    required this.onDeactivated,
    required this.settings,
    required this.dayLogs,
    this.engineOutput,
  });
  final String pregnancyStartDate;
  final String pregnancyDueDate;
  final VoidCallback onDeactivated;
  final Map<String, String> settings;
  final List<Map<String, dynamic>> dayLogs;
  final CycleEngineOutput? engineOutput;

  @override
  State<CyclePregnancyModeView> createState() => _CyclePregnancyModeViewState();
}

class _CyclePregnancyModeViewState extends State<CyclePregnancyModeView> {
  late DateTime _startDate;
  late DateTime _dueDate;
  late int _diffDays;
  late int _currentWeek;
  late int _currentDayInWeek;
  late int _remainingDays;
  late double _progressPercent;

  // Interactive logs state
  int _kickCount = 0;
  String _lastKickTime = '';
  List<String> _selectedSymptoms = [];
  final TextEditingController _noteController = TextEditingController();
  bool _isSavingLog = false;
  bool _hasSavedToday = false;
  bool _isEditingToday = false;

  final List<Map<String, String>> _pregnancySymptomsList = [
    {'id': 'nausea', 'label': '🤢 تهوع صبحگاهی'},
    {'id': 'fatigue', 'label': '😴 خستگی شدید'},
    {'id': 'backache', 'label': '⚡ کمر درد'},
    {'id': 'heartburn', 'label': '🔥 سوزش معده'},
    {'id': 'swelling', 'label': '🦶 تورم پا'},
    {'id': 'craving', 'label': '🍕 ویار شدید'},
    {'id': 'moody', 'label': '🎭 نوسان خلق'},
    {'id': 'headache', 'label': '🤕 سردرد'},
  ];

  final Map<int, Map<String, String>> pregnancyWeekData = {
    4: {'size': 'به اندازه یک دانه خشخاش', 'development': 'لانه گزینی جنین در رحم', 'tip': 'تغذیه سالم، نوشیدن آب کافی و استراحت را در اولویت قرار دهید'},
    5: {'size': 'به اندازه یک دانه کنجد', 'development': 'قلب شروع به تپیدن میکند', 'tip': 'از مصرف کافئین زیاد خودداری کنید'},
    6: {'size': 'به اندازه یک دانه عدس', 'development': 'صورت در حال شکلگیری است', 'tip': 'استراحت کافی داشته باشید'},
    8: {'size': 'به اندازه یک تمشک', 'development': 'انگشتان دست شکل گرفتهاند', 'tip': 'غذاهای سرشار از آهن طبیعی مصرف کنید'},
    10: {'size': 'به اندازه یک زیتون', 'development': 'اندامهای حیاتی تشکیل شدهاند', 'tip': 'پیادهروی روزانه ملایم را فراموش نکنید'},
    12: {'size': 'به اندازه یک آلو', 'development': 'ناخنها رشد میکنند', 'tip': 'ویزیت دوم پزشک و انجام غربالگری اول'},
    14: {'size': 'به اندازه یک لیمو', 'development': 'جنین میتواند اخم کند', 'tip': 'حالت تهوع معمولاً کاهش مییابد'},
    16: {'size': 'به اندازه یک آووکادو', 'development': 'جنین حرکات خود را حس میکند', 'tip': 'شاید اولین لگد را حس کنید!'},
    18: {'size': 'به اندازه یک فلفل دلمهای', 'development': 'گوشها کامل شدهاند', 'tip': 'با جنین حرف بزنید، صدایتان را میشنود'},
    20: {'size': 'به اندازه یک موز', 'development': 'نیمه راه! جنسیت قابل تشخیص', 'tip': 'سونوگرافی آنومالی و غربالگری دوم'},
    22: {'size': 'به اندازه یک بلال ذرت', 'development': 'ابروها و مژهها رشد کردهاند', 'tip': 'ورزشهای کگل را شروع کنید'},
    24: {'size': 'به اندازه یک بادمجان', 'development': 'ریهها در حال بلوغ هستند', 'tip': 'تست قند بارداری انجام دهید'},
    26: {'size': 'به اندازه یک کلم بروکلی', 'development': 'چشمها باز میشوند', 'tip': 'خواب به پهلوی چپ را عادت کنید'},
    28: {'size': 'به اندازه یک کدو حلوایی کوچک', 'development': 'مغز بهسرعت رشد میکند', 'tip': 'شمارش حرکات جنین را شروع کنید'},
    30: {'size': 'به اندازه یک کاهو', 'development': 'جنین وضعیت سر پایین میگیرد', 'tip': 'کلاس آمادگی زایمان را در نظر بگیرید'},
    32: {'size': 'به اندازه یک نارگیل', 'development': 'ناخنهای پا رشد کردهاند', 'tip': 'ساک بیمارستان را آماده کنید'},
    34: {'size': 'به اندازه یک طالبی', 'development': 'سیستم ایمنی فعال شده', 'tip': 'استراحت بیشتر و استفاده از بالش بارداری'},
    36: {'size': 'به اندازه یک هندوانه کوچک', 'development': 'جنین تقریباً کامل است', 'tip': 'ویزیتها هفتگی میشوند'},
    38: {'size': 'به اندازه یک کدو تنبل', 'development': 'ریهها بالغ شدهاند', 'tip': 'علائم شروع زایمان را بشناسید'},
    40: {'size': 'به اندازه یک هندوانه', 'development': 'آماده تولد! 🎉', 'tip': 'صبور باشید، نوبتش میرسد'},
  };

  @override
  void initState() {
    super.initState();
    _calculateValues();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);

    try {
      final db = await DatabaseHelper.instance.database;
      
      // 1. Load today's log from db
      final logs = await db.query(
        'cycle_day_logs',
        where: 'logDate = ?',
        whereArgs: [todayStr],
      );

      if (logs.isNotEmpty) {
        final log = logs.first;
        final symptomsJson = log['symptomsJson'] as String? ?? '[]';
        try {
          final List<dynamic> parsed = jsonDecode(symptomsJson);
          _selectedSymptoms = parsed.map((e) => e.toString()).toList();
        } catch (_) {}
        _noteController.text = log['note'] as String? ?? '';
        _hasSavedToday = true;
      } else {
        _hasSavedToday = false;
      }
      _isEditingToday = false;

      // 2. Load today's kick count & time
      final kickSetting = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['pregnancy_kicks_$todayStr'],
      );
      if (kickSetting.isNotEmpty) {
        _kickCount = int.tryParse(kickSetting.first['value'] as String? ?? '0') ?? 0;
      }

      final lastKickSetting = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['pregnancy_last_kick_$todayStr'],
      );
      if (lastKickSetting.isNotEmpty) {
        _lastKickTime = lastKickSetting.first['value'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('Error loading today pregnancy data: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _calculateValues() {
    _startDate = DateTime.tryParse(widget.pregnancyStartDate) ?? DateTime.now();
    _dueDate = DateTime.tryParse(widget.pregnancyDueDate) ?? _startDate.add(const Duration(days: 280));
    final today = DateTime.now();
    final todayTruncated = DateTime(today.year, today.month, today.day);
    final startTruncated = DateTime(_startDate.year, _startDate.month, _startDate.day);

    _diffDays = todayTruncated.difference(startTruncated).inDays;
    if (_diffDays < 0) _diffDays = 0;

    _currentWeek = (_diffDays / 7).floor() + 1;
    _currentDayInWeek = _diffDays % 7;
    
    // Clamp week to 1-42
    if (_currentWeek < 1) _currentWeek = 1;
    if (_currentWeek > 42) _currentWeek = 42;

    _remainingDays = _dueDate.difference(todayTruncated).inDays;
    if (_remainingDays < 0) _remainingDays = 0;

    _progressPercent = (_diffDays / 280.0).clamp(0.0, 1.0);
  }

  Map<String, String> _getWeekData(int week) {
    var targetWeek = 4;
    final keys = pregnancyWeekData.keys.toList()..sort();
    for (final k in keys) {
      if (k <= week) {
        targetWeek = k;
      }
    }
    return pregnancyWeekData[targetWeek]!;
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



  Future<void> _saveKick(int newCount) async {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);
    final nowTimeStr = '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
    
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        'app_settings',
        {
          'key': 'pregnancy_kicks_$todayStr',
          'value': newCount.toString(),
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (newCount > _kickCount) {
        await db.insert(
          'app_settings',
          {
            'key': 'pregnancy_last_kick_$todayStr',
            'value': nowTimeStr,
            'updatedAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _lastKickTime = nowTimeStr;
      }
    } catch (e) {
      debugPrint('Error saving kick count: $e');
    }

    setState(() {
      _kickCount = newCount;
    });
  }

  Future<void> _saveDailyLog() async {
    setState(() {
      _isSavingLog = true;
    });

    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final symptomsJson = jsonEncode(_selectedSymptoms);
    final note = _noteController.text.trim();

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'cycle_day_logs',
        {
          'id': 'preg_log_$todayStr',
          'logDate': todayStr,
          'symptomsJson': symptomsJson,
          'note': note,
          'createdAt': nowMs,
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving daily pregnancy logs: $e');
    }

    if (mounted) {
      setState(() {
        _isSavingLog = false;
        _hasSavedToday = true;
        _isEditingToday = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('وضعیت امروز با موفقیت ثبت شد 🌸', style: TextStyle(fontFamily: 'Vazirmatn')),
          backgroundColor: Color(0xffEC4899),
        ),
      );
    }
  }

  void _showPregnancyLoggerInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colors = context.colors;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.65),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: const Color(0xffEC4899).withValues(alpha: 0.15),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(CupertinoIcons.info_circle_fill, color: Color(0xffEC4899), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'چرا ثبت علائم بارداری مهم است؟',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                '🧠 دستیار هوشمند اختصاصی',
                'هوش مصنوعی با تحلیل علائم روزانه شما، مشاوره‌های بهداشتی، ورزشی و تغذیه‌ای دقیقاً متناسب با وضعیت بدنی‌تان ارائه می‌دهد.',
                colors,
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                '📋 گزارش سلامت برای پزشک زنان',
                'روند علائم ثبت‌شده در طول هفته‌ها ذخیره شده و می‌توانید آن را در ویزیت‌های دوره‌ای به پزشک متخصص خود ارائه دهید تا ارزیابی دقیق‌تری از سلامت شما و جنین داشته باشد.',
                colors,
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                '⚡ تشخیص علائم هشداردهنده',
                'برنامه با ردیابی علائم مفرط یا ناهماهنگ، در صورت نیاز به شما پیشنهاد استراحت بیشتر یا مراجعه به پزشک را می‌دهد.',
                colors,
              ),
              const SizedBox(height: 24),
              CupertinoButton(
                color: const Color(0xffEC4899),
                borderRadius: BorderRadius.circular(16),
                child: const Text('متوجه شدم', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
);
}

  Widget _buildInfoItem(String title, String desc, RitmoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            height: 1.6,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showPregnancyAssistant(BuildContext context) {
    showCycleAiConsentSheet(
      context,
      engineOutput: widget.engineOutput,
      dayLogs: widget.dayLogs,
      settings: widget.settings,
      isPregnancyMode: true,
      onConsentGranted: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AiCycleAssistantSheet(
            engineOutput: widget.engineOutput,
            dayLogs: widget.dayLogs,
            settings: widget.settings,
            isPregnancyMode: true,
            pregnancyWeek: _currentWeek,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekData = _getWeekData(_currentWeek);
    
    // Determine Trimester
    var trimesterTitle = '';
    var trimesterTips = '';
    if (_currentWeek <= 12) {
      trimesterTitle = 'سه‌ماهه اول (هفته ۱ تا ۱۲)';
      trimesterTips = 'تغذیه سالم، نوشیدن آب کافی، کنترل و مدیریت تهوع صبحگاهی و استراحت کافی اولویت‌های این دوره هستند. بدن شما در حال تغییرات شدید هورمونی و پایه‌گذاری اندام‌های حیاتی جنین است.';
    } else if (_currentWeek <= 26) {
      trimesterTitle = 'سه‌ماهه دوم (هفته ۱۳ تا ۲۶)';
      trimesterTips = 'با ورود به این دوره، تهوع کاهش یافته و انرژی شما بیشتر می‌شود. انجام ورزش‌های ملایم نظیر پیاده‌روی، تغذیه متنوع و غنی، و انجام غربالگری دوم (آنومالی) از نکات کلیدی این دوره است.';
    } else {
      trimesterTitle = 'سه‌ماهه سوم (هفته ۲۷ تا ۴۰+)';
      trimesterTips = 'در هفته‌های پایانی بر استراحت بیشتر، شمارش منظم حرکات جنین، آماده‌سازی ساک بیمارستان و آمادگی برای علائم زایمان تمرکز کنید. خوابیدن به پهلوی چپ به خون‌رسانی بهتر جنین کمک می‌کند.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffEC4899).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffEC4899).withValues(alpha: 0.15), width: 1.5),
                ),
                child: const Text('🤰', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دوران شیرین بارداری 🎀',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'پیگیری و خودمراقبتی هفته به هفته بارداری',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Premium Circle Progress & Countdown Card
          RitmoTheme.glassCard(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xffEC4899).withValues(alpha: 0.1), width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: 155,
                    height: 155,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _PregnancyRingPainter(
                            percentage: _progressPercent,
                            colors: [
                              const Color(0xffEC4899),
                              const Color(0xff8B5CF6),
                            ],
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _toPersianDigits('هفته $_currentWeek'),
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (_currentDayInWeek > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _toPersianDigits('+ $_currentDayInWeek روز'),
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 14,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _remainingDays > 0
                        ? _toPersianDigits('$_remainingDays روز تا تاریخ تخمینی زایمان 🎀')
                        : 'تاریخ تخمینی زایمان سپری شده است 🎀',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _toPersianDigits(
                        'تاریخ تخمینی زایمان: ${Jalali.fromDateTime(_dueDate).year}/${Jalali.fromDateTime(_dueDate).month}/${Jalali.fromDateTime(_dueDate).day}'),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pregnancy Assistant Card
          _buildPregnancyAssistantCard(context),
          const SizedBox(height: 16),

          // Interactive Kick Counter Card (NEW!)
          _buildKickCounterCard(),
          const SizedBox(height: 16),

          // Interactive Symptoms & Note Logger Card (NEW!)
          _buildSymptomLoggerCard(),
          const SizedBox(height: 16),

          // Baby Development Info Card (Premium Styling)
          RitmoTheme.glassCard(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xffEC4899).withValues(alpha: 0.1), width: 1.2),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xffEC4899).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.heart_fill, color: Color(0xffEC4899), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _toPersianDigits('وضعیت جنین در هفته $_currentWeek'),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildWeekDetailRow(
                    'اندازه تقریبی:',
                    weekData['size'] ?? '',
                    CupertinoIcons.square_grid_2x2_fill,
                    const Color(0xffEC4899),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: isDark ? Colors.white10 : colors.border.withValues(alpha: 0.15), height: 1),
                  ),
                  _buildWeekDetailRow(
                    'رشد فیزیکی:',
                    weekData['development'] ?? '',
                    CupertinoIcons.waveform_path_ecg,
                    const Color(0xff8B5CF6),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: isDark ? Colors.white10 : colors.border.withValues(alpha: 0.15), height: 1),
                  ),
                  _buildWeekDetailRow(
                    'نکته هفته:',
                    weekData['tip'] ?? '',
                    CupertinoIcons.lightbulb_fill,
                    const Color(0xffF59E0B),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Trimester Tips Card (Premium Styling)
          RitmoTheme.glassCard(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xff8B5CF6).withValues(alpha: 0.1), width: 1.2),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xff8B5CF6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.heart_circle_fill, color: Color(0xff8B5CF6), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        trimesterTitle,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    trimesterTips,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14.5,
                      color: isDark ? Colors.white70 : colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildPregnancyAssistantCard(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xffEC4899),
            Color(0xff8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffEC4899).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showPregnancyAssistant(context),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : colors.textPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CupertinoIcons.sparkles, color: isDark ? Colors.white : colors.textPrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.sparkles, color: Color(0xffEC4899), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'دستیار هوشمند بارداری ریتمو',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مشاوره خودمراقبتی، تغذیه و مدیریت علائم هفته $_currentWeek بارداری',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          color: isDark ? Colors.white70 : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_left, color: isDark ? Colors.white : colors.textPrimary, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDetailRow(String label, String value, IconData icon, Color color) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: isDark ? Colors.white38 : colors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 15,
                  color: isDark ? Colors.white : colors.textPrimary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKickCounterCard() {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RitmoTheme.glassCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xff8B5CF6).withValues(alpha: 0.15), width: 1.2),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xff8B5CF6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.waveform_path, color: Color(0xff8B5CF6), size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  'لگدشمار هوشمند بارداری',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Subtract button
                IconButton(
                  icon: Icon(CupertinoIcons.minus_circle, color: isDark ? Colors.white38 : colors.textSecondary.withValues(alpha: 0.4), size: 28),
                  onPressed: _kickCount > 0 ? () => _saveKick(_kickCount - 1) : null,
                ),
                // Kick display (circular pulsing layout)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff8B5CF6).withValues(alpha: 0.05),
                    border: Border.all(color: const Color(0xff8B5CF6).withValues(alpha: 0.2), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _toPersianDigits(_kickCount.toString()),
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : colors.textPrimary),
                      ),
                      Text(
                        'لگد',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : colors.textSecondary.withValues(alpha: 0.4), fontFamily: 'Vazirmatn'),
                      ),
                    ],
                  ),
                ),
                // Add button
                GestureDetector(
                  onTap: () => _saveKick(_kickCount + 1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff8B5CF6).withValues(alpha: 0.15),
                    ),
                    child: const Icon(CupertinoIcons.add_circled_solid, color: Color(0xff8B5CF6), size: 36),
                  ),
                ),
              ],
            ),
            if (_lastKickTime.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _toPersianDigits('آخرین حرکت ثبت‌شده: ساعت $_lastKickTime'),
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : colors.textSecondary.withValues(alpha: 0.4), fontFamily: 'Vazirmatn'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomLoggerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCount = _selectedSymptoms.length;
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isDark
            ? LinearGradient(
                colors: [
                  const Color(0xff181124).withValues(alpha: 0.85),
                  const Color(0xff120D1C).withValues(alpha: 0.95),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : LinearGradient(
                colors: [
                  const Color(0xffFFF1F2).withValues(alpha: 0.9),
                  const Color(0xffFAF5FF).withValues(alpha: 0.95),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        border: Border.all(
          color: const Color(0xffEC4899).withValues(alpha: isDark ? 0.28 : 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffEC4899).withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffEC4899), Color(0xffF472B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffEC4899).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ثبت روزانه بارداری',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xff1F1235),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _showPregnancyLoggerInfo,
                            child: Icon(
                              CupertinoIcons.info_circle,
                              size: 16,
                              color: isDark ? Colors.white30 : colors.textSecondary.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _hasSavedToday && !_isEditingToday
                            ? 'اطلاعات امروز با موفقیت ثبت شد ✓'
                            : 'علائم و یادداشت امروز',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: _hasSavedToday && !_isEditingToday
                              ? const Color(0xff10B981)
                              : (isDark ? Colors.white54 : const Color(0xffEC4899).withValues(alpha: 0.8)),
                        ),
                      ),
                    ],
                  ),
                ),
                // badge
                if (selectedCount > 0 && (!_hasSavedToday || _isEditingToday))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xffEC4899),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _toPersianDigits('$selectedCount علامت'),
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────
          Divider(
            height: 1,
            color: const Color(0xffEC4899).withValues(alpha: isDark ? 0.15 : 0.1),
          ),

          if (_hasSavedToday && !_isEditingToday) ...[
            // ─── Completed Summary View ───
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedSymptoms.isNotEmpty) ...[
                    Text(
                      'علائم ثبت‌شده امروز:',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selectedSymptoms.map((sId) {
                        final item = _pregnancySymptomsList.firstWhere(
                          (element) => element['id'] == sId,
                          orElse: () => {'label': sId},
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xffEC4899).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xffEC4899).withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            item['label'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white : const Color(0xff1F1235),
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Text(
                      'امروز هیچ علامتی ثبت نکردید.',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: isDark ? Colors.white38 : colors.textSecondary,
                      ),
                    ),
                  ],
                  if (_noteController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'یادداشت امروز شما:',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.015),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : colors.border.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _noteController.text.trim(),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white.withValues(alpha: 0.87) : colors.textPrimary,
                          height: 1.5,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingToday = true;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xffEC4899).withValues(alpha: 0.4)),
                        color: Colors.transparent,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.pencil, color: Color(0xffEC4899), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'ویرایش علائم و یادداشت امروز',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xffEC4899),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ─── Editable Form View ───
            // ── Symptoms Grid ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'چطوری امروز؟ علائم رو انتخاب کن:',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: isDark ? Colors.white60 : const Color(0xff6B7280),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.3,
                children: _pregnancySymptomsList.map((s) {
                  final isSelected = _selectedSymptoms.contains(s['id']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSymptoms.remove(s['id']);
                        } else {
                          _selectedSymptoms.add(s['id']!);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xffEC4899), Color(0xffD946EF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.white.withValues(alpha: 0.75)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xffE5E7EB)),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xffEC4899).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s['label']!.split(' ').first, // emoji
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                s['label']!.split(' ').skip(1).join(' '), // text
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xff4B5563)),
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              const Icon(CupertinoIcons.checkmark_circle_fill,
                                  color: Colors.white, size: 14),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Note Field ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.pencil_outline,
                        size: 14,
                        color: isDark ? Colors.white54 : const Color(0xff6B7280),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'یادداشت شخصی:',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          color: isDark ? Colors.white60 : const Color(0xff6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xffE5E7EB),
                      ),
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xff1F1235),
                        fontFamily: 'Vazirmatn',
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: 'حالت چطوره؟ هر چیزی که احساس می‌کنی بنویس...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white30
                              : const Color(0xff9CA3AF),
                          fontSize: 12,
                          fontFamily: 'Vazirmatn',
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Save Button ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: GestureDetector(
                onTap: _isSavingLog ? null : _saveDailyLog,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: _isSavingLog
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xffEC4899), Color(0xff8B5CF6)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                    color: _isSavingLog
                        ? (isDark ? Colors.white12 : Colors.grey.shade300)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isSavingLog
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xffEC4899).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: _isSavingLog
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.checkmark_seal_fill,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'ثبت و ذخیره یادداشت روزانه',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PregnancyRingPainter extends CustomPainter {

  _PregnancyRingPainter({required this.percentage, required this.colors});
  final double percentage;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final paintBg = Paint()
      ..color = colors.first.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, paintBg);

    // Gradient shader
    final gradient = SweepGradient(
      colors: colors,
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
    );

    // Glow effect
    final paintGlow = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Foreground track
    final paintFg = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * percentage;

    // Draw glow first
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paintGlow);
    // Draw crisp path
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paintFg);
  }

  @override
  bool shouldRepaint(covariant _PregnancyRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.colors != colors;
  }
}
