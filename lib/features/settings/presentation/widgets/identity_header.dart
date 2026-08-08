import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ritmo/core/app_mode/app_mode_service.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/settings/settings_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:sqflite/sqflite.dart';

/// هدر هویتی پرمیوم iOS 26 — بالای صفحه تنظیمات
/// تعاملی‌سازی کامل: کلیک روی عکس (تغییر آواتار)، کلیک روی حالت برنامه (سوئیچ ساده/کامل)،
/// کلیک روی آمارها (میان‌برهای هوشمند و پیام‌های وضعیت)
class IdentityHeader extends StatefulWidget {
  const IdentityHeader({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<IdentityHeader> createState() => _IdentityHeaderState();
}

class _IdentityHeaderState extends State<IdentityHeader>
    with SingleTickerProviderStateMixin {
  String _userName = 'کاربر ریتمو';
  String _avatarPath = '';
  int _daysWithRitmo = 1;
  int _activeRoutinesCount = 0;
  int _completedTodayCount = 0;
  bool _isSimpleMode = false;
  bool _isLoading = true;
  bool _isPressed = false;

  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _loadIdentityData();
    SettingsService.instance.revision.addListener(_onSettingsChanged);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    SettingsService.instance.revision.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _loadIdentityData();
  }

  Future<void> _loadIdentityData() async {
    try {
      final name = SettingsService.instance.get<String>('user_name');
      if (name.isNotEmpty) {
        _userName = name;
      }

      _avatarPath = SettingsService.instance.get<String>('user_avatar_path');
      _isSimpleMode = AppModeService.instance.isSimple;

      final db = await DatabaseHelper.instance.database;

      final installEpochRes = await db.query(
        'app_settings',
        where: "key = 'first_install_time'",
        limit: 1,
      );

      if (installEpochRes.isNotEmpty) {
        final rawVal = installEpochRes.first['value'] as String?;
        final installEpoch = int.tryParse(rawVal ?? '') ?? DateTime.now().millisecondsSinceEpoch;
        final installDate = DateTime.fromMillisecondsSinceEpoch(installEpoch);
        final diff = DateTime.now().difference(installDate).inDays;
        _daysWithRitmo = diff > 0 ? diff : 1;
      } else {
        _daysWithRitmo = 1;
      }

      final activeRoutines = await db.rawQuery(
        'SELECT COUNT(*) FROM routines WHERE isArchived = 0',
      );
      final cnt = Sqflite.firstIntValue(activeRoutines) ?? 0;
      _activeRoutinesCount = cnt;

      // محاسبه فعالیت‌های تکمیل‌شده امروز
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final completedRes = await db.rawQuery(
        'SELECT COUNT(*) FROM agenda_items WHERE isCompleted = 1 AND dateStr = ?',
        [dateStr],
      );
      _completedTodayCount = Sqflite.firstIntValue(completedRes) ?? 0;
    } catch (e) {
      debugPrint('Error loading identity header: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// باز کردن شیت تعاملی انتخاب عکس پروفایل
  Future<void> _pickAvatar() async {
    RitmoHapticsPolicy.selection();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('ویرایش عکس پروفایل'),
        message: const Text('تصویر جدیدی از گالری انتخاب کنید یا عکس بگیرید.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (picked != null) {
                await SettingsService.instance.set('user_avatar_path', picked.path);
                if (mounted) RitmoToast.show(context, 'عکس پروفایل با موفقیت به‌روزرسانی شد.');
              }
            },
            child: const Text('انتخاب از گالری'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
              if (picked != null) {
                await SettingsService.instance.set('user_avatar_path', picked.path);
                if (mounted) RitmoToast.show(context, 'عکس پروفایل با موفقیت به‌روزرسانی شد.');
              }
            },
            child: const Text('گرفتن عکس جدید (دوربین)'),
          ),
          if (_avatarPath.isNotEmpty)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(ctx);
                await SettingsService.instance.set('user_avatar_path', '');
                if (mounted) RitmoToast.show(context, 'عکس پروفایل حذف شد.');
              },
              child: const Text('حذف عکس پروفایل'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('انصراف'),
        ),
      ),
    );
  }

  /// سگمنت کنترل دو گزینه‌ای انتخاب حالت اپلیکیشن (ساده / کامل)
  Widget _buildAppModeSegmentedControl(RitmoColors colors) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          // ─── حالت ساده (سمت راست در RTL) ───
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (_isSimpleMode) return;
                RitmoHapticsPolicy.selection();
                await AppModeService.instance.set(AppMode.simple);
                setState(() => _isSimpleMode = true);
                if (mounted) RitmoToast.show(context, 'حالت اپلیکیشن به «حالت ساده» تغییر یافت.');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: _isSimpleMode ? colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isSimpleMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.leaf_arrow_circlepath,
                      size: 13,
                      color: _isSimpleMode ? colors.primary : colors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'حالت ساده',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isSimpleMode ? FontWeight.w800 : FontWeight.w500,
                        color: _isSimpleMode ? colors.primary : colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── حالت کامل (سمت چپ در RTL) ───
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (!_isSimpleMode) return;
                RitmoHapticsPolicy.selection();
                await AppModeService.instance.set(AppMode.full);
                setState(() => _isSimpleMode = false);
                if (mounted) RitmoToast.show(context, 'حالت اپلیکیشن به «حالت کامل» تغییر یافت.');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: !_isSimpleMode ? colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isSimpleMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.sparkles,
                      size: 13,
                      color: !_isSimpleMode ? colors.primary : colors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'حالت کامل',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !_isSimpleMode ? FontWeight.w800 : FontWeight.w500,
                        color: !_isSimpleMode ? colors.primary : colors.textSecondary,
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
    );
  }

  String _getMonogram(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'ر';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1);
  }

  bool _isAvatarFileValid(String path) {
    if (path.isEmpty) return false;
    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:') || path.startsWith('data:')) {
      return true;
    }
    if (!kIsWeb) {
      try {
        return File(path).existsSync();
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    if (_isLoading) {
      return _buildSkeleton(colors);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? RitmoMotion.pressScale : 1.0,
        duration: RitmoMotion.press,
        curve: RitmoMotion.enter,
        child: Container(
          // ─── حاشیه گرادیانی n-stroke: لایه بیرونی ───
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [
                colors.brandGradient.first.withValues(alpha: isDark ? 0.75 : 0.5),
                colors.brandGradient.last.withValues(alpha: isDark ? 0.55 : 0.35),
                colors.accent.withValues(alpha: isDark ? 0.4 : 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Container(
            // ─── لایه داخلی: محتوای کارت شیشه‌ای ───
            margin: const EdgeInsets.all(1.5),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // ─── آواتار با قابلیت کلیک مستقیم برای تغییر عکس ───
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: _buildAvatarWithBadge(colors),
                    ),
                    const SizedBox(width: 16),

                    // ─── بخش اطلاعات نام + زیرعنوان ───
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'ویرایش پروفایل و تنظیمات',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textTertiary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.arrow_left,
                                size: 12,
                                color: colors.textTertiary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ─── شورون (دکمه اکشن) ───
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.chevron_left,
                        size: 16,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ─── نوار آمارهای سه‌گانه زنده ───
                Row(
                  children: [
                    Expanded(
                      child: _buildStatChip(
                        icon: CupertinoIcons.calendar_today,
                        label: '${toPersianDigits(_daysWithRitmo)} روز',
                        sublabel: 'همراهی',
                        color: colors.accent,
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatChip(
                        icon: CupertinoIcons.bolt_fill,
                        label: '${toPersianDigits(_activeRoutinesCount)} کار',
                        sublabel: 'فعال',
                        color: colors.primary,
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatChip(
                        icon: CupertinoIcons.checkmark_seal_fill,
                        label: '${toPersianDigits(_completedTodayCount)} ثبت',
                        sublabel: 'امروز',
                        color: const Color(0xFF00C9FF),
                        colors: colors,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── سگمنت کنترل دو گزینه‌ای انتخاب حالت اپلیکیشن ───
                _buildAppModeSegmentedControl(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ساخت آواتار با حلقه هولوگرام و نشان دوربین
  Widget _buildAvatarWithBadge(RitmoColors colors) {
    const double outerSize = 68;
    const double ringWidth = 3.0;
    const double gapWidth = 2.0;
    const double innerSize = outerSize - (ringWidth + gapWidth) * 2;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _ringController,
          builder: (context, child) {
            return Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  transform: GradientRotation(_ringController.value * math.pi * 2),
                  colors: [
                    colors.brandGradient.first,
                    colors.brandGradient.last,
                    colors.accent,
                    colors.brandGradient.first,
                  ],
                  stops: const [0.0, 0.35, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Center(
            child: Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
              ),
              child: _isAvatarFileValid(_avatarPath)
                  ? ClipOval(
                      child: _avatarPath.startsWith('http') || _avatarPath.startsWith('blob:')
                          ? Image.network(
                              _avatarPath,
                              width: innerSize,
                              height: innerSize,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_avatarPath),
                              width: innerSize,
                              height: innerSize,
                              fit: BoxFit.cover,
                            ),
                    )
                  : Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: colors.brandGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          _getMonogram(_userName),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Vazirmatn',
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        // نشان دکمه دوربین کوچک روی لبه آواتار
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.surface,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.camera_fill,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// بج آماری سه‌گانه شیشه‌ای با زیرمتن
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required RitmoColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  /// حالت بارگذاری (اسکلتون)
  Widget _buildSkeleton(RitmoColors colors) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: const Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
