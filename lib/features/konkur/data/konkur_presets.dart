import 'dart:math';

import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:sqflite/sqflite.dart';

class PresetTopic {

  const PresetTopic({
    required this.name,
    required this.examQuestionCount,
  });
  final String name;
  final int examQuestionCount;
}

class PresetSubject {

  const PresetSubject({
    required this.name,
    required this.subjectGroup,
    required this.importanceFactor,
    required this.examQuestionCount,
    required this.topics,
  });
  final String name;
  final String subjectGroup; // GENERAL or SPECIALIZED
  final double importanceFactor;
  final int examQuestionCount;
  final List<PresetTopic> topics;
}

class KonkurPresets {
  static String _generateUniqueId() {
    final rand = Random();
    final ms = DateTime.now().microsecondsSinceEpoch;
    final r = rand.nextInt(1000000);
    return 'konkur_${ms}_$r';
  }

  // GENERAL SUBJECTS PRESETS (for old system or general switch)
  static const List<PresetSubject> generalSubjects = [
    PresetSubject(
      name: 'ادبیات فارسی عمومی',
      subjectGroup: 'GENERAL',
      importanceFactor: 4,
      examQuestionCount: 25,
      topics: [
        PresetTopic(name: 'قرابت معنایی', examQuestionCount: 9),
        PresetTopic(name: 'آرایه‌های ادبی', examQuestionCount: 6),
        PresetTopic(name: 'دستور زبان', examQuestionCount: 5),
        PresetTopic(name: 'لغت و املا', examQuestionCount: 5),
      ],
    ),
    PresetSubject(
      name: 'عربی عمومی',
      subjectGroup: 'GENERAL',
      importanceFactor: 2,
      examQuestionCount: 25,
      topics: [
        PresetTopic(name: 'ترجمه و تعریب', examQuestionCount: 10),
        PresetTopic(name: 'مفهوم', examQuestionCount: 3),
        PresetTopic(name: 'قواعد و صرف و نحو', examQuestionCount: 8),
        PresetTopic(name: 'درک مطلب', examQuestionCount: 4),
      ],
    ),
    PresetSubject(
      name: 'دین و زندگی',
      subjectGroup: 'GENERAL',
      importanceFactor: 3,
      examQuestionCount: 25,
      topics: [
        PresetTopic(name: 'آیات و روایات', examQuestionCount: 12),
        PresetTopic(name: 'متن درس‌ها', examQuestionCount: 10),
        PresetTopic(name: 'اشعار و ابیات', examQuestionCount: 3),
      ],
    ),
    PresetSubject(
      name: 'زبان انگلیسی عمومی',
      subjectGroup: 'GENERAL',
      importanceFactor: 2,
      examQuestionCount: 25,
      topics: [
        PresetTopic(name: 'واژگان', examQuestionCount: 8),
        PresetTopic(name: 'گرامر', examQuestionCount: 4),
        PresetTopic(name: 'کلوز تست', examQuestionCount: 5),
        PresetTopic(name: 'درک مطلب (Reading)', examQuestionCount: 8),
      ],
    ),
  ];

  static const Map<KonkurField, List<PresetSubject>> fieldPresets = {
    KonkurField.riyazi: [
      PresetSubject(
        name: 'ریاضیات (دیفرانسیل، هندسه و گسسته)',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 12,
        examQuestionCount: 40,
        topics: [
          PresetTopic(name: 'حسابان و ریاضی پایه', examQuestionCount: 15),
          PresetTopic(name: 'هندسه پایه و دوازدهم', examQuestionCount: 12),
          PresetTopic(name: 'ریاضیات گسسته و آمار و احتمال', examQuestionCount: 13),
        ],
      ),
      PresetSubject(
        name: 'فیزیک',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 9,
        examQuestionCount: 35,
        topics: [
          PresetTopic(name: 'مکانیک', examQuestionCount: 10),
          PresetTopic(name: 'الکتریسیته و مغناطیس', examQuestionCount: 11),
          PresetTopic(name: 'حرارت و ترمودینامیک', examQuestionCount: 4),
          PresetTopic(name: 'نوسان، امواج و فیزیک مدرن', examQuestionCount: 10),
        ],
      ),
      PresetSubject(
        name: 'شیمی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 7,
        examQuestionCount: 30,
        topics: [
          PresetTopic(name: 'شیمی پایه (دهم و یازدهم)', examQuestionCount: 15),
          PresetTopic(name: 'شیمی دوازدهم', examQuestionCount: 15),
        ],
      ),
    ],

    KonkurField.tajrobi: [
      PresetSubject(
        name: 'زیست‌شناسی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 12,
        examQuestionCount: 45,
        topics: [
          PresetTopic(name: 'زیست‌شناسی دهم', examQuestionCount: 10),
          PresetTopic(name: 'زیست‌شناسی یازدهم', examQuestionCount: 17),
          PresetTopic(name: 'زیست‌شناسی دوازدهم', examQuestionCount: 18),
        ],
      ),
      PresetSubject(
        name: 'شیمی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 9,
        examQuestionCount: 35,
        topics: [
          PresetTopic(name: 'شیمی پایه (دهم و یازدهم)', examQuestionCount: 17),
          PresetTopic(name: 'شیمی دوازدهم', examQuestionCount: 18),
        ],
      ),
      PresetSubject(
        name: 'ریاضی تجربی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 7,
        examQuestionCount: 30,
        topics: [
          PresetTopic(name: 'تابع و مثلثات', examQuestionCount: 8),
          PresetTopic(name: 'حد، پیوستگی و مشتق', examQuestionCount: 10),
          PresetTopic(name: 'هندسه و آمار و احتمال', examQuestionCount: 6),
          PresetTopic(name: 'معادلات و ریاضی پایه', examQuestionCount: 6),
        ],
      ),
      PresetSubject(
        name: 'فیزیک تجربی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 7,
        examQuestionCount: 30,
        topics: [
          PresetTopic(name: 'فیزیک پایه (دهم و یازدهم)', examQuestionCount: 14),
          PresetTopic(name: 'فیزیک دوازدهم', examQuestionCount: 16),
        ],
      ),
      PresetSubject(
        name: 'زمین‌شناسی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 1,
        examQuestionCount: 15,
        topics: [
          PresetTopic(name: 'زمین‌شناسی پایه', examQuestionCount: 15),
        ],
      ),
    ],

    KonkurField.ensani: [
      PresetSubject(
        name: 'زبان و ادبیات اختصاصی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 8,
        examQuestionCount: 30,
        topics: [
          PresetTopic(name: 'عروض و قافیه', examQuestionCount: 8),
          PresetTopic(name: 'آرایه‌های ادبی اختصاصی', examQuestionCount: 7),
          PresetTopic(name: 'تاریخ ادبیات و سبک‌شناسی', examQuestionCount: 9),
          PresetTopic(name: 'قرابت معنایی اختصاصی', examQuestionCount: 6),
        ],
      ),
      PresetSubject(
        name: 'ریاضی و آمار انسانی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 6,
        examQuestionCount: 20,
        topics: [
          PresetTopic(name: 'ریاضی دهم انسانی', examQuestionCount: 7),
          PresetTopic(name: 'آمار و احتمال یازدهم', examQuestionCount: 7),
          PresetTopic(name: 'ریاضی و آمار دوازدهم', examQuestionCount: 6),
        ],
      ),
      PresetSubject(
        name: 'زبان عربی اختصاصی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 5,
        examQuestionCount: 20,
        topics: [
          PresetTopic(name: 'ترجمه و مفاهیم عربی اختصاصی', examQuestionCount: 8),
          PresetTopic(name: 'درک مطلب عربی اختصاصی', examQuestionCount: 4),
          PresetTopic(name: 'قواعد و تجزیه و ترکیب عربی', examQuestionCount: 8),
        ],
      ),
      PresetSubject(
        name: 'تاریخ و جغرافیا',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 5,
        examQuestionCount: 30,
        topics: [
          PresetTopic(name: 'تاریخ (دهم، یازدهم و دوازدهم)', examQuestionCount: 15),
          PresetTopic(name: 'جغرافیا (دهم، یازدهم و دوازدهم)', examQuestionCount: 15),
        ],
      ),
      PresetSubject(
        name: 'جامعه‌شناسی و علوم اجتماعی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 5,
        examQuestionCount: 20,
        topics: [
          PresetTopic(name: 'جامعه‌شناسی دهم و یازدهم', examQuestionCount: 12),
          PresetTopic(name: 'جامعه‌شناسی دوازدهم', examQuestionCount: 8),
        ],
      ),
      PresetSubject(
        name: 'فلسفه و منطق',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 5,
        examQuestionCount: 20,
        topics: [
          PresetTopic(name: 'منطق دهم', examQuestionCount: 8),
          PresetTopic(name: 'فلسفه یازدهم و دوازدهم', examQuestionCount: 12),
        ],
      ),
      PresetSubject(
        name: 'اقتصاد',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 2,
        examQuestionCount: 15,
        topics: [
          PresetTopic(name: 'اقتصاد دهم', examQuestionCount: 15),
        ],
      ),
      PresetSubject(
        name: 'روان‌شناسی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 2,
        examQuestionCount: 20,
        topics: [
          PresetTopic(name: 'روان‌شناسی یازدهم', examQuestionCount: 20),
        ],
      ),
    ],

    KonkurField.honar: [
      PresetSubject(
        name: 'درک عمومی هنر',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 12,
        examQuestionCount: 50,
        topics: [
          PresetTopic(name: 'تاریخ هنر ایران و جهان', examQuestionCount: 30),
          PresetTopic(name: 'هنرهای سنتی و صنایع دستی', examQuestionCount: 20),
        ],
      ),
      PresetSubject(
        name: 'خلاقیت تصویری و تجسمی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 3,
        examQuestionCount: 20,
        topics: [
          PresetTopic(name: 'مبانی هنرهای تجسمی', examQuestionCount: 10),
          PresetTopic(name: 'کادربندی و رنگ در تصویر', examQuestionCount: 10),
        ],
      ),
      PresetSubject(
        name: 'ترسیم فنی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 3,
        examQuestionCount: 20,
        topics: [
          PresetTopic(name: 'رسم فنی و پرسپکتیو', examQuestionCount: 20),
        ],
      ),
      PresetSubject(
        name: 'خلاقیت نمایشی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 3,
        examQuestionCount: 20,
        topics: [
          PresetTopic(name: 'تاریخ سینما و تئاتر', examQuestionCount: 12),
          PresetTopic(name: 'ابزارها و تکنیک‌های نمایش', examQuestionCount: 8),
        ],
      ),
      PresetSubject(
        name: 'خواص مواد',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 3,
        examQuestionCount: 20,
        topics: [
          PresetTopic(name: 'خواص فلزات، چوب و مواد مصنوعی', examQuestionCount: 20),
        ],
      ),
      PresetSubject(
        name: 'خلاقیت موسیقی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 3,
        examQuestionCount: 20,
        topics: [
          PresetTopic(name: 'تئوری موسیقی و سازشناسی', examQuestionCount: 20),
        ],
      ),
    ],

    KonkurField.zaban: [
      PresetSubject(
        name: 'زبان تخصصی انگلیسی',
        subjectGroup: 'SPECIALIZED',
        importanceFactor: 12,
        examQuestionCount: 70,
        topics: [
          PresetTopic(name: 'واژگان تخصصی', examQuestionCount: 25),
          PresetTopic(name: 'گرامر و ساختار زبان', examQuestionCount: 15),
          PresetTopic(name: 'کاربرد زبان در موقعیت‌ها', examQuestionCount: 10),
          PresetTopic(name: 'درک مطلب تخصصی (Reading)', examQuestionCount: 20),
        ],
      ),
    ],
  };

  static Future<void> seedFieldIntoDb(Database db, KonkurField field, {bool includeGeneral = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final subjectsToSeed = <PresetSubject>[];

    // 1. Gather subjects
    if (includeGeneral) {
      subjectsToSeed.addAll(generalSubjects);
    }

    final specialized = fieldPresets[field];
    if (specialized != null) {
      subjectsToSeed.addAll(specialized);
    }

    // 2. Perform database insert within transaction
    await db.transaction((txn) async {
      var subjectIndex = 0;
      for (final pSub in subjectsToSeed) {
        final subjectId = _generateUniqueId();
        
        await txn.insert('konkur_subjects', {
          'id': subjectId,
          'name': pSub.name,
          'importanceFactor': pSub.importanceFactor,
          'progressPercentage': 0.0,
          'isArchived': 0,
          'createdAt': now,
          'updatedAt': now,
          'subjectGroup': pSub.subjectGroup,
          'examQuestionCount': pSub.examQuestionCount,
          'orderIndex': subjectIndex++,
          'isPreset': 1,
        });

        var topicIndex = 0;
        for (final pTopic in pSub.topics) {
          final topicId = _generateUniqueId();
          
          await txn.insert('konkur_topics', {
            'id': topicId,
            'subjectId': subjectId,
            'parentTopicId': null,
            'name': pTopic.name,
            'progressPercentage': 0.0,
            'studyTargetMinutes': pTopic.examQuestionCount * 60, // e.g. 1 hour per question as target
            'studyCompletedMinutes': 0,
            'createdAt': now,
            'updatedAt': now,
            'examQuestionCount': pTopic.examQuestionCount,
            'masteryLevel': 'NOT_STARTED',
            'lastStudiedAt': null,
            'nextReviewDate': null,
            'plannedDate': null,
            'orderIndex': topicIndex++,
          });
        }
      }
    });
  }
}
