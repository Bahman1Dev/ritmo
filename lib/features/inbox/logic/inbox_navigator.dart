import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models/inbox_item.dart';
import 'package:ritmo/core/services/central_inbox_service.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/assistant/presentation/assistant_screen.dart';
import 'package:ritmo/features/calendar/presentation/calendar_screen.dart';
import 'package:ritmo/features/today/presentation/insights_screen.dart';
import 'package:ritmo/features/today/presentation/widgets/daily_reflection_sheet.dart';
import 'package:ritmo/features/today/presentation/widgets/morning_checkin_sheet.dart';

class InboxNavigator {
  static Future<void> open(BuildContext context, InboxItem item) async {
    // 1. Mark item as read / actioned
    await CentralInboxService.markRead(item.id);

    if (!context.mounted) return;

    // 2. Resolve destination module/action
    switch (item.linkModule) {
      case 'routines':
      case 'calendar':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalendarScreen()),
        );

      case 'assistant':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AssistantScreen()),
        );

      case 'insights':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InsightsScreen()),
        );

      case 'today':
        if (item.linkAction == 'open_morning') {
          unawaited(showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => MorningCheckinSheet(
              onSaved: () {
                unawaited(CentralInboxService.markActioned(item.id));
              },
            ),
          ));
        } else if (item.linkAction == 'open_reflection') {
          unawaited(showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => DailyReflectionSheet(
              onSaved: () {
                unawaited(CentralInboxService.markActioned(item.id));
              },
            ),
          ));
        } else {
          // Fallback: pop current screen or show toast
          RitmoToast.show(context, 'بازگشت به نبض زندگی');
        }

      default:
        // Default fallback if linkModule is not recognized
        RitmoToast.show(context, 'پیام علامت‌گذاری شد');
    }
  }
}
