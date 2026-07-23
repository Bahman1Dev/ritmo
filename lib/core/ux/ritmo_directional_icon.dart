import 'package:flutter/material.dart';

class RitmoDirectionalIcon extends StatelessWidget {

  const RitmoDirectionalIcon({
    super.key,
    required this.ltrIcon,
    required this.rtlIcon,
    this.size,
    this.color,
  });
  final IconData ltrIcon;
  final IconData rtlIcon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      isRtl ? rtlIcon : ltrIcon,
      size: size,
      color: color,
    );
  }
}

class RitmoIcons {
  static Widget back(BuildContext context, {double? size, Color? color}) {
    return RitmoDirectionalIcon(
      ltrIcon: Icons.arrow_back,
      rtlIcon: Icons.arrow_forward,
      size: size,
      color: color,
    );
  }

  static Widget forward(BuildContext context, {double? size, Color? color}) {
    return RitmoDirectionalIcon(
      ltrIcon: Icons.arrow_forward,
      rtlIcon: Icons.arrow_back,
      size: size,
      color: color,
    );
  }

  static Widget chevronBack(BuildContext context, {double? size, Color? color}) {
    return RitmoDirectionalIcon(
      ltrIcon: Icons.chevron_left,
      rtlIcon: Icons.chevron_right,
      size: size,
      color: color,
    );
  }

  static Widget chevronForward(BuildContext context, {double? size, Color? color}) {
    return RitmoDirectionalIcon(
      ltrIcon: Icons.chevron_right,
      rtlIcon: Icons.chevron_left,
      size: size,
      color: color,
    );
  }
}
