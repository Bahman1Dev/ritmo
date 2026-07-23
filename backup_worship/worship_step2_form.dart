// Legacy WorshipStep2Form extracted from universal_planner_sheet.dart
// This code is now kept as a standalone reference backup file.

import 'package:flutter/material.dart';

import '../planner_controller.dart';

class WorshipStep2Form extends StatefulWidget {
  const WorshipStep2Form({super.key, required this.controller});
  final PlannerController controller;

  @override
  State<WorshipStep2Form> createState() => _WorshipStep2FormState();
}

class _WorshipStep2FormState extends State<WorshipStep2Form> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.controller.title;
  }

  @override
  void didUpdateWidget(covariant WorshipStep2Form oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.title != _titleController.text) {
      _titleController.text = widget.controller.title;
      _titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: _titleController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'نوع عبادت',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip('MUSTAHAB', 'عمل مستحبی', Icons.star_rounded),
                const SizedBox(width: 8),
                _buildTypeChip('DHIKR', 'ذکر روزانه', Icons.repeat_rounded),
                const SizedBox(width: 8),
                _buildTypeChip('QURAN', 'قرائت قرآن', Icons.menu_book_rounded),
                const SizedBox(width: 8),
                _buildTypeChip('DEBT', 'بدهی (قضا)', Icons.history_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (widget.controller.worshipType == 'DEBT') ...[
            const Text(
              'نوع بدهی',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildDebtTypeChip('PRAYER', 'نماز قضا'),
                const SizedBox(width: 12),
                _buildDebtTypeChip('FAST', 'روزه قضا'),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'تعداد کل: ${widget.controller.worshipTotalCount}',
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14.5),
            ),
            Slider(
              value: widget.controller.worshipTotalCount.toDouble(),
              min: 1,
              max: 300,
              divisions: 300,
              activeColor: colors.primary,
              onChanged: (val) {
                widget.controller.worshipTotalCount = val.toInt();
                widget.controller.notifyListeners();
              },
            ),
            const SizedBox(height: 10),
            Text(
              'هدف روزانه انجام: ${widget.controller.worshipDailyTarget}',
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14.5),
            ),
            Slider(
              value: widget.controller.worshipDailyTarget.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: colors.primary,
              onChanged: (val) {
                widget.controller.worshipDailyTarget = val.toInt();
                widget.controller.notifyListeners();
              },
            ),
          ] else ...[
            // Custom Title text input field
            const Text(
              'نام عبادت یا ذکر',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15.5,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'تایپ نام عبادت شخصی (مثلاً: زیارت جامعه کبیره)',
                labelStyle: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14.5,
                  color: colors.textSecondary.withOpacity(0.8),
                ),
                hintText: 'نام عبادت را وارد کنید...',
                hintStyle: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13.5,
                  color: colors.textSecondary.withOpacity(0.5),
                ),
                prefixIcon: Icon(Icons.edit_rounded, color: colors.primary, size: 18),
                filled: true,
                fillColor: isDark ? const Color(0xFF16192E).withOpacity(0.3) : Colors.black.withOpacity(0.02),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.border.withOpacity(0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.border.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.primary.withOpacity(0.5), width: 1.5),
                ),
              ),
              onChanged: (val) {
                widget.controller.title = val;
                widget.controller.notifyListeners();
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'انتخاب سریع یا شخصی‌سازی',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip('نماز شب', 'MUSTAHAB'),
                  const SizedBox(width: 8),
                  _buildPresetChip('زیارت عاشورا', 'MUSTAHAB'),
                  const SizedBox(width: 8),
                  _buildPresetChip('دعای عهد', 'MUSTAHAB'),
                  const SizedBox(width: 8),
                  _buildPresetChip('صلوات', 'DHIKR'),
                  const SizedBox(width: 8),
                  _buildPresetChip('تلاوت قرآن', 'QURAN'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'مبنای زمان‌بندی',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildAnchorBasisChip('NONE', 'ساعت مشخص'),
                const SizedBox(width: 8),
                _buildAnchorBasisChip('SHARIA', 'اوقات شرعی'),
                const SizedBox(width: 8),
                _buildAnchorBasisChip('SLEEP', 'بیداری/خواب'),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.controller.worshipReminderAnchor == 'NONE') ...[
              PlannerTimelinePicker(controller: widget.controller),
            ] else if (widget.controller.worshipReminderAnchor == 'SHARIA') ...[
              const Text(
                'کدام وقت شرعی؟',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildShariaAnchorChip('FAJR', '🌅 اذان صبح'),
                  _buildShariaAnchorChip('SUNRISE', '☀️ طلوع آفتاب'),
                  _buildShariaAnchorChip('DHUHR', '🕐 اذان ظهر'),
                  _buildShariaAnchorChip('ASR', '🌤 اذان عصر'),
                  _buildShariaAnchorChip('MAGHRIB', '🌇 اذان مغرب'),
                  _buildShariaAnchorChip('ISHA', '🌙 اذان عشا'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'فاصله زمانی: ${widget.controller.worshipOffsetMinutes} دقیقه',
                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5),
              ),
              Slider(
                value: widget.controller.worshipOffsetMinutes.toDouble(),
                min: -60,
                max: 60,
                divisions: 24,
                activeColor: colors.primary,
                onChanged: (val) {
                  widget.controller.worshipOffsetMinutes = val.toInt();
                  widget.controller.notifyListeners();
                },
              ),
            ] else ...[
              Row(
                children: [
                  _buildShariaAnchorChip('WAKEUP', '⏰ زمان بیداری'),
                  const SizedBox(width: 12),
                  _buildShariaAnchorChip('BEDTIME', '😴 زمان خوابیدن'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'فاصله زمانی: ${widget.controller.worshipOffsetMinutes} دقیقه',
                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5),
              ),
              Slider(
                value: widget.controller.worshipOffsetMinutes.toDouble(),
                min: -60,
                max: 60,
                divisions: 24,
                activeColor: colors.primary,
                onChanged: (val) {
                  widget.controller.worshipOffsetMinutes = val.toInt();
                  widget.controller.notifyListeners();
                },
              ),
            ],
            const SizedBox(height: 20),

            // Repeat frequency toggle
            const Text(
              'نحوه تکرار یادآور',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildRepeatTypeOption('RECURRING', 'تکرار هفتگی'),
                const SizedBox(width: 12),
                _buildRepeatTypeOption('ONCE', 'فقط یک‌بار (تاریخ انتخابی)'),
              ],
            ),
            const SizedBox(height: 20),

            if (widget.controller.worshipRepeatType == 'RECURRING') ...[
              const Text(
                'روزهای تکرار',
                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              PlannerDayOfWeekSelector(
                selectedDays: widget.controller.worshipSelectedDays,
                onChanged: (list) {
                  widget.controller.worshipSelectedDays = list;
                  widget.controller.notifyListeners();
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final sel = widget.controller.worshipType == type;
    final wColor = const Color(0xffFBBF24);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      avatar: Icon(icon, color: sel ? Colors.white : wColor, size: 17),
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5)),
      selected: sel,
      selectedColor: wColor,
      backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.black.withOpacity(0.04),
      labelStyle: TextStyle(
        color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontFamily: 'Vazirmatn',
      ),
      onSelected: (val) {
        if (val) {
          widget.controller.worshipType = type;
          if (type == 'DEBT') {
            widget.controller.title = 'نماز قضا';
          }
          widget.controller.notifyListeners();
        }
      },
    );
  }

  Widget _buildDebtTypeChip(String debtType, String label) {
    final sel = widget.controller.worshipDebtType == debtType;
    final wColor = const Color(0xffFBBF24);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5)),
      selected: sel,
      selectedColor: wColor,
      backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.black.withOpacity(0.04),
      labelStyle: TextStyle(
        color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontFamily: 'Vazirmatn',
      ),
      onSelected: (val) {
        if (val) {
          widget.controller.worshipDebtType = debtType;
          widget.controller.title = debtType == 'PRAYER' ? 'نماز قضا' : 'روزه قضا';
          widget.controller.notifyListeners();
        }
      },
    );
  }

  Widget _buildPresetChip(String name, String type) {
    final sel = widget.controller.title == name;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      label: Text(name, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5)),
      backgroundColor: sel 
          ? const Color(0xffFBBF24).withOpacity(0.2) 
          : (isDark ? const Color(0xFF1E2235) : Colors.black.withOpacity(0.04)),
      side: BorderSide(
        color: sel ? const Color(0xffFBBF24) : Colors.transparent,
        width: 1,
      ),
      labelStyle: TextStyle(
        color: sel ? const Color(0xffFBBF24) : (isDark ? Colors.white70 : Colors.black87),
        fontFamily: 'Vazirmatn',
      ),
      onPressed: () {
        widget.controller.title = name;
        widget.controller.worshipType = type;
        widget.controller.notifyListeners();
      },
    );
  }

  Widget _buildAnchorBasisChip(String basis, String label) {
    final sel = (basis == 'NONE' && widget.controller.worshipReminderAnchor == 'NONE') ||
                 (basis == 'SHARIA' && widget.controller.worshipReminderAnchor != 'NONE' && widget.controller.worshipReminderAnchor != 'WAKEUP' && widget.controller.worshipReminderAnchor != 'BEDTIME') ||
                 (basis == 'SLEEP' && (widget.controller.worshipReminderAnchor == 'WAKEUP' || widget.controller.worshipReminderAnchor == 'BEDTIME'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5)),
      selected: sel,
      selectedColor: const Color(0xffFBBF24),
      backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.black.withOpacity(0.04),
      labelStyle: TextStyle(
        color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontFamily: 'Vazirmatn',
      ),
      onSelected: (val) {
        if (val) {
          if (basis == 'NONE') {
            widget.controller.worshipReminderAnchor = 'NONE';
          } else if (basis == 'SHARIA') {
            widget.controller.worshipReminderAnchor = 'FAJR';
          } else {
            widget.controller.worshipReminderAnchor = 'WAKEUP';
          }
          widget.controller.notifyListeners();
        }
      },
    );
  }

  Widget _buildShariaAnchorChip(String key, String label) {
    final sel = widget.controller.worshipReminderAnchor == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5)),
      selected: sel,
      selectedColor: const Color(0xffFBBF24),
      backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.black.withOpacity(0.04),
      labelStyle: TextStyle(
        color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontFamily: 'Vazirmatn',
      ),
      onSelected: (val) {
        if (val) {
          widget.controller.worshipReminderAnchor = key;
          widget.controller.notifyListeners();
        }
      },
    );
  }

  Widget _buildRepeatTypeOption(String type, String label) {
    final sel = widget.controller.worshipRepeatType == type;
    final wColor = const Color(0xffFBBF24);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13.5)),
      selected: sel,
      selectedColor: wColor,
      backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.black.withOpacity(0.04),
      labelStyle: TextStyle(
        color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontFamily: 'Vazirmatn',
      ),
      onSelected: (val) {
        if (val) {
          widget.controller.worshipRepeatType = type;
          widget.controller.notifyListeners();
        }
      },
    );
  }
}
