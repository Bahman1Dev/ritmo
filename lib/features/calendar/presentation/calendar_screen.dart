import 'package:flutter/material.dart';
import 'package:ritmo/features/calendar/presentation/journey_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    this.initialDate,
    this.initialItemId,
  });

  final DateTime? initialDate;
  final String? initialItemId;

  @override
  Widget build(BuildContext context) {
    return JourneyScreen(
      initialDate: initialDate,
      initialItemId: initialItemId,
    );
  }
}
