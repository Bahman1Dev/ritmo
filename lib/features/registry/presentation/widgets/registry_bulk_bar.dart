// lib/features/registry/presentation/widgets/registry_bulk_bar.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';

class RegistryBulkBar extends StatelessWidget {
  const RegistryBulkBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.onArchiveSelected,
    required this.onDeleteSelected,
  });

  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onArchiveSelected;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onCancel,
                tooltip: 'انصراف',
              ),
              const SizedBox(width: 8),
              Text(
                '${toPersianDigits(selectedCount.toString())} مورد انتخاب شده',
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: selectedCount > 0 ? onArchiveSelected : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64748B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.archive_rounded, size: 16),
                label: const Text(
                  'بایگانی',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: selectedCount > 0 ? onDeleteSelected : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.delete_forever_rounded, size: 16),
                label: const Text(
                  'حذف',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
