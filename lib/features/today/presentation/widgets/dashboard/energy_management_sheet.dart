import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_sheet_scaffold.dart';

/// شیت مدیریت و ثبت سطح انرژی امروز
/// حل باگ pop قبل از ثبت پایگاه‌داده
class EnergyManagementSheet extends StatefulWidget {
  const EnergyManagementSheet({super.key});

  static Future<bool?> present(BuildContext context) {
    return RitmoSheetScaffold.present<bool>(
      context: context,
      semanticsLabel: 'فرم ثبت سطح انرژی امروز',
      builder: (ctx) => const EnergyManagementSheet(),
    );
  }

  @override
  State<EnergyManagementSheet> createState() => _EnergyManagementSheetState();
}

class _EnergyManagementSheetState extends State<EnergyManagementSheet> {
  int _selectedPercent = 65;
  String _selectedLevel = 'MEDIUM';
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T').first;

      await db.insert('energy_logs', {
        'id': 'energy_${now.millisecondsSinceEpoch}',
        'dateStr': todayStr,
        'timestamp': now.millisecondsSinceEpoch,
        'energyPercent': _selectedPercent,
        'energyLevel': _selectedLevel,
        'note': _noteController.text.trim(),
        'createdAt': now.millisecondsSinceEpoch,
      });

      if (!mounted) return;

      RitmoToast.show(context, 'سطح انرژی با موفقیت ثبت شد');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'ثبت سطح انرژی انجام نشد. دوباره تلاش کنید.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(RitmoSpacing.md),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(RitmoRadius.card),
              border: Border.all(color: colors.warning),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: colors.warningText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: RitmoSpacing.md),
        ],

        // انتخاب سطح انرژی با ۳ حالت استاندارد
        Row(
          children: [
            _EnergyLevelChip(
              label: 'پایین',
              icon: Icons.battery_1_bar_rounded,
              isSelected: _selectedLevel == 'LOW',
              onTap: () {
                RitmoHaptics.tap();
                setState(() {
                  _selectedLevel = 'LOW';
                  _selectedPercent = 35;
                });
              },
            ),
            const SizedBox(width: RitmoSpacing.sm),
            _EnergyLevelChip(
              label: 'متوسط',
              icon: Icons.battery_4_bar_rounded,
              isSelected: _selectedLevel == 'MEDIUM',
              onTap: () {
                RitmoHaptics.tap();
                setState(() {
                  _selectedLevel = 'MEDIUM';
                  _selectedPercent = 65;
                });
              },
            ),
            const SizedBox(width: RitmoSpacing.sm),
            _EnergyLevelChip(
              label: 'بالا',
              icon: Icons.battery_full_rounded,
              isSelected: _selectedLevel == 'HIGH',
              onTap: () {
                RitmoHaptics.tap();
                setState(() {
                  _selectedLevel = 'HIGH';
                  _selectedPercent = 90;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: RitmoSpacing.lg),

        // درصد انرژی
        Text(
          'درصد تخمینی: ${toPersianDigits(_selectedPercent.toString())}٪',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        Slider(
          value: _selectedPercent.toDouble(),
          min: 10,
          max: 100,
          divisions: 18,
          activeColor: colors.primary,
          onChanged: (val) {
            setState(() {
              _selectedPercent = val.toInt();
            });
          },
        ),
        const SizedBox(height: RitmoSpacing.md),

        // فیلد یادداشت
        TextField(
          controller: _noteController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'توضیح کوتاه درباره‌ی حالت جسمی یا روحی (اختیاری)',
            hintStyle: TextStyle(fontSize: 13, color: colors.textSecondary),
            filled: true,
            fillColor: colors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RitmoRadius.card),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
        const SizedBox(height: RitmoSpacing.xl),

        // دکمه ذخیره
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RitmoRadius.card),
              ),
            ),
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'ذخیره سطح انرژی',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

class _EnergyLevelChip extends StatelessWidget {
  const _EnergyLevelChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'سطح انرژی $label',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RitmoRadius.chip),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.18)
                  : colors.card,
              borderRadius: BorderRadius.circular(RitmoRadius.chip),
              border: Border.all(
                color: isSelected ? colors.primary : colors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? colors.primary : colors.iconSecondary,
                ),
                const SizedBox(width: RitmoSpacing.xs),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? colors.primary : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
