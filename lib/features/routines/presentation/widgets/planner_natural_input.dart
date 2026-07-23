// lib/features/routines/presentation/widgets/planner_natural_input.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';
import 'package:shamsi_date/shamsi_date.dart';

class PlannerNaturalInput extends StatefulWidget {

  const PlannerNaturalInput({super.key, required this.controller});
  final PlannerController controller;

  @override
  State<PlannerNaturalInput> createState() => _PlannerNaturalInputState();
}

class _PlannerNaturalInputState extends State<PlannerNaturalInput> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _getTimeDateChipLabel() {
    final date = widget.controller.selectedDate;
    final time = widget.controller.selectedTime;
    final now = DateTime.now();
    
    var dateStr = '';
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      dateStr = 'امروز';
    } else if (date.day == now.add(const Duration(days: 1)).day && date.month == now.add(const Duration(days: 1)).month && date.year == now.add(const Duration(days: 1)).year) {
      dateStr = 'فردا';
    } else if (date.day == now.add(const Duration(days: 2)).day && date.month == now.add(const Duration(days: 2)).month && date.year == now.add(const Duration(days: 2)).year) {
      dateStr = 'پس‌فردا';
    } else {
      final jd = Jalali.fromDateTime(date);
      dateStr = '${jd.day} ${jd.formatter.mN}';
    }
    
    final hour = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '🕐 $dateStr $hour:$min';
  }

  String _getRecurrenceChipLabel() {
    final type = widget.controller.recurrenceType;
    if (type == 'WORKDAYS') return '🔁 شنبه تا چهارشنبه';
    if (type == 'EVERY_DAY') return '🔁 هر روز';
    if (type == 'CUSTOM_DAYS') return '🔁 روزهای خاص';
    if (type == 'INTERVAL_DAYS') return '🔁 هر چند روز';
    if (type == 'INTERVAL_HOURS') return '🔁 هر چند ساعت';
    return '🔁 تکرار';
  }

  String _getDurationChipLabel() {
    return '⏱ ${widget.controller.targetDuration} دقیقه';
  }

  Widget _buildChip({
    required String label,
    required VoidCallback onDelete,
    required BuildContext context,
  }) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.goldAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            toPersianDigits(label),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11.5,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final showQuickSaveHint = widget.controller.currentPage == 0 &&
        !widget.controller.isEditing &&
        widget.controller.title.trim().isNotEmpty &&
        (widget.controller.isTimeParsed || widget.controller.prefilledTime != null) &&
        !widget.controller.quickSaveHintDismissed;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2235).withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.controller.inputController,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'مثلاً: فردا ساعت ۸ برم باشگاه',
                      hintStyle: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        color: colors.textSecondary.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onFieldSubmitted: (text) {
                      _debounce?.cancel();
                      widget.controller.onInputTextChanged(text, immediate: true);
                      widget.controller.updatePage(1);
                    },
                    onChanged: (text) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 350), () {
                        widget.controller.onInputTextChanged(text);
                      });
                    },
                  ),
                ),
                if (widget.controller.isAiParsing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff8B5CF6)),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      _debounce?.cancel();
                      widget.controller.onInputTextChanged(widget.controller.inputController.text, immediate: true);
                      widget.controller.updatePage(1);
                    },
                    child: Icon(Icons.arrow_back_rounded, color: colors.primary, size: 20),
                  ),
              ],
            ),
          ),
          
          // Entity Chips
          if (widget.controller.isTimeParsed ||
              widget.controller.isRecurrenceParsed ||
              widget.controller.isDurationParsed) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.controller.isTimeParsed)
                  _buildChip(
                    label: _getTimeDateChipLabel(),
                    onDelete: () => widget.controller.removeParsedEntity('time'),
                    context: context,
                  ),
                if (widget.controller.isRecurrenceParsed)
                  _buildChip(
                    label: _getRecurrenceChipLabel(),
                    onDelete: () => widget.controller.removeParsedEntity('recurrence'),
                    context: context,
                  ),
                if (widget.controller.isDurationParsed)
                  _buildChip(
                    label: _getDurationChipLabel(),
                    onDelete: () => widget.controller.removeParsedEntity('duration'),
                    context: context,
                  ),
              ],
            ),
          ],
          
          // AI Parse Fallback Button
          if (widget.controller.showAiParseAction && !widget.controller.isAiParsing) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => widget.controller.parseWithAI(context),
                icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xff8B5CF6)),
                label: const Text(
                  '✨ تحلیل با هوش مصنوعی',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11.5,
                    color: Color(0xff8B5CF6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: const Color(0xff8B5CF6).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],

          // Quick Save Hint
          if (showQuickSaveHint) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.goldAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.goldAccent.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: colors.goldAccent, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '💡 می‌توانید از دکمه «ذخیره سریع» برای ثبت فوری بدون طی کردن بقیه مراحل استفاده کنید.',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: colors.goldAccent,
                      ),
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
