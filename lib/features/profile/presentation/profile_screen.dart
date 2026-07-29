import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/security/app_lock_service.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/services/device_service.dart';
import 'package:ritmo/core/services/module_management_service.dart';
import 'package:ritmo/core/services/foreground_notification_updater.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/services/secure_key_store.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/features/assistant/presentation/day_plan_template_management_screen.dart';
import 'package:ritmo/features/cycle/presentation/cycle_screen.dart';
import 'package:ritmo/features/premium/presentation/premium_upgrade_sheet.dart';
import 'package:ritmo/features/profile/presentation/ai_memory_management_screen.dart';
import 'package:ritmo/features/profile/presentation/backup_screen.dart';
import 'package:ritmo/features/profile/presentation/crash_reports_screen.dart';
import 'package:ritmo/features/profile/presentation/widgets/worship_seasons_sheet.dart';
import 'package:ritmo/features/today/presentation/widgets/realm_management_sheet.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.themeRepository,
    required this.localeRepository,
  });
  final VoidCallback onLogout;
  final ThemeRepository themeRepository;
  final LocaleRepository localeRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _userName = 'بهمن';
  String _userGender = 'UNSET';
  int _userAge = 25;

  String? _avatarPath;

  // Quick status
  String _currentZone = 'کار عمیق';

  // Premium & devices
  bool _isPremium = false;
  int _deviceCount = 1;

  // App-level lock (separate from CycleLockGate)
  bool _appLockEnabled = false;
  bool _appBiometricEnabled = false;
  bool _appUseDeviceLock = false;

  // Notifications
  bool _notifMasterEnabled = true;
  bool _persistentStatusNotificationEnabled = true;
  bool _notifQuietEnabled = false;
  String _notifQuietStart = '00:00';
  String _notifQuietEnd = '07:00';

  // Module switches
  bool _religionEnabled = false;
  bool _cycleEnabled = false;

  bool get _isFemale => CyclePrivacyGuard.isVisible({'user_gender': _userGender});

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    RitmoEvents.routineChanges.addListener(_onRoutineChanges);
  }

  void _onRoutineChanges() {
    if (mounted) {
      _loadProfileData();
    }
  }

  @override
  void dispose() {
    RitmoEvents.routineChanges.removeListener(_onRoutineChanges);
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};

      _userName = settingsMap['user_name'] ?? 'بهمن';
      _userGender = settingsMap['user_gender'] ?? 'UNSET';
      _userAge = int.tryParse(settingsMap['user_age'] ?? '25') ?? 25;
      _avatarPath = settingsMap['user_avatar_path'];

      // Module flags
      _religionEnabled = settingsMap['module_religion_enabled'] == 'true';
      _cycleEnabled = settingsMap['module_cycle_enabled'] == 'true';

      // Premium & lock
      _isPremium = settingsMap['is_premium'] == 'true';
      _appLockEnabled = settingsMap['app_lock_enabled'] == 'true';
      _appBiometricEnabled = settingsMap['app_biometric_enabled'] == 'true';
      _appUseDeviceLock = settingsMap['app_use_device_lock'] == 'true';

      // Notifications
      _notifMasterEnabled = settingsMap['notif_master_enabled'] != 'false';
      _persistentStatusNotificationEnabled = settingsMap['persistent_status_notification_enabled'] != 'false';
      _notifQuietEnabled = settingsMap['notif_quiet_enabled'] == 'true';
      _notifQuietStart = settingsMap['notif_quiet_start'] ?? '00:00';
      _notifQuietEnd = settingsMap['notif_quiet_end'] ?? '07:00';

      // Device count
      final devices = await DeviceService.instance.getRegisteredDevices();
      _deviceCount = devices.isNotEmpty ? devices.length : 1;

      // Resolve active zone name
      final activeZone = await _resolveActiveZone(db, DateTime.now());
      _currentZone = activeZone?['name'] as String? ?? 'خارج از قلمرو';



    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    final colors = context.colors;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildFrostedBottomSheet(
          title: 'عکس پروفایل',
          children: [
            ListTile(
              leading: Icon(CupertinoIcons.photo, color: colors.primary),
              title: const Text('انتخاب از گالری', style: TextStyle(fontFamily: 'Vazirmatn')),
              onTap: () {
                Navigator.pop(context);
                _processImagePick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(CupertinoIcons.camera, color: colors.primary),
              title: const Text('گرفتن عکس با دوربین', style: TextStyle(fontFamily: 'Vazirmatn')),
              onTap: () {
                Navigator.pop(context);
                _processImagePick(ImageSource.camera);
              },
            ),
            if (_avatarPath != null && _avatarPath!.isNotEmpty)
              ListTile(
                leading: const Icon(CupertinoIcons.trash, color: Colors.redAccent),
                title: const Text('حذف عکس فعلی', style: TextStyle(color: Colors.redAccent, fontFamily: 'Vazirmatn')),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfileImage();
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _processImagePick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (kIsWeb) {
        // On web, just save the pickedFile.path directly (which is a blob url or similar)
        await db.insert(
          'app_settings',
          {'key': 'user_avatar_path', 'value': pickedFile.path, 'updatedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        setState(() {
          _avatarPath = pickedFile.path;
        });
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final localPath = p.join(directory.path, filename);
      
      final localImage = await File(pickedFile.path).copy(localPath);

      await db.insert(
        'app_settings',
        {'key': 'user_avatar_path', 'value': localImage.path, 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (_avatarPath != null && _avatarPath!.isNotEmpty) {
        final oldFile = File(_avatarPath!);
        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (e) {
            debugPrint('Failed to delete old avatar: $e');
          }
        }
      }

      setState(() {
        _avatarPath = localImage.path;
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _deleteProfileImage() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('app_settings', where: 'key = ?', whereArgs: ['user_avatar_path']);

      if (!kIsWeb && _avatarPath != null && _avatarPath!.isNotEmpty) {
        final file = File(_avatarPath!);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            debugPrint('Failed to delete avatar file: $e');
          }
        }
      }

      setState(() {
        _avatarPath = null;
      });
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.65, // Starts at 65% of screen height
      minChildSize: 0.4,     // Can be dragged down to 40%
      expand: false,          // Allows starting at initialChildSize instead of forcing full screen
      snap: true,
      snapSizes: const [0.65, 1.0],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: RitmoTheme.glassCardLight(
              blurSigma: 24,
              borderRadius: 30,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                left: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                right: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Grab Handle
                    Center(
                      child: Container(
                        height: 5,
                        width: 40,
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading) ...[
                      // Avatar & Username Skeleton
                      const Row(
                        children: [
                          RitmoSkeleton(width: 64, height: 64, borderRadius: 32),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RitmoSkeleton(width: 120, height: 16, borderRadius: 4),
                              SizedBox(height: 8),
                              RitmoSkeleton(width: 80, height: 12, borderRadius: 4),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Stats Cards Skeleton
                      const Row(
                        children: [
                          Expanded(child: RitmoSkeletonCard(height: 80)),
                          SizedBox(width: 12),
                          Expanded(child: RitmoSkeletonCard(height: 80)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Settings Items Skeletons
                      const RitmoSkeletonList(itemCount: 4, itemHeight: 56),
                    ] else ...[
                      // Header Info (Avatar & Name)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickProfileImage,
                            child: Stack(
                              children: [
                                Container(
                                  height: 64,
                                  width: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.primary.withValues(alpha: 0.25),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                        border: Border.all(color: colors.primary, width: 2),
                                        image: DecorationImage(
                                          image: (_avatarPath != null && _avatarPath!.isNotEmpty)
                                              ? (kIsWeb
                                                  ? NetworkImage(_avatarPath!)
                                                  : (File(_avatarPath!).existsSync()
                                                      ? FileImage(File(_avatarPath!)) as ImageProvider
                                                      : const NetworkImage('https://picsum.photos/100/100')))
                                              : const NetworkImage('https://picsum.photos/100/100'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark ? const Color(0xff1C1F2E) : Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.camera_fill,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showPersonalInfoSheet,
                                  behavior: HitTestBehavior.opaque,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'مشاهده پروفایل و حساب کاربری',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.textSecondary,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(color: colors.border, height: 32),

                          // 1. Account Section
                          SettingsGroup(
                            title: 'بخش حساب',
                            children: [
                              SettingsRow(
                                icon: CupertinoIcons.person,
                                iconColor: const Color(0xff5B8AF5),
                                title: 'پروفایل من',
                                value: _userName,
                                onTap: _showPersonalInfoSheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.device_phone_portrait,
                                iconColor: const Color(0xff9B89FF),
                                title: 'مدیریت دستگاه‌ها',
                                value: '$_deviceCount دستگاه',
                                onTap: _showDevicesSheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.sparkles,
                                iconColor: const Color(0xffF5B95B),
                                title: 'پریمیوم ریتمو',
                                value: _isPremium ? '👑 فعال' : 'خرید اشتراک',
                                onTap: _showPremiumUpgradeSheet,
                              ),
                            ],
                          ),

                          // 2. Life System Section
                          SettingsGroup(
                            title: 'بخش سیستم زندگی',
                            children: [
                              SettingsRow(
                                icon: CupertinoIcons.clock,
                                iconColor: const Color(0xff5B8AF5),
                                title: 'قلمروهای زمانی',
                                value: _currentZone,
                                onTap: _showZonesManagementSheet,
                              ),
                              if (_religionEnabled)
                                SettingsRow(
                                  icon: CupertinoIcons.sun_haze,
                                  iconColor: const Color(0xffEC4899),
                                  title: 'مناسبت‌های عبادتی سفارشی',
                                  onTap: _showWorshipSeasonsSheet,
                                ),
                              if (_isFemale && _cycleEnabled)
                                SettingsRow(
                                  icon: CupertinoIcons.waveform_path_ecg,
                                  iconColor: const Color(0xffF43F5E),
                                  title: 'چرخه بدن و هماهنگی',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CycleScreen(),
                                      ),
                                    ).then((_) {
                                      _loadProfileData();
                                    });
                                  },
                                ),
                            ],
                          ),

                          // 3. Settings Section
                          SettingsGroup(
                            title: 'بخش برنامه',
                            children: [
                              SettingsRow(
                                icon: Icons.diamond,
                                iconColor: const Color(0xffFFA500),
                                title: 'وضعیت اشتراک',
                                value: PremiumService.instance.isPremium 
                                    ? (PremiumService.instance.purchaseType == 'premium_lifetime' 
                                        ? 'پرمیوم دائمی 💎' 
                                        : 'پرمیوم (تا ${_formatExpiryDate(PremiumService.instance.expiryDateMs)}) 💎')
                                    : 'نسخه رایگان',
                                onTap: () {
                                  PremiumUpgradeSheet.show(context).then((_) {
                                    if (context.mounted) setState(() {});
                                  });
                                },
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.globe,
                                iconColor: const Color(0xff34D399),
                                title: 'تنظیمات عمومی و زبان',
                                value: 'فارسی',
                                onTap: _showLanguageSheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.bell,
                                iconColor: const Color(0xffE5736B),
                                title: 'اعلان‌ها و یادآوری‌ها',
                                onTap: _showNotificationsSheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.sparkles,
                                iconColor: const Color(0xffEC4899),
                                title: 'تنظیمات هوش مصنوعی (AI)',
                                onTap: _showAiSettingsSheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.folder_open,
                                iconColor: const Color(0xffF59E0B),
                                title: 'قالب‌های برنامه‌ریز روز',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(builder: (context) => const DayPlanTemplateManagementScreen()),
                                  );
                                },
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.color_filter,
                                iconColor: const Color(0xff5B8AF5),
                                title: 'ظاهر و تم برنامه',
                                value: isDark ? 'پریمیوم تاریک' : 'پریمیوم روشن',
                                onTap: _showAppearanceSheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.cloud,
                                iconColor: const Color(0xff9B89FF),
                                title: 'پشتیبان‌گیری و بازیابی',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BackupScreen()),
                                  );
                                },
                              ),
                            ],
                          ),

                          // 4. Security Section
                          SettingsGroup(
                            title: 'بخش امنیت',
                            children: [
                              SettingsRow(
                                icon: CupertinoIcons.lock,
                                iconColor: const Color(0xff5B8AF5),
                                title: 'رمز عبور',
                                onTap: _showPasswordLockSheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.rectangle_grid_1x2,
                                iconColor: const Color(0xff34D399),
                                title: 'اثر انگشت',
                                onTap: _showFingerprintSheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.shield,
                                iconColor: const Color(0xffE5736B),
                                title: 'حریم خصوصی',
                                onTap: _showPrivacySheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.trash,
                                iconColor: const Color(0xffE5736B),
                                title: 'حذف تاریخچه اعلان‌ها',
                                onTap: _deleteNotificationHistory,
                              ),
                            ],
                          ),

                          // 5. Support & Other Section
                          SettingsGroup(
                            title: 'بخش پشتیبانی و دیگر',
                            children: [
                              SettingsRow(
                                icon: CupertinoIcons.chat_bubble_2,
                                iconColor: const Color(0xffF5B95B),
                                title: 'بازخورد و پیشنهادات',
                                onTap: _showFeedbackSheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.question_circle,
                                iconColor: const Color(0xff5B8AF5),
                                title: 'راهنما و آموزش',
                                onTap: _showHelpSheet,
                              ),
                              SettingsRow(
                                icon: CupertinoIcons.info_circle,
                                iconColor: const Color(0xff9B89FF),
                                title: 'درباره ریتمو',
                                value: 'نسخه ۱.۰.۰',
                                onTap: _showAboutSheet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Divider(color: colors.border, height: 1),
                          const SizedBox(height: 8),

                          // Danger Zone
                          _buildLogoutButton(context),
                          const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildLogoutButton(BuildContext context) {
    final colors = context.colors;
    final logoutColor = colors.medicalRed;
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showLogoutConfirmation();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: logoutColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.arrow_right,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'خروج از حساب کاربری',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: logoutColor,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrostedBottomSheet({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xff1C1F2E);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 30,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  fontFamily: 'Vazirmatn',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required Color color,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xff1C1F2E);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff5B8AF5).withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xff5B8AF5) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xff5B8AF5), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonalInfoSheet() {
    final nameEditController = TextEditingController(text: _userName);
    var genderTemp = _userGender;
    var ageTemp = _userAge;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : const Color(0xff1C1F2E);
          
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _buildFrostedBottomSheet(
              title: 'ویرایش اطلاعات شخصی',
              children: [
                const Text('نام شما:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn')),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: nameEditController,
                    style: TextStyle(color: textColor, fontSize: 14, fontFamily: 'Vazirmatn'),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('جنسیت:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn')),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSheetGenderChip('MALE', '👨 مرد', genderTemp, (val) => setSheetState(() => genderTemp = val)),
                    _buildSheetGenderChip('FEMALE', '👩 زن', genderTemp, (val) => setSheetState(() => genderTemp = val)),
                    _buildSheetGenderChip('UNSET', '👤 سایر / نگویم', genderTemp, (val) => setSheetState(() => genderTemp = val)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('سن شما:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn')),
                    Text('$ageTemp سال', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xff5B8AF5), fontFamily: 'Vazirmatn')),
                  ],
                ),
                Slider(
                  value: ageTemp.toDouble(),
                  min: 10,
                  max: 90,
                  divisions: 80,
                  activeColor: const Color(0xff5B8AF5),
                  onChanged: (val) {
                    setSheetState(() => ageTemp = val.round());
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff5B8AF5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final newName = nameEditController.text.trim();
                    if (newName.isNotEmpty) {
                      final db = await DatabaseHelper.instance.database;
                      final now = DateTime.now().millisecondsSinceEpoch;
                      final isFemaleSelected = genderTemp == 'FEMALE';

                      await db.insert('app_settings', {'key': 'user_name', 'value': newName, 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                      await db.insert('app_settings', {'key': 'user_gender', 'value': genderTemp, 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                      await db.insert('app_settings', {'key': 'user_age', 'value': ageTemp.toString(), 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                      if (!isFemaleSelected) {
                        await ModuleManagementService.instance.setModuleEnabled('module_cycle_enabled', false);
                      }

                      await AlarmSchedulerService.scheduleNextAlarms();
                      
                      setState(() {
                        _userName = newName;
                        _userGender = genderTemp;
                        _userAge = ageTemp;
                        if (!isFemaleSelected) {
                          _cycleEnabled = false;
                        }
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('ذخیره تغییرات', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetGenderChip(String value, String label, String activeVal, ValueChanged<String> onTap) {
    final isSelected = activeVal == value;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(value);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff5B8AF5).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xff5B8AF5) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontFamily: 'Vazirmatn')),
      ),
    );
  }

  void _showDevicesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: DeviceService.instance.getRegisteredDevices(),
        builder: (context, snapshot) {
          final devices = snapshot.data ?? [];
          return _buildFrostedBottomSheet(
            title: 'دستگاه‌های ثبت‌شده',
            children: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('هنوز دستگاهی ثبت نشده.', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13), textAlign: TextAlign.center),
                )
              else
                ...devices.map((d) {
                  final isCurrent = d['isCurrent'] == 1;
                  final name = d['deviceName'] as String? ?? 'نامشخص';
                  final platform = d['platform'] as String? ?? '';
                  final model = d['model'] as String? ?? '';
                  final lastMs = d['lastActiveAt'] as int? ?? 0;
                  final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
                  final dateStr = '${lastDate.year}/${lastDate.month.toString().padLeft(2, '0')}/${lastDate.day.toString().padLeft(2, '0')}';
                  final IconData icon;
                  if (platform.toLowerCase().contains('android')) {
                    icon = Icons.phone_android;
                  } else if (platform.toLowerCase().contains('ios')) {
                    icon = Icons.phone_iphone;
                  } else if (platform.toLowerCase().contains('windows') || platform.toLowerCase().contains('macos') || platform.toLowerCase().contains('linux')) {
                    icon = Icons.computer;
                  } else {
                    icon = Icons.devices;
                  }
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(icon, color: isCurrent ? const Color(0xff5B8AF5) : Colors.grey),
                        title: Text('$name${isCurrent ? " (این دستگاه)" : ""}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                        subtitle: Text('$platform • $model\nآخرین فعالیت: $dateStr', style: const TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', height: 1.5)),
                        trailing: isCurrent
                            ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xff34D399), shape: BoxShape.circle))
                            : null,
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xff9AA0AE), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'همگام‌سازی ابری در این نسخه موجود نیست. داده‌ها فقط روی این دستگاه ذخیره می‌شوند.',
                        style: TextStyle(fontSize: 11, color: Color(0xff9AA0AE), height: 1.5, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPremiumUpgradeSheet() {
    final licenseController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final fillBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04);
          final borderCol = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);
          final textCol = isDark ? Colors.white : Colors.black87;
          final hintCol = isDark ? Colors.white38 : Colors.black38;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _buildFrostedBottomSheet(
              title: _isPremium ? 'ریتمو پریمیوم 👑' : 'ارتقا به ریتمو پریمیوم 👑',
              children: [
                if (_isPremium)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xffF5B95B), Color(0xffE8A020)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffE8A020).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.workspace_premium, color: Colors.white, size: 36),
                            SizedBox(height: 8),
                            Text(
                              'عضویت پریمیوم فعال است',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Vazirmatn'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPremiumFeature('🎙️ دستیار هوشمند هوش مصنوعی (AI)'),
                      _buildPremiumFeature('📊 تحلیل‌های رفتاری پیشرفته و شخصی'),
                      _buildPremiumFeature('☁️ پشتیبان‌گیری ابری و همگام‌سازی'),
                      _buildPremiumFeature('🎨 پوسته‌های سفارشی و ظاهر اختصاصی'),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () async {
                          await PremiumService.instance.deactivate();
                          setState(() => _isPremium = false);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('لغو فعال‌سازی', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      const Text(
                        'سیستم‌عامل زندگی خود را هوشمندتر کنید',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      _buildPremiumFeature('🎙️ دستیار هوشمند هوش مصنوعی (AI)'),
                      _buildPremiumFeature('📊 تحلیل‌های رفتاری پیشرفته و شخصی'),
                      _buildPremiumFeature('☁️ پشتیبان‌گیری ابری و همگام‌سازی'),
                      _buildPremiumFeature('🎨 پوسته‌های سفارشی و ظاهر اختصاصی'),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: fillBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderCol),
                        ),
                        child: TextField(
                          controller: licenseController,
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, letterSpacing: 2, color: textCol),
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'کد لایسنس یا پرومو را وارد کنید',
                            hintStyle: TextStyle(color: hintCol, fontFamily: 'Vazirmatn', fontSize: 12, letterSpacing: 0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffF5B95B),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () async {
                          final code = licenseController.text.trim();
                          if (code.isEmpty) return;
                          final ok = await PremiumService.instance.activateWithCode(code);
                          if (ok) {
                            setState(() => _isPremium = true);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'لایسنس با موفقیت فعال شد.',
                                    style: TextStyle(fontFamily: 'Vazirmatn'),
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'لایسنس نامعتبر است.',
                                    style: TextStyle(fontFamily: 'Vazirmatn'),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('فعال‌سازی لایسنس', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xff34D399), size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontFamily: 'Vazirmatn'))),
        ],
      ),
    );
  }

  void _showZonesManagementSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RealmManagementSheet(
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
        onChanged: _loadProfileData,
      ),
    );
  }

  Future<Map<String, dynamic>?> _resolveActiveZone(Database db, DateTime now) async {
    // Check override settings first
    final overrideIdQuery = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['realm_override_id'],
    );
    final overrideUntilQuery = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['realm_override_until_ms'],
    );

    if (overrideIdQuery.isNotEmpty && overrideUntilQuery.isNotEmpty) {
      final overrideId = overrideIdQuery.first['value'] as String?;
      final overrideUntilStr = overrideUntilQuery.first['value'] as String?;
      if (overrideId != null && overrideId.isNotEmpty && overrideUntilStr != null) {
        final overrideUntilMs = int.tryParse(overrideUntilStr) ?? 0;
        if (now.millisecondsSinceEpoch < overrideUntilMs) {
          final zoneQuery = await db.query('zones', where: 'id = ?', whereArgs: [overrideId]);
          if (zoneQuery.isNotEmpty) {
            final zone = Map<String, dynamic>.from(zoneQuery.first);
            zone['isOverride'] = true;
            zone['overrideUntilMs'] = overrideUntilMs;
            return zone;
          }
        }
      }
    }

    final weekday = now.weekday;
    final currentMinutes = now.hour * 60 + now.minute;

    final schedulesRaw = await db.query('zone_schedules');
    final schedules = schedulesRaw.map(Map<String, dynamic>.from).toList();
    for (final sched in schedules) {
      final daysOfWeekStr = sched['daysOfWeek'] as String? ?? '';
      final days = daysOfWeekStr.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toSet();
      if (days.contains(weekday)) {
        final startTimeStr = sched['startTime'] as String? ?? '00:00';
        final endTimeStr = sched['endTime'] as String? ?? '23:59';

        final startParts = startTimeStr.split(':');
        final endParts = endTimeStr.split(':');
        if (startParts.length == 2 && endParts.length == 2) {
          final startMin = (int.tryParse(startParts[0]) ?? 0) * 60 + (int.tryParse(startParts[1]) ?? 0);
          final endMin = (int.tryParse(endParts[0]) ?? 0) * 60 + (int.tryParse(endParts[1]) ?? 0);

          if (currentMinutes >= startMin && currentMinutes <= endMin) {
            final zoneId = sched['zoneId'] as String;
            final zoneQuery = await db.query('zones', where: 'id = ?', whereArgs: [zoneId]);
            if (zoneQuery.isNotEmpty) {
              final zone = Map<String, dynamic>.from(zoneQuery.first);
              zone['startTime'] = startTimeStr;
              zone['endTime'] = endTimeStr;
              return zone;
            }
          }
        }
      }
    }
    return null;
  }



  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          // Adaptive theme tokens
          final fillBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04);
          final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
          final textCol = isDark ? Colors.white : const Color(0xff1C1F2E);
          final dividerCol = isDark ? Colors.white10 : Colors.black12;

          return _buildFrostedBottomSheet(
            title: 'اعلان‌ها و یادآوری‌ها 🔔',
            children: [
              const Text(
                'تنظیمات نحوه ارسال یادآورها و مدیریت ساعات آرامش شما',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Master Switch Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fillBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.bell_fill, color: Color(0xff5B8AF5), size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'فعال‌سازی کل اعلان‌ها',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textCol, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ),
                    CupertinoSwitch(
                      value: _notifMasterEnabled,
                      activeTrackColor: const Color(0xff5B8AF5),
                      onChanged: (val) {
                        setSheetState(() {
                          _notifMasterEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Persistent Status Notification Switch
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fillBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.device_phone_portrait, color: Color(0xff5B8AF5), size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'اعلان همیشگی وضعیت',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textCol, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ),
                    CupertinoSwitch(
                      value: _persistentStatusNotificationEnabled,
                      activeTrackColor: const Color(0xff5B8AF5),
                      onChanged: (val) {
                        setSheetState(() {
                          _persistentStatusNotificationEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_notifMasterEnabled) ...[
                // Notification Categories List Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'دسته یادآوری‌های فعال ریتمو',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol, fontFamily: 'Vazirmatn'),
                      ),
                      const SizedBox(height: 10),
                      _buildNotifCategoryRow(CupertinoIcons.refresh_thin, 'یادآور روتین‌ها', 'اعلان شروع زون‌ها و روتین‌های روزانه', const Color(0xff5B8AF5), textCol),
                      Divider(color: dividerCol, height: 16),
                      _buildNotifCategoryRow(CupertinoIcons.heart, 'پزشکی و داروها', 'اعلان مصرف به موقع داروها', const Color(0xffE5736B), textCol),
                      Divider(color: dividerCol, height: 16),
                      _buildNotifCategoryRow(CupertinoIcons.sparkles, 'دستیار و هوش مصنوعی', 'گزارش‌های رفتاری و پیشنهادات هوشمند', const Color(0xff9B89FF), textCol),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quiet Hours Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.moon_fill, color: Color(0xffF5B95B), size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'حالت مزاحم نشوید (ساعات سکوت)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textCol, fontFamily: 'Vazirmatn'),
                              ),
                            ],
                          ),
                          CupertinoSwitch(
                            value: _notifQuietEnabled,
                            activeTrackColor: const Color(0xff5B8AF5),
                            onChanged: (val) {
                              setSheetState(() {
                                _notifQuietEnabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_notifQuietEnabled) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final parsed = _parseTimeOfDay(_notifQuietStart);
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: parsed,
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: isDark
                                              ? const ColorScheme.dark(primary: Color(0xff5B8AF5), surface: Color(0xff1A1D29))
                                              : const ColorScheme.light(primary: Color(0xff5B8AF5)),
                                        ),
                                        child: Directionality(textDirection: TextDirection.rtl, child: child!),
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      _notifQuietStart = _formatTimeOfDay(picked);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderCol),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('شروع سکوت', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Vazirmatn')),
                                      const SizedBox(height: 4),
                                      Text(
                                        _toPersianDigits(_notifQuietStart),
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol, fontFamily: 'Vazirmatn'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final parsed = _parseTimeOfDay(_notifQuietEnd);
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: parsed,
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: isDark
                                              ? const ColorScheme.dark(primary: Color(0xff5B8AF5), surface: Color(0xff1A1D29))
                                              : const ColorScheme.light(primary: Color(0xff5B8AF5)),
                                        ),
                                        child: Directionality(textDirection: TextDirection.rtl, child: child!),
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      _notifQuietEnd = _formatTimeOfDay(picked);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderCol),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('پایان سکوت', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Vazirmatn')),
                                      const SizedBox(height: 4),
                                      Text(
                                        _toPersianDigits(_notifQuietEnd),
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol, fontFamily: 'Vazirmatn'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff5B8AF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () async {
                  final db = await DatabaseHelper.instance.database;
                  final now = DateTime.now().millisecondsSinceEpoch;
                  
                  await db.insert('app_settings', {'key': 'notif_master_enabled', 'value': _notifMasterEnabled.toString(), 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                  await db.insert('app_settings', {'key': 'persistent_status_notification_enabled', 'value': _persistentStatusNotificationEnabled.toString(), 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                  await db.insert('app_settings', {'key': 'notif_quiet_enabled', 'value': _notifQuietEnabled.toString(), 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                  await db.insert('app_settings', {'key': 'notif_quiet_start', 'value': _notifQuietStart, 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                  await db.insert('app_settings', {'key': 'notif_quiet_end', 'value': _notifQuietEnd, 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                  
                  await AlarmSchedulerService.scheduleNextAlarms();
                  await ForegroundNotificationUpdater.update();
                  
                  setState(() {});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تنظیمات اعلان‌ها با موفقیت ذخیره شد.', style: TextStyle(fontFamily: 'Vazirmatn')),
                      ),
                    );
                  }
                },
                child: const Text('ذخیره تغییرات', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotifCategoryRow(IconData icon, String title, String subtitle, Color color, Color textCol) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textCol, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Vazirmatn')),
            ],
          ),
        ),
        const Icon(CupertinoIcons.checkmark_alt, color: Color(0xff34D399), size: 18),
      ],
    );
  }

  void _showAiSettingsSheet() {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return FutureBuilder<Map<String, String>>(
            future: () async {
              final db = await DatabaseHelper.instance.database;
              final settings = await db.query('app_settings');
              return {for (final s in settings) s['key']! as String: s['value']! as String};
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildFrostedBottomSheet(
                  title: 'تنظیمات هوش مصنوعی (AI)',
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(color: Color(0xff5B8AF5))),
                    ),
                  ],
                );
              }
              final settingsMap = snapshot.data ?? {};
              final currentBaseUrl = settingsMap['ai_base_url'] ?? '';
              final currentApiKey = settingsMap['ai_api_key'] ?? '';
              final currentModel = settingsMap['ai_model'] ?? '';

              final currentFeaturesBaseUrl = settingsMap['ai_features_base_url'] ?? '';
              final currentFeaturesApiKey = settingsMap['ai_features_api_key'] ?? '';
              final currentFeaturesModel = settingsMap['ai_features_model'] ?? '';

              final urlController = TextEditingController(text: currentBaseUrl);
              final keyController = TextEditingController(text: currentApiKey);
              final modelController = TextEditingController(text: currentModel);

              final featuresUrlController = TextEditingController(text: currentFeaturesBaseUrl);
              final featuresKeyController = TextEditingController(text: currentFeaturesApiKey);
              final featuresModelController = TextEditingController(text: currentFeaturesModel);

              var obscureKey = true;
              var obscureFeaturesKey = true;
              var briefingEnabled = (settingsMap['assistant_briefing_enabled'] ?? 'true') == 'true';
              var proactiveEnabled = (settingsMap['assistant_proactive_enabled'] ?? 'true') == 'true';

              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: StatefulBuilder(
                  builder: (context, setInnerState) {
                    return _buildFrostedBottomSheet(
                      title: 'تنظیمات هوش مصنوعی (AI)',
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: colors.primary, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'برای هر یک از بخش‌های برنامه (دستیار هوشمند یا سایر ابزارها) می‌توانید سرویس‌دهنده‌های متفاوتی مانند OpenRouter، کلادفلر یا Zhipu AI را جداگانه تنظیم نمایید.',
                                  style: TextStyle(fontSize: 11, height: 1.5, fontFamily: 'Vazirmatn', color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text('۱. تنظیمات هوش مصنوعی دستیار (اصلی و فرعی):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn', color: Colors.tealAccent)),
                        const SizedBox(height: 12),

                        const Text('آدرس Endpoint دستیار (Base URL):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Vazirmatn', color: Colors.white70)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: urlController,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'https://api.cloudflare.com/client/v4/accounts/...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('کلید API دستیار (API Key):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Vazirmatn', color: Colors.white70)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: keyController,
                                  obscureText: obscureKey,
                                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'کلید احراز هویت سرویس‌دهنده دستیار',
                                    hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(obscureKey ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 16, color: Colors.white60),
                                                        onPressed: () {
                                                          setInnerState(() {
                                    obscureKey = !obscureKey;
                                  });
                                                        },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('نام مدل دستیار (Model):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Vazirmatn', color: Colors.white70)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: modelController,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '@cf/zai-org/glm-4.7-flash',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('تنظیمات سریع دستیار (Presets):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Vazirmatn', color: Colors.white60)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: () {
                                setInnerState(() {
                                  urlController.text = 'https://openrouter.ai/api/v1/chat/completions';
                                  modelController.text = 'google/gemma-2-9b-it:free';
                                });
                              },
                              child: const Text('تنظیم OpenRouter 🚀', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Colors.white)),
                            ),
                             OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.tealAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: () {
                                setInnerState(() {
                                  urlController.text = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
                                  modelController.text = 'glm-5.2';
                                });
                              },
                              child: const Text('تنظیم Zhipu AI (智谱) 🇨🇳', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Colors.tealAccent)),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blueAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: () {
                                setInnerState(() {
                                  urlController.text = AIGateway.defaultBaseUrl.isNotEmpty
                                      ? AIGateway.defaultBaseUrl
                                      : 'https://api.cloudflare.com/client/v4/accounts/YOUR_ACCOUNT_ID/ai/v1/chat/completions';
                                  modelController.text = '@cf/zai-org/glm-4.7-flash';
                                });
                              },
                              child: const Text('تنظیم Cloudflare ☁️', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Colors.blueAccent)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(double.infinity, 32),
                          ),
                          onPressed: () {
                            setInnerState(() {
                              urlController.clear();
                              keyController.clear();
                              modelController.clear();
                            });
                          },
                          child: const Text('بازنشانی پیش‌فرض دستیار 🔄', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Colors.redAccent)),
                        ),
                        
                        const Divider(color: Colors.white12, height: 32),
                        const Text('۲. تنظیمات هوش مصنوعی سایر امکانات (خلاصه‌سازی، اهداف و...):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn', color: Colors.amberAccent)),
                        const SizedBox(height: 12),

                        const Text('آدرس Endpoint امکانات (Base URL):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Vazirmatn', color: Colors.white70)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: featuresUrlController,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'https://open.bigmodel.cn/api/paas/v4/chat/completions (پیش‌فرض)',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('کلید API امکانات (API Key):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Vazirmatn', color: Colors.white70)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: featuresKeyController,
                                  obscureText: obscureFeaturesKey,
                                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'پیش‌فرض: فعال با کلید BigModel ثبت‌شده',
                                    hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(obscureFeaturesKey ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 16, color: Colors.white60),
                                onPressed: () {
                                  setInnerState(() {
                                    obscureFeaturesKey = !obscureFeaturesKey;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('نام مدل امکانات (Model):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Vazirmatn', color: Colors.white70)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: featuresModelController,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'glm-4.7-flash (پیش‌فرض)',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('تنظیمات سریع امکانات (Presets):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Vazirmatn', color: Colors.white60)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: () {
                                setInnerState(() {
                                  featuresUrlController.text = 'https://openrouter.ai/api/v1/chat/completions';
                                  featuresModelController.text = 'google/gemma-2-9b-it:free';
                                });
                              },
                              child: const Text('تنظیم OpenRouter 🚀', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Colors.white)),
                            ),
                             OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.tealAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: () {
                                setInnerState(() {
                                  featuresUrlController.text = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
                                  featuresModelController.text = 'glm-5.2';
                                });
                              },
                              child: const Text('تنظیم Zhipu AI (智谱) 🇨🇳', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Colors.tealAccent)),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blueAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: () {
                                setInnerState(() {
                                  featuresUrlController.text = AIGateway.defaultBaseUrl.isNotEmpty
                                      ? AIGateway.defaultBaseUrl
                                      : 'https://api.cloudflare.com/client/v4/accounts/YOUR_ACCOUNT_ID/ai/v1/chat/completions';
                                  featuresModelController.text = '@cf/zai-org/glm-4.7-flash';
                                });
                              },
                              child: const Text('تنظیم Cloudflare ☁️', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Colors.blueAccent)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(double.infinity, 32),
                          ),
                          onPressed: () {
                            setInnerState(() {
                              featuresUrlController.clear();
                              featuresKeyController.clear();
                              featuresModelController.clear();
                            });
                          },
                          child: const Text('بازنشانی پیش‌فرض امکانات 🔄', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Colors.redAccent)),
                        ),

                        const Divider(color: Colors.white12, height: 32),
                        const Text('تنظیمات رفتاری دستیار:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Vazirmatn')),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          activeThumbColor: colors.primary,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('خلاصه روزانه هوشمند (Daily Briefing)', style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn', color: Colors.white)),
                          subtitle: const Text('نمایش وضعیت، آمار و خلاصه‌ای از شرایط روز در تب امروز دستیار', style: TextStyle(fontSize: 10, fontFamily: 'Vazirmatn', color: Colors.white60)),
                          value: briefingEnabled,
                          onChanged: (val) {
                            setInnerState(() {
                              briefingEnabled = val;
                            });
                          },
                        ),
                        SwitchListTile(
                          activeThumbColor: colors.primary,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('پیشنهادهای فعالانه (Proactive Suggestions)', style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn', color: Colors.white)),
                          subtitle: const Text('ارائه بهترین اقدام بعدی و پیشنهادهای داینامیک بر اساس ریتم زندگی شما', style: TextStyle(fontSize: 10, fontFamily: 'Vazirmatn', color: Colors.white60)),
                          value: proactiveEnabled,
                          onChanged: (val) {
                            setInnerState(() {
                              proactiveEnabled = val;
                            });
                          },
                        ),
                        const Divider(color: Colors.white12, height: 32),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          icon: Icon(Icons.psychology, color: colors.primary, size: 18),
                          label: Text(
                            'مدیریت حافظه دستیار 🧠',
                            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => const AiMemoryManagementScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () async {
                            final db = await DatabaseHelper.instance.database;
                            final now = DateTime.now().millisecondsSinceEpoch;

                            final url = urlController.text.trim();
                            final key = keyController.text.trim();
                            final modelVal = modelController.text.trim();

                            final featuresUrl = featuresUrlController.text.trim();
                            final featuresKey = featuresKeyController.text.trim();
                            final featuresModelVal = featuresModelController.text.trim();

                            if (url.isEmpty) {
                              await db.delete('app_settings', where: 'key = ?', whereArgs: ['ai_base_url']);
                            } else {
                              await db.insert('app_settings', {'key': 'ai_base_url', 'value': url, 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                            }

                            if (key.isEmpty) {
                              await SecureKeyStore.deleteKey('ai_api_key');
                            } else {
                              await SecureKeyStore.setKey('ai_api_key', key);
                            }

                            if (modelVal.isEmpty) {
                              await db.delete('app_settings', where: 'key = ?', whereArgs: ['ai_model']);
                            } else {
                              await db.insert('app_settings', {'key': 'ai_model', 'value': modelVal, 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                            }

                            if (featuresUrl.isEmpty) {
                              await db.delete('app_settings', where: 'key = ?', whereArgs: ['ai_features_base_url']);
                            } else {
                              await db.insert('app_settings', {'key': 'ai_features_base_url', 'value': featuresUrl, 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                            }

                            if (featuresKey.isEmpty) {
                              await db.delete('app_settings', where: 'key = ?', whereArgs: ['ai_features_api_key']);
                            } else {
                              await db.insert('app_settings', {'key': 'ai_features_api_key', 'value': featuresKey, 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                            }

                            if (featuresModelVal.isEmpty) {
                              await db.delete('app_settings', where: 'key = ?', whereArgs: ['ai_features_model']);
                            } else {
                              await db.insert('app_settings', {'key': 'ai_features_model', 'value': featuresModelVal, 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                            }

                            await db.insert('app_settings', {'key': 'assistant_briefing_enabled', 'value': briefingEnabled ? 'true' : 'false', 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
                            await db.insert('app_settings', {'key': 'assistant_proactive_enabled', 'value': proactiveEnabled ? 'true' : 'false', 'updatedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تنظیمات هوش مصنوعی با موفقیت ذخیره شد.', style: TextStyle(fontFamily: 'Vazirmatn')),
                                ),
                              );
                            }
                          },
                          child: const Text('ذخیره تنظیمات', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showWorshipSeasonsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const WorshipSeasonsSheet(),
    );
  }

  Future<void> _deleteNotificationHistory() async {
    final colors = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xff1A1D29),
          title: const Text('حذف تاریخچه اعلان‌ها ⚠️', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید تمام تاریخچه ثبت شده اعلان‌ها را برای همیشه حذف کنید؟ این عمل غیرقابل بازگشت است.',
            style: TextStyle(height: 1.6, fontFamily: 'Vazirmatn', color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('خیر، لغو شود', style: TextStyle(color: Color(0xff9AA0AE), fontFamily: 'Vazirmatn')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('بله، حذف کن', style: TextStyle(color: colors.medicalRed, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
            ),
          ],
        ),
      ),
    );

    if (confirm ?? false) {
      try {
        await DatabaseHelper.instance.deleteNotificationHistory();
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تاریخچه اعلان‌ها با موفقیت حذف شد.', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting notification history: $e');
      }
    }
  }

  Future<void> _updateThemeMode(ThemeMode mode) async {
    await widget.themeRepository.updateThemeMode(mode);
    setState(() {});
  }

  void _showAppearanceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final colors = context.colors;
          final currentMode = widget.themeRepository.themeModeNotifier.value;

          return _buildFrostedBottomSheet(
            title: 'تنظیمات ظاهر (تم)',
            children: [
              _buildSheetOption(
                icon: CupertinoIcons.moon_stars_fill,
                color: const Color(0xff9B89FF),
                title: 'تم تاریک پریمیوم',
                isSelected: currentMode == ThemeMode.dark,
                onTap: () async {
                  await _updateThemeMode(ThemeMode.dark);
                  setSheetState(() {});
                },
              ),
              _buildSheetOption(
                icon: CupertinoIcons.sun_max_fill,
                color: const Color(0xffF5B95B),
                title: 'تم روشن',
                isSelected: currentMode == ThemeMode.light,
                onTap: () async {
                  await _updateThemeMode(ThemeMode.light);
                  setSheetState(() {});
                },
              ),
              _buildSheetOption(
                icon: CupertinoIcons.device_phone_portrait,
                color: const Color(0xff5B8AF5),
                title: 'هماهنگ با سیستم',
                isSelected: currentMode == ThemeMode.system,
                onTap: () async {
                  await _updateThemeMode(ThemeMode.system);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('تایید و بستن', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ],
          );
        }
      ),
    );
  }

  String _formatExpiryDate(int ms) {
    if (ms <= 0) return '';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(ms);
      final jalali = Jalali.fromDateTime(date);
      return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ValueListenableBuilder<Locale>(
          valueListenable: widget.localeRepository.localeNotifier,
          builder: (context, currentLocale, _) {
            final isFa = currentLocale.languageCode == 'fa';
            return _buildFrostedBottomSheet(
              title: isFa ? 'تنظیم زبان' : 'Language Settings',
              children: [
                ListTile(
                  title: Text(
                    isFa ? 'فارسی' : 'Persian (Farsi)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isFa ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  trailing: isFa ? const Icon(Icons.check, color: Color(0xff5B8AF5)) : null,
                  onTap: () {
                    widget.localeRepository.updateLocale(const Locale('fa'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(
                    isFa ? 'انگلیسی' : 'English',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: !isFa ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  trailing: !isFa ? const Icon(Icons.check, color: Color(0xff5B8AF5)) : null,
                  onTap: () {
                    widget.localeRepository.updateLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }



  void _showPasswordLockSheet() {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final currentPinController = TextEditingController();

    var sheetStep = 0; // 0: Status/Setup, 1: Setup Ritmo PIN, 3: Change PIN, 4: Disable PIN
    var sheetError = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final colors = context.colors;

          // Adaptive styling tokens
          final fillBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04);
          final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
          final hintCol = isDark ? Colors.white30 : Colors.black38;
          final textCol = isDark ? Colors.white : Colors.black87;
          final iconCol = isDark ? Colors.white54 : Colors.black45;

          Widget buildErrorWidget() {
            if (sheetError.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                sheetError,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Step 0: Main status or setup view
          Widget buildStatusOrSetupView() {
            if (!_appLockEnabled) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'جهت حفاظت از داده‌های شخصی خود در ریتمو، یکی از روش‌های قفل زیر را انتخاب کنید:',
                    style: TextStyle(fontSize: 12, height: 1.6, color: Colors.grey, fontFamily: 'Vazirmatn'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Choice Card 1: Ritmo PIN
                  InkWell(
                    onTap: () {
                      setSheetState(() {
                        sheetStep = 1;
                        sheetError = '';
                        pinController.clear();
                        confirmPinController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: fillBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.number, color: colors.primary, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('پین‌کد اختصاصی ریتمو', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textCol, fontFamily: 'Vazirmatn')),
                                const SizedBox(height: 4),
                                const Text('تنظیم یک رمز عبور ۴ تا ۶ رقمی برای ورود به برنامه', style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Vazirmatn')),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_left, color: iconCol, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Choice Card 2: Device Lock
                  InkWell(
                    onTap: () async {
                      setSheetState(() {
                        sheetError = '';
                      });
                      final supported = await AppLockService.instance.isDeviceSupported();
                      if (!supported) {
                        setSheetState(() {
                          sheetError = 'قفل امنیت در این دستگاه یافت نشد یا در نسخه وب هستید.';
                        });
                        return;
                      }
                      
                      // Authenticate to verify phone lock credentials
                      final ok = await AppLockService.instance.authenticateWithDevice(
                        reason: 'تایید قفل گوشی جهت فعال‌سازی قفل ریتمو',
                        biometricOnly: false,
                      );

                      if (ok) {
                        await AppLockService.instance.setLockEnabled(true);
                        await AppLockService.instance.setUseDeviceLock(true);
                        await AppLockService.instance.setLockPassword(null); // Clear Ritmo PIN
                        
                        setState(() {
                          _appLockEnabled = true;
                          _appUseDeviceLock = true;
                        });
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('قفل امنیت گوشی با موفقیت فعال شد.', style: TextStyle(fontFamily: 'Vazirmatn'))),
                          );
                        }
                      } else {
                        setSheetState(() {
                          sheetError = 'احراز هویت ناموفق بود.';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: fillBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.device_phone_portrait, color: colors.success, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('قفل صفحه گوشی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textCol, fontFamily: 'Vazirmatn')),
                                const SizedBox(height: 4),
                                const Text('ورود سریع با استفاده از رمز عبور، پین یا الگوی فعلی موبایل خود', style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Vazirmatn')),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_left, color: iconCol, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildErrorWidget(),
                ],
              );
            } else {
              final isPinLock = !_appUseDeviceLock;
              return Column(
                children: [
                  Icon(
                    isPinLock ? CupertinoIcons.number : CupertinoIcons.device_phone_portrait,
                    color: colors.success,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPinLock
                        ? 'قفل پین‌کد اختصاصی ریتمو فعال است'
                        : 'قفل با امنیت صفحه گوشی فعال است',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textCol, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPinLock
                        ? 'برای ورود باید پین‌کد اختصاصی را وارد کنید.'
                        : 'برای ورود از پین، الگو یا مشخصات امنیتی گوشی استفاده می‌شود.',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Vazirmatn'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  if (isPinLock) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff5B8AF5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () {
                        setSheetState(() {
                          sheetStep = 3;
                          sheetError = '';
                          currentPinController.clear();
                          pinController.clear();
                          confirmPinController.clear();
                        });
                      },
                      child: const Text('تغییر پین‌کد اختصاصی', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textCol,
                        side: BorderSide(color: borderCol),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () async {
                        setSheetState(() {
                          sheetError = '';
                        });
                        final supported = await AppLockService.instance.isDeviceSupported();
                        if (!supported) {
                          setSheetState(() {
                            sheetError = 'امنیت گوشی در این دستگاه پشتیبانی نمی‌شود.';
                          });
                          return;
                        }
                        
                        final ok = await AppLockService.instance.authenticateWithDevice(
                          reason: 'تایید قفل گوشی برای تغییر روش امنیت',
                          biometricOnly: false,
                        );

                        if (ok) {
                          await AppLockService.instance.setUseDeviceLock(true);
                          await AppLockService.instance.setLockPassword(null);
                          
                          setState(() {
                            _appUseDeviceLock = true;
                          });
                          setSheetState(() {});
                        } else {
                          setSheetState(() {
                            sheetError = 'احراز هویت ناموفق بود.';
                          });
                        }
                      },
                      child: const Text('تغییر روش به قفل صفحه گوشی', style: TextStyle(fontFamily: 'Vazirmatn')),
                    ),
                  ] else ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff5B8AF5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () {
                        setSheetState(() {
                          sheetStep = 1;
                          sheetError = '';
                          pinController.clear();
                          confirmPinController.clear();
                        });
                      },
                      child: const Text('تغییر روش به پین‌کد اختصاصی ریتمو', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                    ),
                  ],
                  
                  const SizedBox(height: 10),
                  
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      setSheetState(() {
                        sheetStep = 4;
                        sheetError = '';
                        currentPinController.clear();
                      });
                    },
                    child: const Text('غیرفعال‌سازی قفل امنیت', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  buildErrorWidget(),
                ],
              );
            }
          }

          // Step 1: Setup Ritmo PIN view
          Widget buildSetupRitmoPinView() {
            return Column(
              children: [
                const Text(
                  'رمز عبور جدید خود را بین ۴ تا ۶ رقم وارد کنید.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: TextField(
                    controller: pinController,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, letterSpacing: 6, color: textCol),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'رمز عبور جدید (۴ تا ۶ رقم)',
                      hintStyle: TextStyle(color: hintCol, letterSpacing: 0, fontFamily: 'Vazirmatn', fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: TextField(
                    controller: confirmPinController,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, letterSpacing: 6, color: textCol),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'تکرار رمز عبور جدید',
                      hintStyle: TextStyle(color: hintCol, letterSpacing: 0, fontFamily: 'Vazirmatn', fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                buildErrorWidget(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff5B8AF5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    final confirm = confirmPinController.text.trim();

                    if (pin.length < 4 || pin.length > 6 || confirm.length < 4 || confirm.length > 6) {
                      setSheetState(() => sheetError = 'رمز عبور باید بین ۴ تا ۶ رقم باشد.');
                      return;
                    }
                    if (pin != confirm) {
                      setSheetState(() => sheetError = 'رمزهای وارد شده همخوانی ندارند.');
                      return;
                    }

                    await AppLockService.instance.setLockEnabled(true);
                    await AppLockService.instance.setLockPassword(pin);
                    await AppLockService.instance.setUseDeviceLock(false);

                    setState(() {
                      _appLockEnabled = true;
                      _appUseDeviceLock = false;
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('قفل پین‌کد با موفقیت فعال شد.', style: TextStyle(fontFamily: 'Vazirmatn'))),
                      );
                    }
                  },
                  child: const Text('فعال‌سازی قفل', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setSheetState(() {
                    sheetStep = 0;
                    sheetError = '';
                  }),
                  child: const Text('بازگشت', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
                ),
              ],
            );
          }

          // Step 3: Change PIN view
          Widget buildChangePinView() {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: TextField(
                    controller: currentPinController,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, letterSpacing: 6, color: textCol),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'رمز عبور فعلی ریتمو',
                      hintStyle: TextStyle(color: hintCol, letterSpacing: 0, fontFamily: 'Vazirmatn', fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: TextField(
                    controller: pinController,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, letterSpacing: 6, color: textCol),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'رمز عبور جدید (۴ تا ۶ رقم)',
                      hintStyle: TextStyle(color: hintCol, letterSpacing: 0, fontFamily: 'Vazirmatn', fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: TextField(
                    controller: confirmPinController,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, letterSpacing: 6, color: textCol),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'تکرار رمز عبور جدید',
                      hintStyle: TextStyle(color: hintCol, letterSpacing: 0, fontFamily: 'Vazirmatn', fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                buildErrorWidget(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff5B8AF5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    final current = currentPinController.text.trim();
                    final pin = pinController.text.trim();
                    final confirm = confirmPinController.text.trim();

                    final correctPin = await AppLockService.instance.getLockPassword();

                    if (current != correctPin) {
                      setSheetState(() => sheetError = 'رمز عبور فعلی نادرست است.');
                      return;
                    }
                    if (pin.length < 4 || pin.length > 6 || confirm.length < 4 || confirm.length > 6) {
                      setSheetState(() => sheetError = 'رمز عبور جدید باید بین ۴ تا ۶ رقم باشد.');
                      return;
                    }
                    if (pin != confirm) {
                      setSheetState(() => sheetError = 'رمزهای جدید وارد شده همخوانی ندارند.');
                      return;
                    }

                    await AppLockService.instance.setLockPassword(pin);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('رمز عبور برنامه با موفقیت تغییر یافت.', style: TextStyle(fontFamily: 'Vazirmatn'))),
                      );
                    }
                  },
                  child: const Text('ثبت رمز جدید', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setSheetState(() {
                    sheetStep = 0;
                    sheetError = '';
                  }),
                  child: const Text('بازگشت', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
                ),
              ],
            );
          }

          // Step 4: Disable PIN view
          Widget buildDisablePinView() {
            final isPinLock = !_appUseDeviceLock;
            
            if (!isPinLock) {
              return Column(
                children: [
                  const Text(
                    'برای غیرفعال‌سازی قفل، لطفاً هویت خود را با امنیت گوشی تایید کنید.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey, fontFamily: 'Vazirmatn'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () async {
                      final ok = await AppLockService.instance.authenticateWithDevice(
                        reason: 'تایید هویت جهت غیرفعال‌سازی قفل امنیت',
                        biometricOnly: false,
                      );
                      
                      if (ok) {
                        await AppLockService.instance.setLockEnabled(false);
                        await AppLockService.instance.setUseDeviceLock(false);
                        await AppLockService.instance.setBiometricEnabled(false);
                        
                        setState(() {
                          _appLockEnabled = false;
                          _appUseDeviceLock = false;
                          _appBiometricEnabled = false;
                        });
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('قفل امنیت با موفقیت غیرفعال شد.', style: TextStyle(fontFamily: 'Vazirmatn'))),
                          );
                        }
                      } else {
                        setSheetState(() {
                          sheetError = 'احراز هویت ناموفق بود.';
                        });
                      }
                    },
                    child: const Text('تایید و غیرفعال‌سازی', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setSheetState(() {
                      sheetStep = 0;
                      sheetError = '';
                    }),
                    child: const Text('بازگشت', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
                  ),
                ],
              );
            }
            
            return Column(
              children: [
                const Text(
                  'جهت غیرفعال‌سازی قفل امنیت، لطفاً پین‌کد فعلی خود را وارد کنید.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: TextField(
                    controller: currentPinController,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, letterSpacing: 6, color: textCol),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'پین‌کد فعلی',
                      hintStyle: TextStyle(color: hintCol, letterSpacing: 0, fontFamily: 'Vazirmatn', fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                buildErrorWidget(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    final current = currentPinController.text.trim();
                    final correctPin = await AppLockService.instance.getLockPassword();

                    if (current != correctPin) {
                      setSheetState(() => sheetError = 'رمز عبور فعلی نادرست است.');
                      return;
                    }

                    await AppLockService.instance.setLockEnabled(false);
                    await AppLockService.instance.setLockPassword(null);
                    await AppLockService.instance.setBiometricEnabled(false);

                    setState(() {
                      _appLockEnabled = false;
                      _appBiometricEnabled = false;
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('قفل برنامه با موفقیت غیرفعال شد.', style: TextStyle(fontFamily: 'Vazirmatn'))),
                      );
                    }
                  },
                  child: const Text('غیرفعال‌سازی', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setSheetState(() {
                    sheetStep = 0;
                    sheetError = '';
                  }),
                  child: const Text('بازگشت', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
                ),
              ],
            );
          }

          Widget viewToShow;
          if (sheetStep == 1) {
            viewToShow = buildSetupRitmoPinView();
          } else if (sheetStep == 3) {
            viewToShow = buildChangePinView();
          } else if (sheetStep == 4) {
            viewToShow = buildDisablePinView();
          } else {
            viewToShow = buildStatusOrSetupView();
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _buildFrostedBottomSheet(
              title: 'قفل امنیت برنامه',
              children: [
                viewToShow,
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFingerprintSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<bool>(
        future: () async {
          if (kIsWeb) return false;
          final auth = LocalAuthentication();
          try {
            final isSupported = await auth.isDeviceSupported();
            final canCheck = await auth.canCheckBiometrics;
            return isSupported && canCheck;
          } catch (_) {
            return false;
          }
        }(),
        builder: (context, snapshot) {
          final isSupported = snapshot.data ?? false;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final colors = context.colors;
          final textCol = isDark ? Colors.white : Colors.black87;

          return StatefulBuilder(
            builder: (context, setSheetState) {
              Widget buildContent() {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: Color(0xff5B8AF5))),
                  );
                }
                
                if (!_appLockEnabled) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'برای فعال‌سازی قفل بیومتریک، ابتدا باید رمز عبور (پین‌کد یا قفل گوشی) را در بخش رمز عبور فعال کنید.',
                                style: TextStyle(fontSize: 12, color: textCol, fontFamily: 'Vazirmatn', height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.border,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: null,
                        child: const Text('قفل امنیت فعال نیست', style: TextStyle(fontFamily: 'Vazirmatn')),
                      ),
                    ],
                  );
                }
                
                if (!isSupported) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                kIsWeb 
                                    ? 'احراز هویت بیومتریک در نسخه وب پشتیبانی نمی‌شود.'
                                    : 'سنسور بیومتریک (اثر انگشت یا تشخیص چهره) در این دستگاه پشتیبانی نمی‌شود یا فعال نیست.',
                                style: TextStyle(fontSize: 12, color: textCol, fontFamily: 'Vazirmatn', height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.border,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: null,
                        child: const Text('بیومتریک غیرقابل استفاده است', style: TextStyle(fontFamily: 'Vazirmatn')),
                      ),
                    ],
                  );
                }
                
                return Column(
                  children: [
                    Icon(
                      _appBiometricEnabled ? Icons.fingerprint : Icons.fingerprint_outlined, 
                      color: _appBiometricEnabled ? const Color(0xff34D399) : colors.textSecondary, 
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _appBiometricEnabled ? 'قفل بیومتریک فعال است.' : 'قفل بیومتریک غیرفعال است.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn', color: textCol),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'با فعال‌سازی این بخش می‌توانید با اثر انگشت یا تشخیص چهره به سرعت وارد ریتمو شوید.',
                      style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5, fontFamily: 'Vazirmatn'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (!_appBiometricEnabled)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.fingerprint, size: 18),
                        label: const Text('فعال‌سازی قفل اثر انگشت / تشخیص چهره', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff5B8AF5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () async {
                          final auth = LocalAuthentication();
                          try {
                            final authenticated = await auth.authenticate(
                              localizedReason: 'تایید اثر انگشت جهت فعال‌سازی قفل ریتمو',
                              persistAcrossBackgrounding: true,
                            );
                            
                            if (authenticated) {
                              await AppLockService.instance.setBiometricEnabled(true);
                              
                              setState(() {
                                _appBiometricEnabled = true;
                              });
                              setSheetState(() {});
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('قفل بیومتریک با موفقیت فعال شد.', style: TextStyle(fontFamily: 'Vazirmatn'))),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('احراز هویت بیومتریک ناموفق بود.', style: TextStyle(fontFamily: 'Vazirmatn'))),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('خطا در احراز هویت: $e', style: const TextStyle(fontFamily: 'Vazirmatn'))),
                              );
                            }
                          }
                        },
                      )
                    else
                      OutlinedButton.icon(
                        icon: const Icon(Icons.lock_open, size: 18),
                        label: const Text('غیرفعال‌سازی قفل اثر انگشت / تشخیص چهره', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () async {
                          await AppLockService.instance.setBiometricEnabled(false);
                          
                          setState(() {
                            _appBiometricEnabled = false;
                          });
                          setSheetState(() {});
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('قفل اثر انگشت غیرفعال شد.', style: TextStyle(fontFamily: 'Vazirmatn'))),
                            );
                          }
                        },
                      ),
                  ],
                );
              }
              
              return _buildFrostedBottomSheet(
                title: 'قفل اثر انگشت / بیومتریک',
                children: [
                  buildContent(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textCol = isDark ? Colors.white : const Color(0xff1C1F2E);
        final fillBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04);
        final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

        return _buildFrostedBottomSheet(
          title: 'حریم خصوصی ریتمو 🛡️',
          children: [
            const Text(
              'حفظ امنیت اطلاعات شخصی شما، پایه و اساس طراحی ریتمو است.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Vazirmatn'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Privacy Point 1
            _buildPrivacyPointItem(
              icon: CupertinoIcons.device_phone_portrait,
              title: 'ذخیره‌سازی کاملاً محلی',
              desc: 'تمامی داده‌های ثبت‌شده در ریتمو فقط روی حافظه گوشی شما ذخیره شده و هرگز به سرورهای ابری منتقل نمی‌شوند.',
              iconColor: const Color(0xff5B8AF5),
              fillBg: fillBg,
              borderCol: borderCol,
              textCol: textCol,
            ),
            const SizedBox(height: 10),

            // Privacy Point 2
            _buildPrivacyPointItem(
              icon: CupertinoIcons.padlock,
              title: 'رمزنگاری پایگاه داده (SQLCipher)',
              desc: 'داده‌های ریتمو با الگوریتم‌های پیشرفته رمزنگاری شده‌اند تا هیچ اپلیکیشن دیگری در دستگاه به آن دسترسی نداشته باشد.',
              iconColor: const Color(0xff34D399),
              fillBg: fillBg,
              borderCol: borderCol,
              textCol: textCol,
            ),
            const SizedBox(height: 10),

            // Privacy Point 3
            _buildPrivacyPointItem(
              icon: CupertinoIcons.eye_slash,
              title: 'هوش مصنوعی محرمانه',
              desc: 'درخواست‌های ارسالی به دستیار هوش مصنوعی بدون اطلاعات هویتی و صرفاً جهت تحلیل رفتاری پردازش می‌شوند.',
              iconColor: const Color(0xff9B89FF),
              fillBg: fillBg,
              borderCol: borderCol,
              textCol: textCol,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff5B8AF5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('متوجه شدم', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrivacyPointItem({
    required IconData icon,
    required String title,
    required String desc,
    required Color iconColor,
    required Color fillBg,
    required Color borderCol,
    required Color textCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fillBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textCol, fontFamily: 'Vazirmatn')),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.5, fontFamily: 'Vazirmatn')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackSheet() {
    final feedbackController = TextEditingController();
    var selectedTag = 'پیشنهاد'; // Default tag

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final colors = context.colors;
          final fillBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04);
          final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
          final textCol = isDark ? Colors.white : Colors.black87;
          final hintCol = isDark ? Colors.white30 : Colors.black38;

          Widget buildTagButton(String label, IconData icon, String tag) {
            final isSelected = selectedTag == tag;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: isSelected ? Colors.white : colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setSheetState(() {
                    selectedTag = tag;
                  });
                }
              },
              backgroundColor: fillBg,
              selectedColor: const Color(0xff5B8AF5),
              labelStyle: TextStyle(color: isSelected ? Colors.white : colors.textSecondary),
              side: BorderSide(color: isSelected ? const Color(0xff5B8AF5) : borderCol),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _buildFrostedBottomSheet(
              title: 'ارسال بازخورد و پیشنهادات',
              children: [
                const Text(
                  'نظرات و گزارش‌های شما به بهبود روزافزون ریتمو کمک می‌کند.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Feedback tags
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildTagButton('گزارش باگ', CupertinoIcons.ant, 'گزارش باگ'),
                    buildTagButton('پیشنهاد', CupertinoIcons.sparkles, 'پیشنهاد'),
                    buildTagButton('نظر عمومی', CupertinoIcons.chat_bubble, 'نظر عمومی'),
                  ],
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    style: TextStyle(fontSize: 13, color: textCol, fontFamily: 'Vazirmatn'),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'جزئیات بازخورد خود را بنویسید...',
                      hintStyle: TextStyle(color: hintCol, fontSize: 12, fontFamily: 'Vazirmatn'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff5B8AF5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    final text = feedbackController.text.trim();
                    if (text.isEmpty) return;
                    
                    final emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'support@ritmoapp.ir',
                      queryParameters: {
                        'subject': '[$selectedTag] بازخورد اپلیکیشن ریتمو',
                        'body': text,
                      },
                    );
                    
                    try {
                      Navigator.pop(context);
                      if (await canLaunchUrl(emailLaunchUri)) {
                        await launchUrl(emailLaunchUri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'برنامه ایمیل یافت نشد. بازخورد کپی شد؛ لطفاً آن را به support@ritmoapp.ir ارسال کنید.',
                                style: TextStyle(fontFamily: 'Vazirmatn'),
                              ),
                              duration: Duration(seconds: 5),
                            ),
                          );
                          await Clipboard.setData(ClipboardData(text: text));
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطا در ارتباط با ایمیل: $e', style: const TextStyle(fontFamily: 'Vazirmatn'))),
                        );
                      }
                    }
                  },
                  child: const Text('ارسال بازخورد', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textCol = isDark ? Colors.white : const Color(0xff1C1F2E);
        final fillBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04);
        final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

        Widget buildAccordionItem({
          required String title,
          required String content,
          required IconData icon,
          required Color color,
        }) {
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: fillBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: ExpansionTile(
                leading: Icon(icon, color: color, size: 20),
                title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textCol, fontFamily: 'Vazirmatn')),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Text(
                      content,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.6, fontFamily: 'Vazirmatn'),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildFrostedBottomSheet(
          title: 'راهنما و آموزش ریتمو 📚',
          children: [
            const Text(
              'سیستم‌عامل زندگی ریتمو چگونه کار می‌کند؟',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Vazirmatn'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            buildAccordionItem(
              title: '۱. روتین‌های روزانه',
              content: 'روتین‌ها قلب تپنده ریتمو هستند. آن‌ها را بر اساس اولویت تنظیم کرده و در ساعات مختلف روز (صبح، ظهر، عصر، شب) تکمیل کنید تا روند بهره‌وری خود را بالا ببرید.',
              icon: CupertinoIcons.arrow_2_circlepath,
              color: const Color(0xff5B8AF5),
            ),
            buildAccordionItem(
              title: '۲. قلمروهای زمانی (Time Realms)',
              content: 'با قلمروهای زمانی می‌توانید روز خود را تفکیک کنید. زون‌های اختصاصی مثل کار عمیق، استراحت یا خانواده مانع تداخل کارها می‌شوند.',
              icon: CupertinoIcons.clock,
              color: const Color(0xff34D399),
            ),
            buildAccordionItem(
              title: '۳. سطح انرژی و خلق روزانه',
              content: 'میزان انرژی و کیفیت روحی خود را ثبت کنید تا الگوریتم‌های هوشمند ریتمو بهترین ساعات بهره‌وری شخصی شما را تحلیل و پیش‌بینی کنند.',
              icon: CupertinoIcons.bolt_fill,
              color: const Color(0xffF5B95B),
            ),
            buildAccordionItem(
              title: '۴. دستیار هوشمند هوش مصنوعی',
              content: 'دستیار AI ریتمو با تحلیل محرمانه رفتار شما، راه‌کارهای عملی و شخصی برای غلبه بر تنبلی و بهبود روتین‌ها ارائه می‌دهد.',
              icon: CupertinoIcons.sparkles,
              color: const Color(0xff9B89FF),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff5B8AF5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('بستن راهنما', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAboutSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          final version = info?.version ?? '۱.۰.۰';
          final buildNumber = info?.buildNumber ?? '۱';
          final appName = info?.appName ?? 'ریتمو';
          
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textCol = isDark ? Colors.white : const Color(0xff1C1F2E);
          final fillBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04);
          final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

          return _buildFrostedBottomSheet(
            title: 'درباره ریتمو ℹ️',
            children: [
              // Logo mock
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff5B8AF5), Color(0xff8FAFF5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff5B8AF5).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(CupertinoIcons.infinite, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Vazirmatn', color: textCol),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'نسخه ${_toPersianDigits(version)} (ساخت ${_toPersianDigits(buildNumber)})',
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fillBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  children: [
                    _buildAboutInfoRow('موتور ذخیره‌سازی', 'ذخیره‌سازی ۱۰۰٪ محلی', textCol),
                    const Divider(color: Colors.white10, height: 16),
                    _buildAboutInfoRow('سیستم‌عامل طراحی', 'iOS 26 Minimalist', textCol),
                    const Divider(color: Colors.white10, height: 16),
                    _buildAboutInfoRow('طراح و توسعه‌دهنده', 'تیم ریتمو', textCol),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CrashReportsScreen()),
                  );
                },
                icon: const Icon(CupertinoIcons.doc_text_search, size: 18),
                label: const Text('مشاهده گزارش‌های فنی خطا', style: TextStyle(fontFamily: 'Vazirmatn')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'ریتمو (Ritmo) - سیستم‌عامل شخصی زندگی شما\nتمامی حقوق محفوظ است.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha: 0.8), height: 1.5, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final url = Uri.parse('https://ritmoapp.ir/privacy');
                  try {
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    debugPrint('Could not launch privacy URL: $e');
                  }
                },
                child: const Text(
                  'سیاست حریم خصوصی ریتمو',
                  style: TextStyle(fontSize: 11, color: Color(0xff5B8AF5), decoration: TextDecoration.underline, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff5B8AF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن شیت', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAboutInfoRow(String label, String value, Color textCol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Vazirmatn')),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol, fontFamily: 'Vazirmatn')),
      ],
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xff1A1D29),
          title: const Text('خروج از حساب کاربری', style: TextStyle(fontFamily: 'Vazirmatn')),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید از سیستم خارج شوید؟ با این کار داده‌های محلی شما پاکسازی می‌شود.',
            style: TextStyle(height: 1.5, fontFamily: 'Vazirmatn'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو', style: TextStyle(color: Color(0xff9AA0AE), fontFamily: 'Vazirmatn')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onLogout();
              },
              child: const Text('خروج', style: TextStyle(color: Color(0xffE5736B), fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {

  const SettingsGroup({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sectionTitleColor = colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 8, top: 18),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: sectionTitleColor,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
        // Flat column containing items
        Column(
          children: children,
        ),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {

  const SettingsRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.value,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xff1C1F2E);
    final secondaryTextColor = isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xff5C6170);
    final iconColorToUse = isDark ? Colors.white.withValues(alpha: 0.75) : const Color(0xff5C6170);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon directly with no background container
            Icon(icon, size: 22, color: iconColorToUse),
            const SizedBox(width: 14),
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
            // Optional Value (like version info, toggles, status, etc.)
            if (value != null) ...[
              Text(
                value!,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Chevron Pointing Left (RTL)
            Icon(
              CupertinoIcons.chevron_left,
              size: 14,
              color: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
