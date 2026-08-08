import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:sqflite/sqflite.dart';

class PsychLayerSettingsSheet extends StatefulWidget {
  const PsychLayerSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const PsychLayerSettingsSheet(),
    );
  }

  @override
  State<PsychLayerSettingsSheet> createState() => _PsychLayerSettingsSheetState();
}

class _PsychLayerSettingsSheetState extends State<PsychLayerSettingsSheet> {
  bool _isLoading = true;
  final Map<String, bool> _settings = {
    'motivation_diagnosis_enabled': true,
    'daily_budget_warning_enabled': true,
    'wip_limit_enabled': true,
    'cognitive_routing_enabled': false,
    'fresh_start_enabled': true,
    'capture_inbox_enabled': true,
    'mastery_pleasure_sampling_enabled': false,
    'mastery_decay_enabled': true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('app_settings');
    final map = <String, String>{};
    for (final r in rows) {
      map[r['key'] as String] = r['value'] as String? ?? '';
    }

    setState(() {
      for (final k in _settings.keys) {
        if (map.containsKey(k)) {
          _settings[k] = map[k] == 'true';
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _toggleSetting(String key, bool val) async {
    setState(() => _settings[key] = val);
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'app_settings',
      {'key': key, 'value': val ? 'true' : 'false', 'updatedAt': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final labels = [
      {'key': 'motivation_diagnosis_enabled', 'title': 'عارضه‌یابی انگیزشی (شیت چرا نشد؟)', 'desc': 'شناسایی علت انجام نشدن روتین‌ها و پیشنهاد راهکار'},
      {'key': 'daily_budget_warning_enabled', 'title': 'هشدار بودجهٔ روزانه', 'desc': 'کارت هشدار ظرفیت بیش از حد در داشبورد امروز'},
      {'key': 'wip_limit_enabled', 'title': 'سقف کار در جریان اهداف (WIP)', 'desc': 'مدیریت اهداف فعال همزمان و پیشنهاد پارک'},
      {'key': 'cognitive_routing_enabled', 'title': 'مسیریابی بار شناختی', 'desc': 'تطبیق روتین‌های تحلیلی/اداری با سطح انرژی روزانه'},
      {'key': 'fresh_start_enabled', 'title': 'نقاط شروع تازه', 'desc': 'شناسایی نشانه‌های شروع مجدد در اول ماه، فصل یا تولد'},
      {'key': 'capture_inbox_enabled', 'title': 'صندوق ثبت سریع (Open-Loop)', 'desc': 'صندوق دریافت افکار و تصمیم‌گیری سه‌گانه'},
      {'key': 'mastery_pleasure_sampling_enabled', 'title': 'نمونه‌گیری تسلط و لذت', 'desc': 'پرسش درباره اثر روتین روی حس تسلط و لذت'},
      {'key': 'mastery_decay_enabled', 'title': 'افت افتراقی تسلط', 'desc': 'محاسبه زمان مرور بر اساس تاریخچه تمرین و مرور'},
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('لایهٔ عادت و اجرا', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                Center(child: CircularProgressIndicator(color: colors.primary))
              else
                ...labels.map((item) {
                  final key = item['key']!;
                  final title = item['title']!;
                  final desc = item['desc']!;
                  final isChecked = _settings[key] ?? false;

                  return SwitchListTile(
                    value: isChecked,
                    activeThumbColor: colors.primary,
                    title: Text(title, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    subtitle: Text(desc, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary)),
                    onChanged: (val) => _toggleSetting(key, val),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
