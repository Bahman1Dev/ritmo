import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/features/supplementary_sports/domain/prescription/session_prescription.dart';

class MuscleGroup {
  const MuscleGroup({
    required this.code,
    required this.titleFa,
    required this.region,
    this.emoji,
  });

  final String code;
  final String titleFa;
  final String region;
  final String? emoji;

  static const Map<String, MuscleGroup> taxonomy = {
    'CHEST': MuscleGroup(code: 'CHEST', titleFa: 'سینه', region: 'UPPER', emoji: '🫁'),
    'SHOULDER': MuscleGroup(code: 'SHOULDER', titleFa: 'سرشانه', region: 'UPPER', emoji: '🎯'),
    'BICEPS': MuscleGroup(code: 'BICEPS', titleFa: 'جلوبازو', region: 'UPPER', emoji: '💪'),
    'TRICEPS': MuscleGroup(code: 'TRICEPS', titleFa: 'پشت‌بازو', region: 'UPPER', emoji: '🦾'),
    'BACK': MuscleGroup(code: 'BACK', titleFa: 'زیربغل و پشت', region: 'UPPER', emoji: '🪽'),
    'CORE': MuscleGroup(code: 'CORE', titleFa: 'شکم و مرکز', region: 'CORE', emoji: '🎽'),
    'QUADS_GLUTES': MuscleGroup(code: 'QUADS_GLUTES', titleFa: 'ران و باسن', region: 'LOWER', emoji: '🦵'),
    'HAMSTRINGS': MuscleGroup(code: 'HAMSTRINGS', titleFa: 'پشت ران', region: 'LOWER', emoji: '🦿'),
    'CALVES': MuscleGroup(code: 'CALVES', titleFa: 'ساق پا', region: 'LOWER', emoji: '🎯'),
    'CARDIO': MuscleGroup(code: 'CARDIO', titleFa: 'هوازی', region: 'CARDIO', emoji: '🫀'),
    'MOBILITY': MuscleGroup(code: 'MOBILITY', titleFa: 'تحرک و کشش', region: 'MOBILITY', emoji: '🧘'),
    'FULL_BODY': MuscleGroup(code: 'FULL_BODY', titleFa: 'کل بدن', region: 'FULL', emoji: '🔥'),
  };

  static String buildHeadline(int minutes, List<String> codes, SlotType type) {
    if (type == SlotType.rest) {
      return 'استراحت';
    }
    if (type == SlotType.activeRest) {
      return 'ریکاوری فعال';
    }

    final minFa = RitmoNumber.fa(minutes);

    // If more than 3 codes or contains FULL_BODY, resolve to FULL_BODY
    List<String> effectiveCodes = List<String>.from(codes);
    if (effectiveCodes.length > 3 || effectiveCodes.contains('FULL_BODY')) {
      effectiveCodes = ['FULL_BODY'];
    }

    if (effectiveCodes.isEmpty) {
      return '$minFa دقیقه ${type.labelFa}';
    }

    final labels = effectiveCodes
        .map((code) => taxonomy[code.toUpperCase()]?.titleFa)
        .whereType<String>()
        .toList();

    if (labels.isEmpty) {
      return '$minFa دقیقه ${type.labelFa}';
    }

    // Join with Persian rules
    String groupText = '';
    if (labels.length == 1) {
      groupText = labels.first;
    } else if (labels.length == 2) {
      groupText = '${labels[0]} و ${labels[1]}';
    } else {
      groupText = '${labels[0]}، ${labels[1]} و ${labels[2]}';
    }

    return '$minFa دقیقه $groupText';
  }
}
