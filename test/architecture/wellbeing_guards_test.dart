import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return const <File>[];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
}

List<String> _matching(String dir, RegExp re, {Set<String> allow = const {}}) {
  final hits = <String>[];
  for (final f in _dartFiles(dir)) {
    final normalized = f.path.replaceAll(r'\', '/');
    if (allow.any(normalized.endsWith)) continue;
    if (re.hasMatch(f.readAsStringSync())) hits.add(normalized);
  }
  return hits;
}

void main() {
  test('no hardcoded hex colors inside the wellbeing feature', () {
    final hits = _matching(
        'lib/features/wellbeing', RegExp(r'0x[fF][fF][0-9a-fA-F]{6}'));
    expect(hits, isEmpty,
        reason: 'W-36: رنگ هاردکد بازگشته است: $hits');
  });

  test('only RitmoDate may build day keys', () {
    final hits = _matching(
      'lib',
      RegExp(r'toIso8601String\(\)\s*\.\s*substring\('),
      allow: {'lib/core/util/ritmo_date.dart'},
    );
    expect(hits, isEmpty,
        reason: 'W-12: مبنای زمانی دوم بازگشته است: $hits');
  });

  test('features never instantiate engines directly', () {
    final hits = _matching(
      'lib/features',
      RegExp(
        r'\b(EnergyAnalyticsEngine|MoodEngine|SleepEngine|ReflectionEngine'
        r'|LifeBalanceEngine|CycleEngine)\(\)\s*\.\s*calculate',
      ),
    );
    expect(hits, isEmpty,
        reason: 'W-25: موتور بدون گذرگاه صدا زده شده: $hits');
  });

  test('wellbeing sheets go through RitmoSheetScaffold', () {
    final hits = _matching(
      'lib/features/wellbeing',
      RegExp(r'showModalBottomSheet\s*<'),
    );
    expect(hits, isEmpty,
        reason: 'W-45: شیت خام بازگشته است: $hits');
  });

  test('analytics engines never read the wall clock', () {
    final hits =
        _matching('lib/core/analytics', RegExp(r'DateTime\s*\.\s*now\(\)'));
    expect(hits, isEmpty,
        reason: 'W-18 / قانون ۱۰: موتور باید زمان تزریقی بگیرد: $hits');
  });

  test('no persian strings inside core analytics', () {
    final hits =
        _matching('lib/core/analytics', RegExp(r"'[^']*[؀-ۿ][^']*'"));
    expect(hits, isEmpty,
        reason: 'قانون ۹: متن فارسی در core: $hits');
  });

  test('no magic sentinel numbers in analytics', () {
    final hits = _matching('lib/core/analytics', RegExp(r'-999'));
    expect(hits, isEmpty, reason: 'W-06: مقدار جادویی -999: $hits');
  });
}
