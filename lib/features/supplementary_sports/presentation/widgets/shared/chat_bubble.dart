import 'package:flutter/material.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class ChatBubble extends StatelessWidget {

  const ChatBubble({
    super.key,
    required this.message,
    required this.isFromUser,
  });
  final String message;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Alignment
    final alignment = isFromUser ? Alignment.centerRight : Alignment.centerLeft;

    // Colors
    final userBgColor = SupplementarySportsTheme.getSuccessColor(context);
    final userTextColor = isDark ? Colors.black : Colors.white;

    final aiBgColor = isDark 
        ? Colors.white.withValues(alpha: 0.06) 
        : Colors.black.withValues(alpha: 0.04);
    final aiBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final aiTextColor = SupplementarySportsTheme.getTextPrimary(context);

    // Padding
    const bubblePadding = EdgeInsets.symmetric(
      horizontal: SupplementarySportsTheme.spacing16,
      vertical: SupplementarySportsTheme.spacing12,
    );

    // Border Radius
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isFromUser ? 16 : 4),
      bottomRight: Radius.circular(isFromUser ? 4 : 16),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: SupplementarySportsTheme.spacing8,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          minHeight: 40,
        ),
        padding: bubblePadding,
        decoration: BoxDecoration(
          color: isFromUser ? userBgColor : aiBgColor,
          borderRadius: borderRadius,
          border: isFromUser 
              ? null 
              : Border.all(color: aiBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          message,
          textDirection: TextDirection.rtl,
          style: SupplementarySportsTheme.body.copyWith(
            color: isFromUser ? userTextColor : aiTextColor,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
