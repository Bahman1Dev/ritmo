import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/study/data/study_settings_repository.dart';
import 'package:ritmo/features/study/study_module_entry.dart';

class StudySettingsSheet extends StatefulWidget {
  const StudySettingsSheet({super.key, required this.settings});

  final StudySettings settings;

  static Future<void> show(BuildContext context, {required StudySettings settings}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StudySettingsSheet(settings: settings),
    );
  }

  @override
  State<StudySettingsSheet> createState() => _StudySettingsSheetState();
}

class _StudySettingsSheetState extends State<StudySettingsSheet> {
  late bool _konkurMode;
  late bool _reviewEnabled;
  late bool _showInDashboard;

  @override
  void initState() {
    super.initState();
    _konkurMode = widget.settings.konkurMode;
    _reviewEnabled = widget.settings.reviewEnabled;
    _showInDashboard = widget.settings.showInDashboard;
  }

  Future<void> _toggleKonkurMode(bool val) async {
    if (val == _konkurMode) return;

    if (!val) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('خروج از حالت کنکور', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
          content: const Text(
            'سرفصل‌ها، آزمون‌ها و روزشمار کنکورت پاک نمی‌شن؛ فقط پنهان می‌شن و هر وقت خواستی برمی‌گردن.',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn'))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: ctx.colors.primary),
              child: const Text('خروج از کنکور', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _konkurMode = val);
    if (!mounted) return;
    await StudyModuleEntry.switchMode(context, konkur: val);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('تنظیمات درس و مطالعه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('حالت کنکور', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            subtitle: const Text('فعال‌سازی روزشمار، ضرایب دروس و آزمون‌های آزمایشی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
            value: _konkurMode,
            activeTrackColor: colors.primary.withValues(alpha: 0.5),
            onChanged: _toggleKonkurMode,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('مرور فاصله‌دار (Spaced Repetition)', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            subtitle: const Text('یادآوری مباحث در فواصل زمانی علمی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
            value: _reviewEnabled,
            activeTrackColor: colors.primary.withValues(alpha: 0.5),
            onChanged: (val) async {
              setState(() => _reviewEnabled = val);
              await StudySettingsRepository.instance.updateSetting('study_review_enabled', val.toString());
            },
          ),
          SwitchListTile(
            title: const Text('نمایش در داشبورد امروز', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            value: _showInDashboard,
            activeTrackColor: colors.primary.withValues(alpha: 0.5),
            onChanged: (val) async {
              setState(() => _showInDashboard = val);
              await StudySettingsRepository.instance.updateSetting('study_show_in_dashboard', val.toString());
            },
          ),
        ],
      ),
    );
  }
}
