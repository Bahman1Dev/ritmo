import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';

/// نمایش جزئیات یک آیتم برنامه‌ریزی‌شده در یک Bottom Sheet.
///
/// دکمه‌های عملیاتی (تکمیل / رد) فقط برای دامنه‌هایی نمایش داده می‌شوند
/// که مسیر امن اجرا دارند. برای سایر دامنه‌ها، اطلاعاتی‌فقط نمایش داده
/// می‌شود.
class AgendaItemDetailSheet extends StatelessWidget {
  const AgendaItemDetailSheet({
    super.key,
    required this.item,
    this.onComplete,
    this.onSkip,
    this.onFocus,
  });

  final AgendaItem item;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onFocus;

  /// دامنه‌هایی که دکمه‌های عملیاتی را پشتیبانی می‌کنند.
  static const Set<AgendaDomain> _actionableDomains = {
    AgendaDomain.routine,
    AgendaDomain.course,
    AgendaDomain.goalStep,
    AgendaDomain.medicine,
    AgendaDomain.sport,
    AgendaDomain.prayer,
    AgendaDomain.mustahab,
    AgendaDomain.worshipDebt,
    AgendaDomain.cycle,
    AgendaDomain.konkur,
  };

  static Future<void> show(
    BuildContext context, {
    required AgendaItem item,
    VoidCallback? onComplete,
    VoidCallback? onSkip,
    VoidCallback? onFocus,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AgendaItemDetailSheet(
        item: item,
        onComplete: onComplete,
        onSkip: onSkip,
        onFocus: onFocus,
      ),
    );
  }

  String _completionLabel(AgendaCompletion completion) {
    switch (completion) {
      case AgendaCompletion.none:
        return 'نامشخص';
      case AgendaCompletion.pending:
        return 'در انتظار';
      case AgendaCompletion.done:
        return 'انجام‌شده';
      case AgendaCompletion.partial:
        return 'ناقص';
      case AgendaCompletion.skipped:
        return 'رد شده';
      case AgendaCompletion.overdue:
        return 'عقب‌افتاده';
      case AgendaCompletion.missed:
        return 'از دست رفته';
    }
  }

  String _domainLabel(AgendaDomain domain) {
    switch (domain) {
      case AgendaDomain.routine:
        return 'روتین';
      case AgendaDomain.prayer:
        return 'نماز';
      case AgendaDomain.mustahab:
        return 'مستحبات';
      case AgendaDomain.course:
        return 'درس';
      case AgendaDomain.goalStep:
        return 'گام هدف';
      case AgendaDomain.konkur:
        return 'کنکور';
      case AgendaDomain.cycle:
        return 'دوره';
      case AgendaDomain.worshipDebt:
        return 'قضا';
      case AgendaDomain.sport:
        return 'ورزش';
      case AgendaDomain.medicine:
        return 'دارو';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = item.isCompleted;
    final isActionable = _actionableDomains.contains(item.domain);

    // زمان پایان آیتم‌های شب‌هنگام
    String? endTimeStr;
    if (item.isTimed && item.durationMinutes != null) {
      final parts = item.timeOfDay!.split(':');
      if (parts.length == 2) {
        final startH = int.tryParse(parts[0]) ?? 0;
        final startM = int.tryParse(parts[1]) ?? 0;
        final endTotal = (startH * 60) + startM + item.durationMinutes!;
        final endH = (endTotal ~/ 60) % 24;
        final endM = endTotal % 60;
        endTimeStr =
            '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // دستگیره
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // هدر: برچسب دامنه + دکمه بستن
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _domainLabel(item.domain),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.maybePop(context),
                          tooltip: 'بستن',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // عنوان
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Vazirmatn',
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // زمان و مدت
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          item.isTimed
                              ? _buildTimeLabel(item, endTimeStr)
                              : 'تمام‌روز / بدون زمان',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // وضعیت
                    Row(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle
                              : Icons.pending_outlined,
                          size: 18,
                          color: isDone ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'وضعیت: ${_completionLabel(item.completion)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Vazirmatn',
                            color: isDone ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // دکمه‌های عملیاتی
                    Row(
                      children: [
                        if (onFocus != null) ...[
                          Semantics(
                            label: 'نمایش روی تایم‌لاین',
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.maybePop(context);
                                onFocus!();
                              },
                              icon:
                                  const Icon(Icons.center_focus_strong, size: 18),
                              label: const Text('تایم‌لاین',
                                  style: TextStyle(fontFamily: 'Vazirmatn')),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (isActionable && !isDone && onSkip != null) ...[
                          Semantics(
                            label: 'رد کردن این آیتم',
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.maybePop(context);
                                onSkip!();
                              },
                              icon: const Icon(Icons.block,
                                  size: 18, color: Colors.orange),
                              label: const Text('رد',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontFamily: 'Vazirmatn')),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (isActionable && !isDone && onComplete != null)
                          Expanded(
                            child: Semantics(
                              label: 'تکمیل این آیتم',
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onComplete!();
                                },
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('تکمیل',
                                    style: TextStyle(fontFamily: 'Vazirmatn')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (!isActionable)
                          Expanded(
                            child: Text(
                              'عملیات مستقیم برای این نوع در دسترس نیست',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTimeLabel(AgendaItem item, String? endTimeStr) {
    final start = toPersianDigits(item.timeOfDay ?? '');
    if (item.durationMinutes != null && item.durationMinutes! > 0) {
      final dur = toPersianDigits('${item.durationMinutes}');
      if (endTimeStr != null) {
        return '$start – ${toPersianDigits(endTimeStr)} ($dur دقیقه)';
      }
      return '$start ($dur دقیقه)';
    }
    return start;
  }
}
