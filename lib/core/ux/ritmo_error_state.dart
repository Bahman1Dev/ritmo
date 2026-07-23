import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RitmoErrorState extends StatelessWidget {

  const RitmoErrorState({
    super.key,
    this.title = 'خطایی رخ داد',
    this.detail,
    this.onRetry,
  });
  final String title;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft circle with warning/error icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.medicalRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colors.medicalRed,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 12),
              // Technical details
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              // Retry Button
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.medicalRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'تلاش مجدد',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
