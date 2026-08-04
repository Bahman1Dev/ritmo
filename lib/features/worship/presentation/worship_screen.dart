import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:ritmo/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart';
import 'package:ritmo/features/worship/presentation/widgets/mustahab_section.dart';
import 'package:ritmo/features/worship/presentation/widgets/obligatory_prayers_section.dart';
import 'package:ritmo/features/worship/presentation/widgets/prayer_city_picker.dart';
import 'package:ritmo/features/worship/presentation/widgets/prayer_times_hero.dart';
import 'package:ritmo/features/worship/presentation/widgets/quran_dhikr_section.dart';
import 'package:ritmo/features/worship/presentation/widgets/worship_debts_section.dart';
import 'package:ritmo/features/worship/presentation/widgets/worship_seasons_section.dart';
import 'package:shamsi_date/shamsi_date.dart';

class WorshipScreen extends StatefulWidget {
  const WorshipScreen({super.key});

  @override
  State<WorshipScreen> createState() => _WorshipScreenState();
}

class _WorshipScreenState extends State<WorshipScreen> {
  PrayerTime? _prayerTime;
  HijriDate? _hijriDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Load prayer times cache
      final settings = await db.query('app_settings', where: 'key = ?', whereArgs: ['prayer_city_id'], limit: 1);
      final cityId = settings.isNotEmpty ? settings.first['value']! as String : 'TEHRAN_TEHRAN';
      final now = DateTime.now();
      final dateStr = now.toIso8601String().substring(0, 10);

      final cacheResults = await db.query(
        'prayer_times_cache',
        where: 'date = ? AND cityId = ?',
        whereArgs: [dateStr, cityId],
        limit: 1,
      );

      PrayerTime? pTime;
      if (cacheResults.isNotEmpty) {
        pTime = PrayerTime.fromMap(cacheResults.first);
      }

      // 2. Load Hijri Date
      final hDate = await HijriDate.getOrFetch(now, db);

      if (mounted) {
        setState(() {
          _prayerTime = pTime;
          _hijriDate = hDate;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading worship screen data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onDataChanged() {
    _loadData();
  }

  Future<void> _refresh() async {
    unawaited(HapticFeedback.mediumImpact());
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('app_settings', where: 'key = ?', whereArgs: ['prayer_city_id'], limit: 1);
      final cityId = settings.isNotEmpty ? settings.first['value']! as String : 'TEHRAN_TEHRAN';
      
      await PrayerTimeProvider.instance.cachePrayerTimes(cityId: cityId, date: DateTime.now());
      _onDataChanged();
    } catch (e) {
      debugPrint('Error refreshing worship screen: $e');
    }
  }

  void _openCityPicker(int tabIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return PrayerCityPicker(
          initialTab: tabIndex,
          onChanged: _onDataChanged,
        );
      },
    );
  }

  void _openAiAssistant() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return const AiWorshipAssistantSheet();
      },
    );
  }

  // ─── Occasions & Dhikr Generator ───
  List<String> _getOccasionsOfDay(Jalali shamsi, HijriDate? hijri) {
    final list = <String>[];

    // Shamsi Month-Day keys: "month-day"
    final shamsiKey = '${shamsi.month}-${shamsi.day}';
    final shamsiEvents = {
      '1-1': 'نوروز و آغاز سال نو هجری شمسی 🌸',
      '1-2': 'عید نوروز',
      '1-12': 'روز جمهوری اسلامی ایران',
      '1-13': 'روز طبیعت (سیزده‌بدر) 🍃',
      '2-1': 'روز بزرگداشت سعدی',
      '2-3': 'روز بزرگداشت شیخ بهایی',
      '2-15': 'روز بزرگداشت فردوسی',
      '3-3': 'فتح خرمشهر در عملیات بیت‌المقدس (روز مقاومت، ایثار و پیروزی)',
      '3-14': 'رحلت جانگداز حضرت امام خمینی (ره)',
      '3-15': 'قیام خونین ۱۵ خرداد',
      '4-7': 'شهادت آیت‌الله دکتر بهشتی و ۷۲ تن از یاران امام خمینی',
      '4-10': 'روز آزادسازی مهران',
      '4-14': 'روز قلم',
      '5-14': 'صدور فرمان مشروطیت',
      '5-30': 'روز بزرگداشت علامه مجلسی',
      '6-4': 'روز کارمند',
      '6-8': 'شهادت رجایی و باهنر (روز مبارزه با تروریسم)',
      '6-21': 'روز سینما',
      '7-8': 'روز بزرگداشت مولوی',
      '7-20': 'روز بزرگداشت حافظ',
      '8-8': 'روز نوجوان',
      '8-24': 'روز کتاب و کتابخوانی',
      '9-16': 'روز دانشجو',
      '9-30': 'شب یلدا 🍉',
      '10-9': 'روز بصیرت و میثاق امت با ولایت',
      '11-22': 'پیروزی انقلاب اسلامی ایران (۱۳۵۷) ✌️',
      '12-29': 'ملی شدن صنعت نفت ایران',
    };

    if (shamsiEvents.containsKey(shamsiKey)) {
      list.add(shamsiEvents[shamsiKey]!);
    }

    if (hijri != null) {
      final hijriKey = '${hijri.month}-${hijri.day}';
      final hijriEvents = {
        '1-1': 'آغاز سال نو هجری قمری (اول محرم)',
        '1-9': 'تاسوعای حسینی 🏴',
        '1-10': 'عاشورای حسینی 🏴',
        '1-12': 'شهادت امام سجاد (ع) 🏴',
        '1-25': 'شهادت امام سجاد (ع) (به روایتی) 🏴',
        '2-7': 'ولادت امام موسی کاظم (ع)',
        '2-20': 'اربعین حسینی 🏴',
        '2-28': 'رحلت پیامبر اکرم (ص) و شهادت امام حسن مجتبی (ع) 🏴',
        '2-30': 'شهادت امام رضا (ع) 🏴',
        '3-1': 'هجرت پیامبر اکرم (ص) (لیلة المبیت)',
        '3-8': 'شهادت امام حسن عسکری (ع) و آغاز امامت امام زمان (عج) 🏴',
        '3-12': 'آغاز هفته وحدت / میلاد پیامبر اکرم (ص) به روایت اهل سنت',
        '3-17': 'میلاد رسول اکرم (ص) و امام جعفر صادق (ع) 🎉',
        '4-8': 'ولادت امام حسن عسکری (ع)',
        '4-10': 'وفات حضرت معصومه (س) 🏴',
        '5-5': 'ولادت حضرت زینب (س) و روز پرستار 🎉',
        '5-13': 'شهادت حضرت فاطمه زهرا (س) (به روایتی) 🏴',
        '6-3': 'شهادت حضرت فاطمه زهرا (س) (فاطمیه دوم) 🏴',
        '6-20': 'ولادت حضرت فاطمه زهرا (س) و روز مادر 🎉',
        '7-1': 'ولادت امام محمد باقر (ع)',
        '7-3': 'شهادت امام علی النقی الهادی (ع) 🏴',
        '7-10': 'ولادت امام محمد تقی الجواد (ع)',
        '7-13': 'ولادت امیرالمؤمنین امام علی (ع) (روز پدر) 🎉 / آغاز ایام البیض',
        '7-15': 'وفات حضرت زینب (س) 🏴',
        '7-25': 'شهادت امام موسی کاظم (ع) 🏴',
        '7-27': 'مبعث رسول اکرم (ص) 🎉',
        '8-3': 'ولادت امام حسین (ع) و روز پاسدار 🎉',
        '8-4': 'ولادت حضرت ابوالفضل العباس (ع) و روز جانباز 🎉',
        '8-5': 'ولادت امام سجاد (ع) 🎉',
        '8-11': 'ولادت حضرت علی اکبر (ع) و روز جوان 🎉',
        '8-15': 'ولادت حضرت مهدی (عج) (نیمه شعبان) 🎉',
        '9-1': 'آغاز ماه مبارک رمضان (ماه روزه‌داری) 🌙',
        '9-10': 'وفات حضرت خدیجه (س) 🏴',
        '9-15': 'ولادت امام حسن مجتبی (ع) 🎉',
        '9-17': 'معراج پیامبر اکرم (ص)',
        '9-19': 'ضربت خوردن امیرالمؤمنین امام علی (ع) 🏴 / شب قدر',
        '9-21': 'شهادت امیرالمؤمنین امام علی (ع) 🏴 / شب قدر',
        '9-23': 'شب قدر 🌙',
        '10-1': 'عید سعید فطر 🎉',
        '10-25': 'شهادت امام جعفر صادق (ع) 🏴',
        '11-1': 'ولادت حضرت معصومه (س) و روز دختر 🎉',
        '11-11': 'ولادت امام رضا (ع) 🎉',
        '12-1': 'سالروز ازدواج حضرت علی (ع) و حضرت زهرا (س) 🎉',
        '12-7': 'شهادت امام محمد باقر (ع) 🏴',
        '12-9': 'روز عرفه (روز نیایش)',
        '12-10': 'عید سعید قربان 🎉',
        '12-15': 'ولادت امام علی النقی الهادی (ع) 🎉',
        '12-18': 'عید سعید غدیر خم 🎉',
        '12-24': 'روز مباهله پیامبر اکرم (ص)',
      };
      if (hijriEvents.containsKey(hijriKey)) {
        list.add(hijriEvents[hijriKey]!);
      }
    }

    if (list.isEmpty) {
      final now = DateTime.now();
      switch (now.weekday) {
        case DateTime.saturday:
          list.add('ذکر روز شنبه: یا رب العالمین (۱۰۰ مرتبه) ☀️');
        case DateTime.sunday:
          list.add('ذکر روز یکشنبه: یا ذالجلال و الاکرام (۱۰۰ مرتبه) ☀️');
        case DateTime.monday:
          list.add('ذکر روز دوشنبه: یا قاضی الحاجات (۱۰۰ مرتبه) ☀️');
        case DateTime.tuesday:
          list.add('ذکر روز سه‌شنبه: یا ارحم الراحمین (۱۰۰ مرتبه) ☀️');
        case DateTime.wednesday:
          list.add('ذکر روز چهارشنبه: یا حی یا قیوم (۱۰۰ مرتبه) ☀️');
        case DateTime.thursday:
          list.add('ذکر روز پنج‌شنبه: لا اله الا الله الملک الحق المبین (۱۰۰ مرتبه) ☀️');
        case DateTime.friday:
          list.add('ذکر روز جمعه: اللهم صل علی محمد و آل محمد (۱۰۰ مرتبه) 💚');
      }
    }

    return list;
  }

  Widget _buildOccasionsSection(Jalali shamsi, HijriDate? hijri, BuildContext context) {
    final colors = context.colors;
    final occasions = _getOccasionsOfDay(shamsi, hijri);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                color: Color(0xffD4A843),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'مناسبت‌های امروز',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Vazirmatn',
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Occasions list (indented under the header)
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: occasions.map((occ) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          color: Color(0xffD4A843),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          occ,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          
          // Sleek gradient divider
          Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.border.withValues(alpha: 0.4),
                  colors.border.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final shamsiNow = Jalali.now();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.buildBackgroundContainer(
        context: context,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: RitmoModuleAppBar(
            title: 'عبادت و معنویت',
            subtitle: 'اذان، ادعیه و نمازهای مستحبی',
            statusBadge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xff10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'فعال',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Color(0xff10B981), fontWeight: FontWeight.bold),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.sparkles, color: Color(0xffC4953B)),
                tooltip: 'دستیار هوشمند',
                onPressed: _openAiAssistant,
              ),
              IconButton(
                icon: Icon(CupertinoIcons.settings, color: isDarkMode ? Colors.white70 : Colors.black87),
                tooltip: 'تنظیمات محاسبه',
                onPressed: () => _openCityPicker(1),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xffD4A843),
            backgroundColor: isDarkMode ? const Color(0xff2A2D3D) : Colors.white,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                // 1. PRAYER TIMES HERO CARD
                PrayerTimesHero(
                  onCityTap: () => _openCityPicker(0),
                  hijriDate: _hijriDate,
                ),
                const SizedBox(height: 16),

                if (_isLoading) ...[
                  const RitmoSkeletonList(itemCount: 4, itemHeight: 90),
                ] else ...[
                  // 2. OCCASIONS OF THE DAY (Premium borderless design)
                  _buildOccasionsSection(shamsiNow, _hijriDate, context),
                  const SizedBox(height: 16),

                  // 3. OBLIGATORY PRAYERS
                  ObligatoryPrayersSection(
                    prayerTime: _prayerTime,
                    onChanged: _onDataChanged,
                  ),
                  const SizedBox(height: 24),

                  // 4. MUSTAHAB
                  MustahabSection(
                    onChanged: _onDataChanged,
                  ),
                  const SizedBox(height: 24),

                  // 5. QURAN & DHIKR
                  QuranDhikrSection(
                    onChanged: _onDataChanged,
                  ),
                  const SizedBox(height: 24),

                  // 6. DEBTS
                  WorshipDebtsSection(
                    onChanged: _onDataChanged,
                  ),
                  const SizedBox(height: 24),

                  // 7. SEASONS
                  WorshipSeasonsSection(
                    onChanged: _onDataChanged,
                    hijriDate: _hijriDate,
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
