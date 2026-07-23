// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'package:flutter/material.dart';

enum InboxCategory {
  REMINDER,
  INSIGHT,
  MILESTONE,
  ALERT,
  SUGGESTION,
  CHECKIN,
  REVIEW,
}

enum InboxPriority {
  normal,      // 0
  important,   // 1
  critical,    // 2
}

enum InboxStatus {
  UNREAD,
  READ,
  ARCHIVED,
  EXPIRED,
  ACTIONED,
}

class InboxItem {

  InboxItem({
    required this.id,
    required this.category,
    required this.sourceSystem,
    required this.title,
    this.body,
    required this.priority,
    this.linkModule,
    this.linkEntityId,
    this.linkAction,
    this.payload = const {},
    required this.status,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
    required this.dedupeKey,
  });

  factory InboxItem.fromMap(Map<String, dynamic> map) {
    var parsedPayload = <String, dynamic>{};
    if (map['payloadJson'] != null && (map['payloadJson'] as String).isNotEmpty) {
      try {
        parsedPayload = jsonDecode(map['payloadJson'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    final cat = InboxCategory.values.firstWhere(
      (e) => e.name == map['category'],
      orElse: () => InboxCategory.REMINDER,
    );

    final pr = InboxPriority.values[map['priority'] as int? ?? 0];

    final st = InboxStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => InboxStatus.UNREAD,
    );

    return InboxItem(
      id: map['id'] as String,
      category: cat,
      sourceSystem: map['sourceSystem'] as String? ?? 'system',
      title: map['title'] as String,
      body: map['body'] as String?,
      priority: pr,
      linkModule: map['linkModule'] as String?,
      linkEntityId: map['linkEntityId'] as String?,
      linkAction: map['linkAction'] as String?,
      payload: parsedPayload,
      status: st,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      readAt: map['readAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['readAt'] as int) : null,
      expiresAt: map['expiresAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int) : null,
      dedupeKey: map['dedupeKey'] as String? ?? '',
    );
  }
  final String id;
  final InboxCategory category;
  final String sourceSystem;
  final String title;
  final String? body;
  final InboxPriority priority;
  final String? linkModule;
  final String? linkEntityId;
  final String? linkAction;
  final Map<String, dynamic> payload;
  final InboxStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final String dedupeKey;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'sourceSystem': sourceSystem,
      'title': title,
      'body': body,
      'priority': priority.index,
      'linkModule': linkModule,
      'linkEntityId': linkEntityId,
      'linkAction': linkAction,
      'payloadJson': jsonEncode(payload),
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'dedupeKey': dedupeKey,
    };
  }

  // Visual Helper Methods
  IconData get icon {
    switch (category) {
      case InboxCategory.REMINDER:
        return Icons.alarm_on;
      case InboxCategory.INSIGHT:
        return Icons.lightbulb_outline;
      case InboxCategory.MILESTONE:
        return Icons.emoji_events_outlined;
      case InboxCategory.ALERT:
        return Icons.warning_amber_rounded;
      case InboxCategory.SUGGESTION:
        return Icons.assistant_outlined;
      case InboxCategory.CHECKIN:
        return Icons.waving_hand_outlined;
      case InboxCategory.REVIEW:
        return Icons.rate_review_outlined;
    }
  }

  String get categoryLabelFa {
    switch (category) {
      case InboxCategory.REMINDER:
        return 'یادآوری';
      case InboxCategory.INSIGHT:
        return 'بینش هوشمند';
      case InboxCategory.MILESTONE:
        return 'دستاورد';
      case InboxCategory.ALERT:
        return 'هشدار سیستم';
      case InboxCategory.SUGGESTION:
        return 'پیشنهاد دستیار';
      case InboxCategory.CHECKIN:
        return 'چک‌این';
      case InboxCategory.REVIEW:
        return 'بازخورد';
    }
  }
}
