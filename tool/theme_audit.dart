import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Error: lib directory not found.');
    exit(1);
  }

  int hardcodedColors = 0;
  int materialColors = 0;
  int oldOpacity = 0;
  int duplicateFont = 0;
  int scatteredBlur = 0;
  int manualShadow = 0;

  final files = libDir.listSync(recursive: true).whereType<File>();

  for (final file in files) {
    if (!file.path.endsWith('.dart')) continue;

    final isFeatures = file.path.contains('lib${Platform.pathSeparator}features');
    final isCoreTheme = file.path.contains('lib${Platform.pathSeparator}core${Platform.pathSeparator}theme');
    if (isCoreTheme) continue;

    final content = file.readAsStringSync();
    final lines = content.split('\n');

    for (final line in lines) {
      if (line.trim().startsWith('//')) continue;

      if (isFeatures && line.contains('Color(0x')) {
        hardcodedColors++;
      }
      if (isFeatures && line.contains('Colors.')) {
        materialColors++;
      }
      if (line.contains('withOpacity(')) {
        oldOpacity++;
      }
      if (isFeatures && line.contains('fontFamily')) {
        duplicateFont++;
      }
      if (isFeatures && line.contains('BackdropFilter')) {
        scatteredBlur++;
      }
      if (isFeatures && line.contains('BoxShadow(')) {
        manualShadow++;
      }
    }
  }

  final reportContent = '''
# Theme Migration Audit Report

Generated At: ${DateTime.now().toIso8601String()}

## Audit Metrics Summary

| Metric | Pattern | Scope | Count | Target |
|---|---|---|---|---|
| Hardcoded Colors | `Color(0x` | `lib/features/` | $hardcodedColors | 0 |
| Material Colors | `Colors.` | `lib/features/` | $materialColors | 0 |
| Old Opacity | `withOpacity(` | `lib/` | $oldOpacity | 0 |
| Duplicate Font | `fontFamily` | `lib/features/` | $duplicateFont | 0 |
| Scattered Blur | `BackdropFilter` | `lib/features/` | $scatteredBlur | 0 |
| Manual Shadow | `BoxShadow(` | `lib/features/` | $manualShadow | 0 |

''';

  File('docs/theme_migration.md').writeAsStringSync(reportContent);
  print(reportContent);
}
