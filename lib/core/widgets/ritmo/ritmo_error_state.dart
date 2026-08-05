// Ritmo ErrorState — وضعیت خطای بارگیری و پردازش
// شامل پیام خطا و دکمه تلاش مجدد

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_button.dart';

class RitmoErrorState extends StatelessWidget {
  const RitmoErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'خطایی رخ داد',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(RitmoSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(RitmoSpacing.lg),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
          ),
          const SizedBox(height: RitmoSpacing.lg),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RitmoSpacing.xs),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.5,
              fontFamily: 'Vazirmatn',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RitmoSpacing.xl),
          RitmoSecondaryButton(
            label: 'تلاش مجدد',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
