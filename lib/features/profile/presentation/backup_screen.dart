import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/services/backup_passcode_manager.dart';
import 'package:ritmo/core/services/google_drive_backup_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_directional_icon.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/widgets/restart_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _passcodeManager = BackupPasscodeManager();
  final _driveService = GoogleDriveBackupService.instance;

  bool _isGoogleConnected = false;
  String? _googleEmail;
  bool _isLoading = false;
  bool _isWeeklyBackupEnabled = false;
  List<RemoteBackupMetadata> _remoteBackups = [];
  String? _passcodeHint;
  bool _hasPasscode = false;

  @override
  void initState() {
    super.initState();
    _isGoogleConnected = _driveService.isSignedIn;
    _googleEmail = _driveService.userEmail;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _isWeeklyBackupEnabled = prefs.getBool('weekly_backup_enabled') ?? false;
      _hasPasscode = await _passcodeManager.hasPasscode();
      _passcodeHint = await _passcodeManager.getHint();
      
      if (_isGoogleConnected) {
        await _fetchBackupList();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBackupList() async {
    try {
      final backups = await _driveService.listBackups();
      if (mounted) {
        setState(() {
          _remoteBackups = backups;
        });
      }
    } catch (e) {
      debugPrint('Error fetching backup list: $e');
      _showToast('خطا در دریافت لیست پشتیبان‌ها از گوگل درایو.', isError: true);
    }
  }

  Future<void> _connectGoogle() async {
    setState(() => _isLoading = true);
    try {
      final success = await _driveService.signIn();
      if (success) {
        setState(() {
          _isGoogleConnected = true;
          _googleEmail = _driveService.userEmail;
        });
        await _fetchBackupList();
        _showToast('اتصال به گوگل درایو با موفقیت برقرار شد.');
      } else {
        _showToast('اتصال به حساب گوگل لغو شد یا با خطا مواجه گردید.', isError: true);
      }
    } catch (e) {
      debugPrint('Google connect error: $e');
      _showToast('خطا در اتصال به حساب گوگل.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _driveService.signOut();
      setState(() {
        _isGoogleConnected = false;
        _googleEmail = null;
        _remoteBackups = [];
      });
      _showToast('از حساب گوگل خارج شدید.');
    } catch (e) {
      debugPrint('Google disconnect error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWeeklyBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled && !_hasPasscode) {
      _showToast('لطفاً ابتدا رمز عبور پشتیبان‌گیری را تنظیم کنید.', isError: true);
      return;
    }

    setState(() {
      _isWeeklyBackupEnabled = enabled;
    });
    await prefs.setBool('weekly_backup_enabled', enabled);

    if (enabled) {
      await Workmanager().registerPeriodicTask(
        'weekly_backup_task',
        'weekly_backup_task',
        frequency: const Duration(days: 7),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
      _showToast('پشتیبان‌گیری خودکار هفتگی فعال شد.');
    } else {
      await Workmanager().cancelByUniqueName('weekly_backup_task');
      _showToast('پشتیبان‌گیری خودکار هفتگی غیرفعال شد.');
    }
  }

  void _showPasscodeSheet({required VoidCallback onSuccess}) {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets;
        final passController = TextEditingController();
        final hintController = TextEditingController();
        final formKey = GlobalKey<FormState>();

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: colors.border, width: 1),
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4.5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colors.textTertiary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Text(
                      'تنظیم رمز عبور پشتیبان 🔑',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'این رمز عبور برای رمزگذاری سرتاسری داده‌های شما در گوگل درایو استفاده می‌شود. حتماً آن را یادداشت کنید؛ بدون این رمز، بازیابی اطلاعات غیرممکن خواهد بود.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passController,
                      obscureText: true,
                      style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      decoration: InputDecoration(
                        hintText: 'رمز عبور (حداقل ۸ کاراکتر)',
                        hintStyle: TextStyle(color: colors.textTertiary),
                        filled: true,
                        fillColor: colors.surfaceSunken,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 8) {
                          return 'رمز عبور باید حداقل ۸ کاراکتر باشد.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: hintController,
                      style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      decoration: InputDecoration(
                        hintText: 'راهنما / نشانه برای یادآوری رمز (اختیاری)',
                        hintStyle: TextStyle(color: colors.textTertiary),
                        filled: true,
                        fillColor: colors.surfaceSunken,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await _passcodeManager.setPasscode(
                            passController.text.trim(),
                            hint: hintController.text.trim().isEmpty ? null : hintController.text.trim(),
                          );
                          setState(() {
                            _hasPasscode = true;
                            _passcodeHint = hintController.text.trim().isEmpty ? null : hintController.text.trim();
                          });
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                          onSuccess();
                        }
                      },
                      child: const Text(
                        'ذخیره و تایید رمز عبور',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _runManualBackup() async {
    if (kIsWeb) {
      _showToast('پشتیبان‌گیری ابری در نسخه وب پشتیبانی نمی‌شود.', isError: true);
      return;
    }
    if (!_isGoogleConnected) {
      _showToast('ابتدا به حساب گوگل درایو متصل شوید.', isError: true);
      return;
    }

    final hasCode = await _passcodeManager.hasPasscode();
    if (!hasCode) {
      _showPasscodeSheet(onSuccess: _runManualBackup);
      return;
    }

    final passcode = await _passcodeManager.getPasscode();
    if (passcode == null) return;

    setState(() => _isLoading = true);
    try {
      await _driveService.uploadBackup(passcode);
      await _driveService.pruneOldBackups();
      await _fetchBackupList();
      _showToast('پشتیبان با موفقیت ذخیره شد.');
    } catch (e) {
      debugPrint('Backup error: $e');
      _showToast('خطا در پشتیبان‌گیری و آپلود فایل.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRestoreDialog(RemoteBackupMetadata meta) {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final passController = TextEditingController();
        final formKey = GlobalKey<FormState>();
        var localLoading = false;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: colors.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(
                  'بازیابی اطلاعات ☁️',
                  style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold),
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'با بازیابی، تمام اطلاعات فعلی این دستگاه حذف شده و با اطلاعات فایل پشتیبان جایگزین خواهد شد. رمز عبوری که در زمان تهیه این پشتیبان تنظیم کرده بودید را وارد کنید:',
                        style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn', fontSize: 12.5, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      if (_passcodeHint != null) ...[
                        Text(
                          'راهنمای رمز شما: $_passcodeHint',
                          style: TextStyle(color: colors.primary, fontFamily: 'Vazirmatn', fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextFormField(
                        controller: passController,
                        obscureText: true,
                        style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                        decoration: InputDecoration(
                          hintText: 'رمز عبور پشتیبان‌گیری',
                          hintStyle: TextStyle(color: colors.textTertiary),
                          filled: true,
                          fillColor: colors.surfaceSunken,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'رمز عبور را وارد کنید.';
                          }
                          return null;
                        },
                      ),
                      if (localLoading) ...[
                        const SizedBox(height: 16),
                        Center(child: CircularProgressIndicator(color: colors.primary)),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: localLoading ? null : () => Navigator.pop(dialogContext),
                    child: Text('انصراف', style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.medicalRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: localLoading ? null : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => localLoading = true);
                        try {
                          await _driveService.restoreFromCloud(meta.fileId, passController.text.trim());
                          
                          await _passcodeManager.setPasscode(passController.text.trim(), hint: _passcodeHint);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            _showRestoreSuccessOverlay();
                          }
                        } catch (e) {
                          setDialogState(() => localLoading = false);
                          final msg = e.toString();
                          if (msg.contains('رمز عبور نادرست')) {
                            _showToast('رمز عبور بکاپ نادرست است.', isError: true);
                          } else {
                            _showToast('خطا در بازیابی پشتیبان از ابر.', isError: true);
                          }
                        }
                      }
                    },
                    child: const Text('شروع بازیابی', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showRestoreSuccessOverlay() {
    final colors = context.colors;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {},
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: colors.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.check_mark_circled_solid, color: colors.success, size: 54),
                  const SizedBox(height: 16),
                  Text(
                    'بازیابی با موفقیت انجام شد 🎉',
                    style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'برای بارگذاری اطلاعات جدید، اپلیکیشن به صورت خودکار راه‌اندازی مجدد می‌شود.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn', fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      RestartWidget.restart(context);
                    },
                    child: const Text('راه‌اندازی مجدد', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteBackup(RemoteBackupMetadata meta) async {
    setState(() => _isLoading = true);
    try {
      await _driveService.deleteBackup(meta.fileId);
      await _fetchBackupList();
      _showToast('پشتیبان با موفقیت حذف شد.');
    } catch (e) {
      debugPrint('Delete backup error: $e');
      _showToast('خطا در حذف پشتیبان.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      RitmoHaptics.warning();
      RitmoToast.show(context, msg, icon: Icons.error_outline, iconColor: context.colors.medicalRed);
    } else {
      RitmoHaptics.success();
      RitmoToast.show(context, msg, icon: Icons.check_circle_outline, iconColor: context.colors.success);
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '۰ کیلوبایت';
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCard({required Widget child, Color? borderColor}) {
    final colors = context.colors;
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.1) : colors.border),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = context.isDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'پشتیبان‌گیری ابری ☁️',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: colors.textPrimary,
            ),
          ),
          leading: IconButton(
            icon: RitmoIcons.back(context, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            // Background Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDarkMode
                        ? [const Color(0xff08090C), const Color(0xff12141C)]
                        : [colors.background, colors.surfaceSunken],
                  ),
                ),
              ),
            ),
            
            // Content Scroll
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Google Account Status
                  _buildCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'حساب گوگل درایو',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!_isGoogleConnected) ...[
                            Text(
                              'برای پشتیبان‌گیری ابری و بازیابی آسان داده‌ها، باید به حساب گوگل درایو خود متصل شوید.',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: colors.textSecondary,
                                fontSize: 11.5,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '🔒 حریم خصوصی: ما فقط به یک پوشه مخفی اختصاصی ریتمو (appDataFolder) دسترسی داریم و فایل‌های شخصی شما هرگز خوانده یا لمس نخواهند شد.',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: colors.primary,
                                fontSize: 10.5,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isLoading ? null : _connectGoogle,
                              icon: const Icon(CupertinoIcons.link),
                              label: const Text('اتصال به گوگل درایو', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'متصل شده با حساب:',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          color: colors.textTertiary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _googleEmail ?? '',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.medicalRed,
                                    side: BorderSide(color: colors.medicalRed),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isLoading ? null : _disconnectGoogle,
                                  icon: const Icon(CupertinoIcons.power, size: 16),
                                  label: const Text('خروج', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Manual Backup & Password Setting
                  if (_isGoogleConnected) ...[
                    _buildCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'پشتیبان‌گیری دستی',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (!_hasPasscode) ...[
                              Text(
                                'برای اجرای اولین پشتیبان‌گیری، ابتدا باید یک رمز عبور (passcode) امن تعریف کنید.',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  color: colors.textSecondary,
                                  fontSize: 11.5,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _showPasscodeSheet(onSuccess: () {}),
                                icon: const Icon(CupertinoIcons.lock),
                                label: const Text('تنظیم رمز عبور پشتیبان‌گیری', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Icon(CupertinoIcons.checkmark_circle, color: colors.success, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'رمز عبور پشتیبان قبلاً ثبت شده است.',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      color: colors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => _showPasscodeSheet(onSuccess: () => _showToast('رمز عبور جدید با موفقیت تنظیم شد.')),
                                    child: Text('تغییر رمز 🔑', style: TextStyle(color: colors.primary, fontFamily: 'Vazirmatn', fontSize: 11)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isLoading ? null : _runManualBackup,
                                icon: const Icon(CupertinoIcons.cloud_upload),
                                label: const Text('پشتیبان‌گیری اکنون', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Auto Backup settings
                    _buildCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'پشتیبان‌گیری خودکار',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              activeTrackColor: colors.primary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'پشتیبان‌گیری خودکار هفتگی',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'داده‌های شما هفته‌ای یک‌بار در صورت اتصال به Wi-Fi در پس‌زمینه پشتیبان‌گیری می‌شوند.',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  color: colors.textSecondary,
                                  fontSize: 10.5,
                                  height: 1.5,
                                ),
                              ),
                              value: _isWeeklyBackupEnabled,
                              onChanged: _isLoading ? null : _toggleWeeklyBackup,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Remote Backups List
                    _buildCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'لیست نسخه‌های پشتیبان ابری',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_isLoading)
                                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: colors.primary))
                                else
                                  IconButton(
                                    icon: Icon(CupertinoIcons.refresh, color: colors.textSecondary, size: 18),
                                    onPressed: _fetchBackupList,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_remoteBackups.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'هیچ نسخه‌ای یافت نشد. اولین نسخه پشتیبان خود را تهیه کنید.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      color: colors.textTertiary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _remoteBackups.length,
                                itemBuilder: (context, index) {
                                  final meta = _remoteBackups[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceSunken,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: colors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(CupertinoIcons.cloud, color: colors.primary, size: 24),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatDateTime(meta.createdAt),
                                                style: TextStyle(
                                                  fontFamily: 'Vazirmatn',
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'حجم: ${_formatSize(meta.sizeBytes)}',
                                                style: TextStyle(
                                                  fontFamily: 'Vazirmatn',
                                                  color: colors.textSecondary,
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(CupertinoIcons.cloud_download, color: colors.success, size: 20),
                                          onPressed: () => _showRestoreDialog(meta),
                                          tooltip: 'بازیابی',
                                        ),
                                        IconButton(
                                          icon: Icon(CupertinoIcons.trash, color: colors.medicalRed, size: 20),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (dialogCtx) => AlertDialog(
                                                backgroundColor: colors.card,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                title: Text(
                                                  'حذف فایل پشتیبان؟',
                                                  style: TextStyle(
                                                    color: colors.medicalRed,
                                                    fontFamily: 'Vazirmatn',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: Text(
                                                  'آیا مطمئن هستید که می‌خواهید این فایل پشتیبان را از گوگل درایو حذف کنید؟ این عمل غیرقابل بازگشت است.',
                                                  style: TextStyle(
                                                    color: colors.textSecondary,
                                                    fontFamily: 'Vazirmatn',
                                                    fontSize: 13,
                                                    height: 1.5,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dialogCtx, false),
                                                    child: Text('انصراف', style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dialogCtx, true),
                                                    child: Text('بله، حذف کن', style: TextStyle(color: colors.medicalRed, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm ?? false) {
                                              await _deleteBackup(meta);
                                            }
                                          },
                                          tooltip: 'حذف',
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 5. Passcode Warning Card
                  _buildCard(
                    borderColor: colors.warning.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(CupertinoIcons.exclamationmark_triangle_fill, color: colors.warning, size: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'هشدار امنیتی بسیار مهم ⚠️',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontWeight: FontWeight.bold,
                                    color: colors.warning,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'رمز عبوری که برای فایل‌های پشتیبان تنظیم می‌کنید کاملاً مستقل از رمز عبور حساب گوگل شماست. ما این رمز را روی سرور ذخیره نمی‌کنیم؛ بنابراین اگر رمز عبور خود را فراموش کنید، به هیچ عنوان داده‌های شما در دستگاه‌های دیگر قابل بازیابی نخواهند بود.',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Loading overlay
            if (_isLoading)
              ColoredBox(
                color: colors.overlay,
                child: Center(
                  child: CircularProgressIndicator(
                    color: colors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
