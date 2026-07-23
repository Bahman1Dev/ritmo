class SSMuscleImageResolver {
  static String resolve(String workoutName, String? gender, {int level = 2}) {
    final name = workoutName.toLowerCase();
    final g = (gender ?? '').toUpperCase();
    
    // Explicitly check for female variants. Default to MALE if unspecified or male ('MALE', 'MAN', 'M', 'مرد', etc.)
    final isFemale = g == 'FEMALE' || g == 'WOMAN' || g == 'ZAN' || g == 'F' || g == 'زن';
    final l = level.clamp(1, 3);

    // 0. Full Body Holographic Biometric Scan
    if (name == 'full_body') {
      return isFemale
          ? 'assets/images/ss_female_body_scan.jpg'
          : 'assets/images/ss_male_body_scan.jpg';
    }

    // 1. Legs, Calves, Glutes, Thighs (ران و باسن و ساق پا)
    if (name.contains('پا') ||
        name.contains('ساق') ||
        name.contains('ران') ||
        name.contains('باسن') ||
        name.contains('leg') ||
        name.contains('glute') ||
        name.contains('calf')) {
      return isFemale
          ? 'assets/images/cover_female_leg_$l.webp'
          : 'assets/images/cover_leg_$l.webp';
    }

    // 2. Abs, Core, Waist (شکم و پهلو)
    if (name.contains('شکم') ||
        name.contains('پلو') ||
        name.contains('پهلو') ||
        name.contains('abs') ||
        name.contains('core')) {
      return isFemale
          ? 'assets/images/cover_female_abs_$l.webp'
          : 'assets/images/cover_abs_$l.webp';
    }

    // 3. Chest (سینه)
    if (name.contains('سینه') || name.contains('chest') || name.contains('pec')) {
      return isFemale
          ? 'assets/images/cover_female_chest_$l.webp'
          : 'assets/images/cover_chest_$l.webp';
    }

    // 4. Arms, Biceps, Triceps (بازو، جلوبازو، پشت بازو)
    if (name.contains('بازو') ||
        name.contains('جلو بازو') ||
        name.contains('پشت بازو') ||
        name.contains('arm') ||
        name.contains('biceps') ||
        name.contains('triceps')) {
      return isFemale
          ? 'assets/images/cover_female_arm_$l.webp'
          : 'assets/images/cover_arm_$l.webp';
    }

    // 5. Back, Shoulders, Lats (پشت، زیربغل، کمر، سرشانه، شانه)
    if (name.contains('پشت') ||
        name.contains('زیربغل') ||
        name.contains('کمر') ||
        name.contains('سرشانه') ||
        name.contains('شانه') ||
        name.contains('back') ||
        name.contains('shoulder') ||
        name.contains('lat')) {
      return isFemale
          ? 'assets/images/cover_female_shoulder_$l.webp'
          : 'assets/images/cover_shoulder_$l.webp';
    }

    // Default Fallback to Leg cover (Male vs Female)
    return isFemale
        ? 'assets/images/cover_female_leg_$l.webp'
        : 'assets/images/cover_leg_$l.webp';
  }
}
