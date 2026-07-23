class ChatSessionSummarizer {
  /// heuristic محلی، بدون LLM
  static String summarize({required String firstUserMessage, required int messageCount}) {
    final t = firstUserMessage.trim().replaceAll('\n', ' ');
    final head = t.length <= 50 ? t : '${t.substring(0, 50)}…';
    return head.isEmpty ? 'گفتگو ($messageCount پیام)' : '$head ($messageCount پیام)';
  }
}
