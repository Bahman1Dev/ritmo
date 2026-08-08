import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/settings/settings_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_page_scaffold.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_segmented_control.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_section.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_tile.dart';

class NotificationsGroupScreen extends StatefulWidget {
  const NotificationsGroupScreen({super.key});

  @override
  State<NotificationsGroupScreen> createState() => _NotificationsGroupScreenState();
}

class _NotificationsGroupScreenState extends State<NotificationsGroupScreen> {
  bool _masterEnabled = true;
  bool _quietEnabled = false;
  String _quietStart = '00:00';
  String _quietEnd = '07:00';
  bool _persistentEnabled = true;
  String _digestMode = 'standard';
  int _coalescingMinutes = 15;
  int _maxNonEssential = 3;
  int _snoozeMinutes = 10;
  int _snoozeMaxDefer = 3;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _masterEnabled = SettingsService.instance.get<bool>('notif_master_enabled');
      _quietEnabled = SettingsService.instance.get<bool>('notif_quiet_enabled');
      _quietStart = SettingsService.instance.get<String>('notif_quiet_start');
      _quietEnd = SettingsService.instance.get<String>('notif_quiet_end');
      _persistentEnabled = SettingsService.instance.get<bool>('persistent_status_notification_enabled');
      _digestMode = SettingsService.instance.get<String>('digest_mode');
      _coalescingMinutes = SettingsService.instance.get<int>('coalescing_window_minutes');
      _maxNonEssential = SettingsService.instance.get<int>('max_non_essential_per_hour');
      _snoozeMinutes = SettingsService.instance.get<int>('snooze_minutes');
      _snoozeMaxDefer = SettingsService.instance.get<int>('snooze_max_defer_count');
    });
  }

  Future<void> _updateSetting(String key, Object val) async {
    await SettingsService.instance.set(key, val);
    await AlarmSchedulerService.scheduleNextAlarms();
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
                        await _updateSetting(key, formatted);
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
      appBar: const RitmoModuleAppBar(title: 'اعلان‌ها و یادآوری‌ها'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
        child: Column(
          children: [
            SettingsSection(
              title: 'کنترل سراسری',
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
                            'اعلان‌های سراسری',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'فعال بودن زمان‌بندی آلارم‌ها و یادآوری روتین‌ها',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                        ],
                      ),
                      CupertinoSwitch(
                        value: _masterEnabled,
                        activeTrackColor: colors.primary,
                        onChanged: (val) => _updateSetting('notif_master_enabled', val),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اعلان دائمی وضعیت',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'نمایش نوار فعالیت جاری در پانل اعلان‌ها',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                        ],
                      ),
                      CupertinoSwitch(
                        value: _persistentEnabled,
                        activeTrackColor: colors.primary,
                        onChanged: (val) => _updateSetting('persistent_status_notification_enabled', val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: 'ساعات سکوت (مزاحم نشوید)',
              footer: 'در ساعات سکوت، یادآوری‌های غیراضطراری قطع می‌شوند؛ اما اعلان‌های پزشکی و دارویی همچنان ارسال خواهند شد.',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'فعال‌سازی ساعات سکوت',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      CupertinoSwitch(
                        value: _quietEnabled,
                        activeTrackColor: colors.primary,
                        onChanged: (val) => _updateSetting('notif_quiet_enabled', val),
                      ),
                    ],
                  ),
                ),
                if (_quietEnabled) ...[
                  SettingsTile(
                    title: 'زمان آغاز سکوت',
                    subtitle: toPersianDigits(_quietStart),
                    onTap: () => _pickTime('notif_quiet_start', _quietStart, 'زمان آغاز سکوت'),
                  ),
                  SettingsTile(
                    title: 'زمان پایان سکوت',
                    subtitle: toPersianDigits(_quietEnd),
                    onTap: () => _pickTime('notif_quiet_end', _quietEnd, 'زمان پایان سکوت'),
                  ),
                ],
              ],
            ),
            SettingsSection(
              title: 'تجمیع و خلاصه‌سازی',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالت خلاصه اعلان',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      RitmoSegmentedControl<String>(
                        selected: _digestMode,
                        segments: const {
                          'standard': 'استاندارد',
                          'concise': 'فشرده',
                          'grouped': 'دسته‌ای',
                        },
                        onSelected: (val) => _updateSetting('digest_mode', val),
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
                          Text('بازهٔ تجمیع اعلان‌ها', style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                          Text('${toPersianDigits(_coalescingMinutes)} دقیقه', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                        ],
                      ),
                      CupertinoSlider(
                        value: _coalescingMinutes.toDouble(),
                        min: 1,
                        max: 60,
                        divisions: 59,
                        activeColor: colors.primary,
                        onChanged: (val) => _updateSetting('coalescing_window_minutes', val.round()),
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
                          Text('سقف پیام‌های غیراضطراری در ساعت', style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                          Text('${toPersianDigits(_maxNonEssential)} پیام', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                        ],
                      ),
                      CupertinoSlider(
                        value: _maxNonEssential.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        activeColor: colors.primary,
                        onChanged: (val) => _updateSetting('max_non_essential_per_hour', val.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: 'تعویق و اسنوز',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('مدت زمان تعویق پیش‌فرض', style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                          Text('${toPersianDigits(_snoozeMinutes)} دقیقه', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                        ],
                      ),
                      CupertinoSlider(
                        value: _snoozeMinutes.toDouble(),
                        min: 1,
                        max: 120,
                        divisions: 119,
                        activeColor: colors.primary,
                        onChanged: (val) => _updateSetting('snooze_minutes', val.round()),
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
                          Text('حداکثر دفعات تعویق مجاز', style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                          Text('${toPersianDigits(_snoozeMaxDefer)} بار', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                        ],
                      ),
                      CupertinoSlider(
                        value: _snoozeMaxDefer.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        activeColor: colors.primary,
                        onChanged: (val) => _updateSetting('snooze_max_defer_count', val.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
