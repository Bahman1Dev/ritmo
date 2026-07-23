class CyclePrivacyGuard {
  static bool isVisible(Map<String, String> settings) {
    return settings['user_gender'] == 'FEMALE';
  }
}
