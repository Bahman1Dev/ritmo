import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class BottomSheetContainer extends StatelessWidget {

  const BottomSheetContainer({
    super.key,
    required this.child,
    this.title,
  });
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final handleColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Semantics(
      label: title ?? 'صفحه کشویی پایین',
      child: ClipRRect(
        borderRadius: SupplementarySportsTheme.borderRadiusBottomSheet,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF0F172A).withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: SupplementarySportsTheme.borderRadiusBottomSheet,
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            padding: const EdgeInsets.only(
              left: SupplementarySportsTheme.spacing16,
              right: SupplementarySportsTheme.spacing16,
              bottom: SupplementarySportsTheme.spacing24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.rtl,
                children: [
                  const SizedBox(height: SupplementarySportsTheme.spacing12),
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (title != null) ...[
                    const SizedBox(height: SupplementarySportsTheme.spacing16),
                    // Title
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        title!,
                        textDirection: TextDirection.rtl,
                        style: SupplementarySportsTheme.h2.copyWith(
                          color: SupplementarySportsTheme.getTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: SupplementarySportsTheme.spacing16),
                  // Content
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
