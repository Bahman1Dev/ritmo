import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIDeepAnalysisDialog extends StatefulWidget {
  const AIDeepAnalysisDialog({super.key});

  static const String consentKey = 'ai_deep_analysis_consent';

  static Future<bool> checkConsent(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasConsent = prefs.getBool(consentKey) ?? false;
    if (hasConsent) return true;

    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AIDeepAnalysisDialog(),
    );

    return result ?? false;
  }

  @override
  State<AIDeepAnalysisDialog> createState() => _AIDeepAnalysisDialogState();
}

class _AIDeepAnalysisDialogState extends State<AIDeepAnalysisDialog> {
  bool _rememberChoice = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xff1C1F2E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.sparkles, color: Color(0xff06B6D4), size: 22),
            const SizedBox(width: 8),
            Text(
              'حریم خصوصی و پردازش هوشمند 🧠',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تحلیل عمیق الگوهای رفتاری نیازمند بررسی خلاصهٔ غیرشناسایی‌شده از آمارهای تکمیل روتین‌ها، نمرهٔ انرژی و خواب شما توسط دستیار هوش مصنوعی ریتمو است.',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                '🔒 هیچ اطلاعات شخصی مانند نام، شماره همراه یا محتوای یادداشت‌های محرمانه ارسال نمی‌شود و فقط خلاصه آمارهای عددی تحلیل می‌گردد.',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  color: colors.primary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _rememberChoice,
                  activeColor: const Color(0xff06B6D4),
                  onChanged: (val) {
                    setState(() {
                      _rememberChoice = val ?? true;
                    });
                  },
                ),
                Text(
                  'این انتخاب برای تحلیل‌های بعدی ذخیره شود',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                color: colors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_rememberChoice) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(AIDeepAnalysisDialog.consentKey, true);
              }
              if (context.mounted) Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff06B6D4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'تایید و شروع تحلیل',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
