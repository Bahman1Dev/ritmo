import 'dart:math';

/// Utility class for normalizing Persian text and calculating text similarity.
class TextSimilarity {
  TextSimilarity._();

  /// Normalizes Persian text by unifying characters and removing diacritics.
  static String normalize(String input) {
    if (input.isEmpty) return '';

    String text = input;
    // Replace Arabic Kaf and Yeh with Persian equivalents
    text = text.replaceAll('ك', 'ک').replaceAll('ي', 'ی').replaceAll('ى', 'ی');

    // Remove Persian/Arabic diacritics
    text = text.replaceAll(RegExp(r'[\u064B-\u0652\u0670]'), '');

    // Replace ZWNJ with space
    text = text.replaceAll('\u200c', ' ');

    return text.trim();
  }

  /// Computes similarity score between two strings (0.0 to 1.0).
  static double similarity(String s1, String s2) {
    final n1 = normalize(s1).toLowerCase();
    final n2 = normalize(s2).toLowerCase();

    if (n1 == n2) return 1.0;
    if (n1.isEmpty || n2.isEmpty) return 0.0;

    // Substring contains check
    if (n1.contains(n2) || n2.contains(n1)) {
      final minLen = min(n1.length, n2.length).toDouble();
      final maxLen = max(n1.length, n2.length).toDouble();
      return minLen / maxLen;
    }

    // Levenshtein distance calculation
    final distance = _levenshteinDistance(n1, n2);
    final maxLength = max(n1.length, n2.length);
    if (maxLength == 0) return 1.0;

    return (1.0 - (distance / maxLength)).clamp(0.0, 1.0);
  }

  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final v0 = List<int>.generate(s2.length + 1, (i) => i);
    final v1 = List<int>.filled(s2.length + 1, 0);

    for (var i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < s2.length; j++) {
        final cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (var j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}
