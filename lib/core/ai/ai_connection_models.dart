import 'package:flutter/material.dart';

enum AiMode { ritmoServer, personalKey }

enum AiSlot { assistant, features }

class AiProviderPreset {
  const AiProviderPreset({
    required this.id,
    required this.nameFa,
    required this.taglineFa,
    required this.endpoint,
    required this.models,
    required this.keyUrl,
    required this.brandColor,
    this.worksInIranWithoutVpn = false,
    this.needsAccountId = false,
    this.allowsHttp = false,
  });

  final String id;
  final String nameFa;
  final String taglineFa;
  final String endpoint;
  final List<String> models;
  final String keyUrl;
  final Color brandColor;
  final bool worksInIranWithoutVpn;
  final bool needsAccountId;
  final bool allowsHttp;
}

const List<AiProviderPreset> kAiProviderPresets = [
  AiProviderPreset(
    id: 'zhipu',
    nameFa: 'ژیپو (智谱)',
    taglineFa: 'پیشنهاد ریتمو برای ایران — سریع و ارزان',
    endpoint: 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    models: ['glm-5.2', 'glm-4-plus', 'glm-4-flash'],
    keyUrl: 'https://open.bigmodel.cn/usercenter/apikeys',
    brandColor: Color(0xff3B82F6),
    worksInIranWithoutVpn: true,
  ),
  AiProviderPreset(
    id: 'openrouter',
    nameFa: 'OpenRouter',
    taglineFa: 'دسترسی به ده‌ها مدل با یک کلید، مدل رایگان هم دارد',
    endpoint: 'https://openrouter.ai/api/v1/chat/completions',
    models: [
      'google/gemini-2.0-flash-exp:free',
      'meta-llama/llama-3.3-70b-instruct',
      'deepseek/deepseek-chat',
    ],
    keyUrl: 'https://openrouter.ai/keys',
    brandColor: Color(0xff6366F1),
    worksInIranWithoutVpn: true,
  ),
  AiProviderPreset(
    id: 'cloudflare',
    nameFa: 'Cloudflare Workers AI',
    taglineFa: 'سهمیهٔ رایگان روزانه — نیازمند شناسهٔ حساب',
    endpoint: 'https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/ai/v1/chat/completions',
    models: [
      '@cf/meta/llama-3.2-3b-instruct',
      '@cf/meta/llama-3.3-70b-instruct',
      '@cf/deepseek-ai/deepseek-r1-distill-qwen-32b',
    ],
    keyUrl: 'https://dash.cloudflare.com/',
    brandColor: Color(0xffF97316),
    worksInIranWithoutVpn: false,
    needsAccountId: true,
  ),
  AiProviderPreset(
    id: 'groq',
    nameFa: 'Groq',
    taglineFa: 'سریع‌ترین پاسخ‌دهی، مناسب دستیار زنده',
    endpoint: 'https://api.groq.com/openai/v1/chat/completions',
    models: [
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
      'mixtral-8x7b-32768',
    ],
    keyUrl: 'https://console.groq.com/keys',
    brandColor: Color(0xffF43F5E),
    worksInIranWithoutVpn: false,
  ),
  AiProviderPreset(
    id: 'local',
    nameFa: 'مدل محلی (Ollama)',
    taglineFa: 'کاملاً آفلاین، هیچ داده‌ای دستگاه را ترک نمی‌کند',
    endpoint: 'http://10.0.2.2:11434/v1/chat/completions',
    models: ['llama3.2', 'qwen2.5:7b', 'mistral'],
    keyUrl: 'https://ollama.com/',
    brandColor: Color(0xff10B981),
    worksInIranWithoutVpn: true,
    allowsHttp: true,
  ),
  AiProviderPreset(
    id: 'custom',
    nameFa: 'سرویس دلخواه',
    taglineFa: 'هر سرویس سازگار با OpenAI',
    endpoint: '',
    models: [],
    keyUrl: '',
    brandColor: Color(0xff8B5CF6),
    worksInIranWithoutVpn: false,
  ),
];

class AiConnectionConfig {
  const AiConnectionConfig({
    required this.slot,
    required this.mode,
    required this.providerPresetId,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.timeoutMs,
    this.backupBaseUrl = '',
    this.backupApiKey = '',
    this.cloudflareAccountId = '',
    this.separateFeaturesConfig = false,
    this.lastTestAt,
    this.lastTestOk,
    this.lastTestLatencyMs,
    this.lastErrorCode,
  });

  final AiSlot slot;
  final AiMode mode;
  final String providerPresetId;
  final String baseUrl;
  final String apiKey;
  final String model;
  final int timeoutMs;
  final String backupBaseUrl;
  final String backupApiKey;
  final String cloudflareAccountId;
  final bool separateFeaturesConfig;
  final int? lastTestAt;
  final bool? lastTestOk;
  final int? lastTestLatencyMs;
  final String? lastErrorCode;

  AiConnectionConfig copyWith({
    AiSlot? slot,
    AiMode? mode,
    String? providerPresetId,
    String? baseUrl,
    String? apiKey,
    String? model,
    int? timeoutMs,
    String? backupBaseUrl,
    String? backupApiKey,
    String? cloudflareAccountId,
    bool? separateFeaturesConfig,
    int? lastTestAt,
    bool? lastTestOk,
    int? lastTestLatencyMs,
    String? lastErrorCode,
  }) {
    return AiConnectionConfig(
      slot: slot ?? this.slot,
      mode: mode ?? this.mode,
      providerPresetId: providerPresetId ?? this.providerPresetId,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      backupBaseUrl: backupBaseUrl ?? this.backupBaseUrl,
      backupApiKey: backupApiKey ?? this.backupApiKey,
      cloudflareAccountId: cloudflareAccountId ?? this.cloudflareAccountId,
      separateFeaturesConfig: separateFeaturesConfig ?? this.separateFeaturesConfig,
      lastTestAt: lastTestAt ?? this.lastTestAt,
      lastTestOk: lastTestOk ?? this.lastTestOk,
      lastTestLatencyMs: lastTestLatencyMs ?? this.lastTestLatencyMs,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
    );
  }
}

class AiTestResult {
  const AiTestResult({
    required this.ok,
    required this.latencyMs,
    required this.resolvedModel,
    required this.messageFa,
    this.statusCode,
  });

  final bool ok;
  final int latencyMs;
  final String resolvedModel;
  final String messageFa;
  final int? statusCode;
}

class AiChainEntry {
  const AiChainEntry({
    required this.labelFa,
    required this.host,
    required this.model,
  });

  final String labelFa;
  final String host; // Only host, NEVER key
  final String model;
}
