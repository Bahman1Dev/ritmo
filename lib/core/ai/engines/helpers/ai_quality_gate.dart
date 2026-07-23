import 'package:ritmo/core/ai/engines/helpers/sensitive_reflection_filter.dart';
import 'package:ritmo/core/behavior/models/behavior_snapshot.dart';

class AIQualityGate {
  /// Filters the daily digest JSON map based on quality, evidence, and safety rules from the BehaviorSnapshot.
  static Map<String, dynamic> filterDigest(Map<String, dynamic> digestJson, BehavioralSnapshot snapshot) {
    // Create a mutable copy of the digest map to avoid mutating the original
    final filtered = Map<String, dynamic>.from(digestJson);

    final coverage = snapshot.sparseData;
    final evidence = snapshot.evidence;

    // Rule 1 & 2: Check evidence and coverage per domain.
    // If coverage is sparse, set key to empty/insufficient or remove it.

    // Routines
    if (!coverage.enoughRoutine || evidence.level == EvidenceLevel.LOW || evidence.level == EvidenceLevel.UNKNOWN) {
      filtered.remove('routines_summary');
      filtered['routines_summary'] = {'status': 'insufficient_data'};
      if (filtered.containsKey('rhythm')) {
        filtered['rhythm'] = {
          'status': 'insufficient_data'
        };
      }
    }

    // Sleep
    if (!coverage.enoughSleep) {
      filtered.remove('sleep');
      filtered['sleep'] = {'status': 'insufficient_data'};
    }

    // Energy
    if (!coverage.enoughEnergy) {
      filtered.remove('energy');
      filtered['energy'] = {'status': 'insufficient_data'};
    }

    // Goals
    if (!coverage.enoughGoals) {
      filtered.remove('goals');
      filtered['goals'] = {'status': 'insufficient_data'};
    }

    // Study/Courses/Konkur
    if (!coverage.enoughStudy) {
      filtered.remove('courses');
      filtered.remove('konkur');
      filtered['courses'] = {'status': 'insufficient_data'};
      filtered['konkur'] = {'status': 'insufficient_data'};
    }

    // Reflection
    if (!coverage.enoughReflection) {
      filtered.remove('reflection');
      filtered['reflection'] = {'status': 'insufficient_data'};
    } else {
      // Rule 4: Clean reflections topic / victory list in the digest for safety
      if (filtered.containsKey('reflection') && filtered['reflection'] is Map) {
        final reflectionMap = filtered['reflection'] as Map;
        if (reflectionMap.containsKey('dominantThemes') && reflectionMap['dominantThemes'] is List) {
          final themes = reflectionMap['dominantThemes'] as List;
          final cleanThemes = themes.where((t) => !SensitiveReflectionFilter.isSensitive(t.toString())).toList();
          reflectionMap['dominantThemes'] = cleanThemes;
        }
      }
    }

    // Clean reflection memory from snapshot if any contains sensitive keywords
    if (filtered.containsKey('reflectionMemory') && filtered['reflectionMemory'] is Map) {
      final mem = filtered['reflectionMemory'] as Map;
      if (mem.containsKey('recurringTopics') && mem['recurringTopics'] is List) {
        mem['recurringTopics'] = (mem['recurringTopics'] as List).where((t) {
          final topic = t is Map ? (t['topic']?.toString() ?? '') : t.toString();
          return !SensitiveReflectionFilter.isSensitive(topic);
        }).toList();
      }
      if (mem.containsKey('victories') && mem['victories'] is List) {
        mem['victories'] = (mem['victories'] as List).where((v) {
          final title = v is Map ? (v['title']?.toString() ?? '') : v.toString();
          return !SensitiveReflectionFilter.isSensitive(title);
        }).toList();
      }
      if (mem.containsKey('recurringProblems') && mem['recurringProblems'] is List) {
        mem['recurringProblems'] = (mem['recurringProblems'] as List).where((p) {
          final problem = p is Map ? (p['problem']?.toString() ?? '') : p.toString();
          return !SensitiveReflectionFilter.isSensitive(problem);
        }).toList();
      }
      if (mem.containsKey('commitments') && mem['commitments'] is List) {
        mem['commitments'] = (mem['commitments'] as List).where((c) {
          final promise = c is Map ? (c['promise']?.toString() ?? '') : c.toString();
          return !SensitiveReflectionFilter.isSensitive(promise);
        }).toList();
      }
    }

    // Rule 3: Outdated fingerprint check.
    // If evidence level is UNKNOWN or LOW, exclude fingerprint from prompts
    if (evidence.level == EvidenceLevel.UNKNOWN || evidence.level == EvidenceLevel.LOW) {
      filtered.remove('fingerprint');
    }

    return filtered;
  }
}
