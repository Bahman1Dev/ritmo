import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/domain/agenda/agenda_action_handler.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/worship/logic/worship_engine.dart';
import 'package:ritmo/features/worship/models/worship_models.dart' hide toPersianDigits;
import 'package:ritmo/features/worship/presentation/widgets/prayer_agenda_card.dart';

class ObligatoryPrayersSection extends StatefulWidget {
  const ObligatoryPrayersSection({
    super.key,
    required this.onChanged,
    this.prayerTime,
    this.date,
  });

  final VoidCallback onChanged;
  final PrayerTime? prayerTime;
  final DateTime? date;

  @override
  State<ObligatoryPrayersSection> createState() => _ObligatoryPrayersSectionState();
}

class _ObligatoryPrayersSectionState extends State<ObligatoryPrayersSection> {
  bool _isLoading = true;
  String? _errorMessage;
  WorshipDay? _worshipDay;
  Timer? _tickerTimer;
  final Map<String, bool> _optimisticState = {};

  @override
  void initState() {
    super.initState();
    _loadWorshipData();
    _scheduleNextTick();
  }

  @override
  void didUpdateWidget(ObligatoryPrayersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date || oldWidget.prayerTime != widget.prayerTime) {
      _loadWorshipData();
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextTick() {
    _tickerTimer?.cancel();
    final now = DateTime.now();
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final delay = nextMinute.difference(now);
    _tickerTimer = Timer(delay, () {
      if (mounted) {
        setState(() {});
        _scheduleNextTick();
      }
    });
  }

  Future<void> _loadWorshipData() async {
    try {
      if (mounted && _worshipDay == null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final targetDate = widget.date ?? DateTime.now();
      final dayData = await WorshipEngine.instance.loadDay(targetDate);

      if (mounted) {
        setState(() {
          _worshipDay = dayData;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error loading worship day data: $e\n$st');
      if (mounted) {
        setState(() {
          _errorMessage = 'خطا در دریافت اطلاعات نمازها';
          _isLoading = false;
        });
      }
    }
  }

  WorshipPracticeState? _findPracticeState(String identifier) {
    if (_worshipDay == null) return null;
    try {
      final key = identifier.toUpperCase();
      return _worshipDay!.practices.firstWhere(
        (ps) => ps.practice.id.toUpperCase() == key ||
                (ps.practice.subType ?? '').toUpperCase() == key,
      );
    } catch (_) {
      return null;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return toPersianDigits('$h:$m');
  }

  Future<void> _handleToggleGroup({
    required String groupKey,
    required bool isDone,
  }) async {
    unawaited(HapticFeedback.mediumImpact());
    final targetDate = widget.date ?? DateTime.now();
    final dateStr = targetDate.toIso8601String().substring(0, 10);

    setState(() {
      _optimisticState[groupKey] = isDone;
    });

    try {
      await AgendaActionHandler.instance.togglePrayer(
        group: groupKey,
        isDone: isDone,
        dateStr: dateStr,
      );

      WorshipEngine.instance.invalidate(date: targetDate);
      await _loadWorshipData();
      if (mounted) {
        setState(() {
          _optimisticState.remove(groupKey);
        });
      }
      widget.onChanged();

      if (mounted) {
        RitmoToast.show(
          context,
          isDone ? 'نماز با موفقیت ثبت شد.' : 'ثبت نماز لغو شد.',
        );
      }
    } catch (e) {
      debugPrint('Error toggling prayer group: $e');
      if (mounted) {
        setState(() {
          _optimisticState.remove(groupKey);
        });
        final msg = e.toString().replaceAll('Exception: ', '').trim();
        RitmoToast.show(
          context,
          msg.isNotEmpty ? msg : 'خطا در ثبت وضعیت نماز.',
        );
      }
    }
  }

  Future<void> _handleSkipGroup({
    required String groupTitle,
    required List<String> practiceIds,
    required bool addToQada,
  }) async {
    unawaited(HapticFeedback.mediumImpact());
    final targetDate = widget.date ?? DateTime.now();

    try {
      for (final id in practiceIds) {
        await WorshipEngine.instance.logSkip(
          practiceId: id,
          date: targetDate,
          addToQada: addToQada,
        );
      }

      WorshipEngine.instance.invalidate(date: targetDate);
      await _loadWorshipData();
      widget.onChanged();

      if (mounted) {
        RitmoToast.show(
          context,
          addToQada ? 'نماز به عنوان قضا ثبت شد.' : 'نماز رد شد.',
        );
      }
    } catch (e) {
      debugPrint('Error skipping prayer group: $e');
      if (mounted) {
        RitmoToast.show(context, 'خطا در ثبت قضا.');
      }
    }
  }

  Future<void> _confirmSkipDialog({
    required String groupTitle,
    required List<String> practiceIds,
  }) async {
    final colors = context.colors;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'افزودن $groupTitle به قضا',
          style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'آیا می‌خواهید این نماز را رد کرده و به فهرست بدهی‌های قضا اضافه کنید؟',
          style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('انصراف', style: TextStyle(color: colors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.textOnColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('افزودن به قضا'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _handleSkipGroup(
        groupTitle: groupTitle,
        practiceIds: practiceIds,
        addToQada: true,
      );
    }
  }

  Future<void> _handleSnooze(List<String> practiceIds) async {
    final dateStr = (widget.date ?? DateTime.now()).toIso8601String().substring(0, 10);
    try {
      await AgendaActionHandler.instance.snoozePrayer(
        practiceIds: practiceIds,
        minutes: 15,
        dateStr: dateStr,
      );

      await _loadWorshipData();
      widget.onChanged();

      if (mounted) {
        RitmoToast.show(context, 'یادآور با موفقیت ۱۵ دقیقه به تعویق افتاد.');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        RitmoToast.show(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const CupertinoActivityIndicator(),
      );
    }

    if (_errorMessage != null || _worshipDay == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, color: colors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage ?? 'خطا در بارگذاری اطلاعات نماز',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _loadWorshipData,
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    final day = _worshipDay!;
    final times = day.times;
    final dayCtx = day.context;
    final isExempt = dayCtx.prayerExempt;
    final now = DateTime.now();

    // Group 1: Fajr
    final fajrState = _findPracticeState('FAJR') ?? _findPracticeState('wp_fajr');
    final fajrDeadline = times.sunrise;
    final fajrIsDone = _optimisticState.containsKey('FAJR')
        ? _optimisticState['FAJR']!
        : (fajrState?.isDone ?? false);
    final fajrExpired = fajrState != null && !fajrIsDone && !fajrState.isSkipped && now.isAfter(fajrDeadline);

    // Group 2: Dhuhr & Asr
    final dhuhrState = _findPracticeState('DHUHR') ?? _findPracticeState('wp_dhuhr');
    final asrState = _findPracticeState('ASR') ?? _findPracticeState('wp_asr');
    final dhuhrPractices = <WorshipPracticeState>[];
    if (dhuhrState != null) dhuhrPractices.add(dhuhrState);
    if (asrState != null) dhuhrPractices.add(asrState);
    final dhuhrDeadline = times.maghrib;
    final dhuhrDone = _optimisticState.containsKey('DHUHR_ASR')
        ? _optimisticState['DHUHR_ASR']!
        : (dhuhrPractices.isNotEmpty && dhuhrPractices.any((p) => p.isDone));
    final dhuhrSkipped = dhuhrPractices.isNotEmpty && dhuhrPractices.every((p) => p.isSkipped);
    final dhuhrExpired = dhuhrPractices.isNotEmpty && !dhuhrDone && !dhuhrSkipped && now.isAfter(dhuhrDeadline);

    // Group 3: Maghrib & Isha
    final maghribState = _findPracticeState('MAGHRIB') ?? _findPracticeState('wp_maghrib');
    final ishaState = _findPracticeState('ISHA') ?? _findPracticeState('wp_isha');
    final maghribPractices = <WorshipPracticeState>[];
    if (maghribState != null) maghribPractices.add(maghribState);
    if (ishaState != null) maghribPractices.add(ishaState);
    final maghribDeadline = times.midnightShari;
    final maghribDone = _optimisticState.containsKey('MAGHRIB_ISHA')
        ? _optimisticState['MAGHRIB_ISHA']!
        : (maghribPractices.isNotEmpty && maghribPractices.any((p) => p.isDone));
    final maghribSkipped = maghribPractices.isNotEmpty && maghribPractices.every((p) => p.isSkipped);
    final maghribExpired = maghribPractices.isNotEmpty && !maghribDone && !maghribSkipped && now.isAfter(maghribDeadline);

    // Ramadan Fasting
    final ramadanFastState = _findPracticeState('RAMADAN') ?? _findPracticeState('wp_fasting_ramadan');
    final ramadanFastDone = _optimisticState.containsKey('RAMADAN_FAST')
        ? _optimisticState['RAMADAN_FAST']!
        : (ramadanFastState?.isDone ?? false);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Text(
                'نمازهای واجب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              if (times.isFallbackLocation)
                Tooltip(
                  message: 'اوقات شرعی بر اساس پیش‌فرض تهران محاسبه شده است.',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(CupertinoIcons.location_slash, size: 16, color: colors.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Exemption Banner if active
          if (isExempt) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: colors.accentContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.info_circle_fill, color: colors.accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'امروز معاف از نمازهای واجب هستید.',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Fajr Row
          if (fajrState != null)
            PrayerAgendaCard(
              title: 'نماز صبح',
              timeStr: 'اذان صبح ${_formatTime(times.fajr)}',
              isDone: fajrIsDone,
              isSkipped: fajrState.isSkipped,
              isSnoozed: false,
              deferCount: 0,
              hasReminder: true,
              isExpired: fajrExpired,
              isExempt: isExempt,
              expiredTimeDetail: 'وقت نماز صبح گذشته است (طلوع: ${_formatTime(times.sunrise)}).',
              onToggle: (val) => _handleToggleGroup(
                groupKey: 'FAJR',
                isDone: val,
              ),
              onSkip: () => _confirmSkipDialog(
                groupTitle: 'نماز صبح',
                practiceIds: [fajrState.practice.id],
              ),
              onLogAsQada: () => _handleToggleGroup(
                groupKey: 'FAJR',
                isDone: true,
              ),
              onSnooze: () => _handleSnooze([fajrState.practice.id]),
            ),

          // Dhuhr & Asr Row
          if (dhuhrPractices.isNotEmpty)
            PrayerAgendaCard(
              title: asrState != null ? 'نماز ظهر و عصر (مجزا)' : 'نماز ظهر و عصر',
              timeStr: 'اذان ظهر ${_formatTime(times.dhuhr)}',
              isDone: dhuhrDone,
              isSkipped: dhuhrSkipped,
              isSnoozed: false,
              deferCount: 0,
              hasReminder: true,
              isExpired: dhuhrExpired,
              isExempt: isExempt,
              expiredTimeDetail: 'وقت نماز ظهر و عصر گذشته است (اذان مغرب: ${_formatTime(times.maghrib)}).',
              onToggle: (val) => _handleToggleGroup(
                groupKey: 'DHUHR_ASR',
                isDone: val,
              ),
              onSkip: () => _confirmSkipDialog(
                groupTitle: 'نماز ظهر و عصر',
                practiceIds: dhuhrPractices.map((p) => p.practice.id).toList(),
              ),
              onLogAsQada: () => _handleToggleGroup(
                groupKey: 'DHUHR_ASR',
                isDone: true,
              ),
              onSnooze: () => _handleSnooze(dhuhrPractices.map((p) => p.practice.id).toList()),
            ),

          // Maghrib & Isha Row
          if (maghribPractices.isNotEmpty)
            PrayerAgendaCard(
              title: ishaState != null ? 'نماز مغرب و عشا (مجزا)' : 'نماز مغرب و عشا',
              timeStr: 'اذان مغرب ${_formatTime(times.maghrib)}',
              isDone: maghribDone,
              isSkipped: maghribSkipped,
              isSnoozed: false,
              deferCount: 0,
              hasReminder: true,
              isExpired: maghribExpired,
              isExempt: isExempt,
              expiredTimeDetail: 'وقت نماز مغرب و عشا گذشته است (نیمه‌شب شرعی: ${_formatTime(times.midnightShari)}).',
              onToggle: (val) => _handleToggleGroup(
                groupKey: 'MAGHRIB_ISHA',
                isDone: val,
              ),
              onSkip: () => _confirmSkipDialog(
                groupTitle: 'نماز مغرب و عشا',
                practiceIds: maghribPractices.map((p) => p.practice.id).toList(),
              ),
              onLogAsQada: () => _handleToggleGroup(
                groupKey: 'MAGHRIB_ISHA',
                isDone: true,
              ),
              onSnooze: () => _handleSnooze(maghribPractices.map((p) => p.practice.id).toList()),
            ),

          // Ramadan Fasting Row (if active season)
          if (ramadanFastState != null)
            PrayerAgendaCard(
              title: 'روزه ماه مبارک رمضان',
              timeStr: 'از اذان صبح تا اذان مغرب',
              isDone: ramadanFastDone,
              isSkipped: ramadanFastState.isSkipped,
              isSnoozed: false,
              deferCount: 0,
              hasReminder: false,
              isExempt: dayCtx.fastingExempt,
              onToggle: (val) => _handleToggleGroup(
                groupKey: 'RAMADAN_FAST',
                isDone: val,
              ),
              onSkip: () => _confirmSkipDialog(
                groupTitle: 'روزه ماه رمضان',
                practiceIds: [ramadanFastState.practice.id],
              ),
              onLogAsQada: () => _handleToggleGroup(
                groupKey: 'RAMADAN_FAST',
                isDone: true,
              ),
            ),
        ],
      ),
    );
  }
}
