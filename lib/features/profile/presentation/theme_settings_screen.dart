// صفحهٔ تنظیمات تم با انتخاب پالت و پیش‌نمایش زنده (فاز ۳)
// جایگزین شیت قدیمی انتخاب تم

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_preferences.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_card.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_page_scaffold.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_segmented_control.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({
    super.key,
    required this.themeRepository,
  });

  final ThemeRepository themeRepository;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<ThemePreferences>(
      valueListenable: themeRepository.preferencesNotifier,
      builder: (context, prefs, _) {
        return RitmoPageScaffold(
          appBar: const RitmoModuleAppBar(
            title: 'ظاهر و تم',
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: RitmoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ۱. حالت روشنایی
                Text(
                  'حالت روشنایی',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: RitmoSpacing.sm),
                RitmoSegmentedControl<ThemeMode>(
                  segments: const {
                    ThemeMode.system: 'هماهنگ با سیستم',
                    ThemeMode.light: 'روشن',
                    ThemeMode.dark: 'تاریک',
                  },
                  selected: prefs.mode,
                  onSelected: (mode) async {
                    await themeRepository.updateThemeMode(mode);
                  },
                ),
                const SizedBox(height: RitmoSpacing.xl),

                // ۲. پالت رنگی
                Text(
                  'پالت رنگی',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: RitmoSpacing.sm),
                ...RitmoPalette.all.map((palette) {
                  final isSelected = palette.id == prefs.paletteId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: RitmoSpacing.md),
                    child: _PalettePreviewCard(
                      palette: palette,
                      isSelected: isSelected,
                      onTap: () async {
                        final oldPalette = prefs.paletteId;
                        final success = await themeRepository.updatePalette(palette.id);
                        if (success && context.mounted) {
                          RitmoToast.show(
                            context,
                            'پالت به «${palette.nameFa}» تغییر کرد',
                            icon: Icons.palette_rounded,
                            iconColor: palette.dark.primary,
                            onUndo: () {
                              themeRepository.updatePalette(oldPalette);
                            },
                          );
                        } else if (!success && context.mounted) {
                          RitmoToast.show(
                            context,
                            'ذخیرهٔ تنظیمات ناموفق بود',
                            icon: Icons.error_outline_rounded,
                            iconColor: colors.error,
                          );
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(height: RitmoSpacing.xl),

                // ۳. تنظیمات پیشرفته
                Text(
                  'تنظیمات پیشرفته',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: RitmoSpacing.sm),
                RitmoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          value: prefs.reduceTransparency,
                          onChanged: (val) {
                            themeRepository.updateReduceTransparency(val);
                          },
                          title: Text(
                            'کاهش شفافیت',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          subtitle: Text(
                            'سطوح شیشه‌ای مات می‌شوند. روی گوشی‌های قدیمی‌تر روان‌تر است',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          activeColor: colors.primary,
                        ),
                      ),
                      Divider(color: colors.divider, height: 1),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          value: prefs.trueBlack,
                          onChanged: prefs.mode == ThemeMode.light
                              ? null
                              : (val) {
                                  themeRepository.updateTrueBlack(val);
                                },
                          title: Text(
                            'مشکی مطلق',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: prefs.mode == ThemeMode.light
                                  ? colors.disabled
                                  : colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          subtitle: Text(
                            prefs.mode == ThemeMode.light
                                ? 'فقط در حالت تاریک اثر دارد'
                                : 'در حالت تاریک، پس‌زمینه کاملاً مشکی می‌شود. مناسب نمایشگر AMOLED',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          activeColor: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RitmoSpacing.lg),

                // دکمه بازنشانی
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await themeRepository.resetAppearance();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تنظیمات ظاهر به حالت پیش‌فرض بازگشت'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'بازگرداندن به حالت پیش‌فرض',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.error,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: RitmoSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PalettePreviewCard extends StatelessWidget {
  const _PalettePreviewCard({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  final RitmoPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBrightness = Theme.of(context).brightness;

    return Theme(
      data: RitmoTheme.build(
        palette: palette,
        brightness: activeBrightness,
      ),
      child: Builder(
        builder: (innerContext) {
          final innerColors = innerContext.colors;

          return Semantics(
            label: 'پالت ${palette.nameFa}',
            selected: isSelected,
            button: true,
            child: GestureDetector(
              onTap: () {
                RitmoHapticsPolicy.selection();
                onTap();
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: RitmoMotion.state,
                padding: const EdgeInsets.all(RitmoSpacing.lg),
                decoration: BoxDecoration(
                  color: innerColors.surface,
                  borderRadius: BorderRadius.circular(RitmoRadius.card),
                  border: Border.all(
                    color: isSelected
                        ? innerColors.primary
                        : (activeBrightness == Brightness.dark
                            ? innerColors.border
                            : innerColors.divider),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: activeBrightness == Brightness.dark
                      ? RitmoElevation.none
                      : RitmoElevation.cardLight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with 3 dots & checkmark
                    Row(
                      children: [
                        _ColorDot(color: innerColors.primary),
                        const SizedBox(width: RitmoSpacing.xs),
                        _ColorDot(color: innerColors.accent),
                        const SizedBox(width: RitmoSpacing.xs),
                        _ColorDot(color: innerColors.surfaceElevated),
                        const Spacer(),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: innerColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: innerColors.onPrimary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: RitmoSpacing.md),

                    // Sample Title & Subtitle
                    Text(
                      'نمونه عنوان کارت',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: innerColors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'این پیش‌نمایش نحوه رندر رنگ‌های پالت را نشان می‌دهد',
                      style: TextStyle(
                        fontSize: 12,
                        color: innerColors.textSecondary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: RitmoSpacing.md),

                    // Sample button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: innerColors.primary,
                        borderRadius: BorderRadius.circular(RitmoRadius.field),
                      ),
                      child: Text(
                        'دکمه نمونه',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: innerColors.onPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                    const SizedBox(height: RitmoSpacing.md),

                    // 8 Module color circles
                    Row(
                      children: List.generate(8, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(left: RitmoSpacing.xs),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: innerColors.modules.bySlot(i),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: RitmoSpacing.md),

                    // Name & Tagline
                    Text(
                      '${palette.nameFa} · ${palette.taglineFa}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: innerColors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
    );
  }
}
