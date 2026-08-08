import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/modules/module_registry.dart';
import 'package:ritmo/core/services/module_management_service.dart';
import 'package:ritmo/core/settings/settings_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_page_scaffold.dart';
import 'package:ritmo/features/settings/presentation/widgets/settings_section.dart';

class ModulesGroupScreen extends StatefulWidget {
  const ModulesGroupScreen({super.key});

  @override
  State<ModulesGroupScreen> createState() => _ModulesGroupScreenState();
}

class _ModulesGroupScreenState extends State<ModulesGroupScreen> {
  final Map<String, bool> _moduleStates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  void _loadModules() {
    setState(() {
      for (final mod in ModuleRegistry.modules) {
        _moduleStates[mod.key] = SettingsService.instance.get<bool>(mod.key);
      }
      _isLoading = false;
    });
  }

  Future<void> _toggleModule(ModuleDescriptor mod, bool val) async {
    if (mod.key == 'module_medicine_enabled' && !val) {
      final confirmed = await _showMedicineWarningDialog();
      if (!confirmed) return;
    }

    setState(() {
      _moduleStates[mod.key] = val;
    });

    await ModuleManagementService.instance.setModuleEnabled(mod.key, val);
    await SettingsService.instance.set(mod.key, val);
  }

  Future<bool> _showMedicineWarningDialog() async {
    final colors = context.colors;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'هشدار پزشکی و دارویی',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        content: Text(
          'با غیرفعال کردن ماژول دارو، کلیه یادآوری‌های مصرف دارو لغو می‌شوند. آیا از قطع یادآوری‌های دارویی اطمینان دارید؟',
          style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('انصراف', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('غیرفعال کن', style: TextStyle(color: colors.medicalRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _confirmAndResetModule(String key, String title) async {
    final colors = context.colors;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'بازنشانی داده‌های ماژول',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        content: Text(
          'آیا از پاک کردن تمام داده‌ها و سوابق ماژول «$title» اطمینان دارید؟ این عمل غیرقابل بازگشت است.',
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
              await ModuleManagementService.instance.resetModuleData(key);
              if (mounted) {
                RitmoToast.show(context, 'داده‌های ماژول «$title» با موفقیت بازنشانی شدند.');
              }
            },
            child: Text('پاک‌سازی داده‌ها', style: TextStyle(color: colors.medicalRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final gender = SettingsService.instance.get<String>('user_gender');
    final isFemale = CyclePrivacyGuard.isVisible({'user_gender': gender});

    final visibleModules = ModuleRegistry.modules.where((m) {
      if (m.key == 'module_cycle_enabled' && !isFemale) {
        return false;
      }
      return true;
    }).toList();

    return RitmoPageScaffold(
      appBar: const RitmoModuleAppBar(title: 'ماژول‌ها و بخش‌های برنامه'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
              child: SettingsSection(
                title: 'انتخاب بخش‌های فعال',
                footer: 'ماژول‌های غیرفعال از نوار پایین، داشبورد و اعلان‌های روزانه پنهان خواهند شد.',
                children: visibleModules.map((mod) {
                  final isEnabled = _moduleStates[mod.key] ?? mod.defaultEnabled;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            mod.icon,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mod.titleFa,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mod.oneLineFa,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (mod.isCore) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'همیشه فعال',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ] else ...[
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _confirmAndResetModule(mod.key, mod.titleFa),
                            child: Icon(
                              CupertinoIcons.arrow_counterclockwise,
                              size: 18,
                              color: colors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          CupertinoSwitch(
                            value: isEnabled,
                            activeTrackColor: colors.primary,
                            onChanged: (val) => _toggleModule(mod, val),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
