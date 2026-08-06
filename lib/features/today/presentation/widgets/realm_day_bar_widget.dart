import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/realm/active_realm_resolver.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RealmDayBarWidget extends StatelessWidget {
  const RealmDayBarWidget({
    super.key,
    required this.selectedWeekday,
    required this.realms,
    required this.schedules,
    required this.activeRealmState,
    required this.onWeekdayChanged,
    this.onRealmTap,
  });

  final int selectedWeekday; // 1: Mon ... 7: Sun
  final List<RealmData> realms;
  final List<RealmScheduleData> schedules;
  final ActiveRealmState activeRealmState;
  final ValueChanged<int> onWeekdayChanged;
  final ValueChanged<String>? onRealmTap;

  static const List<({String label, int weekday})> weekdaysFa = [
    (label: 'ش', weekday: 6), // Saturday
    (label: 'ی', weekday: 7), // Sunday
    (label: 'د', weekday: 1), // Monday
    (label: 'س', weekday: 2), // Tuesday
    (label: 'چ', weekday: 3), // Wednesday
    (label: 'پ', weekday: 4), // Thursday
    (label: 'ج', weekday: 5), // Friday
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day selector tabs (ش تا ج)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdaysFa.map((item) {
            final isSelected = item.weekday == selectedWeekday;
            final isToday = item.weekday == now.weekday;

            return InkWell(
              onTap: () => onWeekdayChanged(item.weekday),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary
                      : (isToday
                          ? colors.primary.withValues(alpha: 0.12)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected
                      ? Border.all(color: colors.primary.withValues(alpha: 0.5), width: 1)
                      : null,
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (item.weekday == 5
                            ? const Color(0xFFE53935)
                            : colors.textPrimary),
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // 24-Hour Visual Segment Bar
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.textPrimary.withValues(alpha: 0.08)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                const totalMinutesInDay = 1440;

                // Find schedules for selected weekday
                final daySchedules = schedules
                    .where((s) => s.daysOfWeek.contains(selectedWeekday))
                    .toList();

                final segments = <_BarSegment>[];

                for (final sched in daySchedules) {
                  final realm = realms.firstWhere(
                    (r) => r.id == sched.zoneId,
                    orElse: () => RealmData(
                      id: sched.zoneId,
                      name: 'قلمرو',
                      colorHex: '#6366F1',
                      icon: '🎯',
                      mode: RealmMode.normal,
                    ),
                  );

                  final startParts = sched.startTime.split(':');
                  final endParts = sched.endTime.split(':');
                  final startMin = (int.tryParse(startParts[0]) ?? 0) * 60 + (int.tryParse(startParts[1]) ?? 0);
                  final endMin = (int.tryParse(endParts[0]) ?? 0) * 60 + (int.tryParse(endParts[1]) ?? 0);

                  if (startMin <= endMin) {
                    segments.add(_BarSegment(
                      realmId: realm.id,
                      realmName: realm.name,
                      color: realm.parseColor(),
                      startMin: startMin,
                      endMin: endMin,
                    ));
                  } else {
                    // Cross-midnight schedule: split into late night and early morning
                    segments.add(_BarSegment(
                      realmId: realm.id,
                      realmName: realm.name,
                      color: realm.parseColor(),
                      startMin: startMin,
                      endMin: 1440,
                    ));
                    segments.add(_BarSegment(
                      realmId: realm.id,
                      realmName: realm.name,
                      color: realm.parseColor(),
                      startMin: 0,
                      endMin: endMin,
                    ));
                  }
                }

                // Render background bar with colored segments and live indicator
                final isSelectedDayToday = selectedWeekday == now.weekday;
                final currentMinutes = now.hour * 60 + now.minute;
                final nowX = (currentMinutes / totalMinutesInDay) * barWidth;

                return Stack(
                  children: [
                    // Realm Colored Segments
                    ...segments.map((seg) {
                      final left = (seg.startMin / totalMinutesInDay) * barWidth;
                      final width = ((seg.endMin - seg.startMin) / totalMinutesInDay) * barWidth;

                      return Positioned(
                        left: left,
                        width: width.clamp(2.0, barWidth),
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            if (onRealmTap != null) onRealmTap!(seg.realmId);
                          },
                          child: Tooltip(
                            message: '${seg.realmName} (${_fmtMinutes(seg.startMin)} الی ${_fmtMinutes(seg.endMin)})',
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: seg.color.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Live "Now" Indicator Line (if viewing today)
                    if (isSelectedDayToday)
                      Positioned(
                        left: nowX.clamp(0.0, barWidth - 3),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.redAccent,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Hour Markers (00:00, 06:00, 12:00, 18:00, 24:00)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('۰۰:۰۰', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('۰۶:۰۰', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('۱۲:۰۰', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('۱۸:۰۰', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('۲۴:۰۰', style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmtMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _BarSegment {
  const _BarSegment({
    required this.realmId,
    required this.realmName,
    required this.color,
    required this.startMin,
    required this.endMin,
  });

  final String realmId;
  final String realmName;
  final Color color;
  final int startMin;
  final int endMin;
}
