import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

/// Single unified primitive for bottom sheets across the application.
class RitmoSheetScaffold extends StatelessWidget {
  final String semanticsLabel;
  final Widget child;
  final bool isDismissible;
  final double maxHeightFactor;

  const RitmoSheetScaffold({
    super.key,
    required this.semanticsLabel,
    required this.child,
    this.isDismissible = true,
    this.maxHeightFactor = 0.9,
  });

  /// Present a bottom sheet using RitmoSheetScaffold.
  static Future<T?> present<T>({
    required BuildContext context,
    required String semanticsLabel,
    required WidgetBuilder builder,
    bool isDismissible = true,
    double maxHeightFactor = 0.9,
  }) {
    RitmoHaptics.sheetOpen();
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: isDismissible,
      builder: (context) => Semantics(
        label: semanticsLabel,
        container: true,
        child: RitmoSheetScaffold(
          semanticsLabel: semanticsLabel,
          isDismissible: isDismissible,
          maxHeightFactor: maxHeightFactor,
          child: builder(context),
        ),
      ),
    ).then((result) {
      RitmoHaptics.sheetClose();
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * maxHeightFactor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: RitmoTheme.glassCardLight(
            blurSigma: 20,
            color: colors.card.withValues(alpha: isDarkMode ? 0.85 : 0.9),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 40,
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
