// lib/features/assistant/presentation/day_plan_template_management_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/assistant/logic/day_plan_template_service.dart';
import 'package:ritmo/features/assistant/models/day_plan_models.dart';

class DayPlanTemplateManagementScreen extends StatefulWidget {
  const DayPlanTemplateManagementScreen({super.key});

  @override
  State<DayPlanTemplateManagementScreen> createState() => _DayPlanTemplateManagementScreenState();
}

class _DayPlanTemplateManagementScreenState extends State<DayPlanTemplateManagementScreen> {
  List<DayPlanTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await DayPlanTemplateService.instance.getTemplates();
      setState(() {
        _templates = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        RitmoToast.show(context, 'خطا در بارگذاری قالب‌ها ❌');
      }
    }
  }

  void _renameTemplate(DayPlanTemplate template) {
    final controller = TextEditingController(text: template.name);
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.bg,
          title: const Text('تغییر نام قالب', textAlign: TextAlign.right),
          content: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              hintText: 'نام جدید قالب',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;
                try {
                  await DayPlanTemplateService.instance.renameTemplate(template.id, newName);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    await _loadTemplates();
                    RitmoToast.show(ctx, 'نام قالب تغییر یافت ✏️');
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    RitmoToast.show(ctx, 'خطا در تغییر نام ❌');
                  }
                }
              },
              child: const Text('ثبت'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTemplate(DayPlanTemplate template) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.bg,
          title: const Text('حذف قالب', textAlign: TextAlign.right),
          content: Text(
            'آیا از حذف قالب "${template.name}" مطمئن هستید؟ این عمل غیرقابل بازگشت است.',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                try {
                  await DayPlanTemplateService.instance.deleteTemplate(template.id);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    await _loadTemplates();
                    RitmoToast.show(ctx, 'قالب با موفقیت حذف شد 🗑️');
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    RitmoToast.show(ctx, 'خطا در حذف قالب ❌');
                  }
                }
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  void _viewTemplateItems(DayPlanTemplate template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = ctx.colors;
        return Container(
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'جزئیات قالب: ${template.name}',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: template.items.length,
                      itemBuilder: (context, index) {
                        final item = template.items[index];
                        return Card(
                          color: colors.card,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              item.targetModule == 'worship'
                                  ? CupertinoIcons.moon_stars
                                  : item.targetModule == 'sleep'
                                      ? CupertinoIcons.bed_double
                                      : CupertinoIcons.check_mark_circled,
                              color: colors.goldAccent,
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 14,
                                color: colors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'زمان: ${item.startKind == 'clock' ? (item.startTime ?? '') : item.startKind == 'anchor' ? 'لنگر ${item.anchorEvent}' : 'بعد از فعالیت قبلی'} • مدت: ${item.durationMin ?? 30} دقیقه',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'قالب‌های برنامه‌ریز روز',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _templates.isEmpty
                ? Center(
                    child: Text(
                      'هیچ قالبی ذخیره نشده است. 💾',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : colors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            template.name,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'شامل ${template.items.length} فعالیت • تعداد استفاده: ${template.useCount}',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility_outlined, color: colors.textSecondary, size: 20),
                                onPressed: () => _viewTemplateItems(template),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: colors.textSecondary, size: 20),
                                onPressed: () => _renameTemplate(template),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteTemplate(template),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
