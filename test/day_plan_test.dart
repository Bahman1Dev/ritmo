// test/day_plan_test.dart
//
// Unit tests for AI Day Planner subsystems.
// Run with: flutter test test/day_plan_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/assistant/logic/day_plan_composer.dart';
import 'package:ritmo/features/assistant/logic/duration_estimator.dart';
import 'package:ritmo/features/assistant/models/day_plan_models.dart';

void main() {
  group('DayPlanDraft JSON Parsing', () {
    test('parses a valid JSON with items, questions, and suggestions', () {
      final json = {
        'planDate': '2026-07-16',
        'items': [
          {
            'title': 'بیدار شدن',
            'targetModule': 'sleep',
            'start': {
              'kind': 'clock',
              'time': '06:00',
              'offsetMin': 0,
              'bufferMin': 0,
            },
            'durationMin': 5,
            'durationSource': 'llm',
            'recurrence': 'daily',
            'category': 'personal',
            'confidence': 0.95,
            'note': null,
          },
          {
            'title': 'نماز صبح',
            'targetModule': 'worship',
            'start': {
              'kind': 'anchor',
              'anchorEvent': 'FAJR',
              'offsetMin': 10,
              'bufferMin': 0,
            },
            'durationMin': 15,
            'durationSource': 'llm',
            'recurrence': 'daily',
            'category': 'worship',
            'confidence': 0.98,
          },
        ],
        'questions': [
          {
            'id': 'q1',
            'text': 'ساعت ناهار چنده؟',
            'quickReplies': ['۱۲:۳۰', '۱:۰۰', '۱:۳۰'],
          },
        ],
        'suggestions': [
          {
            'text': 'بهتره ساعت خواب رو زودتر بزاری',
            'action': 'setBedtime',
          },
        ],
      };

      final draft = DayPlanDraft.fromJson(json);

      expect(draft.planDate, '2026-07-16');
      expect(draft.items.length, 2);
      expect(draft.items[0].title, 'بیدار شدن');
      expect(draft.items[0].targetModule, 'sleep');
      expect(draft.items[0].startKind, 'clock');
      expect(draft.items[0].startTime, '06:00');
      expect(draft.items[0].durationMin, 5);
      expect(draft.items[0].recurrence, 'daily');

      expect(draft.items[1].title, 'نماز صبح');
      expect(draft.items[1].startKind, 'anchor');
      expect(draft.items[1].anchorEvent, 'FAJR');
      expect(draft.items[1].offsetMin, 10);

      expect(draft.questions.length, 1);
      expect(draft.questions[0].text, 'ساعت ناهار چنده؟');
      expect(draft.questions[0].quickReplies.length, 3);

      expect(draft.suggestions.length, 1);
      expect(draft.suggestions[0].text, 'بهتره ساعت خواب رو زودتر بزاری');
    });

    test('handles empty items/questions/suggestions gracefully', () {
      final json = {
        'planDate': '2026-07-16',
        'items': [],
        'questions': [],
        'suggestions': [],
      };

      final draft = DayPlanDraft.fromJson(json);

      expect(draft.planDate, '2026-07-16');
      expect(draft.items, isEmpty);
      expect(draft.questions, isEmpty);
      expect(draft.suggestions, isEmpty);
    });

    test('handles missing optional fields with defaults', () {
      final json = {
        'planDate': '2026-07-16',
        'items': [
          {
            'title': 'تست',
            'start': {},
          },
        ],
      };

      final draft = DayPlanDraft.fromJson(json);

      expect(draft.items.length, 1);
      expect(draft.items[0].title, 'تست');
      expect(draft.items[0].targetModule, 'routine');
      expect(draft.items[0].startKind, 'clock');
      expect(draft.items[0].durationMin, isNull);
      expect(draft.items[0].durationSource, 'none');
      expect(draft.items[0].recurrence, 'oneOff');
      expect(draft.items[0].category, 'personal');
      expect(draft.items[0].confidence, 1.0);
    });

    test('toJson roundtrip preserves all data', () {
      final original = DayPlanDraft(
        planDate: '2026-07-16',
        items: [
          DayPlanItemDraft(
            title: 'ورزش',
            targetModule: 'routine',
            startKind: 'clock',
            startTime: '18:00',
            durationMin: 60,
            durationSource: 'user',
            recurrence: 'daily',
            category: 'fitness',
            confidence: 0.9,
          ),
        ],
        questions: [],
        suggestions: [],
      );

      final json = original.toJson();
      final restored = DayPlanDraft.fromJson(json);

      expect(restored.planDate, original.planDate);
      expect(restored.items.length, 1);
      expect(restored.items[0].title, 'ورزش');
      expect(restored.items[0].startTime, '18:00');
      expect(restored.items[0].durationMin, 60);
      expect(restored.items[0].category, 'fitness');
    });
  });

  group('DayPlanItemDraft mutability', () {
    test('can modify title, durationMin, recurrence', () {
      final item = DayPlanItemDraft(
        title: 'قدیم',
        targetModule: 'routine',
        startKind: 'clock',
        durationSource: 'llm',
        recurrence: 'oneOff',
        category: 'personal',
      );

      item.title = 'جدید';
      item.durationMin = 45;
      item.recurrence = 'daily';

      expect(item.title, 'جدید');
      expect(item.durationMin, 45);
      expect(item.recurrence, 'daily');
    });
  });

  group('DayPlanDraft copyWith', () {
    test('creates a new instance with overridden fields', () {
      final original = DayPlanDraft(
        planDate: '2026-07-16',
        items: [],
        questions: [],
        suggestions: [],
      );

      final modified = original.copyWith(planDate: '2026-07-17');

      expect(modified.planDate, '2026-07-17');
      expect(original.planDate, '2026-07-16');
    });
  });

  group('DurationEstimator', () {
    test('getIranianDefaultMinutes returns known defaults', () {
      expect(DurationEstimator.getIranianDefaultMinutes('نماز صبح'), 15);
      expect(DurationEstimator.getIranianDefaultMinutes('نماز ظهر'), 15);
      expect(DurationEstimator.getIranianDefaultMinutes('صبحانه'), 20);
      expect(DurationEstimator.getIranianDefaultMinutes('ناهار'), 30);
      expect(DurationEstimator.getIranianDefaultMinutes('شام'), 30);
      expect(DurationEstimator.getIranianDefaultMinutes('ورزش'), 60);
      expect(DurationEstimator.getIranianDefaultMinutes('پیاده‌روی'), 30);
      expect(DurationEstimator.getIranianDefaultMinutes('دوش'), 20);
    });

    test('getIranianDefaultMinutes returns null for unknown titles', () {
      expect(DurationEstimator.getIranianDefaultMinutes('فعالیت ناشناخته'), isNull);
      expect(DurationEstimator.getIranianDefaultMinutes('xyz'), isNull);
    });
  });

  group('DayPlanTemplate Model and Result', () {
    test('DayPlanTemplate model construction', () {
      final template = DayPlanTemplate(
        id: 'tpl1',
        name: 'روز کاری',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastUsedAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        items: [
          DayPlanItemDraft(
            title: 'ورزش',
            targetModule: 'routine',
            startKind: 'clock',
            startTime: '08:00',
            durationMin: 30,
            durationSource: 'llm',
            recurrence: 'oneOff',
            category: 'fitness',
          ),
        ],
        useCount: 3,
      );

      expect(template.id, 'tpl1');
      expect(template.name, 'روز کاری');
      expect(template.items.length, 1);
      expect(template.useCount, 3);
    });

    test('DayPlanComposeResult properties', () {
      final resSingle = DayPlanComposeResult(
        singleDraft: DayPlanDraft(planDate: '2026-07-16', items: [], questions: [], suggestions: []),
      );
      expect(resSingle.isSingleDay, true);
      expect(resSingle.isMultiDay, false);
      expect(resSingle.isTemplateApply, false);

      final resMulti = DayPlanComposeResult(
        multiDayDrafts: [
          DayPlanDraft(planDate: '2026-07-16', items: [], questions: [], suggestions: []),
          DayPlanDraft(planDate: '2026-07-17', items: [], questions: [], suggestions: []),
        ],
      );
      expect(resMulti.isMultiDay, true);
      expect(resMulti.isSingleDay, false);

      final resTemplate = DayPlanComposeResult(
        applyTemplateName: 'روز کاری',
        applyTemplateDate: '2026-07-16',
      );
      expect(resTemplate.isTemplateApply, true);
      expect(resTemplate.applyTemplateName, 'روز کاری');
    });
  });
}
