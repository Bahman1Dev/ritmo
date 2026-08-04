import 'dart:io';

void main() {
  final patterns = [
    (name: 'showModalBottomSheet', paths: ['lib'], pattern: 'showModalBottomSheet'),
    (name: 'Vazirmatn', paths: ['lib'], pattern: 'Vazirmatn'),
    (name: 'Color(0x in scope', paths: ['lib/features/today', 'lib/features/routines', 'lib/features/onboarding'], pattern: 'Color(0x'),
    (name: 'CircularProgressIndicator', paths: ['lib'], pattern: 'CircularProgressIndicator'),
    (name: 'catch (_)', paths: ['lib'], pattern: 'catch (_)'),
    (name: 'Directionality(', paths: ['lib'], pattern: 'Directionality('),
    (name: 'Icons.arrow_back', paths: ['lib'], pattern: 'Icons.arrow_back'),
    (name: 'fontSize: 9', paths: ['lib'], pattern: RegExp(r'fontSize:\s*9\b')),
    (name: 'fontSize: 10', paths: ['lib'], pattern: RegExp(r'fontSize:\s*10\b')),
    (name: 'fontSize: 11', paths: ['lib'], pattern: RegExp(r'fontSize:\s*11\b')),
  ];

  print('=== Phase 0 Baseline Quantitative Audit ===');
  for (final p in patterns) {
    int count = 0;
    for (final path in p.paths) {
      final dir = Directory(path);
      if (!dir.existsSync()) continue;
      for (final file in dir.listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          final content = file.readAsStringSync();
          if (p.pattern is String) {
            final str = p.pattern as String;
            int idx = 0;
            while ((idx = content.indexOf(str, idx)) != -1) {
              count++;
              idx += str.length;
            }
          } else if (p.pattern is RegExp) {
            count += (p.pattern as RegExp).allMatches(content).length;
          }
        }
      }
    }
    print('${p.name}: $count');
  }
}
