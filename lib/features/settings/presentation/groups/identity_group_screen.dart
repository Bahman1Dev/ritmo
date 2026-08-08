import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ritmo/core/app_mode/app_mode_service.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/services/module_management_service.dart';
import 'package:ritmo/core/settings/settings_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_page_scaffold.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_segmented_control.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_section.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_tile.dart';

class IdentityGroupScreen extends StatefulWidget {
  const IdentityGroupScreen({super.key});

  @override
  State<IdentityGroupScreen> createState() => _IdentityGroupScreenState();
}

class _IdentityGroupScreenState extends State<IdentityGroupScreen> {
  late final TextEditingController _nameController;
  String _avatarPath = '';
  String _gender = 'UNSET';
  int _age = 25;
  String _appMode = 'full';
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final name = SettingsService.instance.get<String>('user_name');
    _nameController = TextEditingController(text: name);
    _avatarPath = SettingsService.instance.get<String>('user_avatar_path');
    _gender = SettingsService.instance.get<String>('user_gender');
    _age = SettingsService.instance.get<int>('user_age');
    _appMode = SettingsService.instance.get<String>('app_mode');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('ویرایش عکس پروفایل'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (picked != null) {
                setState(() => _avatarPath = picked.path);
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
                setState(() => _avatarPath = picked.path);
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
                setState(() => _avatarPath = '');
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

  Future<void> _saveName() async {
    final text = _nameController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _nameError = 'نام نمی‌تواند خالی باشد.';
      });
      return;
    }

    setState(() {
      _nameError = null;
    });

    await SettingsService.instance.set('user_name', text);
    if (mounted) {
      RitmoToast.show(context, 'نام با موفقیت ذخیره شد.');
    }
  }

  Future<void> _changeGender(String val) async {
    final upperVal = val.toUpperCase();
    setState(() => _gender = upperVal);
    await SettingsService.instance.set('user_gender', upperVal);
    await SettingsService.instance.set('identity_gender_asked', true);

    if (upperVal == 'FEMALE') {
      await ModuleManagementService.instance.setModuleEnabled('module_cycle_enabled', true);
      await AlarmSchedulerService.scheduleNextAlarms();
    } else {
      await ModuleManagementService.instance.setModuleEnabled('module_cycle_enabled', false);
      await AlarmSchedulerService.scheduleNextAlarms();
    }
  }

  Future<void> _pickAge() async {
    int tempAge = _age;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 250,
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
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text('تأیید', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        setState(() => _age = tempAge);
                        await SettingsService.instance.set('user_age', tempAge);
                        await SettingsService.instance.set('identity_age_asked', true);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(initialItem: _age - 10),
                  onSelectedItemChanged: (index) {
                    tempAge = 10 + index;
                  },
                  children: List.generate(
                    111,
                    (i) => Center(
                      child: Text(
                        toPersianDigits(10 + i),
                        style: TextStyle(
                          fontSize: 18,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _switchAppMode(String mode) async {
    setState(() => _appMode = mode);
    await SettingsService.instance.set('app_mode', mode);
    await AppModeService.instance.set(mode == 'simple' ? AppMode.simple : AppMode.full);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final genderLabels = {
      'MALE': 'آقا (مرد)',
      'FEMALE': 'خانم (زن)',
      'OTHER': 'سایر',
      'male': 'آقا (مرد)',
      'female': 'خانم (زن)',
      'other': 'سایر',
      'UNSET': 'مشخص نشده',
    };

    return RitmoPageScaffold(
      appBar: const RitmoModuleAppBar(title: 'حساب و هویت'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
        child: Column(
          children: [
            SettingsSection(
              title: 'اطلاعات کاربری',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نام و نام خانوادگی',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: _nameController,
                              placeholder: 'نام خود را وارد کنید',
                              style: TextStyle(color: colors.textPrimary, fontSize: 14),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _nameError != null ? colors.medicalRed : colors.border,
                                ),
                              ),
                              onChanged: (_) {
                                if (_nameError != null) {
                                  setState(() => _nameError = null);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            onPressed: _saveName,
                            child: const Text('ذخیره', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      if (_nameError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _nameError!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.medicalRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SettingsTile(
                  title: 'عکس پروفایل',
                  subtitle: _avatarPath.isNotEmpty ? 'عکس اختصاصی انتخاب شده' : 'مونواصلی (پیش‌فرض)',
                  trailing: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(alpha: 0.1),
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    child: _isAvatarFileValid(_avatarPath)
                        ? ClipOval(
                            child: _avatarPath.startsWith('http') || _avatarPath.startsWith('blob:')
                                ? Image.network(
                                    _avatarPath,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_avatarPath),
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : Icon(CupertinoIcons.person_fill, size: 20, color: colors.primary),
                  ),
                  onTap: _pickAvatar,
                ),
                SettingsTile(
                  title: 'جنسیت',
                  subtitle: genderLabels[_gender] ?? _gender,
                  onTap: () {
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (ctx) => CupertinoActionSheet(
                        title: const Text('انتخاب جنسیت'),
                        actions: [
                          CupertinoActionSheetAction(
                            onPressed: () {
                              _changeGender('MALE');
                              Navigator.pop(ctx);
                            },
                            child: const Text('آقا (مرد)'),
                          ),
                          CupertinoActionSheetAction(
                            onPressed: () {
                              _changeGender('FEMALE');
                              Navigator.pop(ctx);
                            },
                            child: const Text('خانم (زن)'),
                          ),
                          CupertinoActionSheetAction(
                            onPressed: () {
                              _changeGender('OTHER');
                              Navigator.pop(ctx);
                            },
                            child: const Text('سایر'),
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('انصراف'),
                        ),
                      ),
                    );
                  },
                ),
                SettingsTile(
                  title: 'سن',
                  subtitle: '${toPersianDigits(_age)} سال',
                  onTap: _pickAge,
                ),
              ],
            ),
            SettingsSection(
              title: 'حالت اپلیکیشن (ساده / کامل)',
              footer: 'حالت ساده فقط روتین‌ها و تایمرها را نمایش می‌دهد و امکانات پیشرفته را مخفی می‌سازد.',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: RitmoSegmentedControl<String>(
                    selected: _appMode,
                    segments: const {
                      'full': 'نسخهٔ کامل',
                      'simple': 'نسخهٔ ساده',
                    },
                    onSelected: (val) => _switchAppMode(val),
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
