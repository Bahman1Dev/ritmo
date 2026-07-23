import 'package:flutter/material.dart';

import 'package:ritmo/core/theme/ritmo_theme.dart';

/// Reusable empty state placeholder view displaying an icon, title, description and CTA.
class RitmoEmptyState extends StatelessWidget {

  /// Constructs a [RitmoEmptyState].
  const RitmoEmptyState({
    required this.icon,
    required this.title,
    this.description,
    this.ctaLabel,
    this.onCta,
    super.key,
  });
  /// Icon to display in the central soft circle.
  final IconData icon;

  /// Main headline text.
  final String title;

  /// Optional body description text.
  final String? description;

  /// Optional call-to-action button label.
  final String? ctaLabel;

  /// Optional call-to-action callback.
  final VoidCallback? onCta;

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
            // Soft circle with icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 48,
                  color: colors.primary,
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
            if (description != null) ...[
              const SizedBox(height: 12),
              // Description
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13.5,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 28),
              // CTA Button
              ElevatedButton(
                onPressed: onCta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  ctaLabel!,
                  style: const TextStyle(
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
