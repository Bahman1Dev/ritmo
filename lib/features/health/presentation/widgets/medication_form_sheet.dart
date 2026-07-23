import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:shamsi_date/shamsi_date.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL  — pure data, no DB logic
// ─────────────────────────────────────────────────────────────────────────────

class MedicationFormData {

  const MedicationFormData({
    required this.name,
    required this.dose,
    required this.type,
    required this.scheduledTimes,
    required this.repeatType,
    required this.selectedWeekdays,
    required this.intervalDays,
    required this.startDate,
    required this.stockCount,
    required this.warningThreshold,
    required this.minInterval,
    required this.maxDoses,
    this.existingMedication,
  });
  final String name;
  final String dose;
  final String type; // 'FIXED' | 'PRN'
  final List<TimeOfDay> scheduledTimes;
  final String repeatType; // 'WEEKDAYS' | 'INTERVAL'
  final List<int> selectedWeekdays;
  final int intervalDays;
  final DateTime startDate;
  final int stockCount;
  final int warningThreshold;
  final int minInterval;
  final int maxDoses;
  /// Non-null when editing an existing medication routine row.
  final Map<String, dynamic>? existingMedication;

  bool get isEdit => existingMedication != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVE HELPER  — single place for DB write logic
// ─────────────────────────────────────────────────────────────────────────────

class MedicationSaveHelper {
  MedicationSaveHelper._();

  /// Persists [data] to the database.  Returns the saved routineId.
  static Future<String> save(MedicationFormData data) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final routineId = data.isEdit
        ? data.existingMedication!['id'] as String
        : 'routine_med_$now';

    final routineData = {
      'id': routineId,
      'title': data.name,
      'description': data.dose.isNotEmpty ? data.dose : null,
      'category': 'medical',
      'routineType': data.type == 'FIXED' ? 'timeBased' : 'asNeeded',
      'notificationLevel': 'normal',
      'isEssential': 0,
      'isEssentialLocked': 0,
      'energyRule': 'NONE',
      'priority': 1.0,
      'medStockCount': data.stockCount,
      'medRefillThreshold': data.warningThreshold,
      'minIntervalHours': data.type == 'PRN' ? data.minInterval : 0,
      'maxDosesPerDay': data.type == 'PRN' ? data.maxDoses : 0,
      'isArchived': 0,
      'isPrivate': 0,
      'displayOrder': 1,
      'createdAt':
          data.isEdit ? data.existingMedication!['createdAt'] as int : now,
      'updatedAt': now,
      'itemType': 'ROUTINE',
    };

    final firstTime = data.type == 'FIXED'
        ? '${data.scheduledTimes.first.hour.toString().padLeft(2, '0')}:${data.scheduledTimes.first.minute.toString().padLeft(2, '0')}'
        : '08:00';

    final String daysStr;
    final RecurrenceRule rule;

    if (data.type == 'PRN') {
      daysStr = '6,7,1,2,3,4,5';
      rule = RecurrenceRule(
        weekdays: [6, 7, 1, 2, 3, 4, 5],
        reminderTimes: ['08:00'],
        startDate: DateTime.now(),
      );
    } else if (data.repeatType == 'WEEKDAYS') {
      daysStr = data.selectedWeekdays.join(',');
      rule = RecurrenceRule(
        weekdays: data.selectedWeekdays,
        reminderTimes: data.scheduledTimes.map((t) {
          return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        }).toList(),
        startDate: DateTime.now(),
      );
    } else {
      daysStr = '6,7,1,2,3,4,5';
      rule = RecurrenceRule(
        weekdays: [],
        intervalDays: data.intervalDays,
        reminderTimes: data.scheduledTimes.map((t) {
          return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        }).toList(),
        startDate: data.startDate,
      );
    }

    final scheduleData = {
      'id': 'sched_$routineId',
      'routineId': routineId,
      'scheduleType': data.type == 'FIXED' ? 'RECURRENCE' : 'DAILY',
      'timeOfDay': firstTime,
      'daysOfWeek': daysStr,
      'recurrenceRule': jsonEncode(rule.toMap()),
      'createdAt': now,
      'updatedAt': now,
    };

    if (data.isEdit) {
      await RitmoExecutionKernel.instance.execute(
        EditRoutineCommand(
          routineId: routineId,
          routineData: routineData,
          scheduleData: scheduleData,
          applyToAll: true,
        ),
      );
    } else {
      await RitmoExecutionKernel.instance.execute(
        CreateRoutineCommand(
          routineData: routineData,
          scheduleData: scheduleData,
        ),
      );
    }

    RitmoEvents.notifyRoutineChanged();
    return routineId;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM SHEET  — data collection only, no saving
// ─────────────────────────────────────────────────────────────────────────────

/// Opens a bottom sheet for collecting medication details.
/// When the user taps "ادامه", [onFormCompleted] is called with the data.
/// Nothing is saved to the DB by this widget.
class MedicationFormSheet extends StatefulWidget {

  const MedicationFormSheet({
    super.key,
    this.medication,
    this.prefillData,
    required this.onFormCompleted,
  });
  final Map<String, dynamic>? medication;
  final MedicationFormData? prefillData;
  final void Function(MedicationFormData data) onFormCompleted;

  /// Shows the form sheet as a modal.
  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? medication,
    MedicationFormData? prefillData,
    required void Function(MedicationFormData data) onFormCompleted,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MedicationFormSheet(
        medication: medication,
        prefillData: prefillData,
        onFormCompleted: onFormCompleted,
      ),
    );
  }

  @override
  State<MedicationFormSheet> createState() => _MedicationFormSheetState();
}

class _MedicationFormSheetState extends State<MedicationFormSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();

  bool _isLoading = true;
  List<String> _drugAllergens = [];
  String? _matchedAllergen;

  bool _nameHasError = false;
  bool _doseHasError = false;
  bool _stockHasError = false;
  bool _warningHasError = false;

  String _type = 'FIXED';
  int _minInterval = 4;
  int _maxDoses = 4;
  int _stockCount = 30;
  int _warningThreshold = 5;

  List<TimeOfDay> _scheduledTimes = [const TimeOfDay(hour: 8, minute: 0)];
  String _repeatType = 'WEEKDAYS';
  List<int> _selectedWeekdays = [6, 7, 1, 2, 3, 4, 5];
  int _intervalDays = 2;
  DateTime _startDate = DateTime.now();

  bool get _isEdit => widget.medication != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    if (widget.prefillData != null) {
      final p = widget.prefillData!;
      _nameController.text = p.name;
      _doseController.text = p.dose;
      _type = p.type;
      _minInterval = p.minInterval;
      _maxDoses = p.maxDoses;
      _stockCount = p.stockCount;
      _warningThreshold = p.warningThreshold;
      _scheduledTimes = List.from(p.scheduledTimes);
      _repeatType = p.repeatType;
      _selectedWeekdays = List.from(p.selectedWeekdays);
      _intervalDays = p.intervalDays;
      _startDate = p.startDate;
    } else if (_isEdit) {
      final med = widget.medication!;
      _nameController.text = med['title'] as String? ?? '';
      _doseController.text = med['description'] as String? ?? '';
      _type = med['routineType'] == 'asNeeded' ? 'PRN' : 'FIXED';
      _minInterval = med['minIntervalHours'] as int? ?? 4;
      _maxDoses = med['maxDosesPerDay'] as int? ?? 4;
      _stockCount = med['medStockCount'] as int? ?? 30;
      _warningThreshold = med['medRefillThreshold'] as int? ?? 5;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.query('allergies', where: "category = 'DRUG'");
      _drugAllergens = res.map((r) => r['allergen']! as String).toList();
    } catch (e) {
      debugPrint('Error loading allergens: $e');
    }

    if (_isEdit && widget.prefillData == null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final res = await db.query(
          'routine_schedules',
          where: 'routineId = ?',
          whereArgs: [widget.medication!['id']],
        );
        if (res.isNotEmpty) {
          final ruleStr = res.first['recurrenceRule'] as String?;
          if (ruleStr != null && ruleStr.isNotEmpty) {
            final rule = RecurrenceRule.fromMap(
                jsonDecode(ruleStr) as Map<String, dynamic>);
            if (rule.reminderTimes.isNotEmpty) {
              _scheduledTimes = rule.reminderTimes.map((t) {
                final p = t.split(':');
                return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
              }).toList();
            }
            if (rule.startDate != null) _startDate = rule.startDate!;
            if (rule.intervalDays != null && rule.intervalDays! > 0) {
              _repeatType = 'INTERVAL';
              _intervalDays = rule.intervalDays!;
            } else if (rule.monthDay != null && rule.monthDay! > 0) {
              _repeatType = 'INTERVAL';
              _intervalDays = 30;
            } else {
              _repeatType = 'WEEKDAYS';
              _selectedWeekdays = rule.weekdays.isNotEmpty
                  ? List<int>.from(rule.weekdays)
                  : [6, 7, 1, 2, 3, 4, 5];
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading schedule: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _nameController.addListener(_checkAllergy);
    }
  }

  void _checkAllergy() {
    final text = _nameController.text.trim().toLowerCase();
    if (!mounted) return;
    setState(() {
      if (text.isEmpty || _drugAllergens.isEmpty) {
        _matchedAllergen = null;
        return;
      }
      _matchedAllergen = null;
      for (final a in _drugAllergens) {
        final ca = a.toLowerCase().trim();
        if (text.contains(ca) || ca.contains(text)) {
          _matchedAllergen = a;
          break;
        }
      }
    });
  }

  void _onContinue() {
    final name = _nameController.text.trim();
    final dose = _doseController.text.trim();

    // Validate that dose is not empty AND contains at least one digit or a number (e.g., "۱ قرص", "500", "5cc")
    final hasNumber = RegExp(r'[0-9\u06F0-\u06F9]+').hasMatch(dose);

    setState(() {
      _nameHasError = name.isEmpty;
      _doseHasError = dose.isEmpty || !hasNumber;
      _stockHasError = _stockCount <= 0;
      _warningHasError = _warningThreshold < 0 || _warningThreshold >= _stockCount;
    });

    if (name.isEmpty || dose.isEmpty || !hasNumber || _stockCount <= 0 || _warningThreshold < 0 || _warningThreshold >= _stockCount) {
      return;
    }

    final formData = MedicationFormData(
      name: name,
      dose: dose,
      type: _type,
      scheduledTimes: List.from(_scheduledTimes),
      repeatType: _repeatType,
      selectedWeekdays: List.from(_selectedWeekdays),
      intervalDays: _intervalDays,
      startDate: _startDate,
      stockCount: _stockCount,
      warningThreshold: _warningThreshold,
      minInterval: _minInterval,
      maxDoses: _maxDoses,
      existingMedication: widget.medication,
    );

    Navigator.pop(context);
    widget.onFormCompleted(formData);
  }

  Widget _buildWeekdayChip(int isoDay, String label, RitmoColors colors, bool isDark) {
    final isSelected = _selectedWeekdays.contains(isoDay);
    return FilterChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
      selected: isSelected,
      onSelected: (v) => setState(() {
        if (v) {
          _selectedWeekdays.add(isoDay);
        } else if (_selectedWeekdays.length > 1) {
          _selectedWeekdays.remove(isoDay);
        }
      }),
      selectedColor: colors.primary.withValues(alpha: 0.15),
      checkmarkColor: colors.primary,
      labelStyle: TextStyle(
        color: isSelected ? colors.primary : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: colors.card.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.4)
            : colors.border.withValues(alpha: 0.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          expand: false,
          snap: true,
          builder: (ctx, scrollController) => RitmoTheme.glassCardLight(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colors.primary))
                : Container(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 40, height: 5,
                              decoration: BoxDecoration(
                                color: colors.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isEdit ? 'ویرایش اطلاعات دارو' : 'ثبت داروی جدید',
                            style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold,
                              color: colors.textPrimary, fontFamily: 'Vazirmatn',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Drug name
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'نام دارو',
                              labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                              errorText: _nameHasError ? 'وارد کردن نام دارو الزامی است' : null,
                              errorStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (val) {
                              if (_nameHasError && val.trim().isNotEmpty) {
                                setState(() => _nameHasError = false);
                              }
                            },
                          ),

                          // Allergy warning
                          if (_matchedAllergen != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.medicalRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.medicalRed),
                              ),
                              child: Row(children: [
                                Icon(Icons.warning, color: colors.medicalRed, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'هشدار: تداخل آلرژیک با «$_matchedAllergen»!',
                                    style: TextStyle(color: colors.medicalRed, fontSize: 12,
                                        fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                  ),
                                ),
                              ]),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Dose
                          TextFormField(
                            controller: _doseController,
                            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'دوز یا مقدار مصرف (مثلا: ۱ قرص، ۵ سی‌سی)',
                              labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                             errorText: _doseHasError ? 'مقدار دوز مصرفی باید شامل عدد باشد (مثلاً: ۱ قرص)' : null,
                              errorStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (val) {
                              final hasNumber = RegExp(r'[0-9\u06F0-\u06F9]+').hasMatch(val);
                              if (_doseHasError && val.trim().isNotEmpty && hasNumber) {
                                setState(() => _doseHasError = false);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Type
                          DropdownButtonFormField<String>(
                            initialValue: _type,
                            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'نوع برنامه مصرفی',
                              labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'FIXED', child: Text('منظم تکرارشونده (ثابت)')),
                              DropdownMenuItem(value: 'PRN', child: Text('در صورت نیاز (PRN)')),
                            ],
                            onChanged: (v) { if (v != null) setState(() => _type = v); },
                          ),
                          const SizedBox(height: 16),

                          if (_type == 'FIXED') ...[
                            Text('دوره تکرار مصرف:',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                    color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                            const SizedBox(height: 8),
                            // Repeat-type toggle
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E2235).withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(children: [
                                _toggleTab('روزهای هفته', 'WEEKDAYS', colors, isDark),
                                _toggleTab('هر چند روز', 'INTERVAL', colors, isDark),
                              ]),
                            ),

                            if (_repeatType == 'WEEKDAYS') ...[
                              const SizedBox(height: 12),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                _buildWeekdayChip(6, 'شنبه', colors, isDark),
                                _buildWeekdayChip(7, 'یکشنبه', colors, isDark),
                                _buildWeekdayChip(1, 'دوشنبه', colors, isDark),
                                _buildWeekdayChip(2, 'سه‌شنبه', colors, isDark),
                                _buildWeekdayChip(3, 'چهارشنبه', colors, isDark),
                                _buildWeekdayChip(4, 'پنج‌شنبه', colors, isDark),
                                _buildWeekdayChip(5, 'جمعه', colors, isDark),
                              ]),
                            ] else ...[
                              const SizedBox(height: 12),
                              Row(children: [
                                Text('هر ', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary)),
                                const SizedBox(width: 8),
                                DropdownButton<int>(
                                  value: _intervalDays,
                                  dropdownColor: colors.card,
                                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14,
                                      color: colors.textPrimary, fontWeight: FontWeight.bold),
                                  underline: const SizedBox(),
                                  items: List.generate(89, (i) => i + 2)
                                      .map((d) => DropdownMenuItem(value: d,
                                          child: Text('$d', style: const TextStyle(fontFamily: 'Vazirmatn'))))
                                      .toList(),
                                  onChanged: (v) { if (v != null) setState(() => _intervalDays = v); },
                                ),
                                const SizedBox(width: 8),
                                Text('روز یک‌بار', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary)),
                              ]),
                              const SizedBox(height: 12),
                              Row(children: [
                                Text('شروع از:', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary)),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () async {
                                    final picked = await RitmoDatePicker.show(
                                      context: context, initialDate: _startDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) setState(() => _startDate = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                                      borderRadius: BorderRadius.circular(8),
                                      color: isDark
                                          ? const Color(0xFF16192E).withValues(alpha: 0.4)
                                          : Colors.black.withValues(alpha: 0.02),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.calendar_month_rounded, size: 16, color: colors.primary),
                                      const SizedBox(width: 6),
                                      Builder(builder: (ctx) {
                                        final j = Jalali.fromDateTime(_startDate);
                                        return Text(
                                          '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}',
                                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13,
                                              color: colors.textPrimary, fontWeight: FontWeight.bold),
                                        );
                                      }),
                                    ]),
                                  ),
                                ),
                              ]),
                            ],

                            const SizedBox(height: 20),
                            Text('ساعات مصرف دارو:',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                    color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                            const SizedBox(height: 8),
                            ..._scheduledTimes.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final time = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final sel = await showTimePicker(context: context, initialTime: time);
                                        if (sel != null) setState(() => _scheduledTimes[idx] = sel);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: colors.border),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(time.format(context),
                                            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary)),
                                      ),
                                    ),
                                  ),
                                  if (_scheduledTimes.length > 1) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: colors.medicalRed),
                                      onPressed: () => setState(() => _scheduledTimes.removeAt(idx)),
                                    ),
                                  ],
                                ]),
                              );
                            }),
                            TextButton.icon(
                              onPressed: () => setState(() =>
                                  _scheduledTimes.add(const TimeOfDay(hour: 12, minute: 0))),
                              icon: const Icon(Icons.add),
                              label: const Text('افزودن ساعت مصرف', style: TextStyle(fontFamily: 'Vazirmatn')),
                            ),
                          ] else ...[
                            // PRN
                            Row(children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _minInterval,
                                  style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: 'حداقل فاصله مصرف (ساعت)',
                                    labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: [2, 4, 6, 8, 12, 24]
                                      .map((h) => DropdownMenuItem(value: h, child: Text('هر $h ساعت')))
                                      .toList(),
                                  onChanged: (v) { if (v != null) setState(() => _minInterval = v); },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _maxDoses,
                                  style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: 'سقف دوز در روز',
                                    labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: [1, 2, 3, 4, 6, 8, 10]
                                      .map((d) => DropdownMenuItem(value: d, child: Text('حداکثر $d بار')))
                                      .toList(),
                                  onChanged: (v) { if (v != null) setState(() => _maxDoses = v); },
                                ),
                              ),
                            ]),
                          ],

                          const SizedBox(height: 16),
                          // Stock
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _stockCount.toString(),
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'موجودی اولیه (تعداد دوز)',
                                  labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                                  errorText: _stockHasError ? 'باید بزرگتر از ۰ باشد' : null,
                                  errorStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onChanged: (v) {
                                  final val = int.tryParse(v) ?? 0;
                                  _stockCount = val;
                                  if (_stockHasError && val > 0) {
                                    setState(() => _stockHasError = false);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: _warningThreshold.toString(),
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'آستانه هشدار اتمام',
                                  labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                                  errorText: _warningHasError ? 'باید کمتر از موجودی باشد' : null,
                                  errorStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onChanged: (v) {
                                  final val = int.tryParse(v) ?? 0;
                                  _warningThreshold = val;
                                  if (_warningHasError && val >= 0 && val < _stockCount) {
                                    setState(() => _warningHasError = false);
                                  }
                                },
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),

                          // Continue button (no saving here)
                          ElevatedButton(
                            onPressed: _onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _isEdit ? 'ادامه و مشاهده پیش‌نمایش' : 'ادامه ←',
                              style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _toggleTab(String label, String value, RitmoColors colors, bool isDark) {
    final isActive = _repeatType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _repeatType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF2E334D) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn', fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? (isDark ? Colors.white : colors.primary) : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREVIEW CARD  — shared widget used in both the preview sheet & planner step 3
// ─────────────────────────────────────────────────────────────────────────────

class MedicationPreviewCard extends StatelessWidget {

  const MedicationPreviewCard({super.key, required this.data, this.onEdit});
  final MedicationFormData data;
  final VoidCallback? onEdit;

  String _weekdayName(int iso) {
    const names = {6: 'شنبه', 7: 'یکشنبه', 1: 'دوشنبه', 2: 'سه‌شنبه', 3: 'چهارشنبه', 4: 'پنج‌شنبه', 5: 'جمعه'};
    return names[iso] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String scheduleLabel;
    if (data.type == 'PRN') {
      scheduleLabel = 'در صورت نیاز (PRN) · فاصله حداقل ${data.minInterval} ساعت · سقف ${data.maxDoses} بار/روز';
    } else if (data.repeatType == 'WEEKDAYS') {
      final days = data.selectedWeekdays.map(_weekdayName).join('، ');
      final times = data.scheduledTimes.map((t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(' و ');
      scheduleLabel = '$days · ساعت $times';
    } else {
      final j = Jalali.fromDateTime(data.startDate);
      final dateStr = '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
      final times = data.scheduledTimes.map((t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(' و ');
      scheduleLabel = 'هر ${data.intervalDays} روز · از $dateStr · ساعت $times';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1D2E).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.primary.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.medication_rounded, color: colors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data.name,
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 17,
                          fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  if (data.dose.isNotEmpty)
                    Text(data.dose,
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary)),
                ]),
              ),
              if (onEdit != null) ...[
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_rounded, size: 18, color: colors.primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (data.type == 'PRN' ? colors.warning : colors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.type == 'PRN' ? 'PRN' : 'منظم',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.bold,
                    color: data.type == 'PRN' ? colors.warning : colors.primary,
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 16),
            Divider(color: colors.border.withValues(alpha: 0.3)),
            const SizedBox(height: 12),

            // Schedule row
            _infoRow(Icons.repeat_rounded, 'برنامه مصرف', scheduleLabel, colors),
            const SizedBox(height: 10),
            _infoRow(Icons.inventory_2_outlined, 'موجودی', '${data.stockCount} دوز (هشدار زیر ${data.warningThreshold})', colors),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, RitmoColors colors) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: colors.textSecondary.withValues(alpha: 0.7)),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5, color: colors.textSecondary)),
      Expanded(
        child: Text(value,
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5,
                fontWeight: FontWeight.bold, color: colors.textPrimary)),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREVIEW SHEET  — used by the health section (standalone flow)
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a preview of the collected medication data.
/// Tapping "ثبت دارو" / "ذخیره تغییرات" actually saves to the DB.
class MedicationPreviewSheet extends StatefulWidget {

  const MedicationPreviewSheet({super.key, required this.data, this.onSaved, this.onEdit});
  final MedicationFormData data;
  final VoidCallback? onSaved;
  final VoidCallback? onEdit;

  static Future<void> show(
    BuildContext context, {
    required MedicationFormData data,
    VoidCallback? onSaved,
    VoidCallback? onEdit,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MedicationPreviewSheet(data: data, onSaved: onSaved, onEdit: onEdit),
    );
  }

  @override
  State<MedicationPreviewSheet> createState() => _MedicationPreviewSheetState();
}

class _MedicationPreviewSheetState extends State<MedicationPreviewSheet> {
  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await MedicationSaveHelper.save(widget.data);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved?.call();
      }
    } catch (e) {
      debugPrint('MedicationPreviewSheet save error: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.85,
        minChildSize: 0.5,
        expand: false,
        snap: true,
        builder: (ctx, scrollController) => RitmoTheme.glassCardLight(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 5,
                    decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '👁️ پیش‌نمایش دارو',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'اطلاعات زیر را بررسی کنید. تا تأیید نکنید، ذخیره نمی‌شود.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                MedicationPreviewCard(data: widget.data),

                const SizedBox(height: 24),

                // Edit button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onEdit != null) {
                      widget.onEdit!();
                    }
                  },
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('ویرایش اطلاعات', style: TextStyle(fontFamily: 'Vazirmatn')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm save button
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.data.isEdit ? '✅ ذخیره تغییرات' : '✅ ثبت دارو',
                          style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
