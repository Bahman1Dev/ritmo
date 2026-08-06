// lib/core/ai/ai_proxy_service.dart

import 'dart:convert';
import 'package:ritmo/core/backend/appwrite_gateway.dart';
import 'package:ritmo/core/backend/models/auth_result.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';

class AIProxyService {
  AIProxyService._();
  static final AIProxyService instance = AIProxyService._();

  final AppwriteGateway _gateway = AppwriteGateway.instance;

  /// Routes AI completion request securely through Appwrite Core Function.
  /// No API keys stored on client!
  Future<AuthResult<String>> completeChat({
    required List<Map<String, String>> messages,
    String? systemPrompt,
  }) async {
    final payload = jsonEncode({
      'action': 'ai/complete',
      'systemPrompt': systemPrompt,
      'messages': messages,
    });

    final result = await _gateway.executeCoreFunction({'body': payload});

    if (!result.isSuccess) {
      return AuthResult.failure(result.errorCode, result.errorMessage);
    }

    try {
      final json = jsonDecode(result.data ?? '{}') as Map<String, dynamic>;
      if (json['success'] == true && json['content'] != null) {
        return AuthResult.success(json['content'] as String);
      }
      return AuthResult.failure(
        AuthErrorCode.unknown,
        json['error'] as String? ?? 'خطا در پاسخ هوش مصنوعی سرور',
      );
    } catch (e, st) {
      RitmoLog.error('AIProxyService', 'Failed to parse AI proxy response', e, st);
      return const AuthResult.failure(AuthErrorCode.unknown);
    }
  }
}
