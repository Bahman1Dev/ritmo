import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/features/cycle/models/cycle_intelligence_models.dart';

class CycleBurdenEngine {
  static BodyBurdenScore calculateBurden({
    required CyclePhase phase,
    required int dayOfPeriod,
    required String? flowIntensity,
    required List<String> loggedSymptoms,
    required String? energyTag,
    required double? sleepHours,
  }) {
    var score = 10.0;
    final reasonsFa = <String>[];

    // Phase impact
    if (phase == CyclePhase.menstrual) {
      score += 35.0;
      reasonsFa.add('دوره فعال قاعدگی');
    } else if (phase == CyclePhase.luteal) {
      score += 20.0;
      reasonsFa.add('فاز لوتئال (قبل از دوره)');
    }

    // Flow intensity impact
    if (flowIntensity == 'HEAVY') {
      score += 25.0;
      reasonsFa.add('خونریزی شدید');
    } else if (flowIntensity == 'MEDIUM') {
      score += 15.0;
    }

    // Symptoms impact
    if (loggedSymptoms.isNotEmpty) {
      final symScore = (loggedSymptoms.length * 8.0).clamp(0.0, 30.0);
      score += symScore;
      reasonsFa.add('${loggedSymptoms.length} علامت بدنی ثبت شده');
    }

    // Energy tag impact
    if (energyTag == 'LOW') {
      score += 15.0;
      reasonsFa.add('سطح انرژی پایین');
    }

    // Sleep hours impact
    if (sleepHours != null && sleepHours < 6.0) {
      score += 15.0;
      reasonsFa.add('کمبود خواب دیشب');
    }

    final finalScore = score.clamp(0.0, 100.0);
    final level = finalScore >= 60.0
        ? 'HIGH'
        : (finalScore >= 35.0 ? 'MODERATE' : 'LOW');

    return BodyBurdenScore(
      score: finalScore,
      level: level,
      reasonsFa: reasonsFa,
    );
  }
}
