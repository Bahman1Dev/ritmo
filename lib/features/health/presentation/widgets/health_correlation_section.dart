import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/health/models/health_models.dart';

class HealthCorrelationSection extends StatelessWidget {

  const HealthCorrelationSection({
    super.key,
    required this.correlations,
  });
  final List<HealthCorrelation> correlations;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Filter correlations to only show those that have calculations (coefficient != null)
    final activeCorrelations = correlations.where((c) => c.coefficient != null).toList();

    return Card(
      color: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تحلیل همبستگی هوشمند سلامت',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'بررسی ارتباط ریاضی بین خواب/انرژی روزانه و مقادیر قند/فشار خون شما در بازه اخیر.',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (activeCorrelations.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'داده‌های ثبت‌شده در بازه اخیر کافی نیست. همبستگی‌ها پس از حداقل ۳ روز ثبت همزمان خواب/انرژی و مقادیر علائم حیاتی ظاهر می‌شوند.',
                    style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeCorrelations.length,
                separatorBuilder: (context, index) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final item = activeCorrelations[index];
                  final coeff = item.coefficient!;

                  // Determine color and icons based on positive/negative correlation
                  var iconColor = colors.success;
                  var correlationIcon = Icons.swap_vert;
                  var typeLabel = 'بدون همبستگی';

                  if (coeff.abs() >= 0.2) {
                    if (coeff > 0) {
                      iconColor = colors.medicalRed;
                      correlationIcon = Icons.trending_up;
                      typeLabel = 'همبستگی مستقیم (مثبت)';
                    } else {
                      iconColor = colors.success;
                      correlationIcon = Icons.trending_down;
                      typeLabel = 'همبستگی معکوس (منفی)';
                    }
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(correlationIcon, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getMetricLabel(item.metric),
                                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.bg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Text(
                                    _toPersianDigits(coeff.toStringAsFixed(2)),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              typeLabel,
                              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: iconColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.insight,
                              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary, height: 1.5),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'توجه: همبستگی ریاضی لزوماً به معنای رابطه علّی مستقیم نیست و رفتارهای زیستی تحت تأثیر فاکتورهای متعددی هستند.',
                      style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMetricLabel(String metric) {
    switch (metric) {
      case 'sugar_energy':
        return 'ارتباط قند خون و سطح انرژی';
      case 'sugar_sleep':
        return 'ارتباط قند خون و کیفیت خواب';
      case 'bp_energy':
        return 'ارتباط فشار خون و سطح انرژی';
      case 'bp_sleep':
        return 'ارتباط فشار خون و کیفیت خواب';
      default:
        return 'همبستگی سلامت';
    }
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
}
