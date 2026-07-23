import 'package:flutter/material.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class MultiSelectCard extends StatefulWidget {

  const MultiSelectCard({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onToggle,
  });
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onToggle;

  @override
  State<MultiSelectCard> createState() => _MultiSelectCardState();
}

class _MultiSelectCardState extends State<MultiSelectCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Active color styles
    final activeBorderColor = SupplementarySportsTheme.getSuccessColor(context);
    final activeBgColor = activeBorderColor.withValues(alpha: isDark ? 0.15 : 0.08);

    // Default color styles
    final defaultBorderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final defaultBgColor = SupplementarySportsTheme.getSurfaceColor(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onToggle();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Semantics(
          label: widget.title,
          selected: widget.selected,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            constraints: const BoxConstraints(
              minHeight: SupplementarySportsTheme.minimumTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: SupplementarySportsTheme.spacing16,
              vertical: SupplementarySportsTheme.spacing12,
            ),
            decoration: BoxDecoration(
              color: widget.selected ? activeBgColor : defaultBgColor,
              borderRadius: SupplementarySportsTheme.borderRadiusCard,
              border: Border.all(
                color: widget.selected ? activeBorderColor : defaultBorderColor,
                width: widget.selected ? 2.0 : 1.0,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                // Right side: Icon + Title
                Icon(
                  widget.icon,
                  color: widget.selected
                      ? activeBorderColor
                      : SupplementarySportsTheme.getTextSecondary(context),
                  size: 24,
                  semanticLabel: widget.title,
                ),
                const SizedBox(width: SupplementarySportsTheme.spacing12),
                Expanded(
                  child: Text(
                    widget.title,
                    textDirection: TextDirection.rtl,
                    style: SupplementarySportsTheme.body.copyWith(
                      color: SupplementarySportsTheme.getTextPrimary(context),
                      fontWeight: widget.selected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                // Left side: Checkbox
                IgnorePointer(
                  child: Checkbox(
                    value: widget.selected,
                    onChanged: (_) {},
                    activeColor: activeBorderColor,
                    checkColor: defaultBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
