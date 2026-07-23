import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Enables drag scrolling across all input devices (touch, mouse, stylus, trackpad)
/// particularly critical for WSL / Linux / Desktop / Emulators where mouse drag is otherwise blocked.
class RitmoScrollBehavior extends MaterialScrollBehavior {
  const RitmoScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}
