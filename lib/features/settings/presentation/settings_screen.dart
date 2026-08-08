import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/settings/settings_registry.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/utils/ios26_page_route.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_page_scaffold.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/features/profile/presentation/crash_reports_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/appearance_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/assistant_privacy_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/data_backup_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/identity_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/modules_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/notifications_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/security_group_screen.dart';
import 'package:ritmo/features/settings/presentation/settings_search_delegate.dart';
import 'package:ritmo/features/settings/presentation/widgets/identity_header.dart';

/// صفحه اصلی تنظیمات اپلیکیشن با طراحی اختصاصی iOS 26 Inset Grouped
/// به همراه آیکن‌های سه‌بعدی نئونی و انیمیشن ناوبری Depth Parallax
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.onFactoryReset,
    required this.themeRepository,
    required this.localeRepository,
  });

  final VoidCallback onFactoryReset;
  final ThemeRepository themeRepository;
  final LocaleRepository localeRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '۱.۰.۰';
  String _buildNumber = '۱';
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = toPersianDigits(info.version);
          _buildNumber = toPersianDigits(info.buildNumber);
        });
      }
    } catch (_) {}
  }

  void _onVersionTapped() {
    _tapCount++;
    if (_tapCount >= 7) {
      _tapCount = 0;
      Navigator.push(
        context,
        Ios26PageRoute(builder: (_) => const CrashReportsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    final groups = [
      _GroupItem(
        group: SettingsGroup.identity,
        title: 'حساب و هویت',
        subtitle: 'نام، سن، جنسیت و حالت اپلیکیشن (ساده / کامل)',
        icon: CupertinoIcons.person_crop_circle_fill,
        gradient: const [Color(0xFF00C9FF), Color(0xFF92FE9D)],
        pageBuilder: () => const IdentityGroupScreen(),
      ),
      _GroupItem(
        group: SettingsGroup.modules,
        title: 'ماژول‌ها و بخش‌های برنامه',
        subtitle: 'فعال‌سازی، پیکربندی و بازنشانی بخش‌های مختلف',
        icon: CupertinoIcons.square_grid_2x2_fill,
        gradient: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
        pageBuilder: () => const ModulesGroupScreen(),
      ),
      _GroupItem(
        group: SettingsGroup.notifications,
        title: 'اعلان‌ها و یادآوری‌ها',
        subtitle: 'کلید اصلی، ساعات سکوت، تجمیع و تعویق آلارم‌ها',
        icon: CupertinoIcons.bell_fill,
        gradient: const [Color(0xFFFF9966), Color(0xFFFF5E62)],
        pageBuilder: () => const NotificationsGroupScreen(),
      ),
      _GroupItem(
        group: SettingsGroup.appearance,
        title: 'ظاهر و زبان',
        subtitle: 'حالت روشنایی، پالت رنگ، سیاه خالص OLED و زبان',
        icon: CupertinoIcons.paintbrush_fill,
        gradient: const [Color(0xFFDA22FF), Color(0xFF9733EE)],
        pageBuilder: () => AppearanceGroupScreen(
          themeRepository: widget.themeRepository,
          localeRepository: widget.localeRepository,
        ),
      ),
      _GroupItem(
        group: SettingsGroup.assistant,
        title: 'دستیار و روان‌شناسی',
        subtitle: 'هوش مصنوعی، حافظه شناختی و تنظیمات رفتار روان‌شناختی',
        icon: CupertinoIcons.sparkles,
        gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
        pageBuilder: () => const AssistantPrivacyGroupScreen(),
      ),
      _GroupItem(
        group: SettingsGroup.dataBackup,
        title: 'داده و پشتیبان',
        subtitle: 'پشتیبان‌گیری محلی، گزارش خطاها، پاک‌سازی و بازنشانی',
        icon: CupertinoIcons.archivebox_fill,
        gradient: const [Color(0xFF373B44), Color(0xFF4286F4)],
        pageBuilder: () => DataBackupGroupScreen(onFactoryReset: widget.onFactoryReset),
      ),
      _GroupItem(
        group: SettingsGroup.security,
        title: 'امنیت و قفل برنامه',
        subtitle: 'قفل ورود، بیومتریک، مهلت قفل و رمز بخش چرخه',
        icon: CupertinoIcons.lock_shield_fill,
        gradient: const [Color(0xFFFF416C), Color(0xFFFF4B2B)],
        pageBuilder: () => const SecurityGroupScreen(),
      ),
    ];

    return RitmoPageScaffold(
      appBar: RitmoModuleAppBar(
        title: 'پروفایل و تنظیمات',
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showSearch(
                    context: context,
                    delegate: SettingsSearchDelegate(
                      themeRepository: widget.themeRepository,
                      localeRepository: widget.localeRepository,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'جست‌وجو...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── هدر هویتی اختصاصی پرمیوم iOS 26 ───
            IdentityHeader(
              onTap: () {
                Navigator.push(
                  context,
                  Ios26PageRoute(builder: (_) => const IdentityGroupScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            // ─── عنوان بخش دسته‌بندی‌ها ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'دسته‌بندی تنظیمات',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                      fontFamily: 'Vazirmatn',
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── کارت شیشه‌ای گروه‌بندی iOS 26 (Inset Grouped Glass Card) ───
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : colors.border,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: groups.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.border.withValues(alpha: 0.5),
                    indent: 74, // Align with text after icon
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final g = groups[index];
                    final count = SettingsRegistry.userVisibleByGroup(g.group).length;

                    return _Ios26SettingsTile(
                      title: g.title,
                      subtitle: g.subtitle,
                      icon: g.icon,
                      gradient: g.gradient,
                      count: count,
                      onTap: () {
                        Navigator.push(
                          context,
                          Ios26PageRoute(builder: (_) => g.pageBuilder()),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ─── بخش نسخه و کپی‌رایت ───
            Center(
              child: GestureDetector(
                onTap: _onVersionTapped,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        'ریتمو — سبک زندگی منظم و خودآگاه',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نسخه $_version (ساخت $_buildNumber)',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textTertiary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ردیف تنظیمات به سبک اختصاصی iOS 26
class _Ios26SettingsTile extends StatefulWidget {
  const _Ios26SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.count,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final int count;
  final VoidCallback onTap;

  @override
  State<_Ios26SettingsTile> createState() => _Ios26SettingsTileState();
}

class _Ios26SettingsTileState extends State<_Ios26SettingsTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        RitmoHaptics.tap();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isPressed
              ? colors.primary.withValues(alpha: 0.07)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // ─── آیکن سه‌بعدی با هاله‌ی گرادیانی ───
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: LinearGradient(
                  colors: widget.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // ─── متن عنوان و زیرعنوان ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                      fontFamily: 'Vazirmatn',
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ─── بج تعداد تنظیمات و شورون ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: widget.gradient.first.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.gradient.first.withValues(alpha: 0.16),
                  width: 1,
                ),
              ),
              child: Text(
                '${toPersianDigits(widget.count)} تنظیم',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.gradient.first,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              CupertinoIcons.chevron_left,
              size: 16,
              color: colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupItem {
  const _GroupItem({
    required this.group,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.pageBuilder,
  });

  final SettingsGroup group;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Widget Function() pageBuilder;
}
