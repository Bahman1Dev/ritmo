import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ritmo/core/services/secure_key_store.dart';
import 'package:ritmo/core/settings/settings_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_page_scaffold.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_section.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_tile.dart';

class SecurityGroupScreen extends StatefulWidget {
  const SecurityGroupScreen({super.key});

  @override
  State<SecurityGroupScreen> createState() => _SecurityGroupScreenState();
}

class _SecurityGroupScreenState extends State<SecurityGroupScreen> {
  bool _appLockEnabled = false;
  bool _useDeviceLock = false;
  bool _biometricEnabled = false;
  int _timeoutSeconds = 300;
  bool _hasAppPassword = false;

  bool _cycleBiometricEnabled = false;
  bool _hasCyclePassword = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    _appLockEnabled = SettingsService.instance.get<bool>('app_lock_enabled');
    _useDeviceLock = SettingsService.instance.get<bool>('app_use_device_lock');
    _biometricEnabled = SettingsService.instance.get<bool>('app_biometric_enabled');
    _timeoutSeconds = SettingsService.instance.get<int>('app_lock_timeout_seconds');

    final appPass = await SecureKeyStore.getKey('app_lock_password');
    _hasAppPassword = appPass != null && appPass.isNotEmpty;

    _cycleBiometricEnabled = SettingsService.instance.get<bool>('cycle_biometric_enabled');
    final cyclePass = await SecureKeyStore.getKey('cycle_lock_password');
    _hasCyclePassword = cyclePass != null && cyclePass.isNotEmpty;

    if (mounted) setState(() {});
  }

  Future<void> _update(String key, Object val) async {
    await SettingsService.instance.set(key, val);
    await _loadState();
  }

  Future<void> _setPin(String keyName, String title) async {
    final colors = context.colors;
    final pinController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'یک رمز عددی ۴ رقمی وارد کنید:',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              obscureText: true,
              placeholder: '••••',
              style: TextStyle(fontSize: 20, letterSpacing: 6, color: colors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('انصراف', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length < 4) {
                RitmoToast.show(context, 'رمز باید حداقل ۴ رقم باشد.', iconColor: colors.medicalRed);
                return;
              }
              Navigator.pop(ctx);
              await SecureKeyStore.setKey(keyName, pin);
              await SettingsService.instance.set(keyName, pin);
              await _loadState();
              if (mounted) {
                RitmoToast.show(context, 'رمز با موفقیت ذخیره شد.');
              }
            },
            child: Text('ذخیره رمز', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePin(String keyName, String title) async {
    final colors = context.colors;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('حذف $title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        content: const Text('آیا از حذف این رمز عبور اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('انصراف', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SecureKeyStore.setKey(keyName, '');
              await SettingsService.instance.set(keyName, '');
              await _loadState();
              if (mounted) {
                RitmoToast.show(context, 'رمز با موفقیت حذف شد.');
              }
            },
            child: Text('حذف رمز', style: TextStyle(color: colors.medicalRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    final colors = context.colors;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('سیاست حریم خصوصی و امنیت'),
        content: SingleChildScrollView(
          child: Text(
            'ریتمو یک نرم‌افزار متمرکز بر حریم خصوصی محلی (Local-First) است.\n\n'
            '۱. کلیه اطلاعات شما اعم از روتین‌ها، یادآوری‌ها، داده‌های زیستی و یادداشت‌ها روی دستگاه شما ذخیره می‌شوند.\n'
            '۲. رمزهای عبور و کلیدهای هوش مصنوعی در محیط امن سخت‌افزاری دستگاه (Keychain / KeyStore) نگهداری می‌شوند.\n'
            '۳. هیچ‌گونه داده‌ای بدون رضایت صریح و فعال‌سازی پردازش ابری به خارج از دستگاه ارسال نخواهد شد.',
            style: TextStyle(fontSize: 12, height: 1.5, color: colors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('متوجه شدم', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCycleVisible = CyclePrivacyGuard.isVisible({
      'user_gender': SettingsService.instance.get<String>('user_gender'),
      'module_cycle_enabled': SettingsService.instance.get<bool>('module_cycle_enabled') ? 'true' : 'false',
    });

    final timeoutLabels = {
      0: 'فوری',
      60: '۱ دقیقه',
      300: '۵ دقیقه',
      900: '۱۵ دقیقه',
      -1: 'هرگز',
    };

    return RitmoPageScaffold(
      appBar: const RitmoModuleAppBar(title: 'امنیت و قفل برنامه'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
        child: Column(
          children: [
            SettingsSection(
              title: 'قفل کلی اپلیکیشن',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('فعال‌سازی قفل برنامه', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('درخواست رمز عبور یا بیومتریک هنگام ورود', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                        ],
                      ),
                      CupertinoSwitch(
                        value: _appLockEnabled,
                        activeTrackColor: colors.primary,
                        onChanged: (val) => _update('app_lock_enabled', val),
                      ),
                    ],
                  ),
                ),
                SettingsTile(
                  title: _hasAppPassword ? 'تغییر رمز قفل برنامه' : 'تعریف رمز عددی',
                  subtitle: _hasAppPassword ? 'رمز عددی ۴ رقمی فعال است' : 'هنوز رمزی تعریف نشده است',
                  trailing: _hasAppPassword
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.trash, size: 18, color: colors.medicalRed),
                          onPressed: () => _deletePin('app_lock_password', 'رمز قفل برنامه'),
                        )
                      : null,
                  onTap: () => _setPin('app_lock_password', 'رمز قفل برنامه'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ورود با اثر انگشت / تشخیص چهره', style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                      CupertinoSwitch(
                        value: _biometricEnabled,
                        activeTrackColor: colors.primary,
                        onChanged: (val) => _update('app_biometric_enabled', val),
                      ),
                    ],
                  ),
                ),
                SettingsTile(
                  title: 'مهلت قفل خودکار',
                  subtitle: timeoutLabels[_timeoutSeconds] ?? '${toPersianDigits(_timeoutSeconds)} ثانیه',
                  onTap: () {
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (ctx) => CupertinoActionSheet(
                        title: const Text('انتخاب مهلت قفل خودکار'),
                        actions: timeoutLabels.entries.map((e) {
                          return CupertinoActionSheetAction(
                            onPressed: () {
                              _update('app_lock_timeout_seconds', e.key);
                              Navigator.pop(ctx);
                            },
                            child: Text(e.value),
                          );
                        }).toList(),
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('انصراف'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (isCycleVisible) ...[
              SettingsSection(
                title: 'قفل اختصاصی بخش چرخهٔ زیستی',
                footer: 'این رمز کاملاً مجزا از رمز ورود به برنامه است و امنیت بخش سلامت بانوان را تامین می‌کند.',
                children: [
                  SettingsTile(
                    title: _hasCyclePassword ? 'تغییر رمز بخش خصوصی' : 'تعریف رمز بخش خصوصی',
                    subtitle: _hasCyclePassword ? 'رمز ۴ رقمی مجزا فعال است' : 'رمز اختصاصی تعریف نشده',
                    trailing: _hasCyclePassword
                        ? CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Icon(CupertinoIcons.trash, size: 18, color: colors.medicalRed),
                            onPressed: () => _deletePin('cycle_lock_password', 'رمز بخش چرخه'),
                          )
                        : null,
                    onTap: () => _setPin('cycle_lock_password', 'رمز بخش خصوصی چرخه'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('بیومتریک اختصاصی بخش چرخه', style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                        CupertinoSwitch(
                          value: _cycleBiometricEnabled,
                          activeTrackColor: colors.primary,
                          onChanged: (val) => _update('cycle_biometric_enabled', val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            SettingsSection(
              title: 'حریم خصوصی و شفافیت',
              children: [
                SettingsTile(
                  title: 'سیاست حریم خصوصی',
                  subtitle: 'تعهد ریتمو به ذخیره‌سازی محلی و عدم ردیابی',
                  leading: Icon(CupertinoIcons.shield_lefthalf_fill, color: colors.primary),
                  onTap: _showPrivacyPolicy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
