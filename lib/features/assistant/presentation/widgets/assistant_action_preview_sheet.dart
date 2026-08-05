import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/assistant/logic/assistant_action_registry.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';

class AssistantActionPreviewSheet extends StatelessWidget {

  const AssistantActionPreviewSheet({
    super.key,
    required this.action,
    required this.onSaved,
  });
  final AssistantAction action;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? colors.goldAccent : colors.primary;

    // Build key-value list of payload for user review
    final payloadWidgets = <Widget>[];
    action.payload.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        final keyFa = _translateKey(key);
        payloadWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  keyFa,
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ],
            ),
          ),
        );
      }
    });

    final containerDecoration = isDark
        ? BoxDecoration(
            color: colors.sheetBackground,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colors.goldAccent.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: colors.goldAccent.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 2,
              )
            ],
          )
        : null;

    final detailCardDecoration = isDark
        ? BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.goldAccent.withValues(alpha: 0.15)),
          )
        : null;

    final Widget sheetBody = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: containerDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pull bar
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? colors.goldAccent.withValues(alpha: 0.3) : colors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header Icon and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.type.icon,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'پیش‌نمایش اقدام پیشنهادی',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.title,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Detail Card
          Container(
            decoration: detailCardDecoration,
            child: isDark
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جزئیات اقدام:',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (payloadWidgets.isEmpty)
                          Text(
                            'اقدام شامل داده‌های تکمیلی نیست. برای تایید روی ذخیره کلیک کنید.',
                            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                          )
                        else
                          ...payloadWidgets,
                      ],
                    ),
                  )
                : RitmoTheme.glassCardLight(
                    borderRadius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'جزئیات اقدام:',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (payloadWidgets.isEmpty)
                            Text(
                              'اقدام شامل داده‌های تکمیلی نیست. برای تایید روی ذخیره کلیک کنید.',
                              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                            )
                          else
                            ...payloadWidgets,
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: isDark ? colors.goldAccent.withValues(alpha: 0.35) : colors.border),
                      ),
                    ),
                    child: Text(
                      'انصراف',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close preview
                      AssistantActionRegistry.executeAction(
                        context,
                        action,
                        onSaved,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      action.type == AssistantActionType.openPage ? 'برو به صفحه' : 'تایید و ذخیره',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: isDark ? Colors.black : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: isDark ? sheetBody : RitmoTheme.glassCardLight(
        borderRadius: 30,
        child: sheetBody,
      ),
    );
  }

  String _translateKey(String key) {
    switch (key) {
      case 'title': return 'عنوان';
      case 'description': return 'توضیحات';
      case 'category': return 'دسته‌بندی';
      case 'routineType': return 'نوع روتین';
      case 'timeOfDay': return 'ساعت اجرا';
      case 'goalType': return 'سطح هدف';
      case 'plannedMinutes': return 'مدت زمان برنامه‌ریزی';
      case 'subjectId': return 'شناسه درس';
      case 'topicId': return 'شناسه مبحث';
      case 'courseType': return 'نوع دوره';
      case 'totalSessions': return 'تعداد جلسات';
      case 'sessionDurationMinutes': return 'مدت هر جلسه';
      case 'targetRoute': return 'مسیر صفحه';
      default: return key;
    }
  }
}
