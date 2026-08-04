import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

/// بخش تاشوی «جزئیات امروز» (Today Details Section)
/// شامل خلاصه‌ی ماژول‌ها، بازتاب روزانه، بررسی میان‌روز و پیش‌نمایش اینباکس.
/// پیش‌فرض بسته است و با انیمیشن RitmoMotion باز/بسته می‌شود.
class TodayDetailsSection extends StatefulWidget {
  const TodayDetailsSection({
    super.key,
    required this.itemCount,
    required this.children,
    this.initialExpanded = false,
  });

  final int itemCount;
  final List<Widget> children;
  final bool initialExpanded;

  @override
  State<TodayDetailsSection> createState() => _TodayDetailsSectionState();
}

class _TodayDetailsSectionState extends State<TodayDetailsSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = RitmoMotion.effective(context, RitmoMotion.normal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _isExpanded,
          label: 'جزئیات امروز، ${_isExpanded ? "باز شده" : "بسته شده"}',
          child: InkWell(
            onTap: () {
              RitmoHaptics.tap();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(RitmoRadius.card),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: RitmoSpacing.md,
                vertical: RitmoSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(RitmoRadius.card),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: colors.iconSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: RitmoSpacing.sm),
                  Text(
                    'جزئیات امروز',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.sectionTitle,
                    ),
                  ),
                  const SizedBox(width: RitmoSpacing.xs),
                  Text(
                    '(${toPersianDigits(widget.itemCount.toString())})',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: duration,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        AnimatedSize(
          duration: duration,
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: RitmoSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.children,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
