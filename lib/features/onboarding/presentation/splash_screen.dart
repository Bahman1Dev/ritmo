import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({
    super.key,
    required this.initializationFuture,
    required this.onInitializationComplete,
  });
  final Future<void> initializationFuture;
  final VoidCallback onInitializationComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundGlowController;
  late AnimationController _ringRotationController;
  late AnimationController _particlesController;

  final List<_DriftingParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // 1. Background Glow Animation Controller (Slow ambient breathing movement)
    _backgroundGlowController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);

    // 2. Rings Rotation Controller (Constant slow spin)
    _ringRotationController = AnimationController(
      duration: const Duration(seconds: 24),
      vsync: this,
    )..repeat();

    // 3. Particles Controller (Constant tick to animate environmental particles)
    _particlesController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..addListener(_updateParticles)..repeat();

    // Initialize environment particles
    _initParticles();

    // 4. Synchronization Logic
    _syncInitialization();
  }

  void _initParticles() {
    for (var i = 0; i < 20; i++) {
      _particles.add(
        _DriftingParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 2.5 + 0.8,
          speed: _random.nextDouble() * 0.0015 + 0.0005,
          opacity: _random.nextDouble() * 0.4 + 0.1,
          angleOffset: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _updateParticles() {
    setState(() {
      for (final particle in _particles) {
        // Drifts upwards
        particle.y -= particle.speed;
        // Subtle horizontal wiggle
        particle.angleOffset += 0.02;
        particle.x += math.sin(particle.angleOffset) * 0.0005;

        // Reset if goes off-screen
        if (particle.y < -0.05) {
          particle.y = 1.05;
          particle.x = _random.nextDouble();
        }
        if (particle.x < -0.05 || particle.x > 1.05) {
          particle.x = _random.nextDouble();
        }
      }
    });
  }

  Future<void> _syncInitialization() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Wait for the app's database/configuration loads
      await widget.initializationFuture;
    } catch (e) {
      // Log error internally and fall through to prevent bricking the app startup
      debugPrint('Ritmo Startup Sync Warning: $e');
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;

    // Enforce minimum splash display duration of 1.5 seconds (1500 ms)
    const minDurationMs = 1500;
    if (elapsedMs < minDurationMs) {
      final remainingMs = minDurationMs - elapsedMs;
      await Future.delayed(Duration(milliseconds: remainingMs));
    }

    // Trigger premium Haptic Impact
    await HapticFeedback.lightImpact();

    // Small delay to let the haptic response and cross-fade register naturally
    await Future.delayed(const Duration(milliseconds: 150));

    // Complete transition
    widget.onInitializationComplete();
  }

  @override
  void dispose() {
    _backgroundGlowController.dispose();
    _ringRotationController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    // Premium background gradient colors
    final bgColors = isDarkMode
        ? [const Color(0xff08090C), const Color(0xff12141C)]
        : [const Color(0xffF4F6FB), const Color(0xffE9EFF8)];

    final textPrimaryColor = isDarkMode ? Colors.white : const Color(0xff1A1D29);
    final textSecondaryColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xff5C6170).withValues(alpha: 0.8);
    final textTertiaryColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.35)
        : const Color(0xff5C6170).withValues(alpha: 0.55);

    // Glowing colors for background blobs
    final blob1Color = isDarkMode
        ? const Color(0xff5B8AF5).withValues(alpha: 0.09) // Ice blue
        : const Color(0xff99F6E4).withValues(alpha: 0.07); // Soft teal
    final blob2Color = isDarkMode
        ? const Color(0xff2DD4BF).withValues(alpha: 0.06) // Turquoise
        : const Color(0xffE9D5FF).withValues(alpha: 0.07); // Lavender
    final blob3Color = isDarkMode
        ? const Color(0xff9B89FF).withValues(alpha: 0.08) // Purple
        : const Color(0xffBAE6FD).withValues(alpha: 0.08); // Light sky

    return Scaffold(
      body: Stack(
        children: [
          // 1. BASE BACKGROUND GRADIENT
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
            ),
          ),

          // 2. AMBIENT GLOW BLOBS (ANIMATED LAYER)
          AnimatedBuilder(
            animation: _backgroundGlowController,
            builder: (context, child) {
              final val = _backgroundGlowController.value;
              final angle = val * math.pi * 2;

              // Compute drifting coordinates for organic flows
              final dx1 = math.sin(angle) * 35.0;
              final dy1 = math.cos(angle) * 45.0;
              final dx2 = math.cos(angle + math.pi/2) * 40.0;
              final dy2 = math.sin(angle + math.pi/2) * 50.0;

              return Stack(
                children: [
                  // Blob 1 (Top-Left)
                  Positioned(
                    top: -50 + dy1,
                    left: -80 + dx1,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [blob1Color, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Blob 2 (Bottom-Right)
                  Positioned(
                    bottom: -60 - dy2,
                    right: -70 - dx2,
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [blob2Color, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Blob 3 (Center-Left)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.4 + dy2,
                    left: -90 + dx1,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [blob3Color, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. ENVIRONMENTAL DRIFTING PARTICLES
          Positioned.fill(
            child: CustomPaint(
              painter: _ParticlesPainter(
                particles: _particles,
                isDarkMode: isDarkMode,
              ),
            ),
          ),

          // 4. CENTRAL VISUAL ZONE (3D RINGS + ORB)
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 7),
                
                // Ring and Orb Stack
                SizedBox(
                  width: 340,
                  height: 340,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated 3D tilted concentric rings
                      AnimatedBuilder(
                        animation: _ringRotationController,
                        builder: (context, child) {
                          final rot = _ringRotationController.value * math.pi * 2;
                          final ringColor = isDarkMode
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xff1A1D29).withValues(alpha: 0.08);

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ring 1 (Tilted forward-right, rotates clockwise)
                              Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001) // 3D Perspective
                                  ..rotateX(1.1)          // Lay down flat
                                  ..rotateY(0.25)
                                  ..rotateZ(rot),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: ringColor, width: 0.8),
                                  ),
                                ),
                              ),
                              // Ring 2 (Tilted forward-left, rotates counter-clockwise, slightly larger)
                              Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateX(1.25)
                                  ..rotateY(-0.2)
                                  ..rotateZ(-rot * 1.25),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 290,
                                  height: 290,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: ringColor, width: 0.6),
                                  ),
                                ),
                              ),
                              // Ring 3 (Flatter, rotates slower clockwise, outer ring)
                              Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateX(1.05)
                                  ..rotateY(0.35)
                                  ..rotateZ(rot * 0.7),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 330,
                                  height: 330,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ringColor.withValues(alpha: ringColor.a * 0.8),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Premium App Logo (Center Piece with ambient breathing glow)
                      AnimatedBuilder(
                        animation: _backgroundGlowController,
                        builder: (context, child) {
                          final val = _backgroundGlowController.value;
                          // Slow, organic breathing scaling
                          final scale = 1.0 + (math.sin(val * math.pi * 2) * 0.025);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 155,
                              height: 155,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDarkMode ? const Color(0xff5B8AF5) : const Color(0xff3B6FE0))
                                        .withValues(alpha: isDarkMode ? 0.35 : 0.18),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDarkMode ? 0.5 : 0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(36),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // 5. TYPOGRAPHY AND SYNC STATUS (LOWER-MIDDLE SECTION)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      // Ritmo App Title
                      Text(
                        'R I T M O',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 10,
                          color: textPrimaryColor,
                          fontFamily: 'Vazirmatn', // Clean sans fallback
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // Persian Main Subtitle
                      Text(
                        'نبض زندگی',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                          color: textSecondaryColor,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 4),

                      // English Subtitle
                      Text(
                        'Life Operating System',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.5,
                          color: textTertiaryColor,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Syncing Progress / Live Status Label
                      Text(
                        'در حال آماده‌سازی ریتم زندگی شما...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: textSecondaryColor.withValues(alpha: 0.45),
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Particle metadata definition
class _DriftingParticle { // Wiggle factor

  _DriftingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angleOffset,
  });
  double x; // Horizontal percentage (0.0 to 1.0)
  double y; // Vertical percentage (0.0 to 1.0)
  final double size;
  final double speed;
  final double opacity;
  double angleOffset;
}

/// Painter to draw smooth drifting particles
class _ParticlesPainter extends CustomPainter {

  _ParticlesPainter({
    required this.particles,
    required this.isDarkMode,
  });
  final List<_DriftingParticle> particles;
  final bool isDarkMode;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final dotColor = isDarkMode ? Colors.white : const Color(0xff5B8AF5);

    for (final particle in particles) {
      final px = particle.x * size.width;
      final py = particle.y * size.height;

      paint.color = dotColor.withValues(alpha: particle.opacity);
      canvas.drawCircle(Offset(px, py), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
