import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/ai/chat/chat_action_parser.dart';
import 'package:ritmo/core/ai/memory/ai_memory_service.dart';
import 'package:ritmo/core/ai/memory/memory_consolidator.dart';
import 'package:ritmo/core/ai/memory/memory_models.dart';

class AssistantMemoryBinding {
  /// Retrieve active memories for a domain and query, and return the system prompt suffix block
  static Future<String> getSystemPromptSuffix({
    required String domain,
    required String query,
  }) async {
    if (!await AiMemoryService.instance.isMemoryEnabled()) return '';
    
    final memories = await AiMemoryService.instance.retrieve(
      domain: domain,
      query: query,
    );
    final memoryBlock = AiMemoryService.instance.buildPromptBlock(memories);
    return '$memoryBlock\n${AiMemoryService.memoryInstruction()}';
  }

  /// Process any memory operations in assistant's response, and run explicit remember safety net
  static Future<void> processResponse({
    required String sessionId,
    required String domain,
    required String userText,
    required String rawResponse,
  }) async {
    // 1. Process parsed memory operations from tags
    final parsed = ChatActionParser.parse(rawResponse);
    if (parsed.memoryOps != null && parsed.memoryOps!.isNotEmpty) {
      try {
        final decoded = jsonDecode(parsed.memoryOps!);
        if (decoded is List) {
          final ops = <MemoryOp>[];
          for (final item in decoded) {
            if (item is Map) {
              ops.add(MemoryOp.fromJson(item.cast<String, dynamic>()));
            }
          }
          if (ops.isNotEmpty) {
            await AiMemoryService.instance.applyOperations(ops);
          }
        }
      } catch (e) {
        debugPrint('[MEMORY] Error processing assistant memory_ops JSON: $e');
      }
    }

    // 2. Process explicit safety net
    await AiMemoryService.instance.processExplicitSafetyNet(
      userText: userText,
      assistantResponse: rawResponse,
      domain: domain,
      sessionId: sessionId,
    );
  }

  /// Trigger session consolidation on closure
  static Future<void> triggerConsolidation({
    required String sessionId,
    required String domain,
  }) async {
    unawaited(MemoryConsolidator.consolidateSession(sessionId, domain));
  }
}
