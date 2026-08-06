import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';

class NowBand extends StatelessWidget {
  const NowBand({
    super.key,
    required this.topPixel,
  });

  final double topPixel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final errorColor = colors.error;

    return Positioned(
      top: topPixel - 6.0,
      left: 0,
      right: 0,
      height: 12.0,
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 12px Gradient band
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    errorColor.withValues(alpha: 0.0),
                    errorColor.withValues(alpha: 0.18),
                    errorColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // 1.5px center line
            Positioned(
              top: 5.25,
              left: 0,
              right: 0,
              height: 1.5,
              child: Container(
                color: errorColor,
              ),
            ),
            // Right edge 6px dot (RTL)
            Positioned(
              right: 0,
              top: 3.0,
              width: 6.0,
              height: 6.0,
              child: Container(
                decoration: BoxDecoration(
                  color: errorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
