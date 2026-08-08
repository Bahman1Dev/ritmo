import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/settings/settings_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_page_scaffold.dart';
import 'package:ritmo/features/profile/presentation/backup_screen.dart';
import 'package:ritmo/features/profile/presentation/crash_reports_screen.dart';
import 'package:ritmo/features/settings/presentation/widgets/danger_zone.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_section.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_tile.dart';
import 'package:shamsi_date/shamsi_date.dart';

class DataBackupGroupScreen extends StatefulWidget {
  const DataBackupGroupScreen({
    super.key,
    this.onFactoryReset,
  });

  final VoidCallback? onFactoryReset;

  @override
  State<DataBackupGroupScreen> createState() => _DataBackupGroupScreenState();
}

class _DataBackupGroupScreenState extends State<DataBackupGroupScreen> {
  String _lastBackupDate = 'هنوز پشتیبانی گرفته نشده';
  bool _autoBackup = false;
  int _backupDays = 7;
  bool _crashReports = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    _autoBackup = SettingsService.instance.get<bool>('auto_backup_enabled');
    _backupDays = SettingsService.instance.get<int>('backup_frequency_days');
    _crashReports = SettingsService.instance.get<bool>('crash_reports_enabled');

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${docDir.path}/backups');
      if (await backupDir.exists()) {
        final files = backupDir.listSync().whereType<File>().toList();
        if (files.isNotEmpty) {
          files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          final lastModified = files.first.lastModifiedSync();
          final j = Jalali.fromDateTime(lastModified);
          _lastBackupDate = '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')} - ${lastModified.hour.toString().padLeft(2, '0')}:${lastModified.minute.toString().padLeft(2, '0')}';
        }
      }
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _update(String key, Object val) async {
    await SettingsService.instance.set(key, val);
    await _loadState();
  }

  Future<void> _clearNotificationHistory() async {
    final colors = context.colors;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف تاریخچه اعلان‌ها',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        content: Text(
          'آیا از پاک کردن سوابق تحویل و رویدادهای اعلان‌های گذشته اطمینان دارید؟ داده‌های روتین‌ها دست‌نخورده باقی می‌مانند.',
          style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('انصراف', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = await DatabaseHelper.instance.database;
              await db.delete('alarm_delivery_log');
              if (mounted) {
                RitmoToast.show(context, 'تاریخچه اعلان‌ها با موفقیت پاک‌سازی شد.');
              }
            },
            child: Text('پاک‌سازی', style: TextStyle(color: colors.medicalRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RitmoPageScaffold(
      appBar: const RitmoModuleAppBar(title: 'داده و پشتیبان'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
        child: Column(
          children: [
            SettingsSection(
              title: 'پشتیبان‌گیری محلی و ابری',
              children: [
                SettingsTile(
                  title: 'مدیریت و استخراج پشتیبان (Backup)',
                  subtitle: 'وضعیت: $_lastBackupDate',
                  leading: Icon(CupertinoIcons.cloud_upload_fill, color: colors.primary),
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const BackupScreen()),
                    ).then((_) => _loadState());
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('پشتیبان‌گیری خودکار', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('تهیه خودکار فایل پشتیبان رمزنگاری‌شده', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                        ],
                      ),
                      CupertinoSwitch(
                        value: _autoBackup,
                        activeTrackColor: colors.primary,
                        onChanged: (val) => _update('auto_backup_enabled', val),
                      ),
                    ],
                  ),
                ),
                if (_autoBackup) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('دوره پشتیبان‌گیری', style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                            Text('هر ${toPersianDigits(_backupDays)} روز یک‌بار', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                          ],
                        ),
                        CupertinoSlider(
                          value: _backupDays.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          activeColor: colors.primary,
                          onChanged: (val) => _update('backup_frequency_days', val.round()),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            SettingsSection(
              title: 'پایداری و گزارش خطا',
              children: [
                SettingsTile(
                  title: 'مشاهده گزارش خطاهای سیستم (Crash Reports)',
                  subtitle: 'ثبت و بررسی گزارش خطاهای غیرمنتظره',
                  leading: Icon(CupertinoIcons.ant_fill, color: colors.primary),
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const CrashReportsScreen()),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ثبت خودکار گزارش خطاها', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('کمک به عیب‌یابی و پایداری اپلیکیشن', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                        ],
                      ),
                      CupertinoSwitch(
                        value: _crashReports,
                        activeTrackColor: colors.primary,
                        onChanged: (val) => _update('crash_reports_enabled', val),
                      ),
                    ],
                  ),
                ),
                SettingsTile(
                  title: 'حذف تاریخچه اعلان‌ها',
                  subtitle: 'پاک‌سازی لاگ‌ها و رویدادهای اعلان‌های گذشته',
                  leading: Icon(CupertinoIcons.trash, color: colors.textSecondary),
                  onTap: _clearNotificationHistory,
                ),
              ],
            ),
            const SizedBox(height: 24),
            DangerZone(
              onFactoryReset: widget.onFactoryReset ?? () {},
            ),
          ],
        ),
      ),
    );
  }
}
