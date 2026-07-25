// lib/features/registry/presentation/widgets/registry_health_card.dart

import 'package:flutter/material.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/registry/domain/registry_health_issue.dart';

class RegistryHealthCard extends StatefulWidget {
  const RegistryHealthCard({
    super.key,
    required this.issue,
    required this.onFixed,
  });

  final RegistryHealthIssue issue;
  final VoidCallback onFixed;

  @override
  State<RegistryHealthCard> createState() => _RegistryHealthCardState();
}

class _RegistryHealthCardState extends State<RegistryHealthCard> {
  bool _isFixing = false;
  bool _isFixed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final severityColor = widget.issue.severity == HealthSeverity.critical
        ? const Color(0xFFF43F5E)
        : (widget.issue.severity == HealthSeverity.warning
            ? const Color(0xFFF59E0B)
            : const Color(0xFF3B82F6));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _isFixed
          ? Container(
              key: const ValueKey('fixed_state'),
              margin: const EdgeInsets.symmetric(
                horizontal: CalendarTokens.spacingL,
                vertical: CalendarTokens.spacingS,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CalendarTokens.emerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CalendarTokens.emerald.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: CalendarTokens.emerald, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'مشکل با موفقیت برطرف شد 🎉',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: CalendarTokens.emerald,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              key: const ValueKey('normal_state'),
              margin: const EdgeInsets.symmetric(
                horizontal: CalendarTokens.spacingL,
                vertical: CalendarTokens.spacingS,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                border: Border.all(
                  color: severityColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.issue.severity == HealthSeverity.critical
                            ? Icons.error_rounded
                            : (widget.issue.severity == HealthSeverity.warning
                                ? Icons.warning_amber_rounded
                                : Icons.info_outline_rounded),
                        color: severityColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.issue.title,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.issue.description,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _isFixing
                          ? null
                          : () async {
                              setState(() {
                                _isFixing = true;
                              });
                              try {
                                await widget.issue.fix(context);
                                if (mounted) {
                                  setState(() {
                                    _isFixed = true;
                                  });
                                  widget.onFixed();
                                }
                              } catch (_) {
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isFixing = false;
                                  });
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: severityColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: _isFixing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.build_rounded, size: 16),
                      label: Text(
                        widget.issue.fixLabel,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
