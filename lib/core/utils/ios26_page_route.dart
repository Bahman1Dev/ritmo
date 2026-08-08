import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// مسیر ناوبری اختصاصی iOS 26 با انیمیشن Depth Parallax سه‌بعدی
/// و پشتیبانی کامل از ژست‌های نیتیو swipe back
class Ios26PageRoute<T> extends CupertinoPageRoute<T> {
  Ios26PageRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // منحنی حرکت فیزیکی فوق‌العاده نرم iOS 26
    final slideCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.fastLinearToSlowEaseIn,
      reverseCurve: Curves.easeInCubic,
    );

    // تغییر مقیاس صفحه قبلی (Depth Scale 0.94x)
    final secondaryScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.fastLinearToSlowEaseIn,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // جابه‌جایی پارالاکس صفحه خروجی
    final secondaryTranslate = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.06, 0.0),
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.fastLinearToSlowEaseIn,
      ),
    );

    // لایه تاریکی شفاف ۵۰٪
    final secondaryDim = Tween<double>(begin: 0.0, end: 0.35).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOut,
      ),
    );

    return AnimatedBuilder(
      animation: secondaryAnimation,
      builder: (context, currentChild) {
        if (secondaryAnimation.value > 0.0) {
          return FractionalTranslation(
            translation: secondaryTranslate.value,
            child: Transform.scale(
              scale: secondaryScale.value,
              child: Stack(
                children: [
                  currentChild!,
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: secondaryDim.value),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return super.buildTransitions(context, slideCurve, secondaryAnimation, currentChild!);
      },
      child: child,
    );
  }
}
