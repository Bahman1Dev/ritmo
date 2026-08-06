// lib/features/supplementary_sports/presentation/widgets/ss_recovery_card.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_profile_repository.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class SSRecoveryCard extends StatefulWidget {
  const SSRecoveryCard({
    super.key,
    required this.isLoggedToday,
    required this.soreness,
    required this.fatigue,
    required this.hydration,
    this.onLogged,
  });

  final bool isLoggedToday;
  final int soreness;
  final int fatigue;
  final int hydration;
  final VoidCallback? onLogged;

  @override
  State<SSRecoveryCard> createState() => _SSRecoveryCardState();
}

class _SSRecoveryCardState extends State<SSRecoveryCard> {
  late int _soreness;
  late int _fatigue;
  late int _hydration;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _soreness = widget.soreness;
    _fatigue = widget.fatigue;
    _hydration = widget.hydration;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    RitmoHaptics.tap();
    await SSProfileRepository.instance.saveRecovery(
      soreness: _soreness,
      fatigue: _fatigue,
      hydration: _hydration,
    );
    RitmoHaptics.success();
    if (mounted) setState(() => _isSaving = false);
    widget.onLogged?.call();
  }

  Widget _buildLevelSelector(String title, int current, ValueChanged<int> onChanged) {
    const theme = SupplementarySportsTheme.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: theme.textSecondary)),
        const SizedBox(height: 6),
        Row(
          children: List.generate(3, (idx) {
            final val = idx + 1;
            final isSelected = current == val;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  RitmoHaptics.selection();
                  onChanged(val);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.emeraldPrimary : theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? theme.emeraldPrimary : theme.cardBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      val == 1 ? 'سبک' : (val == 2 ? 'متوسط' : 'شدید'),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : theme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const theme = SupplementarySportsTheme.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'ارزیابی آمادگی و ریکاوری',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15, color: theme.textPrimary),
                ),
                const Spacer(),
                if (widget.isLoggedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.emeraldPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('ثبت‌شده امروز ✅', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: theme.emeraldPrimary)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _buildLevelSelector('میزان کوفتگی عضلانی (Soreness)', _soreness, (v) => setState(() => _soreness = v)),
            const SizedBox(height: 10),
            _buildLevelSelector('میزان خستگی عمومی (Fatigue)', _fatigue, (v) => setState(() => _fatigue = v)),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.emeraldPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'ثبت وضعیت ریکاوری 🌿',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
