import 'package:flutter/material.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/primary_button.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class EmptyStateView extends StatelessWidget {

  const EmptyStateView({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon,
  });
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SupplementarySportsTheme.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration or Icon
          Icon(
            icon ?? Icons.inbox_outlined,
            size: 64,
            color: SupplementarySportsTheme.getTextSecondary(context).withValues(alpha: 0.5),
            semanticLabel: 'آیکون خالی',
          ),
          const SizedBox(height: SupplementarySportsTheme.spacing24),
          // Friendly Message
          Text(
            message,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: SupplementarySportsTheme.body.copyWith(
              color: SupplementarySportsTheme.getTextSecondary(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: SupplementarySportsTheme.spacing32),
          // Proposed Action Button
          PrimaryButton(
            label: actionLabel,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
