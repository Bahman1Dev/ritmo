import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

class AllergiesSection extends StatefulWidget {
  const AllergiesSection({
    super.key,
  });

  @override
  State<AllergiesSection> createState() => _AllergiesSectionState();
}

class _AllergiesSectionState extends State<AllergiesSection> {
  List<Allergy> _allergies = [];
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
      final results = await db.query('allergies', orderBy: 'createdAt DESC');
      final list = results.map(Allergy.fromMap).toList();

      if (mounted) {
        setState(() {
          _allergies = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading allergies: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _saveAllergy(Allergy allergy) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'allergies',
        allergy.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _loadData();
    } catch (e) {
      debugPrint('Error saving allergy: $e');
    }
  }

  Future<void> _deleteAllergy(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('allergies', where: 'id = ?', whereArgs: [id]);
      _loadData();
    } catch (e) {
      debugPrint('Error deleting allergy: $e');
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: RitmoTheme.glassCardLight(
          child: _AllergyForm(
            onSave: (saved) {
              _saveAllergy(saved);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String cat) {
    final l10n = AppLocalizations.of(context)!;
    switch (cat) {
      case 'FOOD':
        return l10n.allergyCategoryFood;
      case 'DRUG':
        return l10n.allergyCategoryDrug;
      case 'ENVIRONMENT':
        return l10n.allergyCategoryEnvironment;
      case 'OTHER':
      default:
        return l10n.allergyCategoryOther;
    }
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
                l10n.allergies,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddSheet,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: Text(l10n.allergySave, style: const TextStyle(color: Colors.white, fontSize: 13)),
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

    if (_allergies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.allergyNoAllergies,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allergies.length,
      itemBuilder: (context, index) {
        final allergy = _allergies[index];

        // Map severity label to colors
        var sColor = colors.success;
        if (allergy.severity == 'SEVERE' || allergy.severity == 'LIFE_THREATENING') {
          sColor = colors.medicalRed; // Medical safety alert -> red permitted
        } else if (allergy.severity == 'MODERATE') {
          sColor = colors.warning;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: sColor.withValues(alpha: 0.1),
              child: Icon(Icons.warning_amber_rounded, color: sColor),
            ),
            title: Row(
              children: [
                Text(
                  allergy.allergen,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    allergy.severityLabel,
                    style: TextStyle(fontSize: 10, color: sColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دسته‌بندی: ${_getCategoryLabel(allergy.category)}',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
                if (allergy.reaction != null && allergy.reaction!.isNotEmpty)
                  Text(
                    'علائم: ${allergy.reaction}',
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  ),
                if (allergy.diagnosedDate != null)
                  Text(
                    'تاریخ تشخیص: ${_formatJalaliDate(allergy.diagnosedDate!)}',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                if (allergy.notes != null && allergy.notes!.isNotEmpty)
                  Text(
                    allergy.notes!,
                    style: TextStyle(fontSize: 11, color: colors.textPrimary, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: colors.medicalRed),
              onPressed: () => _confirmDelete(allergy.id),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(String id) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: colors.card,
          title: const Text('حذف آلرژی', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
          content: Text(
            l10n.allergyDeleteConfirm,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteAllergy(id);
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

class _AllergyForm extends StatefulWidget {

  const _AllergyForm({required this.onSave});
  final Function(Allergy) onSave;

  @override
  State<_AllergyForm> createState() => _AllergyFormState();
}

class _AllergyFormState extends State<_AllergyForm> {
  final _formKey = GlobalKey<FormState>();

  final _allergenController = TextEditingController();
  final _reactionController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'DRUG'; // Default to drug
  String _severity = 'MODERATE';
  DateTime? _diagnosedDate;

  @override
  void dispose() {
    _allergenController.dispose();
    _reactionController.dispose();
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

  Future<void> _pickDate() async {
    final picked = await RitmoDatePicker.showJalali(
      context: context,
      initialDate: Jalali.fromDateTime(_diagnosedDate ?? DateTime.now()),
      firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 365 * 30))),
      lastDate: Jalali.fromDateTime(DateTime.now()),
    );

    if (picked != null) {
      setState(() {
        _diagnosedDate = picked.toDateTime();
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final allergy = Allergy(
      id: 'allergy_${DateTime.now().millisecondsSinceEpoch}',
      allergen: _allergenController.text.trim(),
      category: _category,
      reaction: _reactionController.text.trim().isEmpty ? null : _reactionController.text.trim(),
      severity: _severity,
      diagnosedDate: _diagnosedDate?.millisecondsSinceEpoch,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: now,
    );

    widget.onSave(allergy);
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
                l10n.allergySave,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _allergenController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.allergyName, icon: Icons.warning_amber_rounded),
                validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً نام آلرژن را وارد کنید' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.allergyCategory, icon: Icons.category),
                dropdownColor: colors.card,
                items: [
                  DropdownMenuItem(value: 'FOOD', child: Text(l10n.allergyCategoryFood)),
                  DropdownMenuItem(value: 'DRUG', child: Text(l10n.allergyCategoryDrug)),
                  DropdownMenuItem(value: 'ENVIRONMENT', child: Text(l10n.allergyCategoryEnvironment)),
                  DropdownMenuItem(value: 'OTHER', child: Text(l10n.allergyCategoryOther)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _severity,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.allergySeverity, icon: Icons.warning_sharp),
                dropdownColor: colors.card,
                items: [
                  DropdownMenuItem(value: 'MILD', child: Text(l10n.allergySeverityMild)),
                  DropdownMenuItem(value: 'MODERATE', child: Text(l10n.allergySeverityModerate)),
                  DropdownMenuItem(value: 'SEVERE', child: Text(l10n.allergySeveritySevere)),
                  DropdownMenuItem(value: 'LIFE_THREATENING', child: Text(l10n.allergySeverityLifeThreatening)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _severity = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reactionController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.allergyReaction, icon: Icons.details),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: Icon(Icons.calendar_today, color: colors.primary, size: 18),
                label: Text(
                  _diagnosedDate != null
                      ? _toPersianDigits('${Jalali.fromDateTime(_diagnosedDate!).year}/${Jalali.fromDateTime(_diagnosedDate!).month}/${Jalali.fromDateTime(_diagnosedDate!).day}')
                      : l10n.allergyDiagnosedDate,
                  style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: 'توضیحات / یادداشت', icon: Icons.notes),
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
                  'ثبت آلرژی',
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
