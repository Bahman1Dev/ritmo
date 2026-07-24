// lib/features/routines/presentation/forms/sports_step2_form.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_day_of_week_selector.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_duration_picker.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_timeline_picker.dart';
import 'package:ritmo/features/supplementary_sports/movement/data/movement_repository.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_kind.dart';

class SportsStep2Form extends StatefulWidget {
  const SportsStep2Form({super.key, required this.controller});
  final PlannerController controller;

  @override
  State<SportsStep2Form> createState() => _SportsStep2FormState();
}

class _SportsStep2FormState extends State<SportsStep2Form> {
  List<MovementKind> _availableKinds = [];
  bool _isLoadingKinds = true;

  @override
  void initState() {
    super.initState();
    _loadKinds();
  }

  Future<void> _loadKinds() async {
    final kinds = await MovementRepository.instance.getKinds();
    if (mounted) {
      setState(() {
        _availableKinds = kinds;
        _isLoadingKinds = false;
      });
    }
  }

  Widget _buildOpChip(String code, String label, IconData icon) {
    final colors = context.colors;
    final isSelected = widget.controller.sportsOpType == code;
    return Expanded(
      child: ChoiceChip(
        avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : colors.onSurface),
        label: Text(label, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: isSelected ? Colors.white : colors.onSurface)),
        selected: isSelected,
        selectedColor: colors.primary,
        onSelected: (_) {
          widget.controller.sportsOpType = code;
          widget.controller.notifyListeners();
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final c = widget.controller;

    // Calculate weekly load preview (MET-min)
    final daysCount = c.recurrenceType == 'EVERY_DAY' ? 7 : (c.recurrenceType == 'CUSTOM_DAYS' ? (c.worshipSelectedDays.length) : 3);
    final duration = c.sportsDuration > 0 ? c.sportsDuration : 30;
    final estWeeklyMetMins = daysCount * duration * 4.0; // ~4.0 average MET

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'نوع عملیات ورزشی',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildOpChip('ROUTINE', 'برنامه‌ریزی روتین (تکرارشونده)', Icons.calendar_month_rounded),
              const SizedBox(width: 8),
              _buildOpChip('LOG', 'ثبت فوری فعالیت (لاگ تمرین)', Icons.history_rounded),
            ],
          ),
          const SizedBox(height: 20),

          // Kind Selector from MovementRepository
          const Text(
            'انتخاب نوع ورزش',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          _isLoadingKinds
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableKinds.take(12).map((k) {
                    final isSelected = c.sportsType == k.code;
                    return ChoiceChip(
                      label: Text('${k.emoji} ${k.titleFa}', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: isSelected ? Colors.white : colors.onSurface)),
                      selected: isSelected,
                      selectedColor: colors.primary,
                      onSelected: (_) {
                        c.sportsType = k.code;
                        c.notifyListeners();
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
          const SizedBox(height: 16),

          if (c.sportsOpType == 'LOG') ...[
            Text(
              'می‌خواهید برای همین الان یک لاگ فعالیت حرکتی ثبت کنید.',
              style: TextStyle(fontFamily: 'Vazirmatn', color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ] else ...[
            PlannerTimelinePicker(controller: c),
            const SizedBox(height: 20),
            PlannerDurationPicker(controller: c),
            const SizedBox(height: 16),
            const Text('روزهای تمرین در هفته:', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            PlannerDayOfWeekSelector(
              selectedDays: c.worshipSelectedDays,
              onChanged: (list) {
                c.worshipSelectedDays = list;
                c.notifyListeners();
                setState(() {});
              },
            ),
            const SizedBox(height: 16),

            // Weekly Load Preview Box (T17 requirement)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insights_rounded, color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'پیش‌نمایش بار هفتگی: ${daysCount.toPersianDigits()} روز × ${duration.toPersianDigits()} دقیقه ≈ ${estWeeklyMetMins.round().toPersianDigits()} MET-min در هفته ⚡',
                      style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
