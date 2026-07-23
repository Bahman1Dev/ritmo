import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/analytics/insight_generation_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:sqflite/sqflite.dart';

class WorshipSeasonsSheet extends StatefulWidget {
  const WorshipSeasonsSheet({super.key});

  @override
  State<WorshipSeasonsSheet> createState() => _WorshipSeasonsSheetState();
}

class _WorshipSeasonsSheetState extends State<WorshipSeasonsSheet> {
  List<Map<String, dynamic>> _seasons = [];
  bool _isLoading = true;
  bool _isFormOpen = false;
  String? _editingId;
  String _worshipCorrelation = 'در حال محاسبه...';
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

  final _titleController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  double _priorityWeight = 1;
  bool _isActive = true;
  String _selectedType = 'custom'; // fasting, prayer, spiritual, custom

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadSeasons() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.query('worship_seasons', orderBy: 'startDate DESC');
      
      // Calculate correlation
      final correlation = await InsightGenerationEngine.calculateWorshipCorrelation();
      
      setState(() {
        _seasons = res.map(Map<String, dynamic>.from).toList();
        _worshipCorrelation = correlation;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading worship seasons: $e');
      setState(() {
        _isLoading = false;
        _worshipCorrelation = 'داده کافی نیست';
      });
    }
  }

  void _openForm([Map<String, dynamic>? season]) {
    if (season != null) {
      _editingId = season['id'] as String;
      _titleController.text = season['title'] as String? ?? '';
      _startDateController.text = (season['start_date'] ?? season['startDate']) as String? ?? '';
      _endDateController.text = (season['end_date'] ?? season['endDate']) as String? ?? '';
      _priorityWeight = (season['priority_weight'] as num?)?.toDouble() ?? 1.0;
      _isActive = (season['is_active'] ?? season['isActive'] ?? 1) == 1;
      _selectedType = (season['type'] ?? season['seasonType'] ?? 'custom').toString().toLowerCase();
    } else {
      _editingId = null;
      _titleController.clear();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      _startDateController.text = todayStr;
      _endDateController.text = todayStr;
      _priorityWeight = 1.0;
      _isActive = true;
      _selectedType = 'custom';
    }
    setState(() {
      _isFormOpen = true;
    });
  }

  void _closeForm() {
    setState(() {
      _isFormOpen = false;
      _editingId = null;
    });
  }

  Future<void> _triggerSystemSync() async {
    try {
      await AlarmSchedulerService.scheduleNextAlarms();
    } catch (e) {
      debugPrint('Error triggering AlarmSchedulerService: $e');
    }
    try {
      RitmoEvents.notifyRoutineChanged();
    } catch (e) {
      debugPrint('Error triggering RitmoEvents: $e');
    }
  }

  Future<void> _saveSeason() async {
    if (_titleController.text.trim().isEmpty ||
        _startDateController.text.trim().isEmpty ||
        _endDateController.text.trim().isEmpty) {
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final id = _editingId ?? 'ws_$nowMs';

      await db.insert(
        'worship_seasons',
        {
          'id': id,
          'seasonType': _selectedType.toUpperCase(),
          'title': _titleController.text.trim(),
          'startDate': _startDateController.text.trim(),
          'endDate': _endDateController.text.trim(),
          'calendar': 'HIJRI',
          'behaviorJson': '{"behavior": "NORMAL"}',
          'isActive': _isActive ? 1 : 0,
          'createdAt': nowMs,
          'priority_weight': _priorityWeight,
          // snake_case support
          'start_date': _startDateController.text.trim(),
          'end_date': _endDateController.text.trim(),
          'type': _selectedType.toLowerCase(),
          'is_active': _isActive ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _triggerSystemSync();
      HapticFeedback.mediumImpact();
      _closeForm();
      _loadSeasons();
    } catch (e) {
      debugPrint('Error saving worship season: $e');
    }
  }

  Future<void> _toggleSeasonActive(Map<String, dynamic> season, bool active) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final id = season['id'] as String;

      await db.update(
        'worship_seasons',
        {
          'isActive': active ? 1 : 0,
          'is_active': active ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _triggerSystemSync();
      HapticFeedback.mediumImpact();
      _loadSeasons();
    } catch (e) {
      debugPrint('Error toggling season active: $e');
    }
  }

  Future<void> _deleteSeason(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('worship_seasons', where: 'id = ?', whereArgs: [id]);
      
      await _triggerSystemSync();
      HapticFeedback.mediumImpact();
      _loadSeasons();
    } catch (e) {
      debugPrint('Error deleting worship season: $e');
    }
  }

  bool _isCurrentlyActive(Map<String, dynamic> season) {
    final activeVal = (season['is_active'] ?? season['isActive'] ?? 1) == 1;
    if (!activeVal) return false;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final start = (season['start_date'] ?? season['startDate']) as String? ?? '';
    final end = (season['end_date'] ?? season['endDate']) as String? ?? '';
    return todayStr.compareTo(start) >= 0 && todayStr.compareTo(end) <= 0;
  }

  bool _hasOverlap(String start, String end) {
    if (start.isEmpty || end.isEmpty) return false;
    for (final s in _seasons) {
      if (s['id'] == _editingId) continue;
      final sActive = (s['is_active'] ?? s['isActive'] ?? 1) == 1;
      if (!sActive) continue;

      final sStart = (s['start_date'] ?? s['startDate']) as String? ?? '';
      final sEnd = (s['end_date'] ?? s['endDate']) as String? ?? '';
      if (sStart.isEmpty || sEnd.isEmpty) continue;

      if (start.compareTo(sEnd) <= 0 && end.compareTo(sStart) >= 0) {
        return true;
      }
    }
    return false;
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await RitmoDatePicker.showJalali(
      context: context,
      initialDate: Jalali.fromDateTime(now),
      firstDate: Jalali(now.year - 5),
      lastDate: Jalali(now.year + 5, 12, 29),
    );
    if (picked != null) {
      final pickedDateTime = picked.toDateTime();
      final dateStr = pickedDateTime.toIso8601String().substring(0, 10);
      setState(() {
        controller.text = dateStr;
      });
    }
  }

  String _formatSeasonPeriodForMap(Map<String, dynamic> s) {
    final start = (s['start_date'] ?? s['startDate'] ?? '') as String;
    final end = (s['end_date'] ?? s['endDate'] ?? '') as String;
    final calendar = (s['calendar'] ?? 'HIJRI') as String;

    if (calendar.toUpperCase() == 'HIJRI') {
      try {
        final startParts = start.split('-');
        final endParts = end.split('-');
        final startM = int.parse(startParts[startParts.length - 2]);
        final startD = int.parse(startParts.last);
        final endM = int.parse(endParts[endParts.length - 2]);
        final endD = int.parse(endParts.last);

        final startMonthName = hijriMonthsFa[startM] ?? '';
        final endMonthName = hijriMonthsFa[endM] ?? '';

        if (startMonthName == endMonthName) {
          return toPersianDigits('$startD تا $endD $startMonthName');
        }
        return toPersianDigits('$startD $startMonthName تا $endD $endMonthName');
      } catch (_) {
        return toPersianDigits('$start تا $end');
      }
    } else {
      final startJalali = _formatDateToJalali(start);
      final endJalali = _formatDateToJalali(end);
      return '$startJalali تا $endJalali';
    }
  }

  String _formatDateToJalali(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final parts = dateStr.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      
      final dt = DateTime(y, m, d);
      final jal = Jalali.fromDateTime(dt);
      
      final englishStr = '${jal.year}/${jal.month}/${jal.day}';
      
      const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
      var output = englishStr;
      for (var i = 0; i < english.length; i++) {
        output = output.replaceAll(english[i], persian[i]);
      }
      return output;
    } catch (_) {
      return dateStr;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'fasting':
        return 'روزه';
      case 'prayer':
        return 'نماز';
      case 'spiritual':
        return 'معنوی';
      case 'custom':
      default:
        return 'سفارشی';
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isFormOpen ? _buildForm(colors) : _buildList(colors),
          ),
        ),
      ),
    );
  }

  Widget _buildList(RitmoColors colors) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activeList = _seasons.where(_isCurrentlyActive).toList();
    final inactiveList = _seasons.where((s) => !_isCurrentlyActive(s)).toList();

    return Column(
      key: const ValueKey('list'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'مناسبت‌های عبادی 🌙',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            ),
            IconButton(
              icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.info_circle, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مناسبت عبادی چیست؟ مناسبت‌های عبادی به شما کمک می‌کنند تا در ایام خاص (مانند رمضان یا چله‌های شخصی) بدون ایجاد اجبار یا تغییر در ساعت روتین‌ها، اولویت کارهای مذهبی را به صورت هوشمند تعدیل کنید.',
                  style: TextStyle(fontSize: 11, color: colors.textPrimary, height: 1.4, fontFamily: 'Vazirmatn'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xff5B8AF5))))
        else ...[
          // Active seasons
          Text(
            'مناسبت‌های فعال:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
          ),
          const SizedBox(height: 6),
          if (activeList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'هیچ مناسبت فعالی در حال حاضر وجود ندارد.',
                style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: activeList.length,
                itemBuilder: (context, index) {
                  final s = activeList[index];
                  final dateRangeStr = _formatSeasonPeriodForMap(s);
                  final type = (s['type'] ?? s['seasonType'] ?? 'custom') as String;
                  final weight = (s['priority_weight'] as num?)?.toDouble() ?? 1.0;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.checkmark_circle_fill, color: colors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['title'] as String? ?? '',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$dateRangeStr • نوع: ${_getTypeLabel(type)} | وزن: $weight',
                                style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.pencil, color: colors.primary, size: 18),
                          onPressed: () => _openForm(s),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(CupertinoIcons.eye_slash, color: colors.textSecondary, size: 18),
                          onPressed: () => _toggleSeasonActive(s, false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // Inactive seasons
          Text(
            'مناسبت‌های غیرفعال:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
          ),
          const SizedBox(height: 6),
          if (inactiveList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'هیچ مناسبت غیرفعالی ثبت نشده است.',
                style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: inactiveList.length,
                itemBuilder: (context, index) {
                  final s = inactiveList[index];
                  final id = s['id'] as String;
                  final dateRangeStr = _formatSeasonPeriodForMap(s);
                  final type = (s['type'] ?? s['seasonType'] ?? 'custom') as String;
                  final weight = (s['priority_weight'] as num?)?.toDouble() ?? 1.0;
                  final isSeasonEnabled = (s['is_active'] ?? s['isActive'] ?? 1) == 1;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withValues(alpha: 0.01) : Colors.black.withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.calendar, color: colors.textSecondary.withValues(alpha: 0.5), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['title'] as String? ?? '',
                                style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$dateRangeStr • نوع: ${_getTypeLabel(type)} | وزن: $weight',
                                style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isSeasonEnabled ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                            color: isSeasonEnabled ? colors.primary : colors.textSecondary.withValues(alpha: 0.4),
                            size: 18,
                          ),
                          onPressed: () => _toggleSeasonActive(s, !isSeasonEnabled),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(CupertinoIcons.trash, color: colors.medicalRed, size: 18),
                          onPressed: () => _deleteSeason(id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
          // Past correlation panel
          Text(
            '📊 تحلیل مناسبت‌های گذشته:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نرخ رشد تکمیل روتین‌های مذهبی:',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
                Text(
                  _worshipCorrelation,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _worshipCorrelation.startsWith('+') ? colors.primary : colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _openForm,
          icon: const Icon(CupertinoIcons.add, size: 16),
          label: const Text('⊕ افزودن مناسبت جدید', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
        ),
      ],
    );
  }

  Widget _buildForm(RitmoColors colors) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final overlapDetected = _hasOverlap(_startDateController.text.trim(), _endDateController.text.trim());

    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _editingId == null ? 'افزودن مناسبت عبادی' : 'ویرایش مناسبت عبادی',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 20),
              onPressed: _closeForm,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Pre-sets Row
        Text(
          'قالب‌های آماده:',
          style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 6),
        _buildTemplatesRow(colors),
        const SizedBox(height: 16),

        // Title input
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
          decoration: InputDecoration(
            labelText: 'عنوان مناسبت (مثال: ماه رمضان)',
            labelStyle: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Vazirmatn'),
            fillColor: Colors.white.withValues(alpha: 0.02),
            filled: true,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
          ),
        ),
        const SizedBox(height: 14),

        // Type Select
        Text(
          'نوع مناسبت:',
          style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 6),
        _buildTypeSelector(colors),
        const SizedBox(height: 14),

        // Start & End Dates
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, _startDateController),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _startDateController,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
                    decoration: InputDecoration(
                      labelText: 'تاریخ شروع',
                      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'Vazirmatn'),
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      filled: true,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, _endDateController),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _endDateController,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
                    decoration: InputDecoration(
                      labelText: 'تاریخ پایان',
                      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'Vazirmatn'),
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      filled: true,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Priority Weight Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'وزن اولویت مناسبت:',
              style: TextStyle(fontSize: 12, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            ),
            Text(
              _priorityWeight.toStringAsFixed(1),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary, fontFamily: 'Vazirmatn'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Slider(
          value: _priorityWeight,
          min: 1,
          max: 10,
          divisions: 18,
          activeColor: colors.primary,
          inactiveColor: colors.textSecondary.withValues(alpha: 0.2),
          onChanged: (val) {
            setState(() {
              _priorityWeight = val;
            });
          },
        ),
        const SizedBox(height: 14),

        // Priority impact preview
        Text(
          'پیش‌نمایش تأثیر:',
          style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            'بر اساس تحلیل RIE، روتین‌های مذهبی در این بازه ضریب امتیاز ۲.۰ دریافت کرده و اولویت بالاتری خواهند داشت.',
            style: TextStyle(fontSize: 11, color: colors.textPrimary, height: 1.4, fontFamily: 'Vazirmatn'),
          ),
        ),
        const SizedBox(height: 12),

        // Overlap warning
        if (overlapDetected) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.medicalRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.medicalRed.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle, color: colors.medicalRed, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '⚠️ هشدار تداخل: این بازه با مناسبت فعال دیگری تداخل دارد. بالاترین وزن اولویت (MAX) بین آن‌ها اعمال خواهد شد.',
                    style: TextStyle(fontSize: 11, color: Colors.white, height: 1.4, fontFamily: 'Vazirmatn'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Active Switch
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'فعال بودن مناسبت',
              style: TextStyle(fontSize: 12, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            ),
            CupertinoSwitch(
              value: _isActive,
              activeTrackColor: colors.primary,
              onChanged: (val) {
                setState(() {
                  _isActive = val;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Save & Cancel Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveSeason,
                child: const Text('✓ ذخیرهٔ مناسبت', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: colors.textSecondary,
                ),
                onPressed: _closeForm,
                child: const Text('انصراف', style: TextStyle(fontSize: 13, fontFamily: 'Vazirmatn')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplatesRow(RitmoColors colors) {
    return Row(
      children: [
        _buildTemplateChip(
          label: '🌙 رمضان',
          colors: colors,
          onTap: () {
            setState(() {
              _titleController.text = 'ماه رمضان';
              _selectedType = 'fasting';
              _priorityWeight = 7.0; // high
              _isActive = true;
            });
          },
        ),
        const SizedBox(width: 8),
        _buildTemplateChip(
          label: '🕋 حج',
          colors: colors,
          onTap: () {
            setState(() {
              _titleController.text = 'ایام حج';
              _selectedType = 'spiritual';
              _priorityWeight = 7.0; // high
              _isActive = true;
            });
          },
        ),
        const SizedBox(width: 8),
        _buildTemplateChip(
          label: '✨ شخصی',
          colors: colors,
          onTap: () {
            setState(() {
              _titleController.clear();
              _selectedType = 'custom';
              _priorityWeight = 1.0;
              _isActive = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTemplateChip({
    required String label,
    required RitmoColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Vazirmatn'),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(RitmoColors colors) {
    final types = [
      {'key': 'fasting', 'label': 'روزه'},
      {'key': 'prayer', 'label': 'نماز'},
      {'key': 'spiritual', 'label': 'معنوی'},
      {'key': 'custom', 'label': 'سفارشی'},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: types.map((t) {
        final isSelected = _selectedType == t['key'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = t['key']!;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : (isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? colors.primary : (isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                ),
              ),
              child: Text(
                t['label']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? (isDarkMode ? Colors.white : Colors.black) : colors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
