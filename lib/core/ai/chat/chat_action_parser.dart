import 'dart:convert';

import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';

class ParsedResponse {
  const ParsedResponse(this.cleanText, this.actions, {this.memoryOps});
  final String cleanText;
  final List<ChatAction> actions;
  final String? memoryOps;
}

class ChatActionParser {
  static final _re = RegExp(r'<actions>([\s\S]*?)</actions>', multiLine: true);
  static final _memOpsRe = RegExp(r'<memory_ops>([\s\S]*?)</memory_ops>', multiLine: true);
  static final _memRe = RegExp(r'<memory>([\s\S]*?)</memory>', multiLine: true);
  static final _allow = AssistantActionType.values.map((e) => e.name).toSet();

  static ParsedResponse parse(String raw) {
    // Extract memory_ops content
    final mOps = _memOpsRe.firstMatch(raw);
    final memoryOps = mOps?.group(1)?.trim();

    // Clean memory_ops and legacy memory tags
    var cleanText = raw
        .replaceAll(_memOpsRe, '')
        .replaceAll(_memRe, '')
        .trim();

    // Secondary safety truncation if unclosed tags remain
    final idxMemOps = cleanText.indexOf('<memory_ops>');
    if (idxMemOps != -1) {
      cleanText = cleanText.substring(0, idxMemOps).trim();
    }
    final idxMem = cleanText.indexOf('<memory>');
    if (idxMem != -1) {
      cleanText = cleanText.substring(0, idxMem).trim();
    }

    final mAct = _re.firstMatch(cleanText);
    if (mAct == null) {
      final idx = cleanText.indexOf('<actions>');
      final finalCleanText = idx != -1 ? cleanText.substring(0, idx).trim() : cleanText.trim();
      return ParsedResponse(finalCleanText, const [], memoryOps: memoryOps);
    }
    
    final finalCleanText = cleanText.replaceAll(_re, '').trim();
    final actions = <ChatAction>[];
    
    try {
      final decoded = jsonDecode(mAct.group(1)!.trim());
      if (decoded is List) {
        for (final item in decoded) {
          if (item is! Map) continue;
          final a = ChatAction.fromJson(item.cast<String, dynamic>());
          if (a.type.isNotEmpty && a.label.isNotEmpty && _allow.contains(a.type)) {
            actions.add(a);
          }
        }
      }
    } catch (_) {
      // silent -> return empty actions list on invalid JSON
    }
    
    return ParsedResponse(finalCleanText, actions, memoryOps: memoryOps);
  }
}
