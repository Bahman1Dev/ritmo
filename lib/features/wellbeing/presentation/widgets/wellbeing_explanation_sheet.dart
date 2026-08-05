import 'package:flutter/material.dart';
import 'package:ritmo/core/analytics/wellbeing_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/core/widgets/ritmo_sheet_scaffold.dart';

class WellbeingExplanationSheet extends StatelessWidget {
  const WellbeingExplanationSheet({
    super.key,
    required this.index,
  });

  final WellbeingIndex index;

  static void show(BuildContext context, WellbeingIndex index) {
    RitmoSheetScaffold.present(
      context: context,
      title: 'این عدد از کجا آمده؟',
      subtitle: 'تحلیل شفاف اجزای شاخص حال و تعادل',
      builder: (ctx) => WellbeingExplanationSheet(index: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final waterfall = index.waterfall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 1: Waterfall chart
        Text(
          'سهم هر سیگنال از پایهٔ ۵۰',
          style: RitmoTextStyles.cardTitle(colors.textPrimary),
        ),
        const SizedBox(height: RitmoSpacing.md),
        Container(
          padding: const EdgeInsets.all(RitmoSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: BorderRadius.circular(RitmoRadius.card),
          ),
          child: Column(
            children: [
              _buildWaterfallRow(context, 'پایهٔ محاسباتی', 50.0, isBase: true),
              const Divider(height: 16),
              ...index.contributions.map((c) {
                final diff = waterfall[c.signal] ?? 0.0;
                return _buildWaterfallRow(
                  context,
                  _signalName(c.signal),
                  diff,
                  isBase: false,
                );
              }),
              const Divider(height: 16),
              _buildWaterfallRow(
                context,
                'شاخص نهایی',
                index.value ?? 0.0,
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: RitmoSpacing.xl),

        // Section 2: Signal detail rows
        Text(
          'جزئیات سیگنال‌های موجود',
          style: RitmoTextStyles.cardTitle(colors.textPrimary),
        ),
        const SizedBox(height: RitmoSpacing.md),
        ...index.contributions.map((c) => _buildContributionCard(context, c)),

        // Section 3: Missing signals
        if (index.missing.isNotEmpty) ...[
          const SizedBox(height: RitmoSpacing.xl),
          Text(
            'سیگنال‌های با دادهٔ ناکافی',
            style: RitmoTextStyles.cardTitle(colors.textPrimary),
          ),
          const SizedBox(height: RitmoSpacing.md),
          ...index.missing.map((m) => _buildMissingCard(context, m)),
        ],

        const SizedBox(height: RitmoSpacing.xl),

        // Section 4: Generated local summary sentence
        Container(
          padding: const EdgeInsets.all(RitmoSpacing.lg),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(RitmoRadius.card),
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            _generateSummarySentence(),
            style: RitmoTextStyles.body(colors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildWaterfallRow(
    BuildContext context,
    String label,
    double score, {
    bool isBase = false,
    bool isTotal = false,
  }) {
    final colors = context.colors;
    String text;
    Color color = colors.textPrimary;

    if (isBase) {
      text = RitmoNumber.faInt(score);
    } else if (isTotal) {
      text = RitmoNumber.faInt(score);
      color = colors.primary;
    } else {
      final sign = score >= 0 ? '+' : '';
      text = '$sign${RitmoNumber.faInt(score.round())}٪';
      color = score >= 0 ? colors.success : colors.error;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isTotal
                ? RitmoTextStyles.cardTitle(colors.textPrimary)
                : RitmoTextStyles.body(colors.textPrimary),
          ),
        ),
        Text(
          text,
          style: isTotal
              ? RitmoTextStyles.heroNumber(color).copyWith(fontSize: 20)
              : RitmoTextStyles.label(color),
        ),
      ],
    );
  }

  Widget _buildContributionCard(BuildContext context, WellbeingContribution c) {
    final colors = context.colors;
    final confText = c.confidence >= 0.8
        ? 'زیاد'
        : (c.confidence >= 0.5 ? 'متوسط' : 'کم');

    return Container(
      margin: const EdgeInsets.only(bottom: RitmoSpacing.md),
      padding: const EdgeInsets.all(RitmoSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RitmoRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_signalName(c.signal)} — ${RitmoNumber.faInt(c.score)} از ۱۰۰ — وزن ${RitmoNumber.faPercent((c.weight * 100).round())} — ${RitmoNumber.faInt(c.sampleCount)} نمونه — اطمینان $confText',
              style: RitmoTextStyles.caption(colors.textPrimary),
            ),
          ),
          if (c.isAiDerived) ...[
            const SizedBox(width: RitmoSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(RitmoRadius.pill),
              ),
              child: Text(
                'AI',
                style: RitmoTextStyles.badge(colors.textOnColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMissingCard(BuildContext context, WellbeingMissingSignal m) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: RitmoSpacing.md),
      padding: const EdgeInsets.all(RitmoSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(RitmoRadius.card),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_signalName(m.signal)} — ${RitmoNumber.faInt(m.have)} ثبت از ${RitmoNumber.faInt(m.need)} ثبت لازم',
              style: RitmoTextStyles.caption(colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _signalName(WellbeingSignal signal) {
    switch (signal) {
      case WellbeingSignal.sleep:
        return 'خواب';
      case WellbeingSignal.energy:
        return 'انرژی';
      case WellbeingSignal.mood:
        return 'حال';
      case WellbeingSignal.reflection:
        return 'بازتاب';
    }
  }

  String _generateSummarySentence() {
    if (index.contributions.isEmpty) {
      return 'هنوز داده کافی برای تحلیل اثر سیگنال‌ها وجود ندارد.';
    }

    WellbeingContribution? maxPos;
    WellbeingContribution? maxNeg;

    final waterfall = index.waterfall;
    for (final c in index.contributions) {
      final diff = waterfall[c.signal] ?? 0.0;
      if (diff > 0 && (maxPos == null || diff > (waterfall[maxPos.signal] ?? 0.0))) {
        maxPos = c;
      }
      if (diff < 0 && (maxNeg == null || diff < (waterfall[maxNeg.signal] ?? 0.0))) {
        maxNeg = c;
      }
    }

    if (maxPos != null && maxNeg != null) {
      return 'بیشترین اثر مثبت این دو هفته از ${_signalName(maxPos.signal)} بوده، و بیشترین افت از ${_signalName(maxNeg.signal)}.';
    } else if (maxPos != null) {
      return 'بیشترین اثر مثبت این دو هفته از ${_signalName(maxPos.signal)} ثبت شده است.';
    } else if (maxNeg != null) {
      return 'بیشترین افت شاخص این دو هفته متأثر از ${_signalName(maxNeg.signal)} بوده است.';
    }
    return 'سیگنال‌های شما در تعادل نسبی با پایه قرار دارند.';
  }
}
