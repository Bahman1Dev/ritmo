import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/markdown_parser.dart';
import 'package:ritmo/features/chat/presentation/widgets/chat_action_chip.dart';

class StreamingMessageBubble extends StatefulWidget {

  const StreamingMessageBubble({
    super.key,
    required this.message,
    required this.isLast,
    required this.onAction,
    required this.onCopy,
  });
  final ChatMessage message;
  final bool isLast;
  final void Function(ChatAction) onAction;
  final void Function(String) onCopy;

  @override
  State<StreamingMessageBubble> createState() => _StreamingMessageBubbleState();
}

class _StreamingMessageBubbleState extends State<StreamingMessageBubble> {
  bool _isCopied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    widget.onCopy(widget.message.content);
    
    _copiedTimer?.cancel();
    setState(() {
      _isCopied = true;
    });

    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  String _getDisplayContent(String rawContent) {
    final idx = rawContent.indexOf('<actions');
    if (idx != -1) {
      return rawContent.substring(0, idx).trim();
    }
    return rawContent;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = widget.message.role == ChatRole.user;

    final bubbleBg = isUser
        ? const Color(0xff5B8AF5)
        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04));

    final textColor = isUser ? Colors.white : colors.textPrimary;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    final baseStyle = TextStyle(
      fontFamily: 'Vazirmatn',
      fontSize: 13.5,
      height: 1.6,
      color: textColor,
    );

    final displayContent = _getDisplayContent(widget.message.content);

    // Build the main message bubble container
    final bubbleContainer = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.76,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bubbleBg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        border: isUser
            ? null
            : Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message content with Markdown parser
          if (displayContent.isNotEmpty)
            RichText(
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: baseStyle,
                children: [
                  ...parseMarkdownText(displayContent, baseStyle),
                  if (widget.message.isStreaming)
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: _BlinkingCursor(),
                      ),
                    ),
                ],
              ),
            )
          else if (widget.message.isStreaming)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              child: _TypingIndicator(),
            ),

          // Actions Chip Row
          if (!widget.message.isStreaming && widget.message.actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.message.actions
                    .map((act) => ChatActionChip(
                          action: act,
                          onTap: () => widget.onAction(act),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );

    // Build the copy icon button with animated transitions
    final copyButton = GestureDetector(
      onTap: _handleCopy,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Icon(
            _isCopied ? CupertinoIcons.checkmark_alt : CupertinoIcons.doc_on_doc,
            key: ValueKey<bool>(_isCopied),
            size: 16,
            color: _isCopied 
                ? const Color(0xff10B981) // Green checkmark
                : colors.textSecondary.withValues(alpha: 0.45),
          ),
        ),
      ),
    );

    final showCopy = !widget.message.isStreaming && displayContent.isNotEmpty;

    // Layout the row based on message sender (User or AI)
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isUser
              ? [
                  bubbleContainer,
                  if (showCopy) copyButton else const SizedBox(width: 32), // Copy icon on the right of user message
                ]
              : [
                  if (showCopy) copyButton else const SizedBox(width: 32), // Copy icon on the left of AI message
                  bubbleContainer,
                ],
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      opacity: _controller.value > 0.5 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: 8,
        height: 16,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff8B5CF6) : const Color(0xff7C3AED),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}


class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isDark ? Colors.white60 : Colors.black45;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * (2 * math.pi / 3);
            final value = math.sin((_controller.value * 2 * math.pi) - delay);
            final offsetY = ((value + 1) / 2) * -7;

            return Transform.translate(
              offset: Offset(0, offsetY),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
