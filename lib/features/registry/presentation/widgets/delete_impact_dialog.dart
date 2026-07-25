// lib/features/registry/presentation/widgets/delete_impact_dialog.dart

import 'package:flutter/material.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/registry/domain/delete_impact_report.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';

class DeleteImpactDialog extends StatelessWidget {
  const DeleteImpactDialog({
    super.key,
    required this.entry,
    required this.report,
    required this.onArchive,
    required this.onDeletePermanent,
  });

  final RegistryEntry entry;
  final DeleteImpactReport report;
  final VoidCallback onArchive;
  final VoidCallback onDeletePermanent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
        ),
        backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.white,
        title: Text(
          'حذف «${entry.title}»؟',
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'با حذف کامل، این موارد از بین می‌روند:',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,

              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report.toFaSentence(),
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12.5,
                  height: 1.5,
                  color: report.orphanedDependents.isNotEmpty
                      ? const Color(0xFFF43F5E)
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDeletePermanent();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF43F5E),
              side: const BorderSide(color: Color(0xFFF43F5E)),
            ),
            child: const Text('حذف کامل', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onArchive();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('بایگانی کن', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
