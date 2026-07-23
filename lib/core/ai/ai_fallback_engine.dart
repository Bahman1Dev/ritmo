class AIFallbackEngine {
  static const String aiPolicyFallbackResponse =
      'I can help you with routines, goals, energy, sleep, and planning.';

  static Map<String, dynamic> getFallbackResponse() {
    return {
      'response': aiPolicyFallbackResponse,
      'type': 'assistant',
      'evidence_level': 'LOW',
      'used_data_categories': <String>[],
      'query_scope': 'narrow'
    };
  }

  static Map<String, dynamic> getNetworkErrorResponse([String? details]) {
    return {
      'response': "خطا در اتصال به سرور هوش مصنوعی. لطفاً اتصال اینترنت یا فیلترشکن خود را بررسی کنید.${details != null ? '\n($details)' : ''}",
      'type': 'error',
      'evidence_level': 'NONE',
      'used_data_categories': <String>[],
      'query_scope': 'narrow'
    };
  }
}
