import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqflite/sqflite.dart';

class VitalSignsSection extends StatefulWidget {
  const VitalSignsSection({
    super.key,
  });

  @override
  State<VitalSignsSection> createState() => _VitalSignsSectionState();
}

class _VitalSignsSectionState extends State<VitalSignsSection> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _heightController = TextEditingController();
  final _noteController = TextEditingController();

  late TabController _tabController;
  List<VitalSignLog> _logs = [];
  double? _height; // in cm
  bool _isLoading = true;
  String _vitalType = 'WEIGHT'; // 'WEIGHT' | 'TEMPERATURE' | 'SPO2' | 'WAIST'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valueController.dispose();
    _heightController.dispose();
    _noteController.dispose();
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

  String _normalizeDigits(String input) {
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '٧', '۸', '۹'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], english[i]).replaceAll(arabic[i], english[i]);
    }
    return result;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Load height from medical_profile
      final profileResult = await db.query(
        'medical_profile',
        where: "profileKey = 'height'",
      );
      if (profileResult.isNotEmpty) {
        final heightStr = profileResult.first['profileValue']! as String;
        _height = double.tryParse(heightStr);
        _heightController.text = _height != null ? _toPersianDigits(_height!.toStringAsFixed(0)) : '';
      }

      // 2. Load vitals logs
      final results = await db.query('vital_signs_logs', orderBy: 'loggedAt DESC');
      final logsList = results.map(VitalSignLog.fromMap).toList();

      if (mounted) {
        setState(() {
          _logs = logsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading vital signs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _saveHeight(String val) async {
    final cleanVal = _normalizeDigits(val.trim());
    final parsedHeight = double.tryParse(cleanVal);
    if (parsedHeight == null || parsedHeight <= 0) return;

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'medical_profile',
        {
          'id': 'mp_height',
          'profileKey': 'height',
          'profileValue': parsedHeight.toString(),
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      setState(() {
        _height = parsedHeight;
      });
      await _loadData();
    } catch (e) {
      debugPrint('Error saving height: $e');
    }
  }

  String _getUnit(String type) {
    switch (type) {
      case 'WEIGHT':
        return 'کیلوگرم';
      case 'TEMPERATURE':
        return 'درجه سانتی‌گراد';
      case 'SPO2':
        return 'درصد';
      case 'WAIST':
      default:
        return 'سانتی‌متر';
    }
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    final normValStr = _normalizeDigits(_valueController.text.trim());
    final value = double.tryParse(normValStr);
    if (value == null) return;

    // Save height if changed
    if (_heightController.text.trim().isNotEmpty) {
      await _saveHeight(_heightController.text.trim());
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final log = VitalSignLog(
      id: 'vs_${_vitalType}_$now',
      vitalType: _vitalType,
      value: value,
      unit: _getUnit(_vitalType),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      loggedAt: now,
    );

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('vital_signs_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      _valueController.clear();
      _noteController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      
      await _loadData();
    } catch (e) {
      debugPrint('Error saving vital log: $e');
    }
  }

  Future<void> _deleteLog(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('vital_signs_logs', where: 'id = ?', whereArgs: [id]);
      await _loadData();
    } catch (e) {
      debugPrint('Error deleting vital log: $e');
    }
  }

  Map<String, dynamic>? _calculateBmi() {
    final weightLogs = _logs.where((l) => l.vitalType == 'WEIGHT').toList();
    if (weightLogs.isEmpty || _height == null || _height == 0) return null;

    final weight = weightLogs.first.value;
    final heightInMeters = _height! / 100.0;
    final bmi = weight / (heightInMeters * heightInMeters);

    final l10n = AppLocalizations.of(context)!;
    var label = '';
    Color color = Colors.green;

    if (bmi < 18.5) {
      label = l10n.vitalSignsBmiUnderweight;
      color = context.colors.warning;
    } else if (bmi < 25.0) {
      label = l10n.vitalSignsBmiNormal;
      color = context.colors.success;
    } else if (bmi < 30.0) {
      label = l10n.vitalSignsBmiOverweight;
      color = context.colors.warning;
    } else {
      label = l10n.vitalSignsBmiObese;
      color = context.colors.medicalRed; // Medical warning for obesity
    }

    return {'value': bmi, 'label': label, 'color': color};
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;



    final bmiInfo = _calculateBmi();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.vitalSignsTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // BMI Display Card
            if (bmiInfo != null) ...[
              Card(
                color: (bmiInfo['color'] as Color).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: (bmiInfo['color'] as Color).withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined, color: bmiInfo['color'] as Color, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.vitalSignsBmi(
                                _toPersianDigits((bmiInfo['value'] as double).toStringAsFixed(1)),
                                bmiInfo['label'] as String,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'قد: ${_toPersianDigits(_height!.toStringAsFixed(0))} سانتی‌متر',
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Fast Add Log Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: l10n.vitalSignsHeight,
                              icon: Icons.height,
                            ),
                            onFieldSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                _saveHeight(val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _vitalType,
                            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Vazirmatn'),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: 'نوع شاخص',
                              icon: Icons.category,
                            ),
                            dropdownColor: colors.card,
                            items: [
                              DropdownMenuItem(value: 'WEIGHT', child: Text(l10n.vitalSignsWeight)),
                              DropdownMenuItem(value: 'TEMPERATURE', child: Text(l10n.vitalSignsTemperature)),
                              DropdownMenuItem(value: 'SPO2', child: Text(l10n.vitalSignsSpo2)),
                              DropdownMenuItem(value: 'WAIST', child: Text(l10n.vitalSignsWaist)),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _vitalType = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _valueController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: '${l10n.vitalSignsValue} (${_getUnit(_vitalType)})',
                              icon: Icons.speed,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'لطفاً مقدار را وارد کنید';
                              }
                              if (double.tryParse(_normalizeDigits(val.trim())) == null) {
                                return 'عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      decoration: RitmoTheme.inputDecoration(
                        context,
                        label: 'یادداشت (اختیاری)',
                        icon: Icons.note_alt_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saveLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        l10n.vitalSignsSave,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.vitalSignsHistory,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              indicatorColor: colors.primary,
              labelColor: colors.textPrimary,
              unselectedLabelColor: colors.textSecondary,
              tabs: [
                Tab(text: l10n.vitalSignsWeight),
                const Tab(text: 'دما'),
                const Tab(text: 'اکسیژن'),
                const Tab(text: 'دور کمر'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: colors.primary))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildHistoryList('WEIGHT'),
                        _buildHistoryList('TEMPERATURE'),
                        _buildHistoryList('SPO2'),
                        _buildHistoryList('WAIST'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(String type) {
    final colors = context.colors;
    final typeLogs = _logs.where((l) => l.vitalType == type).toList();

    if (typeLogs.isEmpty) {
      return Center(
        child: Text(
          'سابقه سنجشی ثبت نشده است.',
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: typeLogs.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final log = typeLogs[index];
        final jalali = Jalali.fromDateTime(DateTime.fromMillisecondsSinceEpoch(log.loggedAt));
        final dateStr = _toPersianDigits('${jalali.year}/${jalali.month}/${jalali.day}');
        final timeStr = _toPersianDigits('${DateTime.fromMillisecondsSinceEpoch(log.loggedAt).hour.toString().padLeft(2, '0')}:${DateTime.fromMillisecondsSinceEpoch(log.loggedAt).minute.toString().padLeft(2, '0')}');

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              _toPersianDigits('${log.value} ${log.unit}'),
              style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dateStr ساعت $timeStr',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
                if (log.note != null && log.note!.isNotEmpty)
                  Text(
                    log.note!,
                    style: TextStyle(fontSize: 11, color: colors.textPrimary, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: colors.medicalRed),
              onPressed: () => _confirmDelete(log.id),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(String id) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: colors.card,
          title: const Text('حذف سنجش', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
          content: const Text('آیا مطمئن هستید که می‌خواهید این سنجش علامت حیاتی را حذف کنید؟', style: TextStyle(fontFamily: 'Vazirmatn')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteLog(id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: colors.medicalRed),
              child: const Text('حذف', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn')),
            ),
          ],
        ),
      ),
    );
  }
}
