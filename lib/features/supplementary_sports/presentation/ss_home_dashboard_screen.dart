import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_movement_tab_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_onboarding_flow.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_plan_day_detail_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_plan_overview_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_progress_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_settings_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_workout_session_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/bottom_sheet_container.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_lottie_player.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_muscle_image_resolver.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/ss_ai_coach_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// --- Sealed Class for State ---
sealed class SSHomeUiState {
  const SSHomeUiState();
}

class SSHomeLoading extends SSHomeUiState {
  const SSHomeLoading();
}

class SSHomeRestDay extends SSHomeUiState {
  const SSHomeRestDay({this.suggestion});
  final String? suggestion;
}

class SSHomeWorkoutReady extends SSHomeUiState {

  const SSHomeWorkoutReady({
    required this.dayName,
    required this.dayOfWeek,
    required this.planId,
    required this.workoutName,
    required this.exerciseCount,
    required this.estimatedMinutes,
    required this.continuity,
    this.aiSuggestion,
    required this.weekTimeline,
  });
  final String dayName;
  final int dayOfWeek;
  final String planId;
  final String workoutName;
  final int exerciseCount;
  final int estimatedMinutes;
  final List<bool> continuity;
  final String? aiSuggestion;
  final List<bool> weekTimeline;
}

class SSHomeWorkoutCompleted extends SSHomeUiState {

  const SSHomeWorkoutCompleted({
    required this.dayName,
    required this.summary,
  });
  final String dayName;
  final String summary;
}

class SSHomePlanCompleted extends SSHomeUiState {
  const SSHomePlanCompleted();
}

// --- Home Screen Shell with Bottom Navigation ---
class SSHomeDashboardScreen extends StatefulWidget {
  const SSHomeDashboardScreen({super.key});

  @override
  State<SSHomeDashboardScreen> createState() => _SSHomeDashboardScreenState();
}

class _SSHomeDashboardScreenState extends State<SSHomeDashboardScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SSHomeDashboardTabContent(
        onNavigateToTab: _navigateToTab,
      ),
      SSPlanOverviewScreen(
        onNavigateToTab: _navigateToTab,
      ),
      SSMovementTabScreen(
        onNavigateToTab: _navigateToTab,
      ),
      SSProgressScreen(onNavigateToTab: _navigateToTab),
    ];
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index.clamp(0, 3);
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index.clamp(0, 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
        ),
      ),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTabSelected,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF10B981),
            unselectedItemColor: Colors.white38,
            selectedLabelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_fire_department),
                activeIcon: Icon(Icons.local_fire_department_rounded),
                label: 'امروز',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month_rounded),
                label: 'برنامه',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_walk),
                activeIcon: Icon(Icons.directions_walk_rounded),
                label: 'حرکت',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart_rounded),
                label: 'پیشرفت',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Trend Line Painter for AI Coach Graph ---
class TrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final linePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.3),
          const Color(0xFF10B981).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.85)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.7,
        size.width * 0.6,
        size.height * 0.1,
        size.width * 1.0,
        size.height * 0.05,
      );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final endPointPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width, size.height * 0.05), 3.5, endPointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Ring Gauge Painter for Body Readiness Gauges ---
class RingGaugePainter extends CustomPainter {

  RingGaugePainter({required this.percentage, required this.color});
  final double percentage; // 0.0 to 1.0
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(2.0, (size.width / 2) - 4);

    final trackPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * percentage.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage || oldDelegate.color != color;
}

// --- Holographic Scanner & Pedestal Painter ---
class HolographicScannerWidget extends StatefulWidget {

  const HolographicScannerWidget({super.key, required this.auraColor, this.userGender});
  final Color auraColor;
  final String? userGender;

  @override
  State<HolographicScannerWidget> createState() => _HolographicScannerWidgetState();
}

class _HolographicScannerWidgetState extends State<HolographicScannerWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyImagePath = SSMuscleImageResolver.resolve('full_body', widget.userGender);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 85,
          height: 125,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pedestal Glow Base
              CustomPaint(
                size: const Size(85, 125),
                painter: HolographicPedestalPainter(
                  progress: _controller.value,
                  glowColor: widget.auraColor,
                ),
              ),
              // Realistic Human Body Image (Male / Female) with Background Filtered Out
              ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.8, 0.98],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Opacity(
                  opacity: 0.85 + (_controller.value * 0.15),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      1.2, 0, 0, 0, 0,
                      0, 1.2, 0, 0, 0,
                      0, 0, 1.2, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: Image.asset(
                      bodyImagePath,
                      height: 105,
                      fit: BoxFit.contain,
                      colorBlendMode: BlendMode.screen,
                      color: const Color(0xFF0F172A),
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.accessibility_new_rounded,
                        size: 68,
                        color: widget.auraColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
              // Scanning Laser Line
              Positioned(
                top: 10 + (_controller.value * 95),
                left: 6,
                right: 6,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: widget.auraColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.auraColor,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HolographicPedestalPainter extends CustomPainter {

  HolographicPedestalPainter({
    this.progress = 0.5,
    this.glowColor = const Color(0xFF06B6D4),
  });
  final double progress;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height * 0.88);

    final fillGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: 0.35),
          glowColor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.45));

    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * 0.8, height: 20),
      fillGlow,
    );

    final ring1 = Paint()
      ..color = glowColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final ring2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * 0.75, height: 18),
      ring1,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * 0.5, height: 12),
      ring2,
    );
  }

  @override
  bool shouldRepaint(covariant HolographicPedestalPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.glowColor != glowColor;
}

// --- Dashboard Tab Content ---
class SSHomeDashboardTabContent extends StatefulWidget {

  const SSHomeDashboardTabContent({
    super.key,
    required this.onNavigateToTab,
  });
  final Function(int) onNavigateToTab;

  @override
  State<SSHomeDashboardTabContent> createState() => _SSHomeDashboardTabContentState();
}

class _SSHomeDashboardTabContentState extends State<SSHomeDashboardTabContent> {
  SSHomeUiState _state = const SSHomeLoading();

  List<bool> _weekCompleted = List.filled(7, false);
  String? _nextWorkoutName;
  int? _nextWorkoutMinutes;
  String? _nextWorkoutDayName;
  int? _nextDayOfWeek;
  String _username = 'بهمن';
  String? _userGender;
  String? _unfinishedActivePlanId;

  // Biometric Scores (Calculated Dynamically from SQLite Data)
  int _energyScore = 82;
  int _recoveryScore = 74;
  int _sleepScore = 82;
  String? _sleepRecoveryTip;
  int _stressScore = 32;
  int _activityScore = 88;

  int get _overallReadinessScore {
    final score = (_energyScore * 0.30) + (_recoveryScore * 0.30) + (_sleepScore * 0.20) + ((100 - _stressScore) * 0.10) + (_activityScore * 0.10);
    return score.round().clamp(0, 100);
  }

  String get _readinessBadgeText {
    final score = _overallReadinessScore;
    if (score >= 80) return 'آمادگی عالی ⚡';
    if (score >= 65) return 'آمادگی ایده‌آل 🏃';
    if (score >= 50) return 'ریکاوری سبک 🧘';
    return 'نیاز به استراحت 😴';
  }

  Color get _readinessColor {
    final score = _overallReadinessScore;
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 65) return const Color(0xFF06B6D4);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const SSSettingsScreen(isModal: true);
      },
    ).then((_) {
      if (mounted) _loadDashboardData();
    });
  }

  void _openAiCoach() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return const SSAiCoachSheet();
      },
    );
  }

  void _showBodyStatusDetailsSheet() {
    final readiness = _overallReadinessScore;
    final color = _readinessColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BottomSheetContainer(
          title: 'تحلیل بیومتریک و وضعیت بدن 🧬',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AI Coach Verdict Hero Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      const Color(0xFF1E293B).withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          toPersianDigits('$readiness٪'),
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        textDirection: TextDirection.rtl,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              const Text(
                                'شاخص آمادگی زیستی:',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _readinessBadgeText,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _sleepRecoveryTip ?? (readiness >= 75
                                ? 'بدن شما در بهترین فاز ریکاوری و انرژی است. امروز می‌توانید وزنه و فشار تمرین را افزایش دهید!'
                                : 'بدن شما نیاز به ریکاوری ملایم دارد. انجام تمرینات با تمرکز بر فرم صحیح حرکت توصیه می‌شود.'),
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11.5,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5 Biometric Meter Breakdown Tiles
              _statusDetailMeterTile('انرژی بدنی ⚡', _energyScore, 'ذخایر گلیکوژن و آمادگی متابولیک عضلات جهت تولید نیرو.', const Color(0xFF10B981)),
              const SizedBox(height: 12),
              _statusDetailMeterTile('ریکاوری عضلانی ❤️', _recoveryScore, 'نرخ بازسازی فیبرهای عضلانی و کاهش التهاب مفصلی.', const Color(0xFFEF4444)),
              const SizedBox(height: 12),
              _statusDetailMeterTile('کیفیت خواب 🌙', _sleepScore, 'تداوم و عمق خواب شبانه برای ترشح هورمون رشد و ترمیم عضلات.', const Color(0xFF06B6D4)),
              const SizedBox(height: 12),
              _statusDetailMeterTile('سطح استرس 🧠', _stressScore, 'میزان فشار روی سیستم عصبی سمپاتیک و بالانس کورتیزول.', const Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              _statusDetailMeterTile('تداوم فعالیت 🏃', _activityScore, 'میزان پایداری در انجام روتین‌های تمرینی هفته جاری.', const Color(0xFF22C55E)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _statusDetailMeterTile(String title, int score, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                toPersianDigits('$score٪'),
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: Colors.white60,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    try {
      final db = await DatabaseHelper.instance.database;
      final today = DateTime.now();
      final dayOfWeek = _getFarsiDayOfWeek(today);

      // Fetch username
      try {
        final nameQuery = await db.query('app_settings', where: 'key = ?', whereArgs: ['user_name']);
        if (nameQuery.isNotEmpty && nameQuery.first['value'] != null) {
          _username = nameQuery.first['value'].toString();
        } else {
          final profileRows = await db.query('profile', limit: 1);
          if (profileRows.isNotEmpty && profileRows.first['name'] != null) {
            _username = profileRows.first['name'].toString();
          }
        }
      } catch (_) {}

      // Fetch gender robustly from all storage options
      try {
        _userGender = await DatabaseHelper.instance.getUserGender(executor: db);
      } catch (e) {
        debugPrint('Error fetching gender: $e');
      }
      _userGender ??= 'MALE';

      // Check plan completion
      final totalPlannedResult = await db.rawQuery('SELECT COUNT(*) as count FROM ss_workout_plan');
      final totalPlanned = Sqflite.firstIntValue(totalPlannedResult) ?? 0;
      final totalCompletedResult = await db.rawQuery('SELECT COUNT(*) as count FROM ss_workout_session_log WHERE finishedAt IS NOT NULL');
      final totalCompleted = Sqflite.firstIntValue(totalCompletedResult) ?? 0;

      if (totalCompleted >= totalPlanned && totalPlanned > 0) {
        if (mounted) {
          setState(() {
            _state = const SSHomePlanCompleted();
          });
        }
        return;
      }

      // Check today's session log
      final startOfToday = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
      final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59).millisecondsSinceEpoch;

      final sessionLogs = await db.query(
        'ss_workout_session_log',
        where: 'startedAt >= ? AND startedAt <= ? AND finishedAt IS NOT NULL',
        whereArgs: [startOfToday, endOfToday],
      );

      // Fetch week completed history (Sat to Fri)
      final startOfWeek = today.subtract(Duration(days: dayOfWeek - 1));
      final startOfWeekMidnight = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final weekLogs = await db.query(
        'ss_workout_session_log',
        where: 'startedAt >= ? AND finishedAt IS NOT NULL',
        whereArgs: [startOfWeekMidnight.millisecondsSinceEpoch],
      );

      _weekCompleted = List.generate(7, (i) {
        final targetDate = startOfWeekMidnight.add(Duration(days: i));
        final start = DateTime(targetDate.year, targetDate.month, targetDate.day).millisecondsSinceEpoch;
        final end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59).millisecondsSinceEpoch;
        return weekLogs.any((log) => (log['startedAt']! as int) >= start && (log['startedAt']! as int) <= end);
      });

      final prefs = await SharedPreferences.getInstance();
      final currentWeek = prefs.getInt('ss_active_week') ?? 1;

      final activeSessionId = prefs.getString('ss_active_session_id');
      final activePlanId = prefs.getString('ss_active_plan_id');
      if (activeSessionId != null && activeSessionId.isNotEmpty && activePlanId != null) {
        _unfinishedActivePlanId = activePlanId;
      } else {
        _unfinishedActivePlanId = null;
      }

      // Calculate Biometric Scores Dynamically
      final completedCount = _weekCompleted.where((c) => c).length;
      _activityScore = ((completedCount / 4) * 100).clamp(25, 96).round();

      try {
        final sleepLogs = await db.query(
          'sleep_logs',
          orderBy: 'createdAt DESC',
          limit: 1,
        );
        if (sleepLogs.isNotEmpty) {
          final sLog = sleepLogs.first;
          final durMin = sLog['durationMinutes'] as int? ?? 420;
          final qScore = sLog['quality'] as int? ?? 3;
          final hrsStr = (durMin / 60).toStringAsFixed(1);
          _sleepScore = ((durMin / 480) * 80 + (qScore * 4)).clamp(35, 98).round();
          if (qScore <= 2 || durMin < 360) {
            _sleepRecoveryTip = 'ثبت خواب: دیشب $hrsStr ساعت خواب دریافت شد. شدت تمرین امروز متناسب با ریکاوری تنظیم شد 🌙';
          }
        }
      } catch (_) {}

      _stressScore = (_sleepScore < 60) ? 55 : ((100 - _sleepScore) * 0.8).clamp(15, 60).round();
      _recoveryScore = ((_sleepScore * 0.55) + (_activityScore * 0.45)).clamp(40, 98).round();
      _energyScore = ((_sleepScore * 0.65) + ((100 - _stressScore) * 0.35)).clamp(35, 96).round();

      final allPlans = await db.query(
        'ss_workout_plan',
        where: 'id LIKE ?',
        whereArgs: ['plan_w${currentWeek}_%'],
      );
      final weekTimeline = List<bool>.generate(7, (i) {
        final targetDayOfWeek = i + 1;
        return allPlans.isNotEmpty && allPlans.any((p) => p['dayOfWeek'] == targetDayOfWeek);
      });

      // Find next workout plan dynamically
      _nextWorkoutName = null;
      _nextWorkoutMinutes = null;
      _nextWorkoutDayName = null;
      _nextDayOfWeek = null;
      for (var offset = 1; offset <= 6; offset++) {
        final nextDayOfWeek = ((dayOfWeek - 1 + offset) % 7) + 1;
        var nextPlans = await db.query(
          'ss_workout_plan',
          where: 'dayOfWeek = ? AND id LIKE ?',
          whereArgs: [nextDayOfWeek, 'plan_w${currentWeek}_%'],
        );
        if (nextPlans.isEmpty && currentWeek == 1) {
          nextPlans = await db.query(
            'ss_workout_plan',
            where: 'dayOfWeek = ?',
            whereArgs: [nextDayOfWeek],
          );
        }
        if (nextPlans.isNotEmpty) {
          final nPlan = nextPlans.first;
          final nMusclesRaw = jsonDecode(nPlan['muscleGroups'].toString()) as List<dynamic>;
          _nextWorkoutName = nMusclesRaw.join(' و ');
          _nextWorkoutMinutes = nPlan['estimatedMinutes'] as int? ?? 30;
          _nextWorkoutDayName = offset == 1 ? 'فردا' : _getFarsiDayName(nextDayOfWeek);
          _nextDayOfWeek = nextDayOfWeek;
          break;
        }
      }

      if (sessionLogs.isNotEmpty) {
        final session = sessionLogs.first;
        if (mounted) {
          setState(() {
            _state = SSHomeWorkoutCompleted(
              dayName: _getFarsiDayName(dayOfWeek),
              summary: toPersianDigits(
                '${session['completedExercisesCount']} از ${session['totalExercisesCount']} حرکت در ${((session['durationSeconds'] as int? ?? 0) / 60).round()} دقیقه انجام شد.',
              ),
            );
          });
        }
        return;
      }

      // Fetch today's plan
      var plans = await db.query(
        'ss_workout_plan',
        where: 'dayOfWeek = ? AND id LIKE ?',
        whereArgs: [dayOfWeek, 'plan_w${currentWeek}_%'],
      );
      if (plans.isEmpty && currentWeek == 1) {
        plans = await db.query(
          'ss_workout_plan',
          where: 'dayOfWeek = ?',
          whereArgs: [dayOfWeek],
        );
      }

      if (plans.isEmpty) {
        if (mounted) {
          setState(() {
            _state = const SSHomeRestDay(
              suggestion: 'امروز روز استراحت شماست. پیاده‌روی سبک یا تمرین کششی پیشنهاد می‌شود.',
            );
          });
        }
        return;
      }

      final plan = plans.first;
      final planId = plan['id'].toString();

      final exercisesCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ss_workout_exercise_crossref WHERE planId = ?',
        [planId],
      );
      final exerciseCount = Sqflite.firstIntValue(exercisesCountResult) ?? 0;

      final musclesRaw = jsonDecode(plan['muscleGroups'].toString()) as List<dynamic>;
      final muscles = musclesRaw.join(' و ');

      if (mounted) {
        setState(() {
          _state = SSHomeWorkoutReady(
            dayName: _getFarsiDayName(dayOfWeek),
            dayOfWeek: dayOfWeek,
            planId: planId,
            workoutName: muscles,
            exerciseCount: exerciseCount,
            estimatedMinutes: plan['estimatedMinutes'] as int? ?? 40,
            continuity: List.generate(7, (i) => i < 6),
            aiSuggestion: 'امروز بدن شما پرانرژی‌تره، بهترین زمان برای افزایش شدت حرکاته. آب بیشتری بنوش و تمرکزت رو حفظ کن.',
            weekTimeline: weekTimeline,
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() {
          _state = const SSHomeRestDay(suggestion: 'خطا در بارگذاری اطلاعات.');
        });
      }
    }
  }

  int _getFarsiDayOfWeek(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday: return 3;
      case DateTime.tuesday: return 4;
      case DateTime.wednesday: return 5;
      case DateTime.thursday: return 6;
      case DateTime.friday: return 7;
      case DateTime.saturday: return 1;
      case DateTime.sunday: return 2;
    }
    return 1;
  }

  String _getFarsiDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1: return 'شنبه';
      case 2: return 'یکشنبه';
      case 3: return 'دوشنبه';
      case 4: return 'سه‌شنبه';
      case 5: return 'چهارشنبه';
      case 6: return 'پنج‌شنبه';
      case 7: return 'جمعه';
    }
    return '';
  }

  void _showCantTodayBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BottomSheetContainer(
          title: 'اصلاح تمرین امروز',
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('انتقال به فردا', style: TextStyle(fontFamily: 'Vazirmatn')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('تمرین فشرده (۳ حرکت)', style: TextStyle(fontFamily: 'Vazirmatn')),
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

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case SSHomeLoading():
        return Center(child: SSLottiePlayer.loading(size: 100));
      case SSHomeRestDay(suggestion: final suggestion):
        return _buildDashboardContent(
          child: Column(
            children: [
              _buildRestDayCard(suggestion ?? ''),
              const SizedBox(height: 16),
              _buildWeeklyStreakWidget(_weekCompleted),
              const SizedBox(height: 16),
              _buildAiCoachCard('امروز روز استراحت شماست. فعالیت بدنی سبک و کشش‌های پویا پیشنهاد می‌شود.'),
              const SizedBox(height: 16),
              _buildTodayBodyStatusWidget(),
              const SizedBox(height: 16),
              _buildNextWorkoutCard(
                nextWorkoutName: _nextWorkoutName,
                nextWorkoutMinutes: _nextWorkoutMinutes,
                nextWorkoutDayName: _nextWorkoutDayName,
              ),
            ],
          ),
        );
      case SSHomeWorkoutReady(
        dayName: final dayName,
        dayOfWeek: _,
        planId: final planId,
        workoutName: final workoutName,
        exerciseCount: final exerciseCount,
        estimatedMinutes: final estimatedMinutes,
        continuity: _,
        aiSuggestion: final aiSuggestion,
        weekTimeline: _
      ):
        return _buildDashboardContent(
          child: Column(
            children: [
              _buildHeroTodayWorkoutCard(
                dayName: dayName,
                workoutName: workoutName,
                exerciseCount: exerciseCount,
                estimatedMinutes: estimatedMinutes,
                onStart: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SSWorkoutSessionScreen(
                        planId: planId,
                        dayName: dayName,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) _loadDashboardData();
                  });
                },
                onCantToday: _showCantTodayBottomSheet,
              ),
              const SizedBox(height: 16),
              _buildWeeklyStreakWidget(_weekCompleted),
              const SizedBox(height: 16),
              _buildAiCoachCard(aiSuggestion ?? 'امروز بدن شما پرانرژی‌تره، بهترین زمان برای افزایش شدت حرکاته. آب بیشتری بنوش و تمرکزت رو حفظ کن.'),
              const SizedBox(height: 16),
              _buildTodayBodyStatusWidget(),
              const SizedBox(height: 16),
              _buildNextWorkoutCard(
                nextWorkoutName: _nextWorkoutName,
                nextWorkoutMinutes: _nextWorkoutMinutes,
                nextWorkoutDayName: _nextWorkoutDayName,
              ),
            ],
          ),
        );
      case SSHomeWorkoutCompleted(dayName: final dayName, summary: final summary):
        return _buildDashboardContent(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 64),
                    const SizedBox(height: 12),
                    const Text('خسته نباشید قهرمان! 🎉', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('تمرین روز $dayName با موفقیت انجام شد.', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(summary, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildWeeklyStreakWidget(_weekCompleted),
              const SizedBox(height: 16),
              _buildTodayBodyStatusWidget(),
              const SizedBox(height: 16),
              _buildNextWorkoutCard(
                nextWorkoutName: _nextWorkoutName,
                nextWorkoutMinutes: _nextWorkoutMinutes,
                nextWorkoutDayName: _nextWorkoutDayName,
              ),
            ],
          ),
        );
      case SSHomePlanCompleted():
        return _buildPlanCompletedView();
    }
  }

  Widget _buildUnfinishedSessionBanner() {
    if (_unfinishedActivePlanId == null) return const SizedBox.shrink();
    final planId = _unfinishedActivePlanId!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xFFF59E0B),
                size: 26,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'جلسه تمرینی ناتمام دارید 🏋️‍♂️',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'یک تمرین از قبل ذخیره شده در حال اجراست. می‌توانید آن را ادامه دهید یا انصراف دهید.',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              color: Colors.white70,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 14),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SSWorkoutSessionScreen(
                          planId: planId,
                          dayName: 'تمرین ناتمام',
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadDashboardData();
                    });
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('ادامه تمرین', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('ss_active_session_id');
                  await prefs.remove('ss_active_plan_id');
                  await prefs.remove('ss_active_session_exercises');
                  await prefs.remove('ss_active_session_index');
                  await prefs.remove('ss_active_session_started_at');
                  await prefs.remove('ss_active_session_status');
                  await prefs.remove('ss_active_session_target_timestamp');
                  await prefs.remove('ss_active_session_elapsed');
                  await prefs.remove('ss_active_session_paused');
                  if (mounted) {
                    setState(() {
                      _unfinishedActivePlanId = null;
                    });
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent({required Widget child}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopHeader(),
          const SizedBox(height: 16),
          if (_unfinishedActivePlanId != null) ...[
            _buildUnfinishedSessionBanner(),
          ],
          child,
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── 1. TOP HEADER (سلام بهمن 👋) ──────────────────────────────
  Widget _buildTopHeader() {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // User Greeting & Avatar
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: const Color(0xFF1E293B),
              ),
              child: const Center(
                child: Icon(CupertinoIcons.person_crop_circle_fill, size: 36, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      'سلام $_username',
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'آماده‌ای یک روز عالی بسازی؟',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Action Buttons: Settings Gear + AI Sparkles
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Settings Gear Button
            InkWell(
              onTap: _openSettingsModal,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // AI Sparkles Button
            InkWell(
              onTap: _openAiCoach,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: const Icon(CupertinoIcons.sparkles, color: Color(0xFFF59E0B), size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── 2. MAIN HERO TODAY WORKOUT CARD (ULTRA-PREMIUM REDESIGN) ───
  Widget _buildHeroTodayWorkoutCard({
    required String dayName,
    required String workoutName,
    required int exerciseCount,
    required int estimatedMinutes,
    required VoidCallback onStart,
    required VoidCallback onCantToday,
  }) {
    final coverImage = SSMuscleImageResolver.resolve(workoutName, _userGender);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1A10), Color(0xFF160E08)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Right 58%: Text Info, Title, Metrics & CTAs (Constrained, No Overlap!)
          Expanded(
            flex: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                // Top Tag Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center, color: Color(0xFFF97316), size: 13),
                      SizedBox(width: 5),
                      Text(
                        'جلسه تمرین',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Workout Title
                Text(
                  'تمرین $workoutName',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // 3 Metrics: Duration, Calories, Difficulty
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  textDirection: TextDirection.rtl,
                  children: [
                    _heroMetric(Icons.access_time_rounded, toPersianDigits('$estimatedMinutes د')),
                    _heroMetric(Icons.local_fire_department_rounded, toPersianDigits('۳۶۰ کالری')),
                    _heroMetric(Icons.speed_rounded, 'متوسط'),
                  ],
                ),
                const SizedBox(height: 16),

                // Stacked CTAs (Constrained inside Right 58% width!)
                Column(
                  children: [
                    // Primary Button: "شروع تمرین"
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text(
                          'شروع تمرین',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        onPressed: onStart,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Secondary Button: "اصلاح تمرین"
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.35),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.white70),
                        label: const Text(
                          'اصلاح تمرین',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                        ),
                        onPressed: onCantToday,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Left 42%: Glowing Stage & Full Athlete Photo
          Expanded(
            flex: 42,
            child: AspectRatio(
              aspectRatio: 0.82,
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // Glowing Radial Stage Background
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFEA580C).withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Athlete Cover Photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.accessibility_new_rounded, size: 60, color: Color(0xFFEA580C)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFFF97316)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  // ─── 3. WEEKLY CONTINUITY STREAK WIDGET ──────────────────────
  Widget _buildWeeklyStreakWidget(List<bool> weekCompleted) {
    final farsiDays = <String>['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    final completedCount = weekCompleted.where((c) => c).length;

    return InkWell(
      onTap: () => widget.onNavigateToTab(1),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF141C2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // Left: Streak Ring Gauge Widget
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CustomPaint(
                    painter: RingGaugePainter(
                      percentage: completedCount / 7,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      toPersianDigits('$completedCount'),
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'روز متوالی',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9, color: Colors.white54),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA580C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Center/Right: Title + Days Row
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        'تداوم این هفته',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    toPersianDigits('تو از ۷ روز هفته $completedCount روز تمرین داشتی'),
                    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: Colors.white54),
                  ),
                  const SizedBox(height: 12),

                  // Days Checkmark Row (Each day is interactive!)
                  Row(
                    textDirection: TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final dayNum = i + 1;
                      final isDone = i < completedCount;
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SSPlanDayDetailScreen(
                                dayOfWeek: dayNum,
                                dayName: _getFarsiDayName(dayNum),
                              ),
                            ),
                          ).then((_) {
                            if (mounted) _loadDashboardData();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              Text(
                                farsiDays[i],
                                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: Colors.white54),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDone ? const Color(0xFFEA580C) : const Color(0xFF1E293B),
                                ),
                                child: Center(
                                  child: isDone
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. AI COACH RECOMMENDATION CARD ────────────────────────
  Widget _buildAiCoachCard(String message) {
    return InkWell(
      onTap: _openAiCoach,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F1E36), Color(0xFF162544)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), width: 1.2),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // 3D Robot Avatar in Glowing Blue Stage
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4), width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/ai_robot_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.android, size: 36, color: Color(0xFF06B6D4)),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Message Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  const Row(
                    children: [
                      Icon(CupertinoIcons.sparkles, color: Color(0xFF06B6D4), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'توصیه مربی AI',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Left side trend graph & readiness tag
            Column(
              children: [
                SizedBox(
                  width: 46,
                  height: 32,
                  child: CustomPaint(painter: TrendLinePainter()),
                ),
                const SizedBox(height: 4),
                const Text(
                  'انرژی بدن',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9, color: Colors.white38),
                ),
                Text(
                  toPersianDigits('$_energyScore٪'),
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 5. TODAY'S BODY STATUS WIDGET (Holographic Scanner HUD) ───
  Widget _buildTodayBodyStatusWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final readiness = _overallReadinessScore;
    final readinessColor = _readinessColor;
    final readinessText = _readinessBadgeText;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? readinessColor.withValues(alpha: 0.25)
              : readinessColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: readinessColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showBodyStatusDetailsSheet,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Overall Readiness Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  textDirection: TextDirection.rtl,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: readinessColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.monitor_heart_rounded, size: 16, color: readinessColor),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'وضعیت بدن امروز',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: readinessColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: readinessColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            toPersianDigits('$readiness٪ — $readinessText'),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: readinessColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_left_rounded, size: 16, color: readinessColor),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // Left: Animated Holographic Body Scanner (Realistic Body for Male/Female)
                    HolographicScannerWidget(
                      auraColor: readinessColor,
                      userGender: _userGender,
                    ),

                    const SizedBox(width: 8),

                    // Right: 5 Biometric Stat Glass Cards
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            _bodyGaugeCard('انرژی', '$_energyScore', Icons.bolt_rounded, const Color(0xFF10B981), _energyScore / 100, _energyScore >= 80 ? 'عالی' : 'متوسط'),
                            const SizedBox(width: 8),
                            _bodyGaugeCard('ریکاوری', '$_recoveryScore', Icons.favorite_rounded, const Color(0xFFEF4444), _recoveryScore / 100, _recoveryScore >= 75 ? 'کامل' : 'نیاز به رشد'),
                            const SizedBox(width: 8),
                            _bodyGaugeCard('خواب', '$_sleepScore', Icons.nightlight_round, const Color(0xFF06B6D4), _sleepScore / 100, _sleepScore >= 80 ? 'عمیق' : 'کافی'),
                            const SizedBox(width: 8),
                            _bodyGaugeCard('استرس', '$_stressScore', Icons.psychology_rounded, const Color(0xFFF59E0B), _stressScore / 100, _stressScore <= 35 ? 'پایین' : 'متوسط'),
                            const SizedBox(width: 8),
                            _bodyGaugeCard('فعالیت', '$_activityScore', Icons.directions_run_rounded, const Color(0xFF22C55E), _activityScore / 100, _activityScore >= 80 ? 'پایدار' : 'عادی'),
                          ],
                        ),
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
  }

  Widget _bodyGaugeCard(String label, String percent, IconData icon, Color color, double val, String statusTag) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: RingGaugePainter(percentage: val, color: color),
                ),
              ),
              Icon(icon, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            toPersianDigits('$percent٪'),
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusTag,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. NEXT WORKOUT PREVIEW CARD ────────────────────────────
  Widget _buildNextWorkoutCard({
    required String? nextWorkoutName,
    required int? nextWorkoutMinutes,
    required String? nextWorkoutDayName,
  }) {
    final name = nextWorkoutName ?? 'ران و باسن و ساق پا و شکم';
    final coverImage = SSMuscleImageResolver.resolve(name, _userGender);
    final dayLabel = nextWorkoutDayName ?? 'فردا';
    final durationMins = nextWorkoutMinutes ?? 30;
    final categoryTag = _getWorkoutCategoryTag(name);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF131F33), Color(0xFF0F172A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_nextDayOfWeek != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SSPlanDayDetailScreen(
                    dayOfWeek: _nextDayOfWeek!,
                    dayName: _nextWorkoutDayName ?? _getFarsiDayName(_nextDayOfWeek!),
                  ),
                ),
              ).then((_) {
                if (mounted) _loadDashboardData();
              });
            } else {
              widget.onNavigateToTab(1);
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                // Top Row: Category pill & Day tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  textDirection: TextDirection.rtl,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10B981)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.rtl,
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                toPersianDigits('برنامه $dayLabel'),
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            categoryTag,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Colors.white38,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Middle Row: Image Thumbnail & Title / Metadata
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // Athlete Image Thumbnail
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              coverImage,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 88,
                                height: 88,
                                color: const Color(0xFF1E293B),
                                child: const Icon(Icons.fitness_center, size: 32, color: Colors.white38),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Workout Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            textDirection: TextDirection.rtl,
                            children: [
                              _buildMetaBadge(
                                icon: Icons.access_time_rounded,
                                label: toPersianDigits('$durationMins دقیقه'),
                                color: const Color(0xFF38BDF8),
                              ),
                              _buildMetaBadge(
                                icon: Icons.local_fire_department_rounded,
                                label: toPersianDigits('${durationMins * 7} کالری'),
                                color: const Color(0xFFFB923C),
                              ),
                            ],
                          ),
                        ],
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
  }

  Widget _buildMetaBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getWorkoutCategoryTag(String workoutName) {
    if (workoutName.contains('کششی') || workoutName.contains('انعطاف')) return 'تمرین کششی';
    if (workoutName.contains('پا') || workoutName.contains('ران') || workoutName.contains('باسن') || workoutName.contains('ساق')) return 'تمرین پایین‌تنه';
    if (workoutName.contains('شکم') || workoutName.contains('پهلو')) return 'تمرین هسته بدن';
    if (workoutName.contains('سینه') || workoutName.contains('بازو') || workoutName.contains('شانه') || workoutName.contains('پشت')) return 'تمرین بالاتنه';
    return 'جلسه بعدی';
  }

  Widget _buildRestDayCard(String suggestion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          const Icon(Icons.spa_outlined, size: 48, color: Color(0xFF10B981)),
          const SizedBox(height: 12),
          const Text(
            'امروز روز استراحت شماست 🧘‍♂️',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            suggestion,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCompletedView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏆🎉🎖️', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 16),
                  const Text(
                    'برنامه ۲۸ روزه شما به پایان رسید!',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تبریک می‌گوییم! شما تمام جلسات این دوره را با اراده و تداوم به پایان رساندید.',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.white70, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _resetAndStartNewPlan,
                      child: const Text(
                        'شروع برنامه جدید',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetAndStartNewPlan() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('ss_workout_exercise_crossref');
      await db.delete('ss_workout_plan');
      await db.delete('ss_workout_session_log');
      await db.delete('ss_exercise_feeling_log');
      await db.delete('ss_user_profile');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ss_active_week');

      if (mounted) {
        unawaited(
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SSOnboardingFlow()),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error resetting plan: $e');
    }
  }
}
