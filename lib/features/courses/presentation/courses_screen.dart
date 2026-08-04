import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/analytics/courses_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/core/ux/ritmo_empty_state.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/course_detail_screen.dart';
import 'package:ritmo/features/courses/presentation/widgets/active_courses_section.dart';
import 'package:ritmo/features/courses/presentation/widgets/ai_courses_assistant_sheet.dart';
import 'package:ritmo/features/courses/presentation/widgets/ai_syllabus_sheet.dart';
import 'package:ritmo/features/courses/presentation/widgets/completed_courses_section.dart';
import 'package:ritmo/features/courses/presentation/widgets/courses_weekly_hero.dart';
import 'package:ritmo/features/courses/presentation/widgets/create_course_sheet.dart';
import 'package:ritmo/features/courses/presentation/widgets/today_sessions_section.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _isLoading = true;
  List<Course> _activeCourses = [];
  List<Course> _completedCourses = [];
  final Map<String, List<CourseSession>> _courseSessionsMap = {};

  String _currentEnergyLevel = 'MEDIUM';

  CoursesEngineOutput? _engineOutput;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Load app_settings for energy level
      final settings = await db.query('app_settings');
      final settingsMap = <String, String>{for (final s in settings) s['key']! as String: s['value']! as String};
      _currentEnergyLevel = settingsMap['default_energy_level'] ?? 'MEDIUM';

      // 2. Fetch active and completed courses
      _activeCourses = await CoursesRepository.instance.getActiveCourses();
      _completedCourses = await CoursesRepository.instance.getCompletedAndArchivedCourses();

      final allCourses = [..._activeCourses, ..._completedCourses];

      _courseSessionsMap.clear();
      final courseIds = allCourses.map((c) => c.id).toSet();
      final sessionsBatchMap = await CoursesRepository.instance.getSessionsForCourses(courseIds);
      _courseSessionsMap.addAll(sessionsBatchMap);
      final allSessions = sessionsBatchMap.values.expand((element) => element).toList();

      // 4. Run CoursesEngine
      final engine = CoursesEngine();
      _engineOutput = await engine.calculate(
        CoursesEngineInput(
          courses: allCourses,
          sessions: allSessions,
          currentEnergyLevel: _currentEnergyLevel,
          today: DateTime.now(),
        ),
      );

    } catch (e) {
      debugPrint('Error loading Courses hub data: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openCreateCourseSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreateCourseSheet(
        onCourseCreated: _loadAllData,
      ),
    ).then((_) => _loadAllData());
  }

  void _openAiAssistantSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AiCoursesAssistantSheet(
        activeCourses: _activeCourses,
        onScheduleSuggested: (suggestedData) {
          // AI suggestions will open the create sheet pre-populated
          Navigator.pop(context); // Close assistant
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => CreateCourseSheet(
              initialValues: suggestedData,
              onCourseCreated: _loadAllData,
            ),
          ).then((_) => _loadAllData());
        },
      ),
    );
  }

  void _openAiSyllabusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AiSyllabusSheet(
        onImported: _loadAllData,
      ),
    ).then((_) => _loadAllData());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.bg,
        appBar: RitmoModuleAppBar(
          title: 'دوره‌های آموزشی',
          subtitle: 'مدیریت دروس و جلسات مطالعاتی',
          statusBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xff3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'فعال',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Color(0xff3B82F6), fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.doc_on_clipboard_fill, color: Color(0xff8B5CF6)),
              tooltip: 'ورود سرفصل AI',
              onPressed: _openAiSyllabusSheet,
            ),
            IconButton(
              icon: Icon(CupertinoIcons.sparkles, color: colors.primary),
              onPressed: _openAiAssistantSheet,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) ...[
                  const RitmoSkeletonCard(height: 150),
                  const SizedBox(height: 24),
                  const RitmoSkeletonList(itemCount: 3, itemHeight: 90),
                ] else if (_activeCourses.isEmpty && _completedCourses.isEmpty) ...[
                  RitmoEmptyState(
                    icon: CupertinoIcons.book,
                    title: 'هنوز هیچ دوره‌ای ایجاد نکرده‌اید',
                    description: 'کتاب‌ها، مهارت‌ها و اهداف یادگیری خود را قالب دوره ثبت کنید تا روند پیشرفت مطالعه خود را ردیابی کنید.',
                    ctaLabel: 'ایجاد اولین دوره',
                    onCta: _openCreateCourseSheet,
                  ),
                ] else ...[
                  // 1. Weekly aggregates card
                  if (_engineOutput != null)
                    CoursesWeeklyHero(
                      weeklyDoneSessions: _engineOutput!.weeklyDoneSessions,
                      weeklyTargetSessions: _engineOutput!.weeklyTargetSessions,
                      weeklyStudyMinutes: _engineOutput!.weeklyStudyMinutes,
                      studyStreakDays: _engineOutput!.studyStreakDays,
                    ),
                  const SizedBox(height: 24),

                  // 2. Today's Sessions Section
                  if (_engineOutput != null)
                    TodaySessionsSection(
                      todaySessions: _engineOutput!.todaySessions,
                      courses: [..._activeCourses, ..._completedCourses],
                      currentEnergyLevel: _currentEnergyLevel,
                      onRefresh: _loadAllData,
                    ),

                  // 3. Active Courses List
                  ActiveCoursesSection(
                    courses: _activeCourses,
                    courseSessionsMap: _courseSessionsMap,
                    onCourseTap: (course) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseDetailScreen(course: course),
                        ),
                      ).then((_) => _loadAllData());
                    },
                  ),
                  const SizedBox(height: 24),

                  // 4. Completed Courses List
                  CompletedCoursesSection(
                    completedCourses: _completedCourses,
                    courseSessionsMap: _courseSessionsMap,
                    onRefresh: _loadAllData,
                  ),
                ],
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openCreateCourseSheet,
          backgroundColor: colors.primary,
          child: const Icon(CupertinoIcons.add, color: Colors.white),
        ),
      ),
    );
  }
}
