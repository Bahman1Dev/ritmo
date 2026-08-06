import 'package:shamsi_date/shamsi_date.dart';
import 'package:ritmo/features/worship/logic/hijri_calendar.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';

enum WorshipOccasionCategory {
  celebration, // ولادت / عید (🎉/☀️)
  mourning,    // شهادت / وفات / سوگواری (🏴/🌙)
  worshipDeed, // اعمال خاص / شب قدر / عرفه (✨/🤲)
  fasting,     // روزه واجب یا مستحبی (🌙/🌾)
}

class WorshipOccasion {
  const WorshipOccasion({
    required this.title,
    required this.category,
    this.description,
    this.recommendedAmal,
    this.isReligiousHoliday = false,
  });

  final String title;
  final WorshipOccasionCategory category;
  final String? description;
  final String? recommendedAmal;
  final bool isReligiousHoliday;
}

class WorshipOccasionsData {
  const WorshipOccasionsData._();

  /// Map of Hijri month-day (e.g. "1-10") to list of worship occasions.
  /// ONLY worship/religious occasions. Secular/national events are omitted.
  static final Map<String, List<WorshipOccasion>> hijriOccasions = {
    // 1. Muharram
    '1-1': [
      const WorshipOccasion(
        title: 'آغاز سال نو هجری قمری (اول محرم)',
        category: WorshipOccasionCategory.worshipDeed,
        recommendedAmal: 'زیارت عاشورا، نماز اول ماه، روزه گرفتن در اول محرم',
      )
    ],
    '1-9': [
      const WorshipOccasion(
        title: 'تاسوعای حسینی (روز عزای آل محمد)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'زیارت عاشورا، امساک تا عصر، عزاداری و اطعام حسینی',
        isReligiousHoliday: true,
      )
    ],
    '1-10': [
      const WorshipOccasion(
        title: 'عاشورای حسینی (شهادت سیدالشهدا ع)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'زیارت عاشورا، زیارت وارث، امساک تا عصر، پرهیز از کار دنیا',
        isReligiousHoliday: true,
      )
    ],
    '1-12': [
      const WorshipOccasion(
        title: 'شهادت امام سجاد (ع)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'قرائت صحیفه سجادیه و زیارت امام سجاد (ع)',
      )
    ],
    '1-25': [
      const WorshipOccasion(
        title: 'شهادت امام زین‌العابدین ع (به روایتی)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'قرائت دعای مکارم الاخلاق و صحیفه سجادیه',
      )
    ],

    // 2. Safar
    '2-7': [
      const WorshipOccasion(
        title: 'ولادت امام موسی کاظم (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'زیارت حضرت باب الحوائج امام کاظم (ع)',
      )
    ],
    '2-20': [
      const WorshipOccasion(
        title: 'اربعین حسینی (چهلم شهادت حضرت سیدالشهدا ع)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'قرائت زیارت اربعین و زیارت حضرت امام حسین (ع)',
        isReligiousHoliday: true,
      )
    ],
    '2-28': [
      const WorshipOccasion(
        title: 'رحلت خاتم الانبیاء حضرت محمد (ص) و شهادت امام حسن مجتبی (ع)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'زیارت از از راه دور حضرت رسول (ص) و زیارت حضرت امام حسن (ع)',
        isReligiousHoliday: true,
      )
    ],
    '2-30': [
      const WorshipOccasion(
        title: 'شهادت ثامن الحجج حضرت علی بن موسی الرضا (ع)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'زیارت حضرت امام رضا (ع) و صلوات خاصه امام رضا',
        isReligiousHoliday: true,
      )
    ],

    // 3. Rabi al-Awwal
    '3-1': [
      const WorshipOccasion(
        title: 'لیلة المبیت (فداکاری امیرالمؤمنین ع)',
        category: WorshipOccasionCategory.worshipDeed,
        recommendedAmal: 'شکرگزاری و زیارت امیرالمؤمنین (ع)',
      )
    ],
    '3-8': [
      const WorshipOccasion(
        title: 'شهادت امام حسن عسکری (ع) و آغاز امامت حضرت مهدی (عج)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'دعای عهد و زیارت امام زمان (عج)',
        isReligiousHoliday: true,
      )
    ],
    '3-17': [
      const WorshipOccasion(
        title: 'میلاد مسعود حضرت رسول اکرم (ص) و امام جعفر صادق (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'روزه داشتن (ثواب یک سال)، غسل، زیارت حضرت رسول و امیرالمؤمنین',
        isReligiousHoliday: true,
      )
    ],

    // 4. Rabi al-Thani
    '4-8': [
      const WorshipOccasion(
        title: 'ولادت با سعادت امام حسن عسکری (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'زیارت امام حسن عسکری (ع) و صدقه دادن',
      )
    ],
    '4-10': [
      const WorshipOccasion(
        title: 'وفات حضرت فاطمه معصومه (س)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'زیارت حضرت معصومه (س) در قم یا از راه دور',
      )
    ],

    // 5. Jumada al-Awwal
    '5-5': [
      const WorshipOccasion(
        title: 'ولادت حضرت زینب کبری (س)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'قرائت خطبه‌های حضرت زینب (س) و زیارت ایشان',
      )
    ],
    '5-13': [
      const WorshipOccasion(
        title: 'شهادت حضرت فاطمه زهرا (س) (روایت ۷۵ روز)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'تسبیحات حضرت زهرا (س) و زیارتنامه ایشان',
      )
    ],

    // 6. Jumada al-Thani
    '6-3': [
      const WorshipOccasion(
        title: 'شهادت حضرت فاطمه زهرا (س) (فاطمیه دوم)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'تسبیحات حضرت زهرا، زیارتنامه و اقامه عزای فاطمی',
        isReligiousHoliday: true,
      )
    ],
    '6-20': [
      const WorshipOccasion(
        title: 'ولادت حضرت فاطمه زهرا (س) و روز زن',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'صلوات حضرت زهرا (س)، نیکی به مادر و تسبیحات',
      )
    ],

    // 7. Rajab
    '7-1': [
      const WorshipOccasion(
        title: 'ولادت امام محمد باقر (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'دعای استغفار ماه رجب و زیارت امام باقر (ع)',
      )
    ],
    '7-3': [
      const WorshipOccasion(
        title: 'شهادت امام علی النقی الهادی (ع)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'زیارت جامعه کبیره (یادگار امام هادی ع)',
      )
    ],
    '7-10': [
      const WorshipOccasion(
        title: 'ولادت امام محمد تقی الجواد (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'زیارت امام جواد (ع) و دعای توسل',
      )
    ],
    '7-13': [
      const WorshipOccasion(
        title: 'ولادت امیرالمؤمنین امام علی (ع) / آغاز ایام البیض',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'زیارت امین‌الله، روزه گرفتن در ایام البیض (۱۳، ۱۴، ۱۵)',
        isReligiousHoliday: true,
      )
    ],
    '7-15': [
      const WorshipOccasion(
        title: 'وفات حضرت زینب (س) / اعمال ام داوود',
        category: WorshipOccasionCategory.worshipDeed,
        recommendedAmal: 'اعمال ام داوود، روزه داشتن و زیارت حضرت زینب (س)',
      )
    ],
    '7-25': [
      const WorshipOccasion(
        title: 'شهادت باب الحوائج امام موسی کاظم (ع)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'زیارت حضرت امام موسی بن جعفر (ع)',
      )
    ],
    '7-27': [
      const WorshipOccasion(
        title: 'عید سعید مبعث حضرت رسول اکرم (ص)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'روزه داشتن (از ۴ روز بسیار بافضیلت سال)، غسل و زیارت حضرت رسول',
        isReligiousHoliday: true,
      )
    ],

    // 8. Sha'ban
    '8-3': [
      const WorshipOccasion(
        title: 'ولادت حضرت اباعبدالله الحسین (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'زیارت حضرت امام حسین (ع) و مناجات شعبانیه',
      )
    ],
    '8-4': [
      const WorshipOccasion(
        title: 'ولادت حضرت ابوالفضل العباس (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'زیارت حضرت عباس (ع) و مناجات شعبانیه',
      )
    ],
    '8-5': [
      const WorshipOccasion(
        title: 'ولادت امام سجاد (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'قرائت دعای صحیفه سجادیه و مناجات شعبانیه',
      )
    ],
    '8-11': [
      const WorshipOccasion(
        title: 'ولادت حضرت علی اکبر (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'زیارت حضرت علی اکبر (ع)',
      )
    ],
    '8-15': [
      const WorshipOccasion(
        title: 'ولادت حضرت ولی‌عصر امام مهدی (عج) (نیمه شعبان)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'احیای شب نیمه شعبان، دعای کمیل، زیارت امام حسین (ع)، دعای فرج',
        isReligiousHoliday: true,
      )
    ],

    // 9. Ramadan
    '9-1': [
      const WorshipOccasion(
        title: 'آغاز ماه مبارک رمضان (ماه نزول قرآن و روزه‌داری)',
        category: WorshipOccasionCategory.fasting,
        recommendedAmal: 'روزه واجب، قرائت قرآن، دعای افتتاح و غسل شب اول رمضان',
      )
    ],
    '9-10': [
      const WorshipOccasion(
        title: 'وفات ام‌المؤمنین حضرت خدیجه کبری (س)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'زیارت حضرت خدیجه (س) و هدیه ثواب روزه به ایشان',
      )
    ],
    '9-15': [
      const WorshipOccasion(
        title: 'ولادت سبط اکبر امام حسن مجتبی (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'اطعام روزه‌داران و زیارت حضرت امام حسن (ع)',
      )
    ],
    '9-19': [
      const WorshipOccasion(
        title: 'ضربت خوردن امیرالمؤمنین (ع) / شب ۱۹ رمضان (اولین شب قدر)',
        category: WorshipOccasionCategory.worshipDeed,
        recommendedAmal: 'احیا، غسل، ۱۰۰ ركعت نماز، صد بار استغفار، زیارت امام حسین (ع) و قرآن بر سر گذاشتن',
      )
    ],
    '9-21': [
      const WorshipOccasion(
        title: 'شهادت امیرالمؤمنین امام علی (ع) / شب ۲۱ رمضان (دومین شب قدر)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'احیای شب قدر، غسل، زیارت امیرالمؤمنین (ع)، دعای جوشن کبیر',
        isReligiousHoliday: true,
      )
    ],
    '9-23': [
      const WorshipOccasion(
        title: 'شب ۲۳ رمضان (مهم‌ترین شب قدر و نزول قرآن)',
        category: WorshipOccasionCategory.worshipDeed,
        recommendedAmal: 'احیا تا سپیده دم، سوره عنکبوت و روم و دخان، دعای سلامتی امام زمان (عج)',
      )
    ],

    // 10. Shawwal
    '10-1': [
      const WorshipOccasion(
        title: 'عید سعید فطر (اول شوال)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'نماز عید فطر، پرداخت زکات فطره، تکبیرات عید و غسل اول روز',
        isReligiousHoliday: true,
      )
    ],
    '10-25': [
      const WorshipOccasion(
        title: 'شهادت رئیس مذهب جعفری امام جعفر صادق (ع)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'زیارت امام جعفر صادق (ع) در بقیع و اقامه عزاداری',
        isReligiousHoliday: true,
      )
    ],

    // 11. Dhu al-Qadah
    '11-1': [
      const WorshipOccasion(
        title: 'ولادت حضرت فاطمه معصومه (س)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'زیارت حضرت معصومه (س) و آغاز دهه کرامت',
      )
    ],
    '11-11': [
      const WorshipOccasion(
        title: 'ولادت با سعادت حضرت امام رضا (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'زیارت حضرت امام رضا (ع) و قرائت صلوات خاصه',
      )
    ],
    '11-25': [
      const WorshipOccasion(
        title: 'روز دحو الارض (پهن شدن زمین از زیر کعبه)',
        category: WorshipOccasionCategory.worshipDeed,
        recommendedAmal: 'روزه داشتن (ثواب ۷۰ سال روزه)، غسل، زیارت امام رضا و نماز دحو الارض',
      )
    ],

    // 12. Dhu al-Hijjah
    '12-1': [
      const WorshipOccasion(
        title: 'سالروز ازدواج آسمانی حضرت علی (ع) و حضرت زهرا (س)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'روزه داشتن و زیارت امیرالمؤمنین و حضرت زهرا (ع)',
      )
    ],
    '12-7': [
      const WorshipOccasion(
        title: 'شهادت امام محمد باقر (ع)',
        category: WorshipOccasionCategory.mourning,
        recommendedAmal: 'زیارت امام باقر (ع) و قرائت دعای توسل',
      )
    ],
    '12-9': [
      const WorshipOccasion(
        title: 'روز عرفه (روز نیایش و استغفار)',
        category: WorshipOccasionCategory.worshipDeed,
        recommendedAmal: 'دعای عرفه امام حسین (ع)، غسل، روزه (در صورت عدم ضعف از دعا)، زیارت امام حسین',
      )
    ],
    '12-10': [
      const WorshipOccasion(
        title: 'عید سعید قربان (عید الاضحی)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'نماز عید قربان، غسل، قربانی کردن و تکبیرات عید',
        isReligiousHoliday: true,
      )
    ],
    '12-15': [
      const WorshipOccasion(
        title: 'ولادت امام علی النقی الهادی (ع)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'زیارت جامعه کبیره و زیارت غدیریه',
      )
    ],
    '12-18': [
      const WorshipOccasion(
        title: 'عید سعید غدیر خم (عید الله الاکبر)',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'روزه (کفاره ۶۰ سال گناه)، غسل، عقد اخوت، اطعام مؤمنین، زیارت امین‌الله',
        isReligiousHoliday: true,
      )
    ],
    '12-24': [
      const WorshipOccasion(
        title: 'روز مباهله پیامبر اکرم (ص) و روز آیه تطهیر',
        category: WorshipOccasionCategory.celebration,
        recommendedAmal: 'غسل، روزه، دعای مباهله و زیارت امیرالمؤمنین (ع)',
      )
    ],
  };

  /// Daily Zikr of the week (ذکر روز هفته)
  static String getDailyZikr(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'یا رَبَّ الْعالَمین (۱۰۰ مرتبه)';
      case DateTime.sunday:
        return 'یا ذَا الْجَلالِ وَ الْإِكْرام (۱۰۰ مرتبه)';
      case DateTime.monday:
        return 'یا قاضِیَ الْحاجات (۱۰۰ مرتبه)';
      case DateTime.tuesday:
        return 'یا أَرْحَمَ الرّاحِمین (۱۰۰ مرتبه)';
      case DateTime.wednesday:
        return 'یا حَیُّ یا قَیّوم (۱۰۰ مرتبه)';
      case DateTime.thursday:
        return 'لا إِلهَ إِلَّا اللهُ الْمَلِكُ الْحَقُّ الْمُبین (۱۰۰ مرتبه)';
      case DateTime.friday:
        return 'اللّهُمَّ صَلِّ عَلی مُحَمَّدٍ وَ آلِ مُحَمَّدٍ وَ عَجِّلْ فَرَجَهُمْ (۱۰۰ مرتبه)';
      default:
        return 'ذکر روز هفته';
    }
  }

  /// Returns worship occasions for a given solar date and Hijri date.
  static List<WorshipOccasion> getOccasionsForDay(Jalali solar, HijriDate hijri) {
    final list = <WorshipOccasion>[];

    // Query Hijri occasions
    final hKey = '${hijri.month}-${hijri.day}';
    if (hijriOccasions.containsKey(hKey)) {
      list.addAll(hijriOccasions[hKey]!);
    }

    return list;
  }
}
