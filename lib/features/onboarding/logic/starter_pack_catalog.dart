import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/features/onboarding/models/focus_area.dart';

class StarterRoutineTemplate {
  const StarterRoutineTemplate({
    required this.id,
    required this.titleFa,
    required this.category,
    required this.durationMinutes,
    required this.defaultTime,
    required this.forAreas,
  });

  final String id;
  final String titleFa;
  final Category category;
  final int durationMinutes;
  final String defaultTime; // 'HH:mm'
  final List<FocusArea> forAreas;
}

class StarterPackCatalog {
  const StarterPackCatalog._();

  static final List<StarterRoutineTemplate> allTemplates = [
    StarterRoutineTemplate(
      id: 'water_habit',
      titleFa: '💧 نوشیدن آب',
      category: Category.fitness,
      durationMinutes: DurationBounds.defaultMinutes,
      defaultTime: '08:00',
      forAreas: const [FocusArea.health],
    ),
    StarterRoutineTemplate(
      id: 'morning_stretch',
      titleFa: '🧘 کشش و نرمش صبحگاهی',
      category: Category.fitness,
      durationMinutes: 15,
      defaultTime: '07:30',
      forAreas: const [FocusArea.sport, FocusArea.health],
    ),
    StarterRoutineTemplate(
      id: 'focus_reading',
      titleFa: '📖 مطالعه عمیق',
      category: Category.personal,
      durationMinutes: 30,
      defaultTime: '21:00',
      forAreas: const [FocusArea.study, FocusArea.skill],
    ),
    StarterRoutineTemplate(
      id: 'daily_planning',
      titleFa: '📋 برنامه‌ریزی کاری روزانه',
      category: Category.work,
      durationMinutes: 15,
      defaultTime: '08:30',
      forAreas: const [FocusArea.work, FocusArea.income],
    ),
    StarterRoutineTemplate(
      id: 'night_winddown',
      titleFa: '🌙 آماده‌سازی برای خواب',
      category: Category.fitness,
      durationMinutes: 20,
      defaultTime: '22:30',
      forAreas: const [FocusArea.sleep, FocusArea.stress],
    ),
    StarterRoutineTemplate(
      id: 'family_checkin',
      titleFa: '🏡 زمان با خانواده',
      category: Category.personal,
      durationMinutes: 30,
      defaultTime: '20:00',
      forAreas: const [FocusArea.family],
    ),
    StarterRoutineTemplate(
      id: 'quiet_reflection',
      titleFa: '🤲 خلوت و عبادت',
      category: Category.religious,
      durationMinutes: 15,
      defaultTime: '05:30',
      forAreas: const [FocusArea.worship],
    ),
  ];

  /// Suggests 3 to 5 templates tailored to the selected focus areas.
  /// Falls back to 3 default general templates if no area selected.
  static List<StarterRoutineTemplate> suggestFor(Set<FocusArea> areas) {
    if (areas.isEmpty) {
      return allTemplates.take(3).toList();
    }

    final matched = <StarterRoutineTemplate>[];
    for (final template in allTemplates) {
      if (template.forAreas.any((a) => areas.contains(a))) {
        matched.add(template);
      }
    }

    if (matched.isEmpty) {
      return allTemplates.take(3).toList();
    }

    return matched.take(5).toList();
  }
}
