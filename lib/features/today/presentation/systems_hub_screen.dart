import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/systems_hub_logic.dart';
import 'package:ritmo/core/localization/locale_repository.dart';

import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/module_management_service.dart';
import 'package:ritmo/features/assistant/presentation/assistant_screen.dart';
import 'package:ritmo/features/courses/presentation/courses_screen.dart';
import 'package:ritmo/features/cycle/presentation/cycle_screen.dart';
import 'package:ritmo/features/goals/presentation/goals_screen.dart';
import 'package:ritmo/features/health/presentation/health_screen.dart';
import 'package:ritmo/features/konkur/presentation/konkur_screen.dart';
import 'package:ritmo/features/premium/presentation/premium_upgrade_sheet.dart';
import 'package:ritmo/features/profile/presentation/profile_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_home_dashboard_screen.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_intro_screen.dart';
import 'package:ritmo/features/wellbeing/presentation/wellbeing_screen.dart';
import 'package:ritmo/features/worship/presentation/worship_screen.dart';



class SystemsHubScreen extends StatefulWidget {

  const SystemsHubScreen({
    super.key,
    required this.onLogout,
    required this.themeRepository,
    required this.localeRepository,
  });
  final VoidCallback onLogout;
  final ThemeRepository themeRepository;
  final LocaleRepository localeRepository;

  @override
  State<SystemsHubScreen> createState() => _SystemsHubScreenState();
}

class _SystemsHubScreenState extends State<SystemsHubScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  bool _isLoading = true;
  bool _isFirstLoad = true;
  Map<String, String> _settingsMap = {};
  
  bool _isSearching = false;
  String _searchQuery = '';

  bool _matchesSearch(String title, String description) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    if (title == 'حال و تعادل') {
      const combinedTags = 'انرژی و حالت روحی خواب و بیداری خودارزیابی و بازتاب حال و تعادل';
      return title.toLowerCase().contains(query) ||
          description.toLowerCase().contains(query) ||
          combinedTags.contains(query);
    }
    return title.toLowerCase().contains(query) || description.toLowerCase().contains(query);
  }
  
  // Enabled flags
  bool _religionEnabled = false;
  bool _medicineEnabled = false;
  bool _cycleEnabled = false;
  bool _coursesEnabled = false;
  bool _konkurEnabled = false;
  bool _goalsEnabled = false;
  bool _assistantEnabled = false;
  bool _sportsEnabled = false;
  bool _supplementarySportsEnabled = false;
  bool _energyEnabled = false;
  bool _sleepEnabled = false;
  bool _progressiveHabitsEnabled = false;


  // Status flags resolved from db state
  ModuleStatus _konkurStatus = ModuleStatus.inactive;
  ModuleStatus _goalsStatus = ModuleStatus.inactive;
  ModuleStatus _assistantStatus = ModuleStatus.inactive;

  @override
  void initState() {
    super.initState();
    RitmoEvents.routineChanges.addListener(_onRoutineChanges);
    _loadAllData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    const itemsCount = 12;

    _fadeAnimations = List.generate(itemsCount, (i) {
      final start = i * 0.06;
      final end = (start + 0.5).clamp(0.0, 1.0);

      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnimations = List.generate(itemsCount, (i) {
      final start = i * 0.06;
      final end = (start + 0.6).clamp(0.0, 1.0);

      return Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _controller.forward();
  }

  void _onRoutineChanges() {
    if (mounted) {
      _loadAllData();
    }
  }

  @override
  void dispose() {
    RitmoEvents.routineChanges.removeListener(_onRoutineChanges);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAllData({bool showLoading = false}) async {
    if (!mounted) return;
    if (showLoading || _isFirstLoad) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Load app_settings
      final settings = await db.query('app_settings');
      _settingsMap = <String, String>{for (final s in settings) s['key']! as String: s['value']! as String};

      // 2. Map module enable flags
      _religionEnabled = _settingsMap['module_religion_enabled'] == 'true';
      _medicineEnabled = _settingsMap['module_medicine_enabled'] == 'true';
      _cycleEnabled = _settingsMap['module_cycle_enabled'] == 'true';
      _coursesEnabled = _settingsMap['module_courses_enabled'] == 'true';
      _konkurEnabled = _settingsMap['module_konkur_enabled'] == 'true';
      _goalsEnabled = _settingsMap['module_goals_enabled'] == 'true';
      _assistantEnabled = _settingsMap['module_assistant_enabled'] == 'true';
      _sportsEnabled = _settingsMap['module_sports_enabled'] == 'true';
      _supplementarySportsEnabled = _settingsMap['module_supplementary_sports_enabled'] == 'true';
      _energyEnabled = _settingsMap['module_energy_enabled'] == 'true';
      _sleepEnabled = _settingsMap['module_sleep_enabled'] == 'true';
      _progressiveHabitsEnabled = _settingsMap['module_progressive_habits_enabled'] == 'true';


      // 3. Load konkur subjects to determine status (active vs setupRequired)
      final subjects = await db.query('konkur_subjects', where: 'isArchived = 0');
      final hasSubjects = subjects.isNotEmpty;
      _konkurStatus = SystemsHubLogic.determineKonkurStatus(_konkurEnabled, hasSubjects);

      // 3b. Load goals to determine status
      final goals = await db.query('goals');
      final hasGoals = goals.isNotEmpty;
      _goalsStatus = SystemsHubLogic.determineKonkurStatus(_goalsEnabled, hasGoals);

      // 4. Load assistant status
      _assistantStatus = SystemsHubLogic.determineGenericStatus(_assistantEnabled);
    } catch (e) {
      debugPrint('Error loading Systems Hub data: $e');
    }

    if (mounted) {
      setState(() {
        _isFirstLoad = false;
        _isLoading = false;
      });
    }
  }

  bool get _isFemale => CyclePrivacyGuard.isVisible(_settingsMap);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colors),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showModulesManagementSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.square_grid_2x2,
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مدیریت ماژول‌های فعال',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'فعال یا غیرفعال‌سازی سیستم‌های کلی زندگی ریتمو',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.textSecondary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_left,
                        color: colors.textSecondary.withValues(alpha: 0.6),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildModulesGrid(colors, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(RitmoColors colors) {
    if (_isSearching) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(CupertinoIcons.search, color: colors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                autofocus: true,
                style: TextStyle(color: colors.textPrimary, fontSize: 13.5, fontFamily: 'Vazirmatn'),
                decoration: const InputDecoration(
                  hintText: 'جستجو در سیستم‌ها...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'Vazirmatn'),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
              ),
            ),
            IconButton(
              icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 18),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                });
              },
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.black.withValues(alpha: 0.4),
                  builder: (context) => ProfileScreen(
                    onLogout: widget.onLogout,
                    themeRepository: widget.themeRepository,
                    localeRepository: widget.localeRepository,
                  ),
                ).then((_) {
                  if (mounted) _loadAllData();
                });
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 1.5),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/avatar_placeholder.png'),
                    fit: BoxFit.cover,
                    onError: _handleAvatarError,
                  ),
                ),
                child: const Center(
                  child: Icon(CupertinoIcons.person_crop_circle_fill, size: 30, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سیستم‌ها',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                Text(
                  'تمام سیستم‌های فعال و قابل مدیریت زندگی شما',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: Icon(CupertinoIcons.search, color: colors.textPrimary),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
      ],
    );
  }

  static void _handleAvatarError(dynamic exception, StackTrace? stackTrace) {}

  Widget _buildCategorySection({
    required String title,
    required List<Widget> cards,
    required RitmoColors colors,
  }) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xffEC4899),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required ModuleStatus status,
    required VoidCallback onTap,
    required RitmoColors colors,
    required bool isDarkMode,
    required String illustrationAsset,
    bool overlayText = false,
  }) {
    return _buildAnimatedModuleCard(
      index: index,
      child: PressableGlassCard(
        onTap: onTap,
        child: _buildModuleCard(
          icon: icon,
          iconColor: iconColor,
          title: title,
          description: description,
          status: status,
          onTap: onTap,
          colors: colors,
          isDarkMode: isDarkMode,
          illustrationAsset: illustrationAsset,
          overlayText: overlayText,
        ),
      ),
    );
  }

  Widget _buildModulesGrid(RitmoColors colors, bool isDarkMode) {
    final healthCards = <Widget>[];
    final growthCards = <Widget>[];
    final spiritualityCards = <Widget>[];
    final assistantCards = <Widget>[];
    var cardIndex = 0;

    // 1. Cycle Module (Female Only)
    if (_isFemale && _matchesSearch('چرخه بدن', 'سلامت بانوان')) {
      healthCards.add(
        _buildGridItem(
          index: cardIndex++,
          icon: CupertinoIcons.heart_fill,
          iconColor: const Color(0xffEC4899),
          title: 'چرخه بدن',
          description: 'سلامت بانوان',
          status: _cycleEnabled ? ModuleStatus.active : ModuleStatus.inactive,
          illustrationAsset: 'assets/images/cycle_card_top.png',
          onTap: () => _handleCycleTap(colors),
          colors: colors,
          isDarkMode: isDarkMode,
          overlayText: true,
        ),
      );
    }

    // 2. Medicine Module
    if (_matchesSearch('دارو', 'مراقبت سلامتی باش')) {
      healthCards.add(
        _buildGridItem(
          index: cardIndex++,
          icon: CupertinoIcons.bandage_fill,
          iconColor: const Color(0xffEF4444),
          title: 'دارو و سلامت',
          description: 'مراقبت سلامتی باش',
          status: _medicineEnabled ? ModuleStatus.active : ModuleStatus.inactive,
          illustrationAsset: 'assets/images/medicine_card_top.png',
          onTap: () => _handleMedicineTap(colors),
          colors: colors,
          isDarkMode: isDarkMode,
        ),
      );
    }

    // 3. Wellbeing Module (Combined Energy, Sleep, and Reflection)
    if (_matchesSearch('حال و تعادل', 'انرژی، خواب و بازتاب در یک نگاه')) {
      healthCards.add(
        _buildGridItem(
          index: cardIndex++,
          icon: CupertinoIcons.waveform_path_ecg,
          iconColor: const Color(0xff8B5CF6),
          title: 'حال و تعادل',
          description: 'انرژی، خواب و بازتاب در یک نگاه',
          status: ModuleStatus.active,
          illustrationAsset: 'assets/images/energy_card_top.png',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WellbeingScreen(
                  
                ),
              ),
            ).then((_) => _loadAllData());
          },
          colors: colors,
          isDarkMode: isDarkMode,
        ),
      );
    }

    // 4.5. Supplementary Sports Module (unified Sports System)
    if (_matchesSearch('ورزش تکمیلی', 'برنامه تمرین هوشمند فیتنس') || _matchesSearch('ورزش', 'قدرت امروز، سلامتی فردا')) {
      healthCards.add(
        _buildGridItem(
          index: cardIndex++,
          icon: Icons.fitness_center,
          iconColor: const Color(0xff10B981),
          title: 'ورزش و حرکت',
          description: 'برنامه تمرین هوشمند و بودجهٔ حرکت هفتگی',
          status: (_sportsEnabled || _supplementarySportsEnabled) ? ModuleStatus.active : ModuleStatus.inactive,
          illustrationAsset: 'assets/images/sports_card_top.png',
          onTap: () => _handleSupplementarySportsTap(colors),
          colors: colors,
          isDarkMode: isDarkMode,
        ),
      );
    }

    // 5. Courses Module
    if (_matchesSearch('دوره‌های آموزشی', 'یادگیری مداوم، رشد بی‌پایان')) {
      growthCards.add(
        _buildGridItem(
          index: cardIndex++,
          icon: CupertinoIcons.book_fill,
          iconColor: const Color(0xff3B82F6),
          title: 'دوره‌های آموزشی',
          description: 'یادگیری مداوم، رشد بی‌پایان',
          status: _coursesEnabled ? ModuleStatus.active : ModuleStatus.inactive,
          illustrationAsset: 'assets/images/courses_card_top.png',
          onTap: () => _handleCoursesTap(colors),
          colors: colors,
          isDarkMode: isDarkMode,
        ),
      );
    }

    // 6. Konkur Module
    if (_matchesSearch('کنکور', 'برنامه‌ریزی هوشمند، موفقیت')) {
      growthCards.add(
        _buildGridItem(
          index: cardIndex++,
          icon: CupertinoIcons.doc_plaintext,
          iconColor: const Color(0xff8B5CF6),
          title: 'کنکور',
          description: 'برنامه‌ریزی هوشمند، موفقیت',
          status: _konkurStatus,
          illustrationAsset: 'assets/images/goals_card_top.png',
          onTap: () => _handleKonkurTap(colors),
          colors: colors,
          isDarkMode: isDarkMode,
        ),
      );
    }

    // 7. Goals Module
    if (_matchesSearch('اهداف و برنامه‌ها', 'برنامه‌ریزی برای بهترین خود')) {
      growthCards.add(
        _buildGridItem(
          index: cardIndex++,
          icon: CupertinoIcons.flag_fill,
          iconColor: const Color(0xffF59E0B),
          title: 'اهداف و برنامه‌ها',
          description: 'برنامه‌ریزی برای بهترین خود',
          status: _goalsStatus,
          illustrationAsset: 'assets/images/konkur_card_top.png',
          onTap: () => _handleGoalsTap(colors),
          colors: colors,
          isDarkMode: isDarkMode,
        ),
      );
    }

    // 8. Religion Module
    if (_matchesSearch('عبادت', 'رشد روح، آرامش قلب')) {
      spiritualityCards.add(
        _buildGridItem(
          index: cardIndex++,
          icon: CupertinoIcons.circle_grid_hex,
          iconColor: const Color(0xffFBBF24),
          title: 'عبادت',
          description: 'رشد روح، آرامش قلب',
          status: SystemsHubLogic.determineReligionStatus(_religionEnabled, _settingsMap['religion_city_id']),
          illustrationAsset: 'assets/images/worship_card_top.png',
          onTap: () => _handleReligionTap(colors),
          colors: colors,
          isDarkMode: isDarkMode,
        ),
      );
    }

    // 10. AI Assistant Module
    if (_matchesSearch('دستیار هوشمند', 'همراه هوشمند ریتمو')) {
      assistantCards.add(
        _buildGridItem(
          index: cardIndex++,
          icon: CupertinoIcons.sparkles,
          iconColor: const Color(0xff06B6D4),
          title: 'دستیار هوشمند',
          description: 'همراه هوشمند ریتمو',
          status: _assistantStatus,
          illustrationAsset: 'assets/images/assistant_card_top.png',
          onTap: () => _handleAssistantTap(colors),
          colors: colors,
          isDarkMode: isDarkMode,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategorySection(title: 'سلامت و بیولوژی', cards: healthCards, colors: colors),
        const SizedBox(height: 24),
        _buildCategorySection(title: 'رشد و برنامه‌ریزی', cards: growthCards, colors: colors),
        const SizedBox(height: 24),
        _buildCategorySection(title: 'توازن و معنویت', cards: spiritualityCards, colors: colors),
        const SizedBox(height: 24),
        _buildCategorySection(title: 'بستر هوشمند', cards: assistantCards, colors: colors),
      ],
    );
  }

  Widget _buildAnimatedModuleCard({
    required int index,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FadeTransition(
          opacity: _fadeAnimations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required ModuleStatus status,
    required VoidCallback onTap,
    required RitmoColors colors,
    required bool isDarkMode,
    required String illustrationAsset,
    bool overlayText = false,
  }) {
    // Use the specific illustration if it's one of the new high-quality card backgrounds.
    // Otherwise, fallback to cycle_card_top.png as requested by the user.
    final String imageAsset;
    if (illustrationAsset.contains('goals_card_top.png') || 
        illustrationAsset.contains('konkur_card_top.png') || 
        illustrationAsset.contains('medicine_card_top.png') || 
        illustrationAsset.contains('courses_card_top.png') || 
        illustrationAsset.contains('worship_card_top.png') || 
        illustrationAsset.contains('sports_card_top.png') || 
        illustrationAsset.contains('assistant_card_top.png') || 
        illustrationAsset.contains('energy_card_top.png') || 
        illustrationAsset.contains('cycle_card_top.png')) {
      imageAsset = illustrationAsset;
    } else {
      imageAsset = 'assets/images/cycle_card_top.png';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 🎨 Full Card Image
          Image.asset(
            imageAsset,
            fit: BoxFit.cover,
          ),

          // Subtle gradient overlay (iOS depth feel)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),

          // Floating Status Pill (Top-Left corner)
          Positioned(
            top: 10,
            left: 10,
            child: _buildStatusPill(status),
          ),

          // Floating Icon Badge (Top-Right corner)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDarkMode ? Colors.black : Colors.white).withValues(alpha: 0.75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 13, color: iconColor),
            ),
          ),

          // 🌫 Frosted Glass overlay on the bottom part of the card (shorter and cleaner)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.55),
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TITLE
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      // DESCRIPTION
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.6),
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(ModuleStatus status) {
    Color color;
    String text;

    switch (status) {
      case ModuleStatus.active:
        color = const Color(0xFF34C759); // iOS green
        text = 'فعال';
      case ModuleStatus.inactive:
        color = const Color(0xFF8E8E93);
        text = 'غیرفعال';
      case ModuleStatus.setupRequired:
        color = const Color(0xFFFF9500);
        text = 'نیاز به توجه';
      case ModuleStatus.locked:
        color = const Color(0xFFFF3B30); // iOS red
        text = 'قفل‌شده';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == ModuleStatus.locked) ...[
            const Icon(CupertinoIcons.lock_fill, size: 10, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  void _handleCycleTap(RitmoColors colors) {
    if (_cycleEnabled) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CycleScreen()),
      ).then((_) => _loadAllData());
    } else {
      _showActivationSheet(
        title: 'فعال‌سازی سیستم چرخه بدن',
        description: 'با فعال‌سازی این سیستم، می‌توانید فازهای چرخه زیستی، پیش‌بینی هوشمند و نوسانات هورمونی خود را پایش کرده و بینش‌های سلامتی اختصاصی دریافت کنید.',
        icon: CupertinoIcons.heart_fill,
        iconColor: const Color(0xffEC4899),
        settingKey: 'module_cycle_enabled',
        onActivated: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CycleScreen()),
          ).then((_) => _loadAllData());
        },
        colors: colors,
      );
    }
  }

  void _handleMedicineTap(RitmoColors colors) {
    if (_medicineEnabled) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HealthScreen()),
      ).then((_) => _loadAllData());
    } else {
      _showActivationSheet(
        title: 'فعال‌سازی سیستم دارو و سلامت',
        description: 'با فعال‌سازی این سیستم، می‌توانید برنامه‌ی داروها، نوبت‌های پزشک، قند خون، فشار خون، علائم حیاتی، مدارک پزشکی، واکسیناسیون و آلرژی‌های خود را ثبت و پیگیری کنید.',
        icon: CupertinoIcons.bandage_fill,
        iconColor: const Color(0xffEF4444),
        settingKey: 'module_medicine_enabled',
        onActivated: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HealthScreen()),
          ).then((_) => _loadAllData());
        },
        colors: colors,
      );
    }
  }

  void _handleCoursesTap(RitmoColors colors) {
    if (!PremiumService.instance.can(PremiumFeature.coursesModule)) {
      PremiumUpgradeSheet.show(context);
      return;
    }
    if (_coursesEnabled) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CoursesScreen()),
      ).then((_) => _loadAllData());
    } else {
      _showActivationSheet(
        title: 'فعال‌سازی سیستم دوره‌های آموزشی',
        description: 'با فعال‌سازی این سیستم، می‌توانید دوره‌های ویدیویی، کتاب‌ها و دوره‌های دلخواه خود را زمان‌بندی ریتمیک کرده، ساعت مطالعه را ثبت و استریک‌های پیشرفت خود را پیگیری کنید.',
        icon: CupertinoIcons.book_fill,
        iconColor: const Color(0xff3B82F6),
        settingKey: 'module_courses_enabled',
        onActivated: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CoursesScreen()),
          ).then((_) => _loadAllData());
        },
        colors: colors,
      );
    }
  }

  void _handleKonkurTap(RitmoColors colors) {
    if (!PremiumService.instance.can(PremiumFeature.konkurModule)) {
      PremiumUpgradeSheet.show(context);
      return;
    }
    if (_konkurEnabled) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KonkurScreen()),
      ).then((_) => _loadAllData());
    } else {
      _showActivationSheet(
        title: 'فعال‌سازی سیستم کنکور',
        description: 'با فعال‌سازی این سیستم، می‌توانید درختواره دروس و مباحث کنکوری را ایجاد و ثبت کرده، ساعت مطالعه و درصدهای کسب شده در آزمون‌های آزمایشی را مدیریت و تحلیل کنید.',
        icon: CupertinoIcons.doc_plaintext,
        iconColor: const Color(0xff8B5CF6),
        settingKey: 'module_konkur_enabled',
        onActivated: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const KonkurScreen()),
          ).then((_) => _loadAllData());
        },
        colors: colors,
      );
    }
  }

  void _handleGoalsTap(RitmoColors colors) {
    if (_goalsEnabled) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GoalsScreen()),
      ).then((_) => _loadAllData());
    } else {
      _showActivationSheet(
        title: 'فعال‌سازی سیستم اهداف و برنامه‌ها',
        description: 'با فعال‌سازی این سیستم، می‌توانید درختواره اهداف زندگی خود را تعریف کرده، آن‌ها را با کمک هوش مصنوعی خرد کنید، و برنامه‌های زمانی خود را پیگیری کنید.',
        icon: CupertinoIcons.flag_fill,
        iconColor: const Color(0xffF59E0B),
        settingKey: 'module_goals_enabled',
        onActivated: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GoalsScreen()),
          ).then((_) => _loadAllData());
        },
        colors: colors,
      );
    }
  }


  Future<void> _handleSupplementarySportsTap(RitmoColors colors) async {
    final isSportsActive = _sportsEnabled || _supplementarySportsEnabled;
    if (isSportsActive) {
      final db = await DatabaseHelper.instance.database;
      final profileResult = await db.query('ss_user_profile', where: 'id = ?', whereArgs: ['default']);
      final hasCompletedOnboarding = profileResult.isNotEmpty && 
          (profileResult.first['onboardingCompleted'] as int? ?? 0) == 1;

      if (mounted) {
        unawaited(
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => hasCompletedOnboarding
                  ? const SSHomeDashboardScreen()
                  : const SSIntroScreen(),
            ),
          ).then((_) => _loadAllData()),
        );
      }
    } else {
      _showActivationSheet(
        title: 'فعال‌سازی سیستم ورزش و حرکت',
        description: 'با فعال‌سازی این سیستم، می‌توانید برنامه تمرین هوشمند بر اساس سطح و اهداف خود دریافت کنید، حرکات را با بازخورد کیفی ثبت کنید و روند تداوم خود را دنبال کنید.',
        icon: Icons.fitness_center,
        iconColor: const Color(0xff10B981),
        settingKey: 'module_sports_enabled',
        onActivated: () async {
          await ModuleManagementService.instance.setModuleEnabled('module_sports_enabled', true);
          await ModuleManagementService.instance.setModuleEnabled('module_supplementary_sports_enabled', true);
          final db = await DatabaseHelper.instance.database;
          final profileResult = await db.query('ss_user_profile', where: 'id = ?', whereArgs: ['default']);
          final hasCompletedOnboarding = profileResult.isNotEmpty && 
              (profileResult.first['onboardingCompleted'] as int? ?? 0) == 1;

          if (mounted) {
            unawaited(
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => hasCompletedOnboarding 
                      ? const SSHomeDashboardScreen() 
                      : const SSIntroScreen(),
                ),
              ).then((_) => _loadAllData()),
            );
          }
        },
        colors: colors,
      );
    }
  }


  void _handleAssistantTap(RitmoColors colors) {
    if (_assistantEnabled) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AssistantScreen()),
      ).then((_) => _loadAllData());
    } else {
      _showActivationSheet(
        title: 'فعال‌سازی دستیار هوشمند ریتمو',
        description: 'دستیار هوشمند با پایش کاملاً امن و محلی روتین‌ها، اهداف، انرژی، خواب و برنامه‌ریزی، به صورت متنی به شما توصیه‌های کاربردی و بینش‌های عملی ارائه می‌دهد.',
        icon: CupertinoIcons.sparkles,
        iconColor: const Color(0xff06B6D4),
        settingKey: 'module_assistant_enabled',
        onActivated: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssistantScreen()),
          ).then((_) => _loadAllData());
        },
        colors: colors,
      );
    }
  }

  void _handleReligionTap(RitmoColors colors) {
    if (_religionEnabled) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WorshipScreen()),
      ).then((_) => _loadAllData());
    } else {
      _showActivationSheet(
        title: 'فعال‌سازی سیستم عبادی ریتمو',
        description: 'سیستم عبادی به شما کمک می‌کند با ثبت مناسبت‌های خاص (مانند ماه مبارک رمضان، ایام اعتکاف، یا چله‌های مذهبی شخصی) وزن و اولویت روتین‌های عبادی خود را به طور هوشمند و بدون مزاحمت مدیریت کنید.',
        icon: CupertinoIcons.circle_grid_hex,
        iconColor: const Color(0xffFBBF24),
        settingKey: 'module_religion_enabled',
        onActivated: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WorshipScreen()),
          ).then((_) => _loadAllData());
        },
        colors: colors,
      );
    }
  }

  void _showActivationSheet({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String settingKey,
    required VoidCallback onActivated,
    required RitmoColors colors,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xff12141C).withValues(alpha: 0.85) 
                  : Colors.white.withValues(alpha: 0.88),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 38),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.5,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ModuleManagementService.instance.setModuleEnabled(settingKey, true);
                      await _loadAllData();
                      onActivated();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'فعال‌سازی سیستم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleModule(String key, bool value) async {
    if (!mounted) return;

    if (key == 'module_medicine_enabled' && !value) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xff1A1D29),
            title: const Text('⚠️ هشدار مهم پزشکی', style: TextStyle(fontFamily: 'Vazirmatn')),
            content: const Text(
              'توجه: غیرفعال‌سازی این ماژول تمام یادآوری‌های دارویی شما را لغو می‌کند و ممکن است بر سلامتتان اثر بگذارد. مطمئنید؟',
              style: TextStyle(height: 1.6, fontFamily: 'Vazirmatn'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('خیر، لغو نشود', style: TextStyle(color: Color(0xff9AA0AE), fontFamily: 'Vazirmatn')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('بله، خاموش کن', style: TextStyle(color: Color(0xffE5736B), fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        ),
      );

      if (confirm != true) return;
    }

    if (key == 'module_sports_enabled' || key == 'module_supplementary_sports_enabled') {
      await ModuleManagementService.instance.setModuleEnabled('module_sports_enabled', value);
      await ModuleManagementService.instance.setModuleEnabled('module_supplementary_sports_enabled', value);
    } else {
      await ModuleManagementService.instance.setModuleEnabled(key, value);
    }
    await _loadAllData();
  }

  Future<void> _confirmAndResetModule(String key, String moduleTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xff1A1D29),
          title: Text('⚠️ بازنشانی سیستم $moduleTitle', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text(
            'آیا از بازنشانی داده‌های سیستم «$moduleTitle» اطمینان دارید؟ تمام ثبت‌ها، تاریخچه و اطلاعات این سیستم پاک خواهد شد و قابل بازگردانی نیست.',
            style: const TextStyle(height: 1.6, fontFamily: 'Vazirmatn', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف', style: TextStyle(color: Color(0xff9AA0AE), fontFamily: 'Vazirmatn')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('بله، بازنشانی کن', style: TextStyle(color: Color(0xffE5736B), fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      if (key == 'module_sports_enabled' || key == 'module_supplementary_sports_enabled') {
        await ModuleManagementService.instance.resetModuleData('module_sports_enabled');
        await ModuleManagementService.instance.resetModuleData('module_supplementary_sports_enabled');
      } else {
        await ModuleManagementService.instance.resetModuleData(key);
      }
      await _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('داده‌های سیستم «$moduleTitle» با موفقیت بازنشانی گردید.', style: const TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: const Color(0xff10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSwitchOption({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required VoidCallback onReset,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xff1C1F2E);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
            InkWell(
              onTap: onReset,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.arrow_counterclockwise, size: 12, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      'ریست',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.redAccent.shade100 : Colors.redAccent.shade700,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoSwitch(
              value: value,
              activeTrackColor: const Color(0xff5B8AF5),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrostedBottomSheet({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xff1C1F2E);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 30,
        color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.65),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  fontFamily: 'Vazirmatn',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showModulesManagementSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return _buildFrostedBottomSheet(
            title: 'مدیریت ماژول‌های فعال',
            children: [
              _buildSwitchOption(
                title: 'عبادت 🕌',
                value: _religionEnabled,
                onChanged: (val) async {
                  await _toggleModule('module_religion_enabled', val);
                  setSheetState(() => _religionEnabled = val);
                },
                onReset: () => _confirmAndResetModule('module_religion_enabled', 'عبادت'),
              ),
              _buildSwitchOption(
                title: 'دارو و سلامت 💊',
                value: _medicineEnabled,
                onChanged: (val) async {
                  await _toggleModule('module_medicine_enabled', val);
                  setSheetState(() => _medicineEnabled = val);
                },
                onReset: () => _confirmAndResetModule('module_medicine_enabled', 'دارو و سلامت'),
              ),
              _buildSwitchOption(
                title: 'ورزش و حرکت 🏃',
                value: _sportsEnabled || _supplementarySportsEnabled,
                onChanged: (val) async {
                  await _toggleModule('module_sports_enabled', val);
                  setSheetState(() {
                    _sportsEnabled = val;
                    _supplementarySportsEnabled = val;
                  });
                },
                onReset: () => _confirmAndResetModule('module_sports_enabled', 'ورزش و حرکت'),
              ),
              if (_isFemale)
                _buildSwitchOption(
                  title: 'چرخه بدن 🌸',
                  value: _cycleEnabled,
                  onChanged: (val) async {
                    await _toggleModule('module_cycle_enabled', val);
                    setSheetState(() => _cycleEnabled = val);
                  },
                  onReset: () => _confirmAndResetModule('module_cycle_enabled', 'چرخه بدن'),
                ),
              _buildSwitchOption(
                title: 'دوره‌های آموزشی 🎓',
                value: _coursesEnabled,
                onChanged: (val) async {
                  await _toggleModule('module_courses_enabled', val);
                  setSheetState(() => _coursesEnabled = val);
                },
                onReset: () => _confirmAndResetModule('module_courses_enabled', 'دوره‌های آموزشی'),
              ),
              _buildSwitchOption(
                title: 'اهداف و برنامه‌ها 🎯',
                value: _goalsEnabled,
                onChanged: (val) async {
                  await _toggleModule('module_goals_enabled', val);
                  setSheetState(() => _goalsEnabled = val);
                },
                onReset: () => _confirmAndResetModule('module_goals_enabled', 'اهداف و برنامه‌ها'),
              ),
              _buildSwitchOption(
                title: 'دستیار هوشمند 💬',
                value: _assistantEnabled,
                onChanged: (val) async {
                  await _toggleModule('module_assistant_enabled', val);
                  setSheetState(() => _assistantEnabled = val);
                },
                onReset: () => _confirmAndResetModule('module_assistant_enabled', 'دستیار هوشمند'),
              ),
              _buildSwitchOption(
                title: 'کنکور 📚',
                value: _konkurEnabled,
                onChanged: (val) async {
                  await _toggleModule('module_konkur_enabled', val);
                  setSheetState(() => _konkurEnabled = val);
                },
                onReset: () => _confirmAndResetModule('module_konkur_enabled', 'کنکور'),
              ),
              _buildSwitchOption(
                title: 'انرژی و خلق روزانه ⚡',
                value: _energyEnabled,
                onChanged: (val) async {
                  await _toggleModule('module_energy_enabled', val);
                  setSheetState(() => _energyEnabled = val);
                },
                onReset: () => _confirmAndResetModule('module_energy_enabled', 'انرژی و خلق روزانه'),
              ),
              _buildSwitchOption(
                title: 'خواب و بیداری 😴',
                value: _sleepEnabled,
                onChanged: (val) async {
                  await _toggleModule('module_sleep_enabled', val);
                  setSheetState(() => _sleepEnabled = val);
                },
                onReset: () => _confirmAndResetModule('module_sleep_enabled', 'خواب و بیداری'),
              ),
              _buildSwitchOption(
                title: 'عادات پیش‌رونده 📈',
                value: _progressiveHabitsEnabled,
                onChanged: (val) async {
                  await _toggleModule('module_progressive_habits_enabled', val);
                  setSheetState(() => _progressiveHabitsEnabled = val);
                },
                onReset: () => _confirmAndResetModule('module_progressive_habits_enabled', 'عادات پیش‌رونده'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PressableGlassCard extends StatefulWidget {

  const PressableGlassCard({
    super.key,
    required this.child,
    required this.onTap,
  });
  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressableGlassCard> createState() => _PressableGlassCardState();
}

class _PressableGlassCardState extends State<PressableGlassCard> {
  double scale = 1;
  double elevation = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          scale = 0.97;
          elevation = 10;
        });
      },
      onTapUp: (_) {
        setState(() {
          scale = 1.0;
          elevation = 0;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          scale = 1.0;
          elevation = 0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(scale, scale, 1),
        child: AnimatedPhysicalModel(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          elevation: elevation,
          color: Colors.transparent,
          shadowColor: Colors.black,
          borderRadius: BorderRadius.circular(28),
          child: widget.child,
        ),
      ),
    );
  }
}

class ParallaxImage extends StatelessWidget {

  const ParallaxImage({super.key, required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            return Transform.translate(
              offset: Offset(0, 6 * (1 - value)),
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
              ),
            );
          },
        );
      },
    );
  }
}


