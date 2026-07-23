import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class TemporaryEventCreateSheet extends StatefulWidget {

  const TemporaryEventCreateSheet({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<TemporaryEventCreateSheet> createState() => _TemporaryEventCreateSheetState();
}

class _TemporaryEventCreateSheetState extends State<TemporaryEventCreateSheet> {
  final _titleController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  int _durationMinutes = 60;
  bool _isSaving = false;

  final List<int> _durations = [30, 60, 90, 120, 180, 240];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xff5B8AF5),
                    onPrimary: Colors.white,
                    surface: Color(0xff1C1F2E),
                  )
                : ColorScheme.light(
                    primary: colors.primary,
                    surface: colors.sheetBackground,
                    onSurface: colors.cardTitle,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final startHourStr = _startTime.hour.toString().padLeft(2, '0');
      final startMinStr = _startTime.minute.toString().padLeft(2, '0');
      final startTimeStr = '$startHourStr:$startMinStr';

      // Calculate end time
      final startTotalMin = _startTime.hour * 60 + _startTime.minute;
      final endTotalMin = startTotalMin + _durationMinutes;
      final endHour = (endTotalMin ~/ 60) % 24;
      final endMin = endTotalMin % 60;
      final endTimeStr = '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';

      await db.insert('temporary_events', {
        'id': 'temp_$nowMs',
        'title': _titleController.text.trim(),
        'date': todayStr,
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'durationMinutes': _durationMinutes,
        'isLocked': 0,
        'createdAt': nowMs,
      });

      HapticFeedback.mediumImpact();
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving temporary event: $e');
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ثبت رویداد موقت جدید',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.cardTitle, fontFamily: 'Vazirmatn'),
                    ),
                    IconButton(
                      icon: Icon(CupertinoIcons.xmark, color: colors.iconSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'یک رویداد ناگهانی یا موقت (مثلاً ناهار کاری غیرمنتظره) ثبت کنید تا برنامه امروز بر اساس آن فشرده‌سازی شود.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
                const SizedBox(height: 20),

                // Title Input
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: colors.cardTitle, fontSize: 13, fontFamily: 'Vazirmatn'),
                  decoration: InputDecoration(
                    hintText: 'عنوان رویداد (مثلاً: جلسه کاری اضطراری)',
                    hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 12),
                    fillColor: colors.inputBackground,
                    filled: true,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.glassBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
                  ),
                ),
                const SizedBox(height: 16),

                // Time picker row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('زمان شروع رویداد:', style: TextStyle(fontSize: 12, color: colors.cardTitle, fontFamily: 'Vazirmatn')),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.cardFill,
                        foregroundColor: colors.cardTitle,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(CupertinoIcons.clock, size: 16, color: colors.primary),
                      label: Text(
                        _startTime.format(context),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: colors.cardTitle),
                      ),
                      onPressed: () => _selectTime(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Duration Selector
                Text('مدت زمان رویداد (دقیقه):', style: TextStyle(fontSize: 12, color: colors.cardTitle, fontFamily: 'Vazirmatn')),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _durations.map((dur) {
                    final isSelected = _durationMinutes == dur;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _durationMinutes = dur;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary.withValues(alpha: 0.12) : colors.cardFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? colors.primary.withValues(alpha: 0.4) : colors.glassBorder,
                          ),
                        ),
                        child: Text(
                          '$dur دقیقه',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? colors.primary : colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Save button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : _saveEvent,
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ثبت رویداد موقت', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
