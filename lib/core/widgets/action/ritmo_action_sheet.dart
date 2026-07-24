import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

enum SheetActionKind {
  complete,
  completeWithVariant,
  startTimer,
  snooze,
  skip,
  cantToday,
  undo,
  edit,
  viewDetails,
  deferExhausted,
}

class SheetAction {
  const SheetAction({
    required this.label,
    required this.kind,
    required this.onTap,
    this.icon,
    this.color,
    this.isPrimary = false,
  });

  final String label;
  final SheetActionKind kind;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final bool isPrimary;
}

class ActionSheetSpec {
  const ActionSheetSpec({
    required this.header,
    required this.body,
    required this.actions,
    this.footer,
  });

  final Widget header;
  final Widget body;
  final List<SheetAction> actions;
  final Widget? footer;
}

/// Standardized bottom sheet skeleton for all domain action sheets in Ritmo.
class RitmoActionSheet extends StatelessWidget {
  const RitmoActionSheet({
    super.key,
    required this.spec,
  });

  final ActionSheetSpec spec;

  static Future<T?> show<T>(BuildContext context, ActionSheetSpec spec) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RitmoActionSheet(spec: spec),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: colors.border.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              spec.header,
              const SizedBox(height: 16),

              // Body
              spec.body,
              const SizedBox(height: 20),

              // Action buttons
              ...spec.actions.map((action) {
                final btnColor = action.color ?? (action.isPrimary ? colors.primary : colors.cardFill);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: action.isPrimary ? Colors.white : colors.textPrimary,
                        elevation: action.isPrimary ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: action.isPrimary
                              ? BorderSide.none
                              : BorderSide(color: colors.border.withValues(alpha: 0.2)),
                        ),
                      ),
                      onPressed: action.onTap,
                      icon: action.icon != null ? Icon(action.icon, size: 18) : const SizedBox.shrink(),
                      label: Text(
                        action.label,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              if (spec.footer != null) ...[
                const SizedBox(height: 8),
                spec.footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
