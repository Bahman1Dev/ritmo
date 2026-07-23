import 'package:ritmo/features/sports/models/workout_split_models.dart';

/// پیشنهاد حرکات متنی برای هر گروه عضله، تفکیک‌شده بر اساس محل تمرین.
const Map<MuscleGroup, Map<SportsLocation, List<String>>> kExerciseSuggestions = {
  MuscleGroup.chest: {
    SportsLocation.home: ['شنا سوئدی', 'شنا روی زانو', 'شنا دست‌جمع', 'دیپ روی صندلی', 'شنا پایک'],
    SportsLocation.gym:  ['پرس سینه هالتر', 'پرس سینه دمبل', 'قفسه سینه', 'پرس بالاسینه', 'کراس‌اوور'],
  },
  MuscleGroup.back: {
    SportsLocation.home: ['زیربغل با کش', 'سوپرمن', 'پارویی خم با بطری آب', 'کشش‌طناب'],
    SportsLocation.gym:  ['زیربغل سیم‌کش', 'بارفیکس', 'پارویی هالتر', 'ددلیفت', 'تی‌بار'],
  },
  MuscleGroup.shoulders: {
    SportsLocation.home: ['نشر جانب با کش', 'پرس سرشانه با بطری', 'شنا پایک', 'نشر خم'],
    SportsLocation.gym:  ['پرس سرشانه دمبل', 'نشر جانب', 'نشر خم', 'پرس نظامی', 'نشر جلو'],
  },
  MuscleGroup.biceps: {
    SportsLocation.home: ['جلو بازو با کش', 'جلو بازو با بطری آب', 'کشش ایزومتریک', 'چکشی با کش'],
    SportsLocation.gym:  ['جلو بازو هالتر', 'جلو بازو دمبل', 'لاری سیم‌کش', 'چکشی', 'اسپایدر'],
  },
  MuscleGroup.triceps: {
    SportsLocation.home: ['دیپ روی صندلی', 'شنا دست‌جمع', 'پشت بازو با کش', 'کیک‌بک با بطری'],
    SportsLocation.gym:  ['پشت بازو سیم‌کش', 'دیپ پارالل', 'پرس دست‌جمع', 'اسکال‌کراشر', 'پشت‌بازو دمبل'],
  },
  MuscleGroup.legs: {
    SportsLocation.home: ['اسکوات با وزن بدن', 'لانگز', 'پل باسن', 'ساق ایستاده', 'اسکوات سوموئی'],
    SportsLocation.gym:  ['اسکوات هالتر', 'پرس پا', 'لانگز دمبل', 'ساق دستگاه', 'ددلیفت رومانیایی'],
  },
  MuscleGroup.abs: {
    SportsLocation.home: ['کرانچ', 'پلانک', 'کوهنورد', 'زیرشکم خوابیده', 'چرخش روسی'],
    SportsLocation.gym:  ['کرانچ سیم‌کش', 'زیرشکم آویزان', 'پلانک', 'چرخش روسی', 'ویل رول‌اوت'],
  },
  MuscleGroup.fullBody: {
    SportsLocation.home: ['برپی', 'جامپینگ‌جک', 'اسکوات+پرس با کش', 'کوهنورد', 'مقص دست و پا'],
    SportsLocation.gym:  ['ددلیفت', 'کلین', 'کتل‌بل سوینگ', 'سرکیت کامل', 'تراست'],
  },
  MuscleGroup.cardio: {
    SportsLocation.home: ['طناب‌زنی', 'دویدن درجا', 'جامپینگ‌جک', 'اینتروال خانگی', 'پله‌نوردی'],
    SportsLocation.gym:  ['تردمیل', 'دوچرخه‌ثابت', 'الپتیکال', 'روئینگ', 'استپ‌میل'],
  },
  MuscleGroup.rest: {
    SportsLocation.home: ['کشش سبک ۱۰ دقیقه', 'پیاده‌روی آرام', 'تنفس دیافراگمی', 'یوگای سبک'],
    SportsLocation.gym:  ['فوم‌رولر', 'کشش سبک', 'ماساژ عضله', 'پیاده‌روی آرام'],
  },
};

List<String> suggestionsFor(List<MuscleGroup> groups, SportsLocation loc) {
  final out = <String>[];
  for (final g in groups) {
    final byLoc = kExerciseSuggestions[g];
    if (byLoc == null) continue;
    out.addAll(byLoc[loc] ?? const []);
  }
  return out;
}
