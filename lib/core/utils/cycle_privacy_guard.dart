class CyclePrivacyGuard {
  static bool isVisible(Map<String, String> settings) {
    final val = (settings['user_gender'] ?? '').trim().toUpperCase();
    return val == 'FEMALE' || val == 'WOMAN' || val == 'ZAN' || val == 'زن';
  }
}
