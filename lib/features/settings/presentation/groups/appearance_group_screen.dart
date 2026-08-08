import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/settings/settings_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_page_scaffold.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_segmented_control.dart';
import 'package:ritmo/features/profile/presentation/theme_settings_screen.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_section.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_tile.dart';

class AppearanceGroupScreen extends StatefulWidget {
  const AppearanceGroupScreen({
    super.key,
    required this.themeRepository,
    required this.localeRepository,
  });

  final ThemeRepository themeRepository;
  final LocaleRepository localeRepository;

  @override
  State<AppearanceGroupScreen> createState() => _AppearanceGroupScreenState();
}

class _AppearanceGroupScreenState extends State<AppearanceGroupScreen> {
  String _locale = 'fa';

  @override
  void initState() {
    super.initState();
    _locale = SettingsService.instance.get<String>('locale');
  }

  Future<void> _changeLocale(String loc) async {
    setState(() => _locale = loc);
    await SettingsService.instance.set('locale', loc);
    await widget.localeRepository.updateLocale(Locale(loc));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RitmoPageScaffold(
      appBar: const RitmoModuleAppBar(title: 'ظاهر و زبان'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
        child: Column(
          children: [
            SettingsSection(
              title: 'پوسته و تم',
              children: [
                SettingsTile(
                  title: 'تنظیمات تم و پالت رنگی',
                  subtitle: 'حالت روشنایی، پالت رنگ، کاهش شفافیت و سیاه خالص OLED',
                  leading: Icon(CupertinoIcons.paintbrush_fill, color: colors.primary),
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => ThemeSettingsScreen(
                          themeRepository: widget.themeRepository,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SettingsSection(
              title: 'زبان برنامه',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'انتخاب زبان محیط کاربری',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      RitmoSegmentedControl<String>(
                        selected: _locale,
                        segments: const {
                          'fa': 'فارسی (پیش‌فرض)',
                          'en': 'English',
                        },
                        onSelected: (val) => _changeLocale(val),
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
