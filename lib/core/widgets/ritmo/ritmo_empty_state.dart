// Ritmo EmptyState — وضعیت خالی لیست‌ها و صفحات
// شامل آیکن، عنوان، توضیح و دکمه اقدام اختیاری

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_button.dart';

class RitmoEmptyState extends StatelessWidget {
  const RitmoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(RitmoSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(RitmoSpacing.xl),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: colors.primary),
          ),
          const SizedBox(height: RitmoSpacing.xl),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RitmoSpacing.sm),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.6,
              fontFamily: 'Vazirmatn',
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: RitmoSpacing.xl),
            RitmoPrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}
