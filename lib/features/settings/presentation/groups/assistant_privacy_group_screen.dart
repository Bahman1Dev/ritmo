import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/settings/settings_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_page_scaffold.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_segmented_control.dart';
import 'package:ritmo/features/profile/presentation/ai_connection_screen.dart';
import 'package:ritmo/features/profile/presentation/ai_memory_management_screen.dart';
import 'package:ritmo/features/profile/presentation/widgets/psych_layer_settings_sheet.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_section.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_tile.dart';

class AssistantPrivacyGroupScreen extends StatefulWidget {
  const AssistantPrivacyGroupScreen({super.key});

  @override
  State<AssistantPrivacyGroupScreen> createState() => _AssistantPrivacyGroupScreenState();
}

class _AssistantPrivacyGroupScreenState extends State<AssistantPrivacyGroupScreen> {
  bool _cloudConsent = true;
  String _gentleness = 'medium';
  int _dailyCapacity = 480;
  String _wakeTime = '06:30';
  String _sleepTime = '23:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _cloudConsent = SettingsService.instance.get<bool>('assistant_cloud_consent');
      _gentleness = SettingsService.instance.get<String>('gentleness_level');
      _dailyCapacity = SettingsService.instance.get<int>('daily_capacity_minutes');
      _wakeTime = SettingsService.instance.get<String>('wake_time');
      _sleepTime = SettingsService.instance.get<String>('sleep_time');
    });
  }

  Future<void> _update(String key, Object val) async {
    await SettingsService.instance.set(key, val);
    _loadSettings();
  }

  Future<void> _pickTime(String key, String currentVal, String title) async {
    final parts = currentVal.split(':');
    final initialH = int.tryParse(parts[0]) ?? 0;
    final initialM = int.tryParse(parts[1]) ?? 0;
    TimeOfDay selectedTime = TimeOfDay(hour: initialH, minute: initialM);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 260,
          color: context.colors.card,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text('انصراف', style: TextStyle(color: context.colors.textSecondary)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text('تأیید', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final formatted = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                        await _update(key, formatted);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(2026, 1, 1, selectedTime.hour, selectedTime.minute),
                  onDateTimeChanged: (dt) {
                    selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RitmoPageScaffold(
      appBar: const RitmoModuleAppBar(title: 'دستیار و حریم خصوصی'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
        child: Column(
          children: [
            SettingsSection(
              title: 'پیکربندی هوش مصنوعی',
              children: [
                SettingsTile(
                  title: 'اتصال و سرور هوش مصنوعی',
                  subtitle: 'پیش‌تنظیم ژیپو، کلودفلر، اوپن‌روتر، کلیدهای اختصاصی و پینگ زنده',
                  leading: Icon(CupertinoIcons.sparkles, color: colors.primary),
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const AiConnectionScreen()),
                    );
                  },
                ),
                SettingsTile(
                  title: 'حافظه و یادگیری شناختی',
                  subtitle: 'فکت‌ها، ترجیحات و استخراج خودکار الگوهای رفتاری',
                  leading: Icon(CupertinoIcons.circle_grid_hex_fill, color: colors.primary),
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const AiMemoryManagementScreen()),
                    );
                  },
                ),
                SettingsTile(
                  title: 'تنظیمات روان‌شناختی رفتاری',
                  subtitle: 'پالایش انگیزشی، اثر شروع تازه و مهار شکست',
                  leading: Icon(CupertinoIcons.heart_fill, color: colors.primary),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => const PsychLayerSettingsSheet(),
                    );
                  },
                ),
              ],
            ),
            SettingsSection(
              title: 'حریم خصوصی و پردازش ابری',
              footer: 'در صورت غیرفعال بودن، اطلاعات متن روز به سرویس‌دهنده‌های هوش مصنوعی ارسال نخواهد شد.',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رضایت‌نامه پردازش ابری',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مجوز تحلیل داده‌های متنی روتین‌ها',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                        ],
                      ),
                      CupertinoSwitch(
                        value: _cloudConsent,
                        activeTrackColor: colors.primary,
                        onChanged: (val) => _update('assistant_cloud_consent', val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: 'رفتار و پارامترهای دستیار',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لحن و نرمی دستیار',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      RitmoSegmentedControl<String>(
                        selected: _gentleness,
                        segments: const {
                          'gentle': 'ملایم و منعطف',
                          'medium': 'متعادل',
                          'strict': 'قاطع و جدی',
                        },
                        onSelected: (val) => _update('gentleness_level', val),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ظرفیت کار روزانه', style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                          Text('${toPersianDigits(_dailyCapacity ~/ 60)} ساعت و ${toPersianDigits(_dailyCapacity % 60)} دقیقه',
                              style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                        ],
                      ),
                      CupertinoSlider(
                        value: _dailyCapacity.toDouble(),
                        min: 60,
                        max: 1440,
                        divisions: 23,
                        activeColor: colors.primary,
                        onChanged: (val) => _update('daily_capacity_minutes', val.round()),
                      ),
                    ],
                  ),
                ),
                SettingsTile(
                  title: 'زمان معمول بیداری',
                  subtitle: toPersianDigits(_wakeTime),
                  onTap: () => _pickTime('wake_time', _wakeTime, 'زمان بیداری'),
                ),
                SettingsTile(
                  title: 'زمان معمول خواب',
                  subtitle: toPersianDigits(_sleepTime),
                  onTap: () => _pickTime('sleep_time', _sleepTime, 'زمان خواب'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
