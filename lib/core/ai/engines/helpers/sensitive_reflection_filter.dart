class SensitiveReflectionFilter {
  static const List<String> cycleKeywords = [
    'menstrual', 'period', 'pregnancy', 'contraceptive', 'hormonal',
    'چرخه قاعدگی', 'سیکل قاعدگی', 'قاعدگی', 'پریود', 'هورمون', 'عادت ماهیانه', 'پریودی'
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
