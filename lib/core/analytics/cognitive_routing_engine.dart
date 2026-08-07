import 'package:flutter/foundation.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';

enum CognitiveLoad {
  analytical,     // تحلیلی
  administrative, // اداری و مکانیکی
  creative,       // خلاق و بینشی
  physical,       // بدنی
  none,
}

@immutable
class CognitiveRoutingInput {
  const CognitiveRoutingInput({
    required this.dateStr,
    required this.routines,
    required this.energyOutput,
  });

  final String dateStr;
  final List<Map<String, dynamic>> routines;
  final EnergyAnalyticsOutput energyOutput;

  @override
  String toString() {
    return 'CognitiveRoutingInput(dateStr: $dateStr, routinesCount: ${routines.length}, energySamples: ${energyOutput.sampleCount})';
  }
}

@immutable
class CognitiveRoutingSuggestion {
  const CognitiveRoutingSuggestion({
    required this.routineId,
    required this.routineTitle,
    required this.currentCognitiveLoad,
    required this.suggestedWindow,
    required this.reasonText,
  });

  final String routineId;
  final String routineTitle;
  final CognitiveLoad currentCognitiveLoad;
  final String suggestedWindow;
  final String reasonText;
}

@immutable
class CognitiveRoutingOutput {
  const CognitiveRoutingOutput({
    required this.dateStr,
    required this.isActive,
    required this.suggestion,
  });

  final String dateStr;
  final bool isActive;
  final CognitiveRoutingSuggestion? suggestion;

  factory CognitiveRoutingOutput.inactive(String dateStr) {
    return CognitiveRoutingOutput(
      dateStr: dateStr,
      isActive: false,
      suggestion: null,
    );
  }
}

/// Cognitive Routing Engine (Daniel Pink Cognitive Timing — §6, م-۵)
class CognitiveRoutingEngine
    implements CachedEngine<CognitiveRoutingInput, CognitiveRoutingOutput> {
  static const int minEnergySamplesRequired = 14;

  @override
  bool canRun(CognitiveRoutingInput input) => input.dateStr.isNotEmpty;

  @override
  List<Type> dependencies() => [EnergyAnalyticsEngine];

  @override
  Duration get ttl => const Duration(minutes: 15);

  @override
  void invalidate() {}

  @override
  String fingerprint(CognitiveRoutingInput input) => input.toString();

  @override
  Future<CognitiveRoutingOutput> calculate(CognitiveRoutingInput input) async {
    // Constraint (ج): Requires >= 14 days of energy sample data
    if (input.energyOutput.sampleCount < minEnergySamplesRequired) {
      return CognitiveRoutingOutput.inactive(input.dateStr);
    }

    final peakWindow = input.energyOutput.peakPerformanceWindow;
    final fatiguedWindow = input.energyOutput.mostFatiguedWindow;

    CognitiveRoutingSuggestion? selectedSuggestion;

    for (final r in input.routines) {
      // Constraint (الف): Worship (religious), medical, isEssential items NEVER suggested to move
      final category = (r['category'] as String? ?? '').toLowerCase();
      final isEssential = (r['isEssential'] as int? ?? 0) == 1 ||
          (r['isEssential'] as bool? ?? false);
      if (category == 'religious' || category == 'medical' || isEssential) {
        continue;
      }

      final loadStr = (r['cognitiveLoad'] as String? ?? '').toUpperCase();
      CognitiveLoad load = CognitiveLoad.none;
      if (loadStr == 'ANALYTICAL') {
        load = CognitiveLoad.analytical;
      } else if (loadStr == 'ADMINISTRATIVE') {
        load = CognitiveLoad.administrative;
      } else if (loadStr == 'CREATIVE') {
        load = CognitiveLoad.creative;
      } else if (loadStr == 'PHYSICAL') {
        load = CognitiveLoad.physical;
      }

      if (load == CognitiveLoad.none) continue;

      final title = r['title'] as String? ?? 'روتین';
      final routineId = r['id'] as String? ?? '';

      // Match cognitive load to window
      if (load == CognitiveLoad.analytical && peakWindow != null && peakWindow.isNotEmpty) {
        selectedSuggestion = CognitiveRoutingSuggestion(
          routineId: routineId,
          routineTitle: title,
          currentCognitiveLoad: load,
          suggestedWindow: peakWindow,
          reasonText: 'فعالیت تحلیلی «$title» برای بهره‌وری حداکثری به پنجرهٔ اوج انرژی ($peakWindow) منتقل شود.',
        );
        break; // Constraint (د): Maximum 1 suggestion per day
      } else if (load == CognitiveLoad.administrative && fatiguedWindow != null && fatiguedWindow.isNotEmpty) {
        selectedSuggestion = CognitiveRoutingSuggestion(
          routineId: routineId,
          routineTitle: title,
          currentCognitiveLoad: load,
          suggestedWindow: fatiguedWindow,
          reasonText: 'فعالیت اداری و مکانیکی «$title» به بازهٔ کم‌فشارتر ($fatiguedWindow) منتقل شود تا انرژی اوج ذخیره گردد.',
        );
        break; // Constraint (د): Maximum 1 suggestion per day
      }
    }

    return CognitiveRoutingOutput(
      dateStr: input.dateStr,
      isActive: true,
      suggestion: selectedSuggestion,
    );
  }
}
