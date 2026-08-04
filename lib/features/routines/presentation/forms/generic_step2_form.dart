// lib/features/routines/presentation/forms/generic_step2_form.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_timeline_picker.dart';

class GenericStep2Form extends StatelessWidget {
  const GenericStep2Form({super.key, required this.controller});
  final PlannerController controller;

  void _showDurationManualDialog(BuildContext context, RitmoColors colors) {
    final textController = TextEditingController(text: controller.targetDuration.toString());
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.sheetBackground,
            title: const Text(
              'وارد کردن دستی مدت زمان',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'مدت زمان مورد نظر خود را به دقیقه وارد کنید:',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    suffixText: 'دقیقه',
                    suffixStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  final val = int.tryParse(textController.text);
                  if (val != null && val > 0) {
                    controller.targetDuration = val;
                    controller.notifyListeners();
                  }
                  Navigator.pop(context);
                },
                child: const Text('تایید', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReminderPicker(BuildContext context, RitmoColors colors) {
    final options = [
      {'label': 'همزمان با شروع', 'value': 0},
      {'label': '۵ دقیقه قبل', 'value': 5},
      {'label': '۱۰ دقیقه قبل', 'value': 10},
      {'label': '۱۵ دقیقه قبل', 'value': 15},
      {'label': '۳۰ دقیقه قبل', 'value': 30},
      {'label': '۱ ساعت قبل', 'value': 60},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تنظیم زمان یادآوری',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final isSelected = controller.reminderOffsetMinutes == opt['value'];
                  return ListTile(
                    title: Text(
                      opt['label']! as String,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colors.primary : colors.textPrimary,
                      ),
                    ),
                    trailing: isSelected ? Icon(Icons.check_rounded, color: colors.primary) : null,
                    onTap: () {
                      controller.reminderOffsetMinutes = opt['value']! as int;
                      controller.notifyListeners();
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          PlannerTimelinePicker(controller: controller),
          const SizedBox(height: 28),
          
          // 1. Duration Picker Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مدت زمان',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2235).withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () => controller.adjustDuration(-15),
                        color: colors.textPrimary.withValues(alpha: 0.6),
                      ),
                      GestureDetector(
                        onTap: () => _showDurationManualDialog(context, colors),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            '${toPersianDigits(controller.targetDuration.toString())} دقیقه',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => controller.adjustDuration(15),
                        color: colors.textPrimary.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Recurrence Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تکرار',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      controller.recurrenceType == 'EVERY_DAY'
                          ? 'روزانه'
                          : (controller.recurrenceType == 'WEEKLY' ? 'هفتگی' : 'دلخواه'),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.sync_rounded, size: 18, color: colors.textSecondary.withValues(alpha: 0.7)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Reminder Card
          GestureDetector(
            onTap: () => _showReminderPicker(context, colors),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'یادآوری',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        controller.reminderOffsetMinutes == 0
                            ? 'همزمان با شروع'
                            : '${toPersianDigits(controller.reminderOffsetMinutes.toString())} دقیقه قبل',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textSecondary.withValues(alpha: 0.6)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Advanced Settings Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    controller.isAdvancedExpanded = !controller.isAdvancedExpanded;
                    controller.notifyListeners();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تنظیمات پیشرفته',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                          ),
                        ),
                        Icon(
                          controller.isAdvancedExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: controller.isAdvancedExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Description field
                              TextFormField(
                                initialValue: controller.description,
                                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'توضیحات یا یادداشت‌ها',
                                  labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: (val) => controller.description = val,
                              ),
                              const SizedBox(height: 12),

                              // Priority dropdown
                              DropdownButtonFormField<double>(
                                initialValue: controller.priority,
                                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'اولویت',
                                  labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 0.5, child: Text('پایین ⚠️')),
                                  DropdownMenuItem(value: 1, child: Text('متوسط ⚠️⚠️')),
                                  DropdownMenuItem(value: 1.5, child: Text('بالا ⚠️⚠️⚠️')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.priority = val;
                                  }
                                },
                              ),
                              const SizedBox(height: 12),

                              // Energy Rule / Adaptive Behavior
                              DropdownButtonFormField<String>(
                                initialValue: controller.energyRule,
                                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'قانون مدیریت انرژی هوشمند (نقشه راه)',
                                  labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'NONE', child: Text('پایبندی بدون قید و شرط 🎯')),
                                  DropdownMenuItem(value: 'SKIP', child: Text('پرش در صورت خستگی شدید 💤')),
                                  DropdownMenuItem(value: 'OFFER_LIGHT', child: Text('کاهش خودکار به نسخه سبک ⚡')),
                                  DropdownMenuItem(value: 'HIGH_ENERGY_ONLY', child: Text('فقط هنگام انرژی بالا 🔥')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.energyRule = val;
                                    controller.notifyListeners();
                                  }
                                },
                              ),
                              const SizedBox(height: 12),

                              // Zone (Realm) selection dropdown
                              DropdownButtonFormField<String?>(
                                initialValue: controller.selectedZoneId,
                                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'زون مربوطه (Realm)',
                                  labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(child: Text('بدون زون (عمومی)')),
                                  ...controller.availableZones.map((z) {
                                    return DropdownMenuItem<String?>(
                                      value: z['id'] as String,
                                      child: Text('${z['emoji'] ?? '🌐'} ${z['name'] ?? ''}'),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  controller.selectedZoneId = val;
                                  controller.notifyListeners();
                                },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
