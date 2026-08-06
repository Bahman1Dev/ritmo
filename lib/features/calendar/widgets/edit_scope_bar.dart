import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';

class EditScopeBar extends StatefulWidget {
  const EditScopeBar({
    super.key,
    required this.onScopeSelected,
    required this.onDismiss,
  });

  final ValueChanged<CalendarEditScope> onScopeSelected;
  final VoidCallback onDismiss;

  @override
  State<EditScopeBar> createState() => _EditScopeBarState();
}

class _EditScopeBarState extends State<EditScopeBar> {
  CalendarEditScope _selectedScope = CalendarEditScope.thisDayOnly;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _selectScope(CalendarEditScope scope) {
    RitmoHapticsPolicy.tap();
    setState(() {
      _selectedScope = scope;
    });
    widget.onScopeSelected(scope);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 44.0,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'دامنه تغییر:',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
            Row(
              children: [
                _buildChip(
                  context,
                  label: 'فقط امروز',
                  isSelected: _selectedScope == CalendarEditScope.thisDayOnly,
                  onTap: () => _selectScope(CalendarEditScope.thisDayOnly),
                ),
                const SizedBox(width: 8),
                _buildChip(
                  context,
                  label: 'همیشه',
                  isSelected: _selectedScope == CalendarEditScope.allFutureDays,
                  onTap: () => _selectScope(CalendarEditScope.allFutureDays),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? colors.onPrimary : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }
}
