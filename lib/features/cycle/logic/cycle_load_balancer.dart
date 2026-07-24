import 'package:ritmo/features/cycle/models/cycle_intelligence_models.dart';

class CycleLoadBalancer {
  static CycleAdaptiveAdvice generateAdvice(BodyBurdenScore burden) {
    if (burden.level == 'HIGH') {
      return const CycleAdaptiveAdvice(
        loadMode: 'lighter',
        energyDelta: -15,
        sessionLengthMultiplier: 0.70,
        extraBreakMinutesEveryHour: 10,
        recommendationsFa: [
          'برنامه‌های سنگین امروز را کاهش دهید یا به روزهای دیگر منتقل کنید.',
          'جلسات تمرکز یا مطالعه را به بازه‌های کوتاه‌تر ۳۰ دقیقه‌ای تقسیم کنید.',
          'استراحت‌های کوتاه‌مدت بیشتری در طول روز برنامه‌ریزی کنید.',
          'مصرف آب، چای گرم و مراقبت‌های آرامش‌بخش را اولویت دهید.',
        ],
      );
    } else if (burden.level == 'MODERATE') {
      return const CycleAdaptiveAdvice(
        loadMode: 'balanced',
        energyDelta: -7,
        sessionLengthMultiplier: 0.85,
        extraBreakMinutesEveryHour: 5,
        recommendationsFa: [
          'برنامه امروز متوازن است؛ ریتم متناسب و بدون فشار حفظ شود.',
          'در صورت احساس خستگی، ۵ دقیقه استراحت اضافه در ساعت بگیرید.',
          'کارهای فکری مهم‌تر را در ساعات اولیه روز انجام دهید.',
        ],
      );
    } else {
      return const CycleAdaptiveAdvice(
        loadMode: 'higher-focus',
        energyDelta: 0,
        sessionLengthMultiplier: 1.0,
        extraBreakMinutesEveryHour: 0,
        recommendationsFa: [
          'وضعیت بدنی در ریتم مطلوب قرار دارد.',
          'زمان مناسبی برای پیشبرد اهداف مهم و برنامه‌های پرانرژی است.',
        ],
      );
    }
  }
}
