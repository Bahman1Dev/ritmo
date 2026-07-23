// lib/features/assistant/models/day_plan_models.dart
import 'dart:convert';

class DayPlanDraft {

  DayPlanDraft({
    required this.planDate,
    required this.items,
    required this.questions,
    required this.suggestions,
  });

  factory DayPlanDraft.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final rawQuestions = json['questions'] as List? ?? [];
    final rawSuggestions = json['suggestions'] as List? ?? [];

    return DayPlanDraft(
      planDate: json['planDate']?.toString() ?? '',
      items: rawItems.map((e) => DayPlanItemDraft.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      questions: rawQuestions.map((e) => DayPlanQuestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      suggestions: rawSuggestions.map((e) => DayPlanSuggestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
  final String planDate;
  final List<DayPlanItemDraft> items;
  final List<DayPlanQuestion> questions;
  final List<DayPlanSuggestion> suggestions;

  Map<String, dynamic> toJson() {
    return {
      'planDate': planDate,
      'items': items.map((e) => e.toJson()).toList(),
      'questions': questions.map((e) => e.toJson()).toList(),
      'suggestions': suggestions.map((e) => e.toJson()).toList(),
    };
  }

  DayPlanDraft copyWith({
    String? planDate,
    List<DayPlanItemDraft>? items,
    List<DayPlanQuestion>? questions,
    List<DayPlanSuggestion>? suggestions,
  }) {
    return DayPlanDraft(
      planDate: planDate ?? this.planDate,
      items: items ?? this.items,
      questions: questions ?? this.questions,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class DayPlanItemDraft {

  DayPlanItemDraft({
    required this.title,
    required this.targetModule,
    required this.startKind,
    this.startTime,
    this.anchorEvent,
    this.offsetMin = 0,
    this.bufferMin = 0,
    this.durationMin,
    required this.durationSource,
    required this.recurrence,
    this.daysOfWeek,
    required this.category,
    this.confidence = 1.0,
    this.note,
    this.resolvedTime,
  });

  factory DayPlanItemDraft.fromJson(Map<String, dynamic> json) {
    final startMap = json['start'] as Map? ?? {};
    final kind = startMap['kind']?.toString() ?? 'clock';
    
    return DayPlanItemDraft(
      title: json['title']?.toString() ?? '',
      targetModule: json['targetModule']?.toString() ?? 'routine',
      startKind: kind,
      startTime: startMap['time']?.toString(),
      anchorEvent: startMap['anchorEvent']?.toString(),
      offsetMin: int.tryParse(startMap['offsetMin']?.toString() ?? '') ?? 0,
      bufferMin: int.tryParse(startMap['bufferMin']?.toString() ?? '') ?? 0,
      durationMin: json['durationMin'] != null ? int.tryParse(json['durationMin'].toString()) : null,
      durationSource: json['durationSource']?.toString() ?? 'none',
      recurrence: json['recurrence']?.toString() ?? 'oneOff',
      daysOfWeek: json['daysOfWeek'] != null ? List<int>.from(json['daysOfWeek'] as List) : null,
      category: json['category']?.toString() ?? 'personal',
      confidence: double.tryParse(json['confidence']?.toString() ?? '') ?? 1.0,
      note: json['note']?.toString(),
    );
  }
  String title;
  String targetModule; // sleep | worship | routine | task | event | reminder
  String startKind; // clock | anchor | after_previous
  String? startTime; // "HH:mm" (for clock startKind)
  String? anchorEvent; // "FAJR" | "SUNRISE" | "DHUHR" | "ASR" | "MAGHRIB" | "ISHA"
  int offsetMin; // offset from anchor
  int bufferMin; // buffer after previous
  int? durationMin;
  String durationSource; // user | history | memory | default | llm | none
  String recurrence; // oneOff | daily | daysOfWeek
  List<int>? daysOfWeek;
  String category;
  double confidence;
  String? note;
  
  // Resolved absolute time after resolving validator, formatted as "HH:mm"
  String? resolvedTime;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'targetModule': targetModule,
      'start': {
        'kind': startKind,
        if (startTime != null) 'time': startTime,
        if (anchorEvent != null) 'anchorEvent': anchorEvent,
        'offsetMin': offsetMin,
        'bufferMin': bufferMin,
      },
      'durationMin': durationMin,
      'durationSource': durationSource,
      'recurrence': recurrence,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
      'category': category,
      'confidence': confidence,
      if (note != null) 'note': note,
    };
  }

  DayPlanItemDraft copyWith({
    String? title,
    String? targetModule,
    String? startKind,
    String? startTime,
    String? anchorEvent,
    int? offsetMin,
    int? bufferMin,
    int? durationMin,
    String? durationSource,
    String? recurrence,
    List<int>? daysOfWeek,
    String? category,
    double? confidence,
    String? note,
    String? resolvedTime,
  }) {
    return DayPlanItemDraft(
      title: title ?? this.title,
      targetModule: targetModule ?? this.targetModule,
      startKind: startKind ?? this.startKind,
      startTime: startTime ?? this.startTime,
      anchorEvent: anchorEvent ?? this.anchorEvent,
      offsetMin: offsetMin ?? this.offsetMin,
      bufferMin: bufferMin ?? this.bufferMin,
      durationMin: durationMin ?? this.durationMin,
      durationSource: durationSource ?? this.durationSource,
      recurrence: recurrence ?? this.recurrence,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      note: note ?? this.note,
      resolvedTime: resolvedTime ?? this.resolvedTime,
    );
  }
}

class DayPlanQuestion {

  DayPlanQuestion({
    required this.id,
    this.itemRef,
    required this.text,
    required this.quickReplies,
  });

  factory DayPlanQuestion.fromJson(Map<String, dynamic> json) {
    return DayPlanQuestion(
      id: json['id']?.toString() ?? '',
      itemRef: json['itemRef'] != null ? int.tryParse(json['itemRef'].toString()) : null,
      text: json['text']?.toString() ?? '',
      quickReplies: List<String>.from(json['quickReplies'] as List? ?? []),
    );
  }
  final String id;
  final int? itemRef; // index reference to items array
  final String text;
  final List<String> quickReplies;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (itemRef != null) 'itemRef': itemRef,
      'text': text,
      'quickReplies': quickReplies,
    };
  }
}

class DayPlanSuggestion {

  DayPlanSuggestion({
    required this.text,
    required this.action,
    this.payload,
  });

  factory DayPlanSuggestion.fromJson(Map<String, dynamic> json) {
    return DayPlanSuggestion(
      text: json['text']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      payload: json['payload'] != null ? Map<String, dynamic>.from(json['payload'] as Map) : null,
    );
  }
  final String text;
  final String action;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'action': action,
      if (payload != null) 'payload': payload,
    };
  }
}

class DayPlanTemplate {

  DayPlanTemplate({
    required this.id,
    required this.name,
    this.icon,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    required this.lastUsedAt,
    required this.useCount,
  });

  factory DayPlanTemplate.fromMap(Map<String, dynamic> map) {
    final List<dynamic> itemsList = jsonDecode(map['itemsJson'] as String? ?? '[]');
    return DayPlanTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      items: itemsList.map((e) => DayPlanItemDraft.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
      lastUsedAt: map['lastUsedAt'] as int,
      useCount: map['useCount'] as int,
    );
  }
  final String id;
  final String name;
  final String? icon;
  final List<DayPlanItemDraft> items;
  final int createdAt;
  final int updatedAt;
  final int lastUsedAt;
  final int useCount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'itemsJson': jsonEncode(items.map((e) => e.toJson()).toList()),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastUsedAt': lastUsedAt,
      'useCount': useCount,
    };
  }
}
