import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/ai/ai_briefing_prompt.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/ai_rate_limiter.dart';
import 'package:ritmo/core/ai/ai_response_processor.dart';
import 'package:ritmo/core/ai/daily_digest_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BriefingInsight { // positive | neutral | attention

  BriefingInsight({required this.text, required this.tone});

  factory BriefingInsight.fromMap(Map<String, dynamic> map) {
    return BriefingInsight(
      text: map['text']?.toString() ?? '',
      tone: map['tone']?.toString() ?? 'neutral',
    );
  }
  final String text;
  final String tone;

  Map<String, dynamic> toMap() => {'text': text, 'tone': tone};
}

class BriefingSuggestion {

  BriefingSuggestion({required this.text, this.actionType, this.payload});

  factory BriefingSuggestion.fromMap(Map<String, dynamic> map) {
    return BriefingSuggestion(
      text: map['text']?.toString() ?? '',
      actionType: map['actionType']?.toString(),
      payload: map['payload'] != null ? Map<String, dynamic>.from(map['payload'] as Map) : null,
    );
  }
  final String text;
  final String? actionType;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toMap() => {
    'text': text,
    'actionType': actionType,
    'payload': payload,
  };
}

class AiBriefing {

  AiBriefing({
    required this.headline,
    required this.summary,
    required this.insights,
    required this.suggestions,
    required this.generatedAtIso,
    required this.evidenceLevel,
  });

  factory AiBriefing.fromMap(Map<String, dynamic> map) {
    return AiBriefing(
      headline: map['headline']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      insights: (map['insights'] as List? ?? [])
          .map((i) => BriefingInsight.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList(),
      suggestions: (map['suggestions'] as List? ?? [])
          .map((s) => BriefingSuggestion.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      generatedAtIso: map['generatedAtIso']?.toString() ?? DateTime.now().toIso8601String(),
      evidenceLevel: map['evidence_level']?.toString() ?? 'MEDIUM',
    );
  }
  final String headline;
  final String summary;
  final List<BriefingInsight> insights;
  final List<BriefingSuggestion> suggestions;
  final String generatedAtIso;
  final String evidenceLevel;

  Map<String, dynamic> toMap() => {
    'headline': headline,
    'summary': summary,
    'insights': insights.map((i) => i.toMap()).toList(),
    'suggestions': suggestions.map((s) => s.toMap()).toList(),
    'generatedAtIso': generatedAtIso,
    'evidence_level': evidenceLevel,
  };
}

class AiBriefingService {
  AiBriefingService._();
  static final AiBriefingService instance = AiBriefingService._();

  static const int briefingVersion = 1;
  static const int digestVersion = DailyDigestBuilder.currentDigestVersion; // 2
  static const int engineVersion = 1;
  static const int fingerprintVersion = 1;

  static const int _throttleHours = 2;

  /// Fetches a new AI daily briefing.
  /// Respects the 2-hour throttle and stats hash comparison.
  /// Falls back to cached briefing on failures or rate limits.
  Future<AiBriefing?> getOrRefresh({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Build full digest (fetches latest snapshot internally)
      final digest = await DailyDigestBuilder.buildFull();

      // 2. Read cache and version metadata
      final cachedBriefingStr = prefs.getString('ai_briefing_v1');
      final cachedTimestamp = prefs.getInt('ai_briefing_ts_v1') ?? 0;
      final cachedHash = prefs.getInt('ai_briefing_hash_v1') ?? 0;

      final cachedBv = prefs.getInt('ai_briefing_version_v1') ?? 0;
      final cachedDv = prefs.getInt('ai_briefing_digest_version_v1') ?? 0;
      final cachedEv = prefs.getInt('ai_briefing_engine_version_v1') ?? 0;
      final cachedFv = prefs.getInt('ai_briefing_fingerprint_version_v1') ?? 0;

      // 3. Verify version metadata
      final versionsMatch = cachedBv == briefingVersion &&
                                 cachedDv == digestVersion &&
                                 cachedEv == engineVersion &&
                                 cachedFv == fingerprintVersion;

      // 4. Throttle check
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final isThrottled = (nowMs - cachedTimestamp) < (_throttleHours * 60 * 60 * 1000);
      final isSameHash = digest.dataHash == cachedHash;

      if (!force && cachedBriefingStr != null && isThrottled && isSameHash && versionsMatch) {
        debugPrint('[BRIEFING] Throttle active, returning cached briefing.');
        return AiBriefing.fromMap(jsonDecode(cachedBriefingStr) as Map<String, dynamic>);
      }

      // 5. Rate limit guard
      if (AIRateLimiter.instance.isRateLimited()) {
        debugPrint('[BRIEFING] Rate limit active, returning cached briefing if available.');
        if (cachedBriefingStr != null) {
          return AiBriefing.fromMap(jsonDecode(cachedBriefingStr) as Map<String, dynamic>);
        }
        return null;
      }

      // 6. Invoke LLM raw completion
      final systemPrompt = AiBriefingPrompt.system();
      final userPrompt = jsonEncode(digest.json);

      debugPrint('[BRIEFING] Querying LLM gateway...');
      final rawResponse = await AIGateway.instance.sendRawCompletion(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        responseFormatJson: true,
      );

      if (rawResponse.isEmpty) {
        debugPrint('[BRIEFING] Empty response from LLM, falling back to cache.');
        if (cachedBriefingStr != null) {
          return AiBriefing.fromMap(jsonDecode(cachedBriefingStr) as Map<String, dynamic>);
        }
        return null;
      }

      // 7. Parse response using unified AIResponseProcessor
      final parsedJson = AIResponseProcessor.processRawJson(rawResponse);
      if (parsedJson == null) {
        debugPrint('[BRIEFING] Failed to parse LLM JSON. Response was: $rawResponse');
        if (cachedBriefingStr != null) {
          return AiBriefing.fromMap(jsonDecode(cachedBriefingStr) as Map<String, dynamic>);
        }
        return null;
      }

      final briefing = AiBriefing.fromMap(parsedJson);

      // 8. Save to cache with all version metadata
      await prefs.setString('ai_briefing_v1', jsonEncode(briefing.toMap()));
      await prefs.setInt('ai_briefing_ts_v1', nowMs);
      await prefs.setInt('ai_briefing_hash_v1', digest.dataHash);
      await prefs.setInt('ai_briefing_version_v1', briefingVersion);
      await prefs.setInt('ai_briefing_digest_version_v1', digestVersion);
      await prefs.setInt('ai_briefing_engine_version_v1', engineVersion);
      await prefs.setInt('ai_briefing_fingerprint_version_v1', fingerprintVersion);

      debugPrint('[BRIEFING] Saved new briefing to cache.');
      return briefing;
    } catch (e) {
      debugPrint('[BRIEFING] Error in getOrRefresh: $e');
      return getCached();
    }
  }

  /// Returns the cached briefing immediately (no network call, no DB queries)
  Future<AiBriefing?> getCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedBriefingStr = prefs.getString('ai_briefing_v1');
      if (cachedBriefingStr != null) {
        return AiBriefing.fromMap(jsonDecode(cachedBriefingStr) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[BRIEFING] Error reading cached briefing: $e');
    }
    return null;
  }
}
