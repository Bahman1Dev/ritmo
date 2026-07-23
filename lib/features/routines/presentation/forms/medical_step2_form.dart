// lib/features/routines/presentation/forms/medical_step2_form.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';

class MedicalStep2Form extends StatefulWidget {
  const MedicalStep2Form({super.key, required this.controller});
  final PlannerController controller;

  @override
  State<MedicalStep2Form> createState() => _MedicalStep2FormState();
}

class _MedicalStep2FormState extends State<MedicalStep2Form> {
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _doseController.text = widget.controller.description;
    _nameController.text = widget.controller.title;
  }

  @override
  void didUpdateWidget(covariant MedicalStep2Form oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.title != _nameController.text) {
      _nameController.text = widget.controller.title;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _doseController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'نام دارو',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 15.5,
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'نام دارو (مثلاً: استامینوفن)',
              labelStyle: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14.5,
                color: colors.textSecondary.withValues(alpha: 0.8),
              ),
              hintText: 'نام دارو را وارد کنید...',
              hintStyle: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13.5,
                color: colors.textSecondary.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(Icons.medication_rounded, color: colors.primary, size: 18),
              filled: true,
              fillColor: isDark ? const Color(0xFF16192E).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.02),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.border.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.border.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
            onChanged: (val) {
              controller.title = val;
            },
          ),
          const SizedBox(height: 20),

          const Text(
            'نحوه مصرف دارو',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildModeChip('FIXED', 'منظم (ساعت مشخص)', Icons.alarm_rounded),
              const SizedBox(width: 8),
              _buildModeChip('PRN', 'در صورت نیاز (PRN)', Icons.medical_services_rounded),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'دوز مصرفی (مثلاً: ۵۰۰ میلی‌گرم)',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _doseController,
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15.5, color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'دوز مصرفی دارو را وارد کنید',
              hintStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5, color: colors.textSecondary.withValues(alpha: 0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onChanged: (val) {
              controller.description = val;
            },
          ),
          const SizedBox(height: 20),

          if (controller.medicalMode == 'FIXED') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ساعات مصرف دارو',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (time != null) {
                      controller.medicalTimes.add(time);
                      controller.notifyListeners();
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('افزودن ساعت', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (controller.medicalTimes.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '⚠️ هیچ ساعتی برای مصرف تنظیم نشده است. لطفاً حداقل یک ساعت اضافه کنید.',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13.5,
                    color: Colors.redAccent.shade200,
                  ),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.medicalTimes.asMap().entries.map((e) {
                  final idx = e.key;
                  final t = e.value;
                  final padH = t.hour.toString().padLeft(2, '0');
                  final padM = t.minute.toString().padLeft(2, '0');
                  return InputChip(
                    label: Text(
                      '$padH:$padM', 
                      style: TextStyle(
                        fontFamily: 'Vazirmatn', 
                        fontSize: 14,
                        color: colors.textPrimary,
                      )
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.black.withValues(alpha: 0.04),
                    deleteIconColor: Colors.redAccent,
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: t,
                      );
                      if (time != null) {
                        controller.medicalTimes[idx] = time;
                        controller.notifyListeners();
                      }
                    },
                    onDeleted: () {
                      controller.medicalTimes.removeAt(idx);
                      controller.notifyListeners();
                    },
                  );
                }).toList(),
              ),
            ],
          ] else ...[
            Text(
              'حداقل فاصله بین دوزها: ${controller.medicalMinIntervalHours} ساعت',
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14.5),
            ),
            Slider(
              value: controller.medicalMinIntervalHours.toDouble(),
              min: 1,
              max: 24,
              divisions: 23,
              activeColor: const Color(0xff06B6D4),
              onChanged: (val) {
                controller.medicalMinIntervalHours = val.toInt();
                controller.notifyListeners();
              },
            ),
            const SizedBox(height: 10),
            Text(
              'حداکثر دوز در روز: ${controller.medicalMaxDosesPerDay} بار',
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14.5),
            ),
            Slider(
              value: controller.medicalMaxDosesPerDay.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              activeColor: const Color(0xff06B6D4),
              onChanged: (val) {
                controller.medicalMaxDosesPerDay = val.toInt();
                controller.notifyListeners();
              },
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'موجودی فعلی دارو: ${controller.medicalStockCount}',
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14.5),
          ),
          Slider(
            value: controller.medicalStockCount.toDouble(),
            max: 100,
            divisions: 100,
            activeColor: const Color(0xff06B6D4),
            onChanged: (val) {
              controller.medicalStockCount = val.toInt();
              controller.notifyListeners();
            },
          ),
          const SizedBox(height: 10),
          Text(
            'هشدار کمبود موجودی: کمتر از ${controller.medicalRefillWarning} عدد',
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14.5),
          ),
          Slider(
            value: controller.medicalRefillWarning.toDouble(),
            max: 20,
            divisions: 20,
            activeColor: const Color(0xff06B6D4),
            onChanged: (val) {
              controller.medicalRefillWarning = val.toInt();
              controller.notifyListeners();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode, String label, IconData icon) {
    final controller = widget.controller;
    final sel = controller.medicalMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      avatar: Icon(icon, color: sel ? Colors.white : const Color(0xff06B6D4), size: 17),
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5)),
      selected: sel,
      selectedColor: const Color(0xff06B6D4),
      backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.black.withValues(alpha: 0.04),
      labelStyle: TextStyle(
        color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontFamily: 'Vazirmatn',
      ),
      onSelected: (val) {
        if (val) {
          controller.medicalMode = mode;
          controller.notifyListeners();
        }
      },
    );
  }
}
