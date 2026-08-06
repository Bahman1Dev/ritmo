import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/features/worship/logic/hijri_calendar.dart';
import 'package:ritmo/features/worship/logic/worship_engine.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:ritmo/features/worship/presentation/widgets/lunar_month_grid.dart';
import 'package:ritmo/features/worship/presentation/widgets/mustahab_section.dart';
import 'package:ritmo/features/worship/presentation/widgets/night_prayer_card.dart';
import 'package:ritmo/features/worship/presentation/widgets/obligatory_prayers_section.dart';
import 'package:ritmo/features/worship/presentation/widgets/prayer_arc_hero.dart';
import 'package:ritmo/features/worship/presentation/widgets/prayer_city_picker.dart';
import 'package:ritmo/features/worship/presentation/widgets/qibla_compass_sheet.dart';
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
  WorshipDay? _worshipDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      final day = await WorshipEngine.instance.loadDay(now);

      if (mounted) {
        setState(() {
          _worshipDay = day;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading worship screen data: $e');
      // Retry once after short delay if first load fails
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final day = await WorshipEngine.instance.loadDay(DateTime.now());
        if (mounted) {
          setState(() {
            _worshipDay = day;
            _isLoading = false;
          });
        }
      } catch (e2) {
        debugPrint('Retry error loading worship screen data: $e2');
        if (mounted) {
          final now = DateTime.now();
          final fallbackTimes = await WorshipEngine.instance.prayerTimes(now);
          setState(() {
            _worshipDay = WorshipDay(
              date: now,
              hijri: WorshipEngine.instance.hijriFor(now),
              times: fallbackTimes,
              practices: [],
              seasons: [],
              context: WorshipDayContext(date: now),
              occasions: [],
            );
            _isLoading = false;
          });
        }
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

  void _openQiblaCompass() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return QiblaCompassSheet(
          cityName: _worshipDay?.times.cityId ?? 'تهران',
        );
      },
    );
  }

  String? _getQamariNightText() {
    if (_worshipDay == null) return null;
    final now = DateTime.now();
    final maghribTime = _worshipDay!.times.maghrib;
    if (now.isAfter(maghribTime)) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowHijri = HijriCalendarCalculator.hijriFromGregorian(tomorrow);
      return 'امشب: شب ${toPersianDigits(tomorrowHijri.day.toString())} ${tomorrowHijri.monthName}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                icon: const Icon(CupertinoIcons.compass, color: Color(0xffC4953B)),
                tooltip: 'قبله‌نما',
                onPressed: _openQiblaCompass,
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
                if (_isLoading && _worshipDay == null) ...[
                  const RitmoSkeletonCard(height: 320),
                  const SizedBox(height: 16),
                ] else if (_worshipDay != null) ...[
                  // 1. DAY ARC HERO ("قوس روز") — Section 4 UI Innovation #1
                  PrayerArcHero(
                    day: _worshipDay!,
                    onPracticeToggle: (practiceId, isDone) async {
                      if (isDone) {
                        await WorshipEngine.instance.logDone(practiceId: practiceId, date: DateTime.now());
                      } else {
                        await WorshipEngine.instance.logSkip(practiceId: practiceId, date: DateTime.now());
                      }
                      _onDataChanged();
                    },
                    onTravellerToggle: (isTraveller) async {
                      final ctx = WorshipDayContext(
                        date: _worshipDay?.context.date ?? DateTime.now(),
                        isTraveller: isTraveller,
                        prayerExempt: false,
                        fastingExempt: isTraveller,
                        reason: isTraveller ? 'TRAVEL' : null,
                      );
                      await WorshipEngine.instance.setDayContext(ctx);
                      _onDataChanged();
                    },
                    onOpenCityPicker: () => _openCityPicker(0),
                  ),
                  const SizedBox(height: 12),

                  // 2. NIGHT PRAYER RITUAL CARD — Section 5 Feature #3 (after Shari Midnight)
                  NightPrayerCard(
                    day: _worshipDay!,
                    onComplete: _onDataChanged,
                  ),
                  const SizedBox(height: 12),

                  // 3. PREMIUM SOLAR WORSHIP CALENDAR & REACTIVE DETAIL PANEL
                  LunarMonthGrid(
                    currentHijri: _worshipDay!.hijri,
                    isRamadan: _worshipDay!.seasons.any((s) => s.id == 'ws_ramadan'),
                    qamariNightText: _getQamariNightText(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_isLoading) ...[
                  const RitmoSkeletonList(itemCount: 4, itemHeight: 90),
                ] else ...[
                  // 4. OBLIGATORY PRAYERS
                  ObligatoryPrayersSection(
                    onChanged: _onDataChanged,
                    prayerTime: _worshipDay?.times.toPrayerTime(),
                  ),
                  const SizedBox(height: 24),

                  // 6. MUSTAHAB
                  MustahabSection(
                    onChanged: _onDataChanged,
                  ),
                  const SizedBox(height: 24),

                  // 7. QURAN & DHIKR
                  QuranDhikrSection(
                    onChanged: _onDataChanged,
                  ),
                  const SizedBox(height: 24),

                  // 8. DEBTS ("جبران")
                  WorshipDebtsSection(
                    onChanged: _onDataChanged,
                  ),
                  const SizedBox(height: 24),

                  // 9. SEASONS
                  WorshipSeasonsSection(
                    onChanged: _onDataChanged,
                    hijriDate: _worshipDay?.hijri,
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
