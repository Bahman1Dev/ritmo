import 'package:flutter/material.dart';

import 'package:ritmo/features/chat/presentation/ai_chat_screen.dart';

/// Screen wrapper for the AI Assistant view.
class AssistantScreen extends StatelessWidget {

  /// Creates an [AssistantScreen].
  const AssistantScreen({super.key, this.isTab = false});
  /// Whether the assistant screen is rendered within a tab bar.
  final bool isTab;

  @override
  Widget build(BuildContext context) {
    return AiChatScreen(isTab: isTab);
  }
}
