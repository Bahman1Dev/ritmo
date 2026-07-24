class DurationVariants {
  static const int minimalFloor = 2;
  static const int minimalCap   = 10;
  static const int lightFloor   = 5;

  static int light(int target) =>
      (target * 0.5).round().clamp(lightFloor, (target - 1).clamp(lightFloor, target));

  static int minimal(int target) =>
      (target * 0.15).round().clamp(minimalFloor, minimalCap);

  static bool supportsVariants(int target) => target > 5;
}
