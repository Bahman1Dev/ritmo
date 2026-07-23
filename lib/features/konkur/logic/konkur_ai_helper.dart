import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/memory/assistant_memory_binding.dart';

class KonkurAiHelper {
  static Future<String?> askAssistant(String systemPrompt, String userMessage) async {
    try {
      final memorySuffix = await AssistantMemoryBinding.getSystemPromptSuffix(
        domain: 'konkur',
        query: userMessage,
      );

      final messagesToSent = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt + memorySuffix},
        {'role': 'user', 'content': userMessage}
      ];

      final aiContent = await AIGateway.instance.sendCustomChat(messages: messagesToSent);
      
      await AssistantMemoryBinding.processResponse(
        sessionId: 'konkur_session',
        domain: 'konkur',
        userText: userMessage,
        rawResponse: aiContent,
      );
      
      await AssistantMemoryBinding.triggerConsolidation(
        sessionId: 'konkur_session',
        domain: 'konkur',
      );

      return aiContent;
    } catch (e) {
      debugPrint('KonkurAiHelper Exception: $e');
    }
    return null;
  }
}
