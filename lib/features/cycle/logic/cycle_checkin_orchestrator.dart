import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/features/cycle/models/cycle_intelligence_models.dart';

class CycleCheckinOrchestrator {
  static String? checkinPromptFa({
    required CyclePhase phase,
    required DataQualityReport dataQuality,
    required DateTime? pmsWindowStart,
    required DateTime now,
  }) {
    if (dataQuality.hasForgottenOpenPeriod) {
      return 'یک دوره باز قدیمی دارید. لطفا تاریخ پایان آن را ثبت یا تعیین تکلیف کنید.';
    }

    if (phase == CyclePhase.menstrual) {
      return 'امروز روز فعال قاعدگی است. ثبت علائم امروز به تنظیم بهتر برنامه‌ها کمک می‌کند.';
    }

    if (pmsWindowStart != null) {
      final daysToPms = pmsWindowStart.difference(now).inDays;
      if (daysToPms >= 0 && daysToPms <= 3 && !dataQuality.hasRecentDailyLogs) {
        return 'نزدیک به پنجره قبل از دوره هستید. ثبت وضعیت بدنی امروز پیشنهادی است.';
      }
    }

    if (!dataQuality.hasRecentDailyLogs && dataQuality.hasEnoughCycles) {
      return 'ثبت وضعیت روزانه به دقت بیشتر پیش‌بینی ریتم بدنی شما کمک می‌کند.';
    }

    return null;
  }
}
