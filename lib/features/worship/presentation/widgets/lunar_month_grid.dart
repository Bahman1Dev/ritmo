// lib/features/worship/presentation/widgets/lunar_month_grid.dart
// Premium Solar Worship Calendar Container with Reactive Occasions & Qamari Night Support.

import 'package:flutter/material.dart';
import 'package:ritmo/features/worship/logic/worship_calendar_logic.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:ritmo/features/worship/presentation/widgets/worship_solar_calendar.dart';

export 'package:ritmo/features/worship/presentation/widgets/worship_solar_calendar.dart';

class LunarMonthGrid extends StatelessWidget {
  const LunarMonthGrid({
    super.key,
    required this.currentHijri,
    this.isRamadan = false,
    this.qamariNightText,
    this.onDaySelected,
    this.onOpenTasbih,
  });

  final HijriDate currentHijri;
  final bool isRamadan;
  final String? qamariNightText;
  final ValueChanged<WorshipCalendarDay>? onDaySelected;
  final VoidCallback? onOpenTasbih;

  @override
  Widget build(BuildContext context) {
    return WorshipSolarCalendar(
      qamariNightText: qamariNightText,
      onDaySelected: onDaySelected,
      onOpenTasbih: onOpenTasbih,
    );
  }
}
