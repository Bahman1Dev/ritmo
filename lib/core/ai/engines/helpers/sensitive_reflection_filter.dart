class SensitiveReflectionFilter {
  static const List<String> cycleKeywords = [
    'cycle', 'hormone', 'hormonal', 'menstrual', 'period', 'pregnancy', 'contraceptive',
    'چرخه', 'قاعدگی', 'پریود', 'هورمون', 'عادت ماهیانه', 'پریودی', 'سیکل'
  ];

  static const List<String> medicalKeywords = [
    'dose', 'dosage', 'medicine', 'medication', 'medical', 'prescription', 'health',
    'clinic', 'hospital', 'doctor', 'treatment', 'test', 'blood',
    'دارو', 'دوز', 'قرص', 'آمپول', 'نسخه', 'پزشکی', 'پزشک', 'سلامت', 'بیماری', 'درمان',
    'دکتر', 'بیمارستان', 'کلینیک', 'مطب', 'آزمایش', 'آزمایشگاه', 'تست'
  ];

  /// Returns true if the text contains any cycle/hormonal/pregnancy terms
  /// or medical/doctor/treatment terms, meaning it is sensitive and should be filtered out.
  static bool isSensitive(String text) {
    if (text.isEmpty) return false;
    final lowercaseText = text.toLowerCase();
    
    // Check cycle keywords
    for (final kw in cycleKeywords) {
      if (lowercaseText.contains(kw)) {
        return true;
      }
    }

    // Check medical keywords
    for (final kw in medicalKeywords) {
      if (lowercaseText.contains(kw)) {
        return true;
      }
    }

    return false;
  }
}
