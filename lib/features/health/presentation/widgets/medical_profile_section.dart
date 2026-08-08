import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalProfileSection extends StatefulWidget {
  const MedicalProfileSection({
    super.key,
  });

  @override
  State<MedicalProfileSection> createState() => _MedicalProfileSectionState();
}

class _MedicalProfileSectionState extends State<MedicalProfileSection> {
  final _formKey = GlobalKey<FormState>();

  final _illnessesController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _insuranceNameController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _insuranceSuppController = TextEditingController();

  Map<String, String> _profileData = {};
  bool _isLoading = true;
  bool _isEditing = false;

  String _bloodGroup = 'O_POS';
  bool _isOrganDonor = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _illnessesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _insuranceNameController.dispose();
    _insuranceNumberController.dispose();
    _insuranceSuppController.dispose();
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
      final results = await db.query('medical_profile');
      
      final data = <String, String>{};
      for (final row in results) {
        data[row['profileKey']! as String] = row['profileValue']! as String;
      }

      _profileData = data;
      _bloodGroup = data['blood_group'] ?? 'O_POS';
      _isOrganDonor = data['organ_donor'] == 'true';

      _illnessesController.text = data['illnesses'] ?? '';
      _emergencyNameController.text = data['emergency_contact_name'] ?? '';
      _emergencyPhoneController.text = _toPersianDigits(data['emergency_contact_phone'] ?? '');
      _insuranceNameController.text = data['insurance_name'] ?? '';
      _insuranceNumberController.text = _toPersianDigits(data['insurance_number'] ?? '');
      _insuranceSuppController.text = data['insurance_supplementary'] ?? '';

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading medical profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  String _getBloodGroupLabel(String key) {
    switch (key) {
      case 'A_POS': return 'A+';
      case 'A_NEG': return 'A-';
      case 'B_POS': return 'B+';
      case 'B_NEG': return 'B-';
      case 'AB_POS': return 'AB+';
      case 'AB_NEG': return 'AB-';
      case 'O_POS': return 'O+';
      case 'O_NEG': return 'O-';
      default: return 'نامشخص';
    }
  }

  Future<void> _callEmergency() async {
    final phone = _profileData['emergency_contact_phone'];
    if (phone == null || phone.trim().isEmpty) return;
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s+'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final cleanPhone = _normalizeDigits(_emergencyPhoneController.text.trim());
    final cleanInsNum = _normalizeDigits(_insuranceNumberController.text.trim());

    final dataToSave = <String, String>{
      'blood_group': _bloodGroup,
      'organ_donor': _isOrganDonor.toString(),
      'illnesses': _illnessesController.text.trim(),
      'emergency_contact_name': _emergencyNameController.text.trim(),
      'emergency_contact_phone': cleanPhone,
      'insurance_name': _insuranceNameController.text.trim(),
      'insurance_number': cleanInsNum,
      'insurance_supplementary': _insuranceSuppController.text.trim(),
    };

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        for (final entry in dataToSave.entries) {
          final key = entry.key;
          final val = entry.value;
          final id = 'mp_$key';
          await txn.insert(
            'medical_profile',
            {
              'id': id,
              'profileKey': key,
              'profileValue': val,
              'updatedAt': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      setState(() {
        _isEditing = false;
      });
      await _loadData();
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;



    if (_isLoading) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: colors.primary),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.medicalProfile,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (!_isEditing)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                  label: const Text('ویرایش پرونده', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing) _buildEditForm() else _buildInfoView(),
        ],
      ),
    );
  }

  Widget _buildInfoView() {
    final colors = context.colors;
    final bgLabel = _getBloodGroupLabel(_bloodGroup);
    final hasEmergencyContact = _profileData['emergency_contact_phone'] != null &&
        _profileData['emergency_contact_phone']!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Emergency Info Card
        Card(
          color: colors.medicalRed.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.medicalRed.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emergency_share, color: colors.medicalRed, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'کارت شناسایی اورژانس پزشکی',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colors.medicalRed,
                          ),
                        ),
                      ],
                    ),
                    if (hasEmergencyContact)
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: colors.medicalRed,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.phone, size: 20),
                        onPressed: _callEmergency,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCardRow('گروه خونی:', bgLabel, colors.textPrimary),
                const SizedBox(height: 6),
                _buildCardRow(
                  'بیماری‌های خاص / حساسیت مهم:',
                  _profileData['illnesses']?.isNotEmpty ?? false ? _profileData['illnesses']! : 'ندارد',
                  colors.textPrimary,
                ),
                const SizedBox(height: 6),
                _buildCardRow(
                  'مخاطب اضطراری:',
                  _profileData['emergency_contact_name']?.isNotEmpty ?? false
                      ? '${_profileData['emergency_contact_name']} (${_toPersianDigits(_profileData['emergency_contact_phone'] ?? "")})'
                      : 'ثبت نشده',
                  colors.textPrimary,
                ),
                const SizedBox(height: 6),
                _buildCardRow('اهداکننده عضو:', _isOrganDonor ? 'بله' : 'خیر', colors.textPrimary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Insurance Details Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: colors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'اطلاعات پوشش بیمه',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCardRow('بیمه پایه:', _profileData['insurance_name']?.isNotEmpty ?? false ? _profileData['insurance_name']! : 'ثبت نشده', colors.textPrimary),
                const SizedBox(height: 6),
                _buildCardRow('شماره بیمه:', _profileData['insurance_number']?.isNotEmpty ?? false ? _toPersianDigits(_profileData['insurance_number']!) : 'ثبت نشده', colors.textPrimary),
                const SizedBox(height: 6),
                _buildCardRow('بیمه تکمیلی:', _profileData['insurance_supplementary']?.isNotEmpty ?? false ? _profileData['insurance_supplementary']! : 'ثبت نشده', colors.textPrimary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardRow(String title, String value, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title ',
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    final colors = context.colors;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _bloodGroup,
            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            decoration: RitmoTheme.inputDecoration(context, label: 'گروه خونی', icon: Icons.water_drop_outlined),
            dropdownColor: colors.card,
            items: const [
              DropdownMenuItem(value: 'A_POS', child: Text('A+')),
              DropdownMenuItem(value: 'A_NEG', child: Text('A-')),
              DropdownMenuItem(value: 'B_POS', child: Text('B+')),
              DropdownMenuItem(value: 'B_NEG', child: Text('B-')),
              DropdownMenuItem(value: 'AB_POS', child: Text('AB+')),
              DropdownMenuItem(value: 'AB_NEG', child: Text('AB-')),
              DropdownMenuItem(value: 'O_POS', child: Text('O+')),
              DropdownMenuItem(value: 'O_NEG', child: Text('O-')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _bloodGroup = val;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _illnessesController,
            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            decoration: RitmoTheme.inputDecoration(context, label: 'بیماری‌های خاص / حساسیت مهم', icon: Icons.sick_outlined),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emergencyNameController,
            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            decoration: RitmoTheme.inputDecoration(context, label: 'نام مخاطب اضطراری', icon: Icons.contact_emergency),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            decoration: RitmoTheme.inputDecoration(context, label: 'تلفن مخاطب اضطراری', icon: Icons.phone),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _insuranceNameController,
            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            decoration: RitmoTheme.inputDecoration(context, label: 'نام بیمه پایه (مثلا: تامین اجتماعی)', icon: Icons.shield_outlined),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _insuranceNumberController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            decoration: RitmoTheme.inputDecoration(context, label: 'شماره بیمه', icon: Icons.pin),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _insuranceSuppController,
            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            decoration: RitmoTheme.inputDecoration(context, label: 'نام بیمه تکمیلی (اختیاری)', icon: Icons.add_moderator),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'کارت اهداکننده عضو هستم',
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
              ),
              Switch(
                value: _isOrganDonor,
                activeThumbColor: colors.primary,
                onChanged: (val) {
                  setState(() {
                    _isOrganDonor = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('انصراف', style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ذخیره تغییرات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
