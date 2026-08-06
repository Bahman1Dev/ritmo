import 'dart:math' as math;

const double kKaabaLat = 21.4225;
const double kKaabaLon = 39.8262;

/// Calculates Qibla azimuth bearing in degrees clockwise from True North [0..360].
double qiblaBearing(double lat, double lon) {
  final phi = lat * math.pi / 180;
  final dLambda = (kKaabaLon - lon) * math.pi / 180;
  final phiK = kKaabaLat * math.pi / 180;

  final y = math.sin(dLambda);
  final x = math.cos(phi) * math.tan(phiK) - math.sin(phi) * math.cos(dLambda);
  final deg = math.atan2(y, x) * 180 / math.pi;
  return (deg + 360) % 360;
}
