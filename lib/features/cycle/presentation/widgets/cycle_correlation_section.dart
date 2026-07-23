import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/cycle/logic/cycle_correlation.dart';
import 'package:ritmo/features/cycle/models/cycle_models.dart';

class CycleCorrelationSection extends StatefulWidget {
  const CycleCorrelationSection({super.key});

  @override
  State<CycleCorrelationSection> createState() => _CycleCorrelationSectionState();
}

class _CycleCorrelationSectionState extends State<CycleCorrelationSection> {
  bool _loading = true;
  List<CycleCorrelation> _correlations = [];

  @override
  void initState() {
    super.initState();
    _loadCorrelations();
  }

  Future<void> _loadCorrelations() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final corrs = await CycleCorrelationAnalyzer.analyzeCorrelations(db);
      if (mounted) {
        setState(() {
          _correlations = corrs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xffEC4899)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Disclaimer Card
        RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(CupertinoIcons.info_circle_fill, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'توجه: همبستگی‌های نمایش داده شده صرفاً آماری بوده و به معنی رابطه علّی و معلولی قطعی نیست.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      fontFamily: 'Vazirmatn',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // List of correlations
        ..._correlations.map((corr) {
          final coeff = corr.coefficient;
          final hasCoeff = coeff != null;

          Color indicatorColor = Colors.grey;
          var strengthText = 'داده کافی نیست';
          if (hasCoeff) {
            if (coeff.abs() > 0.6) {
              indicatorColor = const Color(0xffEC4899);
              strengthText = coeff > 0 ? 'همبستگی مستقیم قوی' : 'همبستگی معکوس قوی';
            } else if (coeff.abs() > 0.3) {
              indicatorColor = Colors.amber;
              strengthText = coeff > 0 ? 'همبستگی مستقیم ملایم' : 'همبستگی معکوس ملایم';
            } else {
              indicatorColor = Colors.green;
              strengthText = 'بدون نوسان همبسته';
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RitmoTheme.glassCardLight(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          corr.metric,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: indicatorColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            strengthText,
                            style: TextStyle(
                              fontSize: 14,
                              color: indicatorColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    if (hasCoeff)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              'ضریب پیرسون: ',
                              style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                            ),
                            Text(
                              _toPersianDigits(coeff.toStringAsFixed(2)),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : colors.textPrimary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      corr.insight,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

      ],
    );
  }
}
