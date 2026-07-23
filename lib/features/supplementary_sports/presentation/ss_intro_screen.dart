import 'package:flutter/material.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_onboarding_flow.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SSIntroScreen extends StatefulWidget {
  const SSIntroScreen({super.key});

  @override
  State<SSIntroScreen> createState() => _SSIntroScreenState();
}

class _SSIntroScreenState extends State<SSIntroScreen> {

  Future<void> _finishIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ss_shown_intro_splash', true);

    if (mounted) {
      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(builder: (context) => const SSOnboardingFlow()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final titleColor = isDark ? const Color(0xFFE8F5E9) : const Color(0xFF133B26);
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final waveColor = isDark ? const Color(0xFF1C221F) : const Color(0xFFF2F9F6);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar spacer
            const SizedBox(height: 24),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dumbbell Custom painted vector Logo
                  CustomPaint(
                    size: const Size(200, 100),
                    painter: DumbbellLogoPainter(isDark: isDark),
                  ),
                  const SizedBox(height: 36),

                  // Title
                  Text(
                    'همراه تمرین',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'برنامه‌ریزی هوشمند تمرینات ورزشی تکمیلی، پایش تداوم و دریافت برنامه‌های ورزشی اختصاصی متناسب با بازخورد کیفی شما.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 15,
                        color: subtitleColor,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bottom Wave Decorative Element & Label
            ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                width: double.infinity,
                height: 150,
                color: waveColor,
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 48, bottom: 24, left: 24, right: 24),
                  child: SizedBox(
                    width: 200,
                    child: PrimaryButton(
                      label: 'شروع کنیم',
                      onPressed: _finishIntro,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Painter to draw dumbbell brand logo exactly as image ---
class DumbbellLogoPainter extends CustomPainter {
  DumbbellLogoPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {

    final lightGreenPaint = Paint()
      ..color = isDark ? const Color(0xFF81C784) : const Color(0xFF4D9E6E) // light accent or dark accent
      ..style = PaintingStyle.fill;

    final barPaint = Paint()
      ..color = isDark ? const Color(0xFF81C784) : const Color(0xFF4D9E6E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Left Plates (3 vertical bars)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(-60, 0), width: 5, height: 28),
        const Radius.circular(3),
      ),
      lightGreenPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(-51, 0), width: 5, height: 42),
        const Radius.circular(3),
      ),
      lightGreenPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(-42, 0), width: 7, height: 56),
        const Radius.circular(4),
      ),
      lightGreenPaint,
    );

    // Right Plates (3 vertical bars)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(42, 0), width: 7, height: 56),
        const Radius.circular(4),
      ),
      lightGreenPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(51, 0), width: 5, height: 42),
        const Radius.circular(3),
      ),
      lightGreenPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(60, 0), width: 5, height: 28),
        const Radius.circular(3),
      ),
      lightGreenPaint,
    );

    // Dumbbell bar connecting line (forming letter A mountain shape)
    final path = Path()
      ..moveTo(center.dx - 35, center.dy)
      ..quadraticBezierTo(center.dx - 24, center.dy, center.dx - 22, center.dy - 2)
      ..lineTo(center.dx - 2, center.dy - 38)
      ..quadraticBezierTo(center.dx, center.dy - 41, center.dx + 2, center.dy - 38)
      ..lineTo(center.dx + 22, center.dy - 2)
      ..quadraticBezierTo(center.dx + 24, center.dy, center.dx + 35, center.dy);

    canvas.drawPath(path, barPaint..color = isDark ? const Color(0xFFC8E6C9) : const Color(0xFF0F3621)..strokeWidth = 7);

    // Chevron pointing down in center (forming a V letter shape)
    final chevronPath = Path()
      ..moveTo(center.dx - 14, center.dy - 10)
      ..lineTo(center.dx, center.dy + 3)
      ..lineTo(center.dx + 14, center.dy - 10);

    canvas.drawPath(chevronPath, barPaint..color = isDark ? const Color(0xFFC8E6C9) : const Color(0xFF0F3621)..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Custom Clipper to clip wave pattern at bottom ---
class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 40);
    
    // Wave bezier curve
    path.quadraticBezierTo(
      size.width / 4,
      10,
      size.width / 2,
      30,
    );
    path.quadraticBezierTo(
      3 * size.width / 4,
      50,
      size.width,
      25,
    );

    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
