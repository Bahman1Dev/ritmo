import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/memory/assistant_memory_binding.dart';

class KonkurAiHelper {
  static Future<String?> askAssistant(
    String systemPrompt,
    String userMessage, {
    String? sessionId,
    String domain = 'konkur',
  }) async {
    try {
      String memorySuffix = '';
      if (sessionId != null) {
        memorySuffix = await AssistantMemoryBinding.getSystemPromptSuffix(
          domain: domain,
          query: userMessage,
        );
      }

      final enrichedSystem = memorySuffix.isNotEmpty
          ? '$systemPrompt\n\n$memorySuffix'
          : systemPrompt;

      final messagesToSend = <Map<String, String>>[
        {'role': 'system', 'content': enrichedSystem},
        {'role': 'user', 'content': userMessage},
      ];

      final res = await AIGateway.instance.sendCustomChat(messages: messagesToSend);

      if (res.isNotEmpty && sessionId != null) {
        await AssistantMemoryBinding.processResponse(
          sessionId: sessionId,
          domain: domain,
          userText: userMessage,
          rawResponse: res,
        );
      }

      return res;
    } catch (e) {
      debugPrint('KonkurAiHelper Exception: $e');
    }
    return null;
  }
}
