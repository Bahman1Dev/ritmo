// Ritmo ListRow — ردیف لیست استاندارد با آیکن، عنوان، زیرعنوان و تریلینگ
// جایگزین ListTile های متفرقه و پدینگ‌های ناهماهنگ

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RitmoListRow extends StatelessWidget {
  const RitmoListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: RitmoSpacing.lg, vertical: RitmoSpacing.md),
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final content = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: RitmoSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: RitmoSpacing.md),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: RitmoSpacing.md),
            Icon(Icons.chevron_left_rounded, color: colors.textTertiary, size: 20),
          ],
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onTap != null)
          InkWell(
            onTap: () {
              RitmoHapticsPolicy.selection();
              onTap?.call();
            },
            child: content,
          )
        else
          content,
        if (showDivider)
          Divider(
            color: colors.divider,
            height: 1,
            indent: leading != null ? 56 : RitmoSpacing.lg,
            endIndent: RitmoSpacing.lg,
          ),
      ],
    );
  }
}
