import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

class VaccinationsSection extends StatefulWidget {
  const VaccinationsSection({
    super.key,
  });

  @override
  State<VaccinationsSection> createState() => _VaccinationsSectionState();
}

class _VaccinationsSectionState extends State<VaccinationsSection> {
  List<Vaccination> _vaccinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  String _formatJalaliDate(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final j = Jalali.fromDateTime(dt);
    return _toPersianDigits('${j.year}/${j.month}/${j.day}');
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query('vaccinations', orderBy: 'dateAdministered DESC');
      final list = results.map(Vaccination.fromMap).toList();

      if (mounted) {
        setState(() {
          _vaccinations = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading vaccinations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _saveVaccination(Vaccination vac) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'vaccinations',
        vac.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _loadData();
    } catch (e) {
      debugPrint('Error saving vaccination: $e');
    }
  }

  Future<void> _deleteVaccination(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('vaccinations', where: 'id = ?', whereArgs: [id]);
      _loadData();
    } catch (e) {
      debugPrint('Error deleting vaccination: $e');
    }
  }

  void _showAddEditSheet({Vaccination? vac}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: RitmoTheme.glassCardLight(
          child: _VaccinationForm(
            vaccination: vac,
            onSave: (saved) {
              _saveVaccination(saved);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;



    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.vaccinations,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddEditSheet,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: Text(l10n.vaccineSave, style: const TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading) Center(child: CircularProgressIndicator(color: colors.primary)) else _buildList(),
        ],
      ),
    );
  }

  Widget _buildList() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (_vaccinations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.vaccineNoDoses,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _vaccinations.length,
      itemBuilder: (context, index) {
        final vac = _vaccinations[index];
        final days = vac.daysUntilNextDose;

        Widget dueWidget = const SizedBox.shrink();
        if (vac.nextDoseDue != null) {
          if (days != null) {
            if (days < 0) {
              dueWidget = Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.vaccineOverdue(days.abs()),
                  style: TextStyle(color: colors.medicalRed, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );
            } else {
              dueWidget = Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.vaccineDaysUntilDue(days),
                  style: TextStyle(color: colors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );
            }
          }
        }

        final doseStr = vac.totalDoses != null
            ? _toPersianDigits('دوز ${vac.doseNumber} از ${vac.totalDoses}')
            : _toPersianDigits('دوز ${vac.doseNumber}');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vac.vaccineName,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                          ),
                          if (vac.diseaseTarget != null && vac.diseaseTarget!.isNotEmpty)
                            Text(
                              'بیماری هدف: ${vac.diseaseTarget}',
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doseStr,
                        style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                if (vac.dateAdministered != null)
                  Row(
                    children: [
                      Icon(Icons.event_available, size: 14, color: colors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'تاریخ تزریق: ${_formatJalaliDate(vac.dateAdministered!)}',
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                    ],
                  ),
                if (vac.nextDoseDue != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event, size: 14, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'سررسید دوز بعدی: ${_formatJalaliDate(vac.nextDoseDue!)}',
                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                      ),
                    ],
                  ),
                  dueWidget,
                ],
                if (vac.clinicName != null && vac.clinicName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.business, size: 14, color: colors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'محل تزریق: ${vac.clinicName}',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
                if (vac.batchNumber != null && vac.batchNumber!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'شماره بچ (Batch): ${_toPersianDigits(vac.batchNumber!)}',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
                if (vac.notes != null && vac.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    vac.notes!,
                    style: TextStyle(fontSize: 12, color: colors.textPrimary, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 18, color: colors.primary),
                      onPressed: () => _showAddEditSheet(vac: vac),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: colors.medicalRed),
                      onPressed: () => _confirmDelete(vac.id),
                    ),
                  ],
                ),
              ],
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
          title: const Text('حذف واکسن', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
          content: const Text('آیا مطمئن هستید که می‌خواهید اطلاعات این واکسیناسیون را حذف کنید؟', style: TextStyle(fontFamily: 'Vazirmatn')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteVaccination(id);
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

class _VaccinationForm extends StatefulWidget {

  const _VaccinationForm({this.vaccination, required this.onSave});
  final Vaccination? vaccination;
  final Function(Vaccination) onSave;

  @override
  State<_VaccinationForm> createState() => _VaccinationFormState();
}

class _VaccinationFormState extends State<_VaccinationForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _diseaseController;
  late TextEditingController _doseController;
  late TextEditingController _totalDosesController;
  late TextEditingController _batchController;
  late TextEditingController _clinicController;
  late TextEditingController _notesController;

  DateTime? _dateAdministered;
  DateTime? _nextDoseDue;

  @override
  void initState() {
    super.initState();
    final v = widget.vaccination;
    _nameController = TextEditingController(text: v?.vaccineName ?? '');
    _diseaseController = TextEditingController(text: v?.diseaseTarget ?? '');
    _doseController = TextEditingController(text: v?.doseNumber.toString() ?? '1');
    _totalDosesController = TextEditingController(text: v?.totalDoses?.toString() ?? '');
    _batchController = TextEditingController(text: v?.batchNumber ?? '');
    _clinicController = TextEditingController(text: v?.clinicName ?? '');
    _notesController = TextEditingController(text: v?.notes ?? '');

    if (v != null) {
      if (v.dateAdministered != null) _dateAdministered = DateTime.fromMillisecondsSinceEpoch(v.dateAdministered!);
      if (v.nextDoseDue != null) _nextDoseDue = DateTime.fromMillisecondsSinceEpoch(v.nextDoseDue!);
    } else {
      _dateAdministered = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _diseaseController.dispose();
    _doseController.dispose();
    _totalDosesController.dispose();
    _batchController.dispose();
    _clinicController.dispose();
    _notesController.dispose();
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

  Future<void> _pickDate({required bool isAdministered}) async {
    final initial = isAdministered ? (_dateAdministered ?? DateTime.now()) : (_nextDoseDue ?? DateTime.now());
    final picked = await RitmoDatePicker.showJalali(
      context: context,
      initialDate: Jalali.fromDateTime(initial),
      firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 365 * 10))),
      lastDate: Jalali.fromDateTime(DateTime.now().add(const Duration(days: 365 * 5))),
    );

    if (picked != null) {
      setState(() {
        if (isAdministered) {
          _dateAdministered = picked.toDateTime();
        } else {
          _nextDoseDue = picked.toDateTime();
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final normDose = _normalizeDigits(_doseController.text.trim());
    final normTotal = _normalizeDigits(_totalDosesController.text.trim());

    final dose = int.tryParse(normDose) ?? 1;
    final total = normTotal.isNotEmpty ? int.tryParse(normTotal) : null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final vac = Vaccination(
      id: widget.vaccination?.id ?? 'vac_${DateTime.now().millisecondsSinceEpoch}',
      vaccineName: _nameController.text.trim(),
      diseaseTarget: _diseaseController.text.trim().isEmpty ? null : _diseaseController.text.trim(),
      doseNumber: dose,
      totalDoses: total,
      dateAdministered: _dateAdministered?.millisecondsSinceEpoch,
      nextDoseDue: _nextDoseDue?.millisecondsSinceEpoch,
      batchNumber: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
      clinicName: _clinicController.text.trim().isEmpty ? null : _clinicController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.vaccination?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(vac);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: mediaQuery.viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.vaccination == null ? 'ثبت واکسیناسیون جدید' : 'ویرایش واکسیناسیون',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.vaccineName, icon: Icons.vaccines),
                validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً نام واکسن را وارد کنید' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diseaseController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.vaccineDiseaseTarget, icon: Icons.bug_report),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _doseController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      decoration: RitmoTheme.inputDecoration(context, label: l10n.vaccineDoseNumber, icon: Icons.pin),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'اجباری';
                        if (int.tryParse(_normalizeDigits(val.trim())) == null) return 'نامعتبر';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _totalDosesController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      decoration: RitmoTheme.inputDecoration(context, label: l10n.vaccineTotalDoses, icon: Icons.summarize),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isAdministered: true),
                      icon: Icon(Icons.event_available, color: colors.primary, size: 18),
                      label: Text(
                        _dateAdministered != null
                            ? _toPersianDigits('${Jalali.fromDateTime(_dateAdministered!).year}/${Jalali.fromDateTime(_dateAdministered!).month}/${Jalali.fromDateTime(_dateAdministered!).day}')
                            : 'تاریخ تزریق',
                        style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isAdministered: false),
                      icon: Icon(Icons.event, color: colors.primary, size: 18),
                      label: Text(
                        _nextDoseDue != null
                            ? _toPersianDigits('${Jalali.fromDateTime(_nextDoseDue!).year}/${Jalali.fromDateTime(_nextDoseDue!).month}/${Jalali.fromDateTime(_nextDoseDue!).day}')
                            : 'سررسید دوز بعدی',
                        style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clinicController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.vaccineClinicName, icon: Icons.business),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _batchController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.vaccineBatchNumber, icon: Icons.qr_code),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.vaccineNotes, icon: Icons.notes),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'ذخیره واکسن',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
