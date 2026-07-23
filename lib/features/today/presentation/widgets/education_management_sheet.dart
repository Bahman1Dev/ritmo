import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class EducationManagementSheet extends StatefulWidget {

  const EducationManagementSheet({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<EducationManagementSheet> createState() => _EducationManagementSheetState();
}

class _EducationManagementSheetState extends State<EducationManagementSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _coursesList = [];
  final Map<String, List<Map<String, dynamic>>> _sessionsMap = {};

  // Form states for creating a course
  bool _isCreatingCourse = false;
  final _courseTitleController = TextEditingController();
  final _totalSessionsController = TextEditingController(text: '10');
  final _sessionDurationController = TextEditingController(text: '45');
  String _selectedEnergyRule = 'NONE';

  @override
  void initState() {
    super.initState();
    _loadCoursesData();
  }

  @override
  void dispose() {
    _courseTitleController.dispose();
    _totalSessionsController.dispose();
    _sessionDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadCoursesData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final courses = await db.query('courses', where: 'isArchived = 0', orderBy: 'createdAt DESC');

      _coursesList = courses;
      _sessionsMap.clear();

      for (final course in courses) {
        final courseId = course['id']! as String;
        final sessions = await db.query(
          'course_sessions',
          where: 'courseId = ?',
          orderBy: 'sessionNumber ASC',
        );
        _sessionsMap[courseId] = sessions;
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

  Future<void> _toggleSession(String sessionId, String currentStatus) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final newStatus = currentStatus == 'COMPLETED' ? 'PENDING' : 'COMPLETED';

      await db.update(
        'course_sessions',
        {
          'completionStatus': newStatus,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      HapticFeedback.lightImpact();
      _loadCoursesData();
      widget.onSaved();
    } catch (e) {
      debugPrint('Error toggling session: $e');
    }
  }

  Future<void> _saveCourse() async {
    if (_courseTitleController.text.trim().isEmpty) return;

    final total = int.tryParse(_totalSessionsController.text) ?? 10;
    final duration = int.tryParse(_sessionDurationController.text) ?? 45;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final courseId = 'course_${DateTime.now().millisecondsSinceEpoch}';
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Insert course
      await db.insert('courses', {
        'id': courseId,
        'title': _courseTitleController.text.trim(),
        'totalSessions': total,
        'sessionDurationMinutes': duration,
        'activityType': 'STUDY',
        'energyRule': _selectedEnergyRule,
        'isArchived': 0,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });

      // 2. Insert course sessions
      for (var i = 1; i <= total; i++) {
        await db.insert('course_sessions', {
          'id': 'session_${courseId}_$i',
          'courseId': courseId,
          'sessionNumber': i,
          'completionStatus': 'PENDING',
          'createdAt': nowMs,
          'updatedAt': nowMs,
        });
      }

      _courseTitleController.clear();
      _totalSessionsController.text = '10';
      _sessionDurationController.text = '45';
      _selectedEnergyRule = 'NONE';

      setState(() {
        _isCreatingCourse = false;
      });

      HapticFeedback.mediumImpact();
      await _loadCoursesData();
      widget.onSaved();
    } catch (e) {
      debugPrint('Error saving course: $e');
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      // Cascade delete handles session deletion due to foreign key
      await db.delete('courses', where: 'id = ?', whereArgs: [courseId]);

      HapticFeedback.mediumImpact();
      _loadCoursesData();
      widget.onSaved();
    } catch (e) {
      debugPrint('Error deleting course: $e');
    }
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
                    Text(
                      _isCreatingCourse ? 'ثبت دوره آموزشی جدید' : 'دوره‌ها و برنامه‌های آموزشی',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                    ),
                    if (!_isCreatingCourse)
                      IconButton(
                        icon: const Icon(CupertinoIcons.add_circled, color: Color(0xff5B8AF5), size: 24),
                        onPressed: () {
                          setState(() {
                            _isCreatingCourse = true;
                          });
                        },
                      )
                    else
                      IconButton(
                        icon: const Icon(CupertinoIcons.back, color: Colors.white60, size: 20),
                        onPressed: () {
                          setState(() {
                            _isCreatingCourse = false;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (!_isCreatingCourse)
                  Text(
                    'دوره‌ها و جلسات یادگیری فعال خود را مدیریت و دنبال کنید.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                  ),
                const Divider(color: Colors.white10, height: 20),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xff5B8AF5)))
                      : _isCreatingCourse
                          ? _buildCreateCourseForm(colors)
                          : _buildCoursesList(colors),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateCourseForm(RitmoColors colors) {
    return ListView(
      children: [
        TextField(
          controller: _courseTitleController,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
          decoration: InputDecoration(
            hintText: 'عنوان دوره آموزشی (مثلاً: برنامه‌نویسی فلاتر)',
            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 12),
            fillColor: Colors.white.withValues(alpha: 0.02),
            filled: true,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _totalSessionsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
                decoration: InputDecoration(
                  labelText: 'تعداد کل جلسات',
                  labelStyle: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'Vazirmatn'),
                  fillColor: Colors.white.withValues(alpha: 0.02),
                  filled: true,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _sessionDurationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
                decoration: InputDecoration(
                  labelText: 'مدت هر جلسه (دقیقه)',
                  labelStyle: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'Vazirmatn'),
                  fillColor: Colors.white.withValues(alpha: 0.02),
                  filled: true,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'قانون تطابق انرژی',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedEnergyRule,
          dropdownColor: const Color(0xff1C1F2E),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
          items: const [
            DropdownMenuItem(value: 'NONE', child: Text('بدون قانون (پیش‌فرض)')),
            DropdownMenuItem(value: 'skip', child: Text('عدم اجرا در انرژی پایین (Skip)')),
            DropdownMenuItem(value: 'offerLight', child: Text('پیشنهاد نسخه سبک در انرژی پایین')),
            DropdownMenuItem(value: 'highEnergyOnly', child: Text('فقط در زمان انرژی بالا')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedEnergyRule = val;
              });
            }
          },
          decoration: InputDecoration(
            fillColor: Colors.white.withValues(alpha: 0.02),
            filled: true,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _saveCourse,
          child: const Text('ذخیره و ایجاد دوره', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
        ),
      ],
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
            const SizedBox(height: 6),
            Text(
              'با زدن دکمه + اولین دوره خود را بسازید.',
              style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 11, fontFamily: 'Vazirmatn'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _coursesList.length,
      itemBuilder: (context, index) {
        final course = _coursesList[index];
        final courseId = course['id'] as String;
        final title = course['title'] as String;
        final total = course['totalSessions'] as int;
        final sessions = _sessionsMap[courseId] ?? [];

        final completedCount = sessions.where((s) => s['completionStatus'] == 'COMPLETED').length;
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
                      final sessionId = session['id'] as String;
                      final sNum = session['sessionNumber'] as int;
                      final sStatus = session['completionStatus'] as String;
                      final isCompleted = sStatus == 'COMPLETED';

                      return GestureDetector(
                        onTap: () => _toggleSession(sessionId, sStatus),
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
