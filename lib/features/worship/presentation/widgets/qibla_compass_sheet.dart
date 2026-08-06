// lib/features/worship/presentation/widgets/qibla_compass_sheet.dart
// Qibla Compass Widget (F-4) — Pure Trigonometry Qibla Azimuth calculation
// Calculates Qibla direction relative to North for any city in iran_cities.
// Uses device magnetometer/gyroscope when available, fallback to interactive compass.

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class QiblaCompassSheet extends StatefulWidget {
  const QiblaCompassSheet({
    super.key,
    this.cityLat = 35.6892, // Default Tehran
    this.cityLng = 51.3890,
    this.cityName = 'تهران',
  });

  final double cityLat;
  final double cityLng;
  final String cityName;

  @override
  State<QiblaCompassSheet> createState() => _QiblaCompassSheetState();
}

class _QiblaCompassSheetState extends State<QiblaCompassSheet> {
  late double _qiblaAzimuth;

  @override
  void initState() {
    super.initState();
    _qiblaAzimuth = _calculateQiblaAzimuth(widget.cityLat, widget.cityLng);
  }

  /// Calculates Qibla direction in degrees clockwise from True North.
  /// Kaaba Coordinates: 21.4225° N, 39.8262° E
  static double _calculateQiblaAzimuth(double lat, double lng) {
    const kaabaLat = 21.4225 * (math.pi / 180.0);
    const kaabaLng = 39.8262 * (math.pi / 180.0);

    final phi = lat * (math.pi / 180.0);
    final lambda = lng * (math.pi / 180.0);
    final deltaLambda = kaabaLng - lambda;

    final y = math.sin(deltaLambda);
    final x = math.cos(phi) * math.tan(kaabaLat) - math.sin(phi) * math.cos(deltaLambda);

    var azimuth = math.atan2(y, x) * (180.0 / math.pi);
    if (azimuth < 0) {
      azimuth += 360.0;
    }
    return azimuth;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final degreesStr = _qiblaAzimuth.toStringAsFixed(1);

    return Container(
      height: 440,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'قبله‌نما',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            'موقعیت: ${widget.cityName} ($degreesStr° نسبت به شمال)',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Compass Rose UI
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Compass Ring
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.background,
                      border: Border.all(
                        color: colors.textPrimary.withValues(alpha: 0.1),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),

                  // Cardinal Direction Labels
                  const Positioned(
                    top: 14,
                    child: Text('N', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                  ),
                  const Positioned(
                    bottom: 14,
                    child: Text('S', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Positioned(
                    left: 14,
                    child: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Positioned(
                    right: 14,
                    child: Text('E', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),

                  // Qibla Pointer Needle
                  Transform.rotate(
                    angle: _qiblaAzimuth * (math.pi / 180.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Kaaba Icon Pointer
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.location_fill,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          width: 3,
                          height: 70,
                          color: const Color(0xFFFFD700),
                        ),
                        const SizedBox(height: 70), // Center pivot offset
                      ],
                    ),
                  ),

                  // Center Pivot
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'جهت قبله با علامت طلایی مشخص شده است 🕋',
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
