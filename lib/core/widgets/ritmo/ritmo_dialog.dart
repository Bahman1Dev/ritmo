// Ritmo Dialog — دیالوگ تأیید و هشدار یکپارچه
// جایگزین AlertDialog های خام

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_button.dart';

class RitmoDialog extends StatelessWidget {
  const RitmoDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'تأیید',
    this.cancelLabel = 'انصراف',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'تأیید',
    String cancelLabel = 'انصراف',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: context.colors.overlay,
      builder: (context) => RitmoDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RitmoRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(RitmoSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDestructive ? colors.error : colors.textPrimary,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: RitmoSpacing.md),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.6,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: RitmoSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RitmoSecondaryButton(
                  label: cancelLabel,
                  onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: RitmoSpacing.md),
                RitmoPrimaryButton(
                  label: confirmLabel,
                  fullWidth: false,
                  onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
