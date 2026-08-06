class SettingsFlags {
  SettingsFlags({
    required this.isFemale,
    required this.cycleConsent,
    required this.cycleModuleEnabled,
    required this.proactiveAssistantEnabled,
    required this.briefingEnabled,
    required this.energyTuningEnabled,
  });

  factory SettingsFlags.fromMap(Map<String, String> m) {
    final gender = m['user_gender'] ?? 'MALE';
    final female = gender.toUpperCase() == 'FEMALE';
    final consent = (m['cycle_consent'] ?? 'false') == 'true';
    final module = (m['module_cycle_enabled'] ?? 'true') == 'true';
    final proactive = (m['proactive_assistant_enabled'] ?? 'true') == 'true';
    final briefing = (m['briefing_enabled'] ?? 'true') == 'true';
    final energy = (m['energy_tuning_enabled'] ?? 'true') == 'true';
    return SettingsFlags(
      isFemale: female,
      cycleConsent: consent,
      cycleModuleEnabled: module,
      proactiveAssistantEnabled: proactive,
      briefingEnabled: briefing,
      energyTuningEnabled: energy,
    );
  }

  final bool isFemale;
  final bool cycleConsent;
  final bool cycleModuleEnabled;
  final bool proactiveAssistantEnabled;
  final bool briefingEnabled;
  final bool energyTuningEnabled;

  /// Rule M-12: Female ONLY + explicit consent + enabled module
  bool get canShowCycle => isFemale && cycleConsent && cycleModuleEnabled;
}
