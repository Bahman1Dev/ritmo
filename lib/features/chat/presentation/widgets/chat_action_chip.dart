import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';

class ChatActionChip extends StatelessWidget {

  const ChatActionChip({
    super.key,
    required this.action,
    required this.onTap,
  });
  final ChatAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final iconData = AssistantActionType.fromString(action.type).icon;

    return ActionChip(
      avatar: Icon(
        iconData,
        size: 16,
        color: isDark ? const Color(0xff8B5CF6) : const Color(0xff7C3AED),
      ),
      label: Text(
        action.label,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
      side: BorderSide(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: onTap,
    );
  }
}
