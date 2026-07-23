import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:shamsi_date/shamsi_date.dart';

class PrayerTimesHero extends StatefulWidget {

  const PrayerTimesHero({
    super.key,
    required this.onCityTap,
    this.hijriDate,
  });
  final VoidCallback onCityTap;
  final HijriDate? hijriDate;

  @override
  State<PrayerTimesHero> createState() => _PrayerTimesHeroState();
}

class _PrayerTimesHeroState extends State<PrayerTimesHero>
    with TickerProviderStateMixin {
  PrayerTime? _prayerTime;
  String _cityName = 'تهران';
  HijriDate? _hijriDate;
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _showAsrIsha = false;

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  double get _pulseValue => _pulseAnimation?.value ?? 0.8;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _startTimer();
  }

  @override
  void reassemble() {
    super.reassemble();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant PrayerTimesHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hijriDate != widget.hijriDate) {
      _hijriDate = widget.hijriDate;
    }
    _loadPrayerTimes();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _pulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation ??= Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final settingsList = await db.query('app_settings');
      final settingsMap = {
        for (final row in settingsList) row['key']! as String: row['value']! as String
      };

      final cityId = settingsMap['prayer_city_id'] ?? 'TEHRAN_TEHRAN';
      final showAsrIsha = settingsMap['show_asr_isha_prayers'] == 'true';

      final cities = await db.query('iran_cities',
          where: 'id = ?', whereArgs: [cityId], limit: 1);
      final cityDisplayName =
          cities.isNotEmpty ? cities.first['city']! as String : 'تهران';

      final now = DateTime.now();
      final dateStr = now.toIso8601String().substring(0, 10);

      await PrayerTimeProvider.instance
          .cachePrayerTimes(cityId: cityId, date: now);

      final cacheResults = await db.query(
        'prayer_times_cache',
        where: 'date = ? AND cityId = ?',
        whereArgs: [dateStr, cityId],
        limit: 1,
      );

      final hDate = widget.hijriDate ?? await HijriDate.getOrFetch(now, db);

      if (mounted) {
        setState(() {
          if (cacheResults.isNotEmpty) {
            _prayerTime = PrayerTime.fromMap(cacheResults.first);
          }
          _cityName = cityDisplayName;
          _hijriDate = hDate;
          _showAsrIsha = showAsrIsha;
        });
      }
    } catch (e) {
      debugPrint('Error loading prayer times in Hero: $e');
    }
  }

  String _getPrayerFaName(String key) {
    switch (key) {
      case 'FAJR': return 'صبح';
      case 'SUNRISE': return 'طلوع';
      case 'DHUHR': return 'ظهر';
      case 'ASR': return 'عصر';
      case 'SUNSET': return 'غروب';
      case 'MAGHRIB': return 'مغرب';
      case 'ISHA': return 'عشا';
      case 'MIDNIGHT_SHARI': return 'نیمه‌شب';
      default: return '';
    }
  }

  IconData _getPrayerIcon(String key) {
    switch (key) {
      case 'FAJR': return CupertinoIcons.sunrise;
      case 'SUNRISE': return CupertinoIcons.sun_max;
      case 'DHUHR': return CupertinoIcons.sun_max_fill;
      case 'ASR': return CupertinoIcons.sun_max;
      case 'SUNSET': return CupertinoIcons.sunset;
      case 'MAGHRIB': return CupertinoIcons.sunset_fill;
      case 'ISHA': return CupertinoIcons.moon_stars;
      case 'MIDNIGHT_SHARI': return CupertinoIcons.moon;
      default: return CupertinoIcons.time;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    var res = '';
    if (hours > 0) res += '$hours ساعت';
    if (minutes > 0) {
      if (res.isNotEmpty) res += ' و ';
      res += '$minutes دقیقه';
    }
    if (res.isEmpty) res = 'کمتر از یک دقیقه';
    return toPersianDigits(res);
  }

  DateTime _parseTime(String timeStr, DateTime baseDate) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  MapEntry<String, DateTime> _nextTimeSlot(DateTime now, PrayerTime pTime) {
    final times = <String, DateTime>{
      'FAJR': _parseTime(pTime.fajr, now),
      'SUNRISE': _parseTime(pTime.sunrise, now),
      'DHUHR': _parseTime(pTime.dhuhr, now),
      'SUNSET': _parseTime(pTime.sunset, now),
      'MAGHRIB': _parseTime(pTime.maghrib, now),
      'MIDNIGHT_SHARI': _parseTime(pTime.midnightShari, now),
    };
    if (_showAsrIsha) {
      times['ASR'] = _parseTime(pTime.asr, now);
      times['ISHA'] = _parseTime(pTime.isha, now);
    }

    final adjustedTimes = <MapEntry<String, DateTime>>[];
    for (final entry in times.entries) {
      var dt = entry.value;
      if (dt.isBefore(now)) {
        dt = dt.add(const Duration(days: 1));
      }
      adjustedTimes.add(MapEntry(entry.key, dt));
    }

    adjustedTimes.sort((a, b) => a.value.compareTo(b.value));
    return adjustedTimes.first;
  }

  String _getEventTargetName(String key) {
    switch (key) {
      case 'FAJR': return 'اذان صبح';
      case 'SUNRISE': return 'طلوع آفتاب';
      case 'DHUHR': return 'اذان ظهر';
      case 'ASR': return 'اذان عصر';
      case 'SUNSET': return 'غروب آفتاب';
      case 'MAGHRIB': return 'اذان مغرب';
      case 'ISHA': return 'اذان عشا';
      case 'MIDNIGHT_SHARI': return 'نیمه‌شب شرعی';
      default: return '';
    }
  }

  String? _getCurrentActivePrayer(DateTime now, PrayerTime pTime) {
    final times = <String, DateTime>{
      'FAJR': _parseTime(pTime.fajr, now),
      'DHUHR': _parseTime(pTime.dhuhr, now),
      'MAGHRIB': _parseTime(pTime.maghrib, now),
    };
    if (_showAsrIsha) {
      times['ASR'] = _parseTime(pTime.asr, now);
      times['ISHA'] = _parseTime(pTime.isha, now);
    }
    for (final entry in times.entries) {
      final diff = now.difference(entry.value);
      if (diff.inSeconds >= 0 && diff.inMinutes < 15) return entry.key;
    }
    return null;
  }


  // ─── Sky Theme Engine ───
  _SkyTheme _getSkyTheme(DateTime now, PrayerTime pTime) {
    final fajr = _parseTime(pTime.fajr, now);
    final sunrise = _parseTime(pTime.sunrise, now);
    final dhuhr = _parseTime(pTime.dhuhr, now);
    final maghrib = _parseTime(pTime.maghrib, now);
    final isha = _parseTime(pTime.isha, now);

    // Pre-fajr: deep night
    if (now.isBefore(fajr.subtract(const Duration(minutes: 30)))) {
      return const _SkyTheme(
        gradient: [Color(0xFF0A0E1A), Color(0xFF111833)],
        textColor: Color(0xFFCCD6F6),
        accentColor: Color(0xFF8892B0),
        goldColor: Color(0xFFC4A35A),
        periodName: 'شب',
        periodIcon: CupertinoIcons.moon_stars_fill,
      );
    }

    // Fajr glow (30 min before fajr to sunrise)
    if (now.isBefore(sunrise)) {
      return const _SkyTheme(
        gradient: [Color(0xFF1B1145), Color(0xFF3D2164), Color(0xFF7B4397), Color(0xFFDC8850)],
        textColor: Color(0xFFF0E0CF),
        accentColor: Color(0xFFE8A87C),
        goldColor: Color(0xFFF5D78A),
        periodName: 'سپیده‌دم',
        periodIcon: CupertinoIcons.sunrise_fill,
      );
    }

    // Morning (sunrise to ~10 AM)
    final morning = DateTime(now.year, now.month, now.day, 10);
    if (now.isBefore(morning)) {
      return const _SkyTheme(
        gradient: [Color(0xFF4A90D9), Color(0xFF74B9FF), Color(0xFFA8D8EA)],
        textColor: Color(0xFF1A2744),
        accentColor: Color(0xFF2D6DA4),
        goldColor: Color(0xFFBF8A2E),
        periodName: 'صبح',
        periodIcon: CupertinoIcons.sun_min_fill,
        useDarkText: true,
      );
    }

    // Midday (10 AM to dhuhr + 1h)
    final afterDhuhr = dhuhr.add(const Duration(hours: 1));
    if (now.isBefore(afterDhuhr)) {
      return const _SkyTheme(
        gradient: [Color(0xFF2980B9), Color(0xFF3498DB), Color(0xFF5DADE2)],
        textColor: Color(0xFFFFFFFF),
        accentColor: Color(0xFFF5E6CA),
        goldColor: Color(0xFFF5D78A),
        periodName: 'ظهر',
        periodIcon: CupertinoIcons.sun_max_fill,
      );
    }

    // Afternoon (after dhuhr+1h to ~1.5h before maghrib)
    final preSet = maghrib.subtract(const Duration(minutes: 90));
    if (now.isBefore(preSet)) {
      return const _SkyTheme(
        gradient: [Color(0xFF2471A3), Color(0xFF5499C7), Color(0xFF85C1E9)],
        textColor: Color(0xFFF8F4EF),
        accentColor: Color(0xFFE8D5B0),
        goldColor: Color(0xFFD4A843),
        periodName: 'بعدازظهر',
        periodIcon: CupertinoIcons.cloud_sun_fill,
      );
    }

    // Golden hour / Sunset (1.5h before maghrib to maghrib)
    if (now.isBefore(maghrib)) {
      return const _SkyTheme(
        gradient: [Color(0xFF2C3E6B), Color(0xFFBE5B3A), Color(0xFFE8913A), Color(0xFFF5D78A)],
        textColor: Color(0xFFFFF5E8),
        accentColor: Color(0xFFFFD185),
        goldColor: Color(0xFFF5D78A),
        periodName: 'غروب',
        periodIcon: CupertinoIcons.sunset_fill,
      );
    }

    // Twilight (maghrib to isha)
    if (now.isBefore(isha)) {
      return const _SkyTheme(
        gradient: [Color(0xFF0D1B3E), Color(0xFF1E3163), Color(0xFF4A2866)],
        textColor: Color(0xFFD6CEE6),
        accentColor: Color(0xFFA78BCA),
        goldColor: Color(0xFFD4A843),
        periodName: 'شفق',
        periodIcon: CupertinoIcons.moon_fill,
      );
    }

    // Night (after isha)
    return const _SkyTheme(
      gradient: [Color(0xFF070B14), Color(0xFF0F172A)],
      textColor: Color(0xFFCCD6F6),
      accentColor: Color(0xFF8892B0),
      goldColor: Color(0xFFC4A35A),
      periodName: 'شب',
      periodIcon: CupertinoIcons.moon_stars_fill,
    );
  }

  String _formatTimeWithSeconds(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_prayerTime == null) {
      return const RitmoSkeletonCard(height: 200);
    }

    final pTime = _prayerTime!;
    final activePrayer = _getCurrentActivePrayer(_now, pTime);
    final nextEvent = _nextTimeSlot(_now, pTime);
    final durationToNext = nextEvent.value.difference(_now);
    final isUrgent = durationToNext.inMinutes < 15;
    final sky = _getSkyTheme(_now, pTime);

    // Dates formatting
    final jalali = Jalali.now();
    final shamsiDate = '${jalali.formatter.wN}، ${jalali.day} ${jalali.formatter.mN} ${jalali.year}';
    final shamsiFa = toPersianDigits(shamsiDate);

    final monthsEn = ['ژانویه','فوریه','مارس','آوریل','مه','ژوئن','ژوئیه','اوت','سپتامبر','اکتبر','نوامبر','دسامبر'];
    final gregorianStr = '${_now.day} ${monthsEn[_now.month - 1]} ${_now.year}';
    final gregorianFa = toPersianDigits(gregorianStr);
    final hijriStr = _hijriDate?.formatted ?? '';

    final allPrayers = <_PrayerSlot>[
      _PrayerSlot('FAJR', 'فجر', toPersianDigits(pTime.fajr)),
      _PrayerSlot('SUNRISE', 'طلوع', toPersianDigits(pTime.sunrise)),
      _PrayerSlot('DHUHR', 'ظهر', toPersianDigits(pTime.dhuhr)),
    ];

    if (_showAsrIsha) {
      allPrayers.add(_PrayerSlot('ASR', 'عصر', toPersianDigits(pTime.asr)));
    }

    allPrayers.add(_PrayerSlot('SUNSET', 'غروب', toPersianDigits(pTime.sunset)));
    allPrayers.add(_PrayerSlot('MAGHRIB', 'مغرب', toPersianDigits(pTime.maghrib)));

    if (_showAsrIsha) {
      allPrayers.add(_PrayerSlot('ISHA', 'عشا', toPersianDigits(pTime.isha)));
    }

    allPrayers.add(_PrayerSlot('MIDNIGHT_SHARI', 'نیمه‌شب', toPersianDigits(pTime.midnightShari)));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Clock and Period Header (above card) ───
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 4, left: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Right side: Period Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isDarkMode ? const Color(0xff0b0b0e) : colors.card,
                    border: Border.all(color: isDarkMode ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(sky.periodIcon, size: 14, color: const Color(0xFFD4A843)),
                      const SizedBox(width: 6),
                      Text(
                        sky.periodName,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Left side: Clock (Clean, borderless, with clock icon to prevent timer look)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 16,
                      color: colors.textSecondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimeWithSeconds(_now),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Main Sky Card ───
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: sky.gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: sky.gradient.last.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  if (!sky.useDarkText)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StarsPainter(
                          starCount: sky.gradient.first.computeLuminance() < 0.1 ? 25 : 8,
                          opacity: sky.gradient.first.computeLuminance() < 0.05 ? 0.6 : 0.2,
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      children: [
                        // ─── Dates Bar (Centered & Larger) ───
                        _buildDatesBar(
                          shamsiFa: shamsiFa,
                          hijriStr: hijriStr,
                          gregorianFa: gregorianFa,
                          sky: sky,
                        ),
                        const SizedBox(height: 16),

                        // ─── Prayer Slots (Expanded & Larger font) ───
                        _buildPrayerTimesRow(allPrayers, activePrayer, nextEvent.key, sky),
                        const SizedBox(height: 14),

                        // ─── Footer: City + Next Prayer Countdown (Larger font) ───
                        _buildCardFooter(
                          sky: sky,
                          activePrayer: activePrayer,
                          nextPrayerKey: nextEvent.key,
                          durationToNext: durationToNext,
                          isUrgent: isUrgent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Dates Bar inside Card
  // ═══════════════════════════════════════════════════════════
  Widget _buildDatesBar({
    required String shamsiFa,
    required String hijriStr,
    required String gregorianFa,
    required _SkyTheme sky,
  }) {
    final overlayColor = sky.useDarkText
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.08);
    final borderColor = sky.useDarkText
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: overlayColor,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            shamsiFa,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sky.textColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            hijriStr.isNotEmpty ? '$hijriStr  ·  $gregorianFa' : gregorianFa,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sky.accentColor.withValues(alpha: 0.9),
              fontSize: 13,
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Prayer Times Row
  // ═══════════════════════════════════════════════════════════
  Widget _buildPrayerTimesRow(
    List<_PrayerSlot> prayers,
    String? activePrayer,
    String nextPrayerKey,
    _SkyTheme sky,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: prayers.map((p) {
        final isActive = activePrayer == p.key;
        final isNext = !isActive && nextPrayerKey == p.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildTimeSlot(p, isActive: isActive, isNext: isNext, sky: sky),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlot(_PrayerSlot prayer,
      {bool isActive = false, bool isNext = false, required _SkyTheme sky}) {
    final overlayActive = sky.useDarkText
        ? Colors.black.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.12);
    final overlayNext = sky.useDarkText
        ? Colors.black.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.05);

    return AnimatedBuilder(
      animation: _pulseAnimation ?? kAlwaysCompleteAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isActive ? overlayActive : isNext ? overlayNext : Colors.transparent,
            border: isActive
                ? Border.all(color: sky.goldColor.withValues(alpha: 0.5), width: 1.2)
                : isNext
                    ? Border.all(
                        color: sky.useDarkText
                            ? Colors.black.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.10),
                        width: 0.8)
                    : null,
            boxShadow: isActive
                ? [BoxShadow(color: sky.goldColor.withValues(alpha: 0.15 * _pulseValue), blurRadius: 10)]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                _getPrayerIcon(prayer.key),
                size: 18,
                color: isActive ? sky.goldColor : sky.textColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 5),
              Text(
                prayer.label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isActive ? sky.goldColor : sky.textColor.withValues(alpha: 0.6),
                  fontFamily: 'Vazirmatn',
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                prayer.time,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isActive ? sky.textColor : sky.textColor.withValues(alpha: 0.88),
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Card Footer: City + Next Prayer Countdown
  // ═══════════════════════════════════════════════════════════
  Widget _buildCardFooter({
    required _SkyTheme sky,
    required String? activePrayer,
    required String nextPrayerKey,
    required Duration durationToNext,
    required bool isUrgent,
  }) {
    final nextPrayerName = _getEventTargetName(nextPrayerKey);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // City badge
        GestureDetector(
          onTap: widget.onCityTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: sky.useDarkText
                  ? Colors.black.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: sky.useDarkText
                    ? Colors.black.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.location_solid, size: 14, color: sky.goldColor),
                const SizedBox(width: 4),
                Text(
                  _cityName,
                  style: TextStyle(
                    color: sky.textColor.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
        ),

        // Next Prayer Countdown
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activePrayer != null ? CupertinoIcons.bell_fill : CupertinoIcons.clock,
              size: 14,
              color: activePrayer != null ? sky.goldColor : sky.textColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 5),
            Text(
              activePrayer != null
                  ? 'وقت اذان ${_getPrayerFaName(activePrayer)}'
                  : 'تا $nextPrayerName: ${_formatDuration(durationToNext)}',
              style: TextStyle(
                color: activePrayer != null
                    ? sky.goldColor
                    : isUrgent
                        ? const Color(0xFFFF8A65)
                        : sky.textColor.withValues(alpha: 0.85),
                fontSize: 13,
                fontFamily: 'Vazirmatn',
                fontWeight: (activePrayer != null || isUrgent) ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Model & Painters
// ═══════════════════════════════════════════════════════════
class _SkyTheme {

  const _SkyTheme({
    required this.gradient,
    required this.textColor,
    required this.accentColor,
    required this.goldColor,
    required this.periodName,
    required this.periodIcon,
    this.useDarkText = false,
  });
  final List<Color> gradient;
  final Color textColor;
  final Color accentColor;
  final Color goldColor;
  final String periodName;
  final IconData periodIcon;
  final bool useDarkText;
}

class _PrayerSlot {
  const _PrayerSlot(this.key, this.label, this.time);
  final String key;
  final String label;
  final String time;
}



class _StarsPainter extends CustomPainter {

  _StarsPainter({required this.starCount, required this.opacity});
  final int starCount;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);

    for (var i = 0; i < starCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.5 + rng.nextDouble() * 1.0;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) =>
      old.starCount != starCount || old.opacity != opacity;
}
