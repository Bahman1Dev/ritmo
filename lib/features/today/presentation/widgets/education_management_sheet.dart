import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/courses/presentation/courses_screen.dart';

class EducationManagementSheet extends StatefulWidget {
  const EducationManagementSheet({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<EducationManagementSheet> createState() => _EducationManagementSheetState();
}

class _EducationManagementSheetState extends State<EducationManagementSheet> {
  bool _isLoading = true;
  List<Course> _coursesList = [];
  final Map<String, List<CourseSession>> _sessionsMap = {};

  @override
  void initState() {
    super.initState();
    _loadCoursesData();
  }

  Future<void> _loadCoursesData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activeCourses = await CoursesRepository.instance.getActiveCourses();
      _coursesList = activeCourses;
      _sessionsMap.clear();

      for (final course in activeCourses) {
        final sessions = await CoursesRepository.instance.getSessionsForCourse(course.id);
        _sessionsMap[course.id] = sessions;
      }
    } catch (e) {
      debugPrint('Error loading courses: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSession(CourseSession session) async {
    try {
      if (session.isCompleted) {
        await CoursesRepository.instance.uncompleteSession(session.id);
      } else {
        await CoursesRepository.instance.completeSession(
          sessionId: session.id,
          actualDurationMinutes: session.estimatedDurationMinutes ?? 45,
        );
      }

      unawaited(HapticFeedback.lightImpact());
      await _loadCoursesData();
      widget.onSaved();
    } catch (e) {
      debugPrint('Error toggling session: $e');
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      await CoursesRepository.instance.deleteCourse(courseId);

      unawaited(HapticFeedback.mediumImpact());
      await _loadCoursesData();
      widget.onSaved();
    } catch (e) {
      debugPrint('Error deleting course: $e');
    }
  }

  void _openCoursesScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoursesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'دوره‌ها و برنامه‌های آموزشی',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _openCoursesScreen,
                      icon: const Icon(CupertinoIcons.square_stack_3d_up, size: 16),
                      label: const Text(
                        'باز کردن دوره‌ها',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'دوره‌ها و جلسات یادگیری فعال خود را مدیریت و دنبال کنید.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
                const Divider(color: Colors.white10, height: 20),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xff5B8AF5)))
                      : _buildCoursesList(colors),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList(RitmoColors colors) {
    if (_coursesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              'هنوز هیچ دوره‌ای ثبت نکرده‌اید.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Vazirmatn'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _openCoursesScreen,
              child: const Text('باز کردن دوره‌های آموزشی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _coursesList.length,
      itemBuilder: (context, index) {
        final course = _coursesList[index];
        final courseId = course.id;
        final title = course.title;
        final total = course.totalSessions;
        final sessions = _sessionsMap[courseId] ?? [];

        final completedCount = sessions.where((s) => s.isCompleted).length;
        final progress = total > 0 ? completedCount / total : 0.0;
        final isFinished = completedCount >= total;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isFinished ? colors.success : Colors.white,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
                    onPressed: () => _deleteCourse(courseId),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 5,
                        color: Colors.white.withValues(alpha: 0.05),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(color: isFinished ? colors.success : colors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completedCount از $total جلسه',
                    style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                  ),
                ],
              ),

              // Sessions list
              if (sessions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sessions.length,
                    itemBuilder: (context, sIndex) {
                      final session = sessions[sIndex];
                      final sNum = session.sessionNumber;
                      final isCompleted = session.isCompleted;

                      return GestureDetector(
                        onTap: () => _toggleSession(session),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? colors.success.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                            border: Border.all(
                              color: isCompleted ? colors.success : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            sNum.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? colors.success : colors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
