import 'dart:convert';
import 'package:ritmo/features/assistant/models/assistant_models.dart';

enum ChatRole { user, assistant, system }

ChatRole chatRoleFromString(String s) => switch (s) {
  'user' => ChatRole.user,
  'system' => ChatRole.system,
  _ => ChatRole.assistant,
};

class ChatAction {

  ChatAction({required this.type, required this.label, this.payload = const {}, this.targetRoute});

  factory ChatAction.fromJson(Map<String, dynamic> j) => ChatAction(
    type: j['type'] as String? ?? '',
    label: j['label'] as String? ?? '',
    payload: (j['payload'] as Map?)?.cast<String, dynamic>() ?? {},
    targetRoute: j['targetRoute'] as String?,
  );
  final String type;            // باید یکی از AssistantActionType.name باشد
  final String label;           // متن فارسی دکمه
  final Map<String, dynamic> payload;
  final String? targetRoute;

  Map<String, dynamic> toJson() =>
    {'type': type, 'label': label, 'payload': payload, 'targetRoute': targetRoute};

  AssistantAction toAssistantAction() => AssistantAction(
    type: AssistantActionType.fromString(type),
    title: label,
    payload: payload,
    targetRoute: targetRoute,
  );
}

class ChatMessage {   // in-memory only — به DB نمیرود

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.tokensUsed,
    this.actions = const [],
    this.isStreaming = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) {
    var acts = <ChatAction>[];
    final raw = m['actions'] as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        acts = (jsonDecode(raw) as List)
          .map((e) => ChatAction.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      } catch (_) {}
    }
    return ChatMessage(
      id: m['id'] as String,
      sessionId: m['session_id'] as String,
      role: chatRoleFromString(m['role'] as String? ?? 'assistant'),
      content: m['content'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int? ?? 0),
      tokensUsed: m['tokens_used'] as int?,
      actions: acts,
    );
  }
  final String id;
  final String sessionId;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final int? tokensUsed;
  final List<ChatAction> actions;
  final bool isStreaming;

  ChatMessage copyWith({String? content, List<ChatAction>? actions, bool? isStreaming, int? tokensUsed}) =>
    ChatMessage(
      id: id, sessionId: sessionId, role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      actions: actions ?? this.actions,
      isStreaming: isStreaming ?? this.isStreaming,
    );

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'role': role.name,
    'content': content,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'tokens_used': tokensUsed,
    'actions': jsonEncode(actions.map((a) => a.toJson()).toList()),
  };
}

class ChatSession {

  ChatSession({
    required this.id,
    required this.createdAt,
    required this.lastMessageAt,
    this.summary,
    this.messageCount = 0,
    this.chatType = 'assistant',
  });

  factory ChatSession.fromMap(Map<String, dynamic> m) => ChatSession(
    id: m['id'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int? ?? 0),
    lastMessageAt: DateTime.fromMillisecondsSinceEpoch(m['last_message_at'] as int? ?? 0),
    summary: m['summary'] as String?,
    messageCount: m['message_count'] as int? ?? 0,
    chatType: m['chat_type'] as String? ?? 'assistant',
  );
  final String id;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? summary;
  final int messageCount;
  final String chatType;
}

/// رویدادهای stream برای UI
sealed class StreamingChatEvent {}
class UserMessageSaved extends StreamingChatEvent { UserMessageSaved(this.message); final ChatMessage message; }
class AssistantStarted extends StreamingChatEvent { AssistantStarted(this.messageId); final String messageId; }
class ChatChunk extends StreamingChatEvent { ChatChunk(this.delta, this.accumulated); final String delta; final String accumulated; }
class ChatComplete extends StreamingChatEvent {
  ChatComplete(this.messageId, this.content, this.actions);
  final String messageId; final String content; final List<ChatAction> actions;
}
class ChatCancelled extends StreamingChatEvent { ChatCancelled(this.messageId, this.content); final String messageId; final String content; }
class ChatErrorEvent extends StreamingChatEvent { ChatErrorEvent(this.code, this.message); final String code; final String message; }
