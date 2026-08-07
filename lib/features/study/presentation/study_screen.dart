import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/features/konkur/presentation/konkur_screen.dart';
import 'package:ritmo/features/study/logic/study_repository.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _isKonkurMode = false;
  
  List<StudySubject> _subjects = [];
  List<StudySession> _sessions = [];
  Map<String, String> _settings = {};

  final TextEditingController _subjectNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectNameController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final settingsList = await db.query('app_settings');
      _settings = {for (final s in settingsList) s['key'] as String: s['value'] as String};

      _isKonkurMode = _settings['study_konkur_mode'] == 'true' || _settings['module_konkur_enabled'] == 'true';

      final repo = StudyRepository.instance;
      _subjects = await repo.getSubjects();
      _sessions = await repo.getSessions();
    } catch (e) {
      debugPrint('StudyScreen: Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleKonkurMode(bool val) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('app_settings', {
      'key': 'study_konkur_mode',
      'value': val.toString(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    setState(() => _isKonkurMode = val);
    await _loadAllData();
  }

  Future<void> _addCustomSubjectDialog(RitmoColors colors) async {
    _subjectNameController.clear();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'افزودن درس جدید',
          style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        content: TextField(
          controller: _subjectNameController,
          autofocus: true,
          style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'نام درس (مثلاً: زیست‌شناسی، برنامه‌نویسی...)',
            hintStyle: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _subjectNameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogContext);
              final repo = StudyRepository.instance;
              final nowMs = DateTime.now().millisecondsSinceEpoch;
              final id = 'subj_$nowMs';
              final subject = StudySubject(
                id: id,
                name: name,
                createdAt: nowMs,
                updatedAt: nowMs,
              );
              await repo.insertSubject(subject);
              if (mounted) {
                await _loadAllData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            child: const Text('ثبت درس', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Direct delegation to full-featured KonkurScreen when Konkur Mode is active!
    if (_isKonkurMode) {
      return KonkurScreen(
        onSwitchToStudyMode: () => _toggleKonkurMode(false),
      );
    }

    // General Study Screen UI
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'درس و مطالعه',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: 'ورود به حالت کنکور',
            onPressed: () => _toggleKonkurMode(true),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
            onPressed: () => _showSettingsSheet(colors),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'دروس من'),
            Tab(text: 'جلسات مطالعه'),
            Tab(text: 'پیشرفت'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustomSubjectDialog(colors),
        backgroundColor: colors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('افزودن درس', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubjectsTab(colors),
          _buildSessionsTab(colors),
          _buildProgressTab(colors),
        ],
      ),
    );
  }

  Widget _buildSubjectsTab(RitmoColors colors) {
    if (_subjects.isEmpty) {
      return _buildEmptyState(
        colors,
        title: 'هیچ درسی ثبت نشده است',
        subtitle: 'با لمس دکمهٔ «افزودن درس»، اولین درس خود را برای مطالعه وارد کنید.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subj = _subjects[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.book_outlined, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subj.name,
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ضریب اهمیت: ${RitmoNumber.fa(subj.importanceFactor.toStringAsFixed(1))}',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: colors.textSecondary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionsTab(RitmoColors colors) {
    if (_sessions.isEmpty) {
      return _buildEmptyState(
        colors,
        title: 'هیچ جلسهٔ مطالعه‌ای ثبت نشده',
        subtitle: 'جلسات مطالعه و زمان ثبت‌شده برای دروس اینجا نمایش داده می‌شوند.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final sess = _sessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'جلسه مطالعه ${RitmoNumber.fa(sess.dateIso)}',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    if (sess.note != null && sess.note!.isNotEmpty)
                      Text(sess.note!, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),
              Text(
                '${RitmoNumber.faInt(sess.durationMinutes)} دقیقه',
                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.primary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressTab(RitmoColors colors) {
    final totalMinutes = _sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Text('مجموع کل زمان مطالعه ثبت‌شده', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: colors.textSecondary)),
                const SizedBox(height: 8),
                Text('${RitmoNumber.faInt(totalMinutes)} دقیقه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 32, fontWeight: FontWeight.bold, color: colors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(RitmoColors colors, {required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: colors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(RitmoColors colors) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تنظیمات ماژول درس و مطالعه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('حالت کنکور (صفحه کامل و پیشرفته کنکور)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14)),
                subtitle: const Text('فعال‌سازی تمام امکانات، بودجه‌بندی، آزمون‌ها و هوش مصنوعی کنکوری', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                value: _isKonkurMode,
                onChanged: (val) {
                  Navigator.pop(context);
                  _toggleKonkurMode(val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
