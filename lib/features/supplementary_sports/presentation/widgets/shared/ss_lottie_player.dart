import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ritmo/features/supplementary_sports/data/seed/ss_exercise_animation_map.dart';

/// Maps exercise category strings → Lottie asset path.
/// Falls back to workout_general if category is unrecognized.
class SSLottieAssets {
  SSLottieAssets._();

  static const String _base = 'assets/animations';

  // ─── Per-category animations ───
  static const String general    = 'assets/animations/custom/hw_143.json'; // chest stretch fallback
  static const String legs       = 'assets/animations/custom/hw_40.json';  // squats
  static const String chest      = 'assets/animations/custom/hw_34.json';  // knee pushups
  static const String back       = 'assets/animations/custom/hw_61.json';  // arm circles
  static const String shoulders  = 'assets/animations/custom/hw_155.json'; // shoulder stretch
  static const String arms       = 'assets/animations/custom/hw_61.json';  // arm circles
  static const String core       = 'assets/animations/custom/hw_16.json';  // straight arm plank
  static const String cardio     = 'assets/animations/custom/hw_12.json';  // mountain climber

  // ─── UI / state animations ───
  static const String loading    = '$_base/workout_loading.json';
  static const String success    = '$_base/workout_success.json';
  static const String complete   = '$_base/workout_complete.json';
  static const String trophy     = '$_base/workout_trophy.json';
  static const String timer      = '$_base/workout_timer.json';
  static const String rest       = '$_base/workout_rest.json';
  static const String start      = '$_base/workout_start.json';

  /// Returns the appropriate asset path for a given exercise category slug.
  static String forCategory(String? category) {
    final clean = (category ?? '').toLowerCase().trim();
    switch (clean) {
      case 'legs':
      case 'leg':
      case 'quad':
      case 'glute':
      case 'hamstring':
      case 'calf':
      case 'lower_body':
        return legs;
      case 'chest':
      case 'pec':
      case 'upper_body':
        return chest;
      case 'back':
      case 'lat':
      case 'row':
      case 'shoulder_and_back':
        return back;
      case 'shoulder':
      case 'shoulders':
      case 'deltoid':
        return shoulders;
      case 'arms':
      case 'arm':
      case 'bicep':
      case 'tricep':
        return arms;
      case 'core':
      case 'abs':
      case 'plank':
        return core;
      case 'cardio':
      case 'hiit':
      case 'running':
      case 'cycling':
      case 'plyometric':
        return cardio;
      default:
        return general;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Main Lottie Player Widget
// ─────────────────────────────────────────────────────────────

enum SSLottieMode {
  /// Plays the animation once and stops
  once,
  /// Loops the animation continuously
  loop,
  /// Plays once then reverses (ping-pong)
  pingPong,
}

class SSLottiePlayer extends StatefulWidget {

  const SSLottiePlayer({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.mode = SSLottieMode.loop,
    this.speed = 1.0,
    this.onComplete,
    this.fit = BoxFit.contain,
  });

  /// Factory: picks custom Lottie animation if exists, otherwise category based
  factory SSLottiePlayer.forExercise({
    Key? key,
    String? exerciseId,
    required String category,
    double? width,
    double? height,
    SSLottieMode mode = SSLottieMode.loop,
    double speed = 1.0,
  }) {
    if (exerciseId != null) {
      final mappedId = ssExerciseAnimationMap[exerciseId];
      if (mappedId != null && _customAnimationIds.contains(mappedId)) {
        return SSLottiePlayer(
          key: key,
          assetPath: 'assets/animations/custom/$mappedId.json',
          width: width,
          height: height,
          mode: mode,
          speed: speed,
        );
      }

      if (_customAnimationIds.contains(exerciseId)) {
        return SSLottiePlayer(
          key: key,
          assetPath: 'assets/animations/custom/$exerciseId.json',
          width: width,
          height: height,
          mode: mode,
          speed: speed,
        );
      }
      
      // Keyword matching based on exerciseId
      final idLower = exerciseId.toLowerCase();
      if (idLower.contains('jumping_jacks') || idLower.contains('jumping_jack')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_15.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('bicycle_crunch')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_167.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('mountain_climber')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_12.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('sumo_squat')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_223.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('squat')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_21.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('plank')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_16.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('pushup') || idLower.contains('push_up')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_20.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('bridge')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_11.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('crunch')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_0.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('leg_raise') || idLower.contains('leg_lift')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_1.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('stretch') || idLower.contains('yoga') || idLower.contains('breathing')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_143.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('wrist') || idLower.contains('ankle')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_326.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('arm_circle') || idLower.contains('arm_circles')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_136.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('calf_raise') || idLower.contains('calf')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_220.json', width: width, height: height, mode: mode, speed: speed);
      }
      if (idLower.contains('jump')) {
        return SSLottiePlayer(key: key, assetPath: 'assets/animations/custom/hw_15.json', width: width, height: height, mode: mode, speed: speed);
      }
    }
    return SSLottiePlayer.forCategory(
      key: key,
      category: category,
      width: width,
      height: height,
      mode: mode,
      speed: speed,
    );
  }

  /// Factory: picks animation based on exercise category
  factory SSLottiePlayer.forCategory({
    Key? key,
    required String category,
    double? width,
    double? height,
    SSLottieMode mode = SSLottieMode.loop,
    double speed = 1.0,
  }) {
    return SSLottiePlayer(
      key: key,
      assetPath: SSLottieAssets.forCategory(category),
      width: width,
      height: height,
      mode: mode,
      speed: speed,
    );
  }

  /// Factory: loading spinner animation
  factory SSLottiePlayer.loading({Key? key, double size = 80}) {
    return SSLottiePlayer(
      key: key,
      assetPath: SSLottieAssets.loading,
      width: size,
      height: size,
    );
  }

  /// Factory: success / completion celebration
  factory SSLottiePlayer.success({
    Key? key,
    double size = 160,
    VoidCallback? onComplete,
  }) {
    return SSLottiePlayer(
      key: key,
      assetPath: SSLottieAssets.success,
      width: size,
      height: size,
      mode: SSLottieMode.once,
      onComplete: onComplete,
    );
  }

  /// Factory: trophy / achievement
  factory SSLottiePlayer.trophy({Key? key, double size = 200}) {
    return SSLottiePlayer(
      key: key,
      assetPath: SSLottieAssets.trophy,
      width: size,
      height: size,
      mode: SSLottieMode.once,
    );
  }

  /// Factory: rest timer pulse
  factory SSLottiePlayer.rest({Key? key, double size = 80}) {
    return SSLottiePlayer(
      key: key,
      assetPath: SSLottieAssets.rest,
      width: size,
      height: size,
      speed: 0.6,
    );
  }

  /// Factory: session start countdown
  factory SSLottiePlayer.start({Key? key, double size = 200}) {
    return SSLottiePlayer(
      key: key,
      assetPath: SSLottieAssets.start,
      width: size,
      height: size,
      mode: SSLottieMode.once,
    );
  }
  /// The Lottie JSON asset path (use [SSLottieAssets] constants)
  final String assetPath;

  /// Width of the animation widget
  final double? width;

  /// Height of the animation widget
  final double? height;

  /// Playback mode
  final SSLottieMode mode;

  /// Playback speed multiplier
  final double speed;

  /// Callback when animation completes (only for once mode)
  final VoidCallback? onComplete;

  /// BoxFit for the animation
  final BoxFit fit;

  static const Set<String> _customAnimationIds = {
    'hw_0', 'hw_1', 'hw_10', 'hw_109', 'hw_11', 'hw_12', 'hw_120', 'hw_121', 'hw_124', 'hw_125', 'hw_127', 'hw_128', 'hw_129', 'hw_13', 'hw_130', 'hw_132', 'hw_133', 'hw_136', 'hw_137', 'hw_138', 'hw_140', 'hw_141', 'hw_143', 'hw_144', 'hw_149', 'hw_15', 'hw_153', 'hw_154', 'hw_155', 'hw_158', 'hw_159', 'hw_16', 'hw_163', 'hw_164', 'hw_165', 'hw_167', 'hw_168', 'hw_169', 'hw_17', 'hw_170', 'hw_172', 'hw_173', 'hw_174', 'hw_175', 'hw_177', 'hw_178', 'hw_179', 'hw_18', 'hw_180', 'hw_181', 'hw_182', 'hw_183', 'hw_184', 'hw_185', 'hw_186', 'hw_187', 'hw_188', 'hw_189', 'hw_19', 'hw_190', 'hw_191', 'hw_192', 'hw_193', 'hw_194', 'hw_195', 'hw_196', 'hw_197', 'hw_198', 'hw_199', 'hw_2', 'hw_20', 'hw_200', 'hw_201', 'hw_202', 'hw_203', 'hw_204', 'hw_21', 'hw_214', 'hw_215', 'hw_217', 'hw_218', 'hw_219', 'hw_22', 'hw_220', 'hw_221', 'hw_222', 'hw_223', 'hw_224', 'hw_225', 'hw_226', 'hw_227', 'hw_228', 'hw_229', 'hw_23', 'hw_230', 'hw_231', 'hw_232', 'hw_236', 'hw_237', 'hw_238', 'hw_239', 'hw_24', 'hw_240', 'hw_241', 'hw_242', 'hw_244', 'hw_25', 'hw_258', 'hw_259', 'hw_26', 'hw_260', 'hw_261', 'hw_262', 'hw_263', 'hw_264', 'hw_265', 'hw_266', 'hw_267', 'hw_268', 'hw_269', 'hw_27', 'hw_270', 'hw_271', 'hw_272', 'hw_273', 'hw_274', 'hw_275', 'hw_276', 'hw_28', 'hw_282', 'hw_285', 'hw_287', 'hw_29', 'hw_298', 'hw_3', 'hw_30', 'hw_300', 'hw_301', 'hw_305', 'hw_306', 'hw_307', 'hw_308', 'hw_31', 'hw_312', 'hw_316', 'hw_32', 'hw_320', 'hw_321', 'hw_322', 'hw_323', 'hw_324', 'hw_325', 'hw_326', 'hw_327', 'hw_328', 'hw_329', 'hw_33', 'hw_330', 'hw_331', 'hw_332', 'hw_333', 'hw_334', 'hw_34', 'hw_35', 'hw_354', 'hw_355', 'hw_358', 'hw_36', 'hw_360', 'hw_363', 'hw_364', 'hw_365', 'hw_366', 'hw_368', 'hw_369', 'hw_37', 'hw_371', 'hw_372', 'hw_373', 'hw_375', 'hw_376', 'hw_377', 'hw_378', 'hw_379', 'hw_38', 'hw_380', 'hw_381', 'hw_386', 'hw_39', 'hw_398', 'hw_399', 'hw_4', 'hw_40', 'hw_400', 'hw_401', 'hw_402', 'hw_403', 'hw_404', 'hw_405', 'hw_407', 'hw_409', 'hw_411', 'hw_42', 'hw_428', 'hw_43', 'hw_430', 'hw_432', 'hw_433', 'hw_439', 'hw_44', 'hw_442', 'hw_443', 'hw_445', 'hw_446', 'hw_45', 'hw_451', 'hw_453', 'hw_454', 'hw_46', 'hw_468', 'hw_469', 'hw_47', 'hw_476', 'hw_477', 'hw_478', 'hw_479', 'hw_48', 'hw_481', 'hw_484', 'hw_486', 'hw_49', 'hw_492', 'hw_493', 'hw_494', 'hw_495', 'hw_50', 'hw_507', 'hw_51', 'hw_513', 'hw_516', 'hw_517', 'hw_52', 'hw_53', 'hw_540', 'hw_541', 'hw_543', 'hw_544', 'hw_547', 'hw_548', 'hw_55', 'hw_551', 'hw_552', 'hw_554', 'hw_559', 'hw_56', 'hw_561', 'hw_562', 'hw_563', 'hw_565', 'hw_566', 'hw_567', 'hw_580', 'hw_588', 'hw_589', 'hw_59', 'hw_6', 'hw_608', 'hw_609', 'hw_61', 'hw_62', 'hw_63', 'hw_64', 'hw_65', 'hw_66', 'hw_67', 'hw_68', 'hw_69', 'hw_7', 'hw_70', 'hw_71', 'hw_721', 'hw_73', 'hw_736', 'hw_737', 'hw_738', 'hw_739', 'hw_74', 'hw_75', 'hw_76', 'hw_772', 'hw_774', 'hw_776', 'hw_777', 'hw_78', 'hw_787', 'hw_791', 'hw_792', 'hw_793', 'hw_798', 'hw_799', 'hw_8', 'hw_80', 'hw_81', 'hw_82', 'hw_821', 'hw_822', 'hw_83', 'hw_834', 'hw_84', 'hw_85', 'hw_86', 'hw_87', 'hw_88', 'hw_89', 'hw_9', 'hw_90', 'hw_91', 'hw_92', 'hw_93', 'hw_94', 'hw_98'
  };

  @override
  State<SSLottiePlayer> createState() => _SSLottiePlayerState();
}

class _SSLottiePlayerState extends State<SSLottiePlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLoaded(LottieComposition composition) {
    final microseconds = (composition.duration.inMicroseconds / widget.speed).round();
    _controller.duration = Duration(microseconds: microseconds);
    _controller.value = 0;

    switch (widget.mode) {
      case SSLottieMode.loop:
        _controller.repeat();
      case SSLottieMode.once:
        _controller.forward().then((_) {
          widget.onComplete?.call();
        });
      case SSLottieMode.pingPong:
        _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SSLottiePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _controller.reset();
    }
    if (oldWidget.speed != widget.speed && _controller.duration != null) {
      _controller.duration = _controller.duration! * (oldWidget.speed / widget.speed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      widget.assetPath,
      controller: _controller,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      onLoaded: _onLoaded,
      errorBuilder: (context, error, stackTrace) {
        // Graceful fallback: show a simple icon
        return SizedBox(
          width: widget.width ?? 80,
          height: widget.height ?? 80,
          child: Center(
            child: Icon(
              Icons.fitness_center_rounded,
              size: (widget.width ?? 80) * 0.5,
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Utility: Animated exercise card illustration
// Used in workout session screen as exercise image area
// ─────────────────────────────────────────────────────────────

class SSExerciseAnimationCard extends StatelessWidget {

  const SSExerciseAnimationCard({
    super.key,
    required this.category,
    this.exerciseId,
    this.height = 180,
  });
  final String category;
  final String? exerciseId;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2D6A4F).withValues(alpha: 0.04),
            const Color(0xFF2D6A4F).withValues(alpha: 0.01),
          ],
        ),
      ),
      child: SSLottiePlayer.forExercise(
        key: exerciseId != null ? ValueKey(exerciseId) : null,
        exerciseId: exerciseId,
        category: category,
        height: height,
        speed: 0.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Utility: Full-screen loading overlay with Lottie
// ─────────────────────────────────────────────────────────────

class SSLottieLoadingOverlay extends StatelessWidget {
  const SSLottieLoadingOverlay({super.key, this.message = 'در حال بارگذاری...'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SSLottiePlayer.loading(size: 100),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
