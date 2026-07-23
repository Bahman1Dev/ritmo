
enum EnergyLevel {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case EnergyLevel.low:
        return 'کم';
      case EnergyLevel.medium:
        return 'متوسط';
      case EnergyLevel.high:
        return 'زیاد';
    }
  }

  int get score {
    switch (this) {
      case EnergyLevel.low:
        return 30;
      case EnergyLevel.medium:
        return 65;
      case EnergyLevel.high:
        return 100;
    }
  }

  static EnergyLevel fromString(String str) {
    return EnergyLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == str.toLowerCase(),
      orElse: () => EnergyLevel.medium,
    );
  }
}

enum Mood {
  calm,
  happy,
  anxious,
  sad,
  angry,
  tired,
  excited,
  neutral;

  String get label {
    switch (this) {
      case Mood.calm:
        return 'آرام';
      case Mood.happy:
        return 'شاد';
      case Mood.anxious:
        return 'مضطرب';
      case Mood.sad:
        return 'غمگین';
      case Mood.angry:
        return 'عصبانی';
      case Mood.tired:
        return 'خسته';
      case Mood.excited:
        return 'هیجان‌زده';
      case Mood.neutral:
        return 'معمولی';
    }
  }

  String get emoji {
    switch (this) {
      case Mood.calm:
        return '😌';
      case Mood.happy:
        return '😊';
      case Mood.anxious:
        return '😰';
      case Mood.sad:
        return '😔';
      case Mood.angry:
        return '😠';
      case Mood.tired:
        return '🥱';
      case Mood.excited:
        return '🤩';
      case Mood.neutral:
        return '😐';
    }
  }

  int get defaultValence {
    switch (this) {
      case Mood.calm:
        return 4;
      case Mood.happy:
        return 5;
      case Mood.anxious:
        return 2;
      case Mood.sad:
        return 1;
      case Mood.angry:
        return 1;
      case Mood.tired:
        return 2;
      case Mood.excited:
        return 5;
      case Mood.neutral:
        return 3;
    }
  }

  static Mood fromString(String str) {
    return Mood.values.firstWhere(
      (m) => m.name.toLowerCase() == str.toLowerCase(),
      orElse: () => Mood.neutral,
    );
  }
}

class MoodLog {

  MoodLog({
    required this.id,
    required this.mood,
    required this.valence,
    this.note,
    required this.loggedAt,
  });

  factory MoodLog.fromMap(Map<String, dynamic> map) {
    return MoodLog(
      id: map['id'] as String,
      mood: Mood.fromString(map['mood'] as String? ?? 'NEUTRAL'),
      valence: map['valence'] as int? ?? 3,
      note: map['note'] as String?,
      loggedAt: map['loggedAt'] as int,
    );
  }
  final String id;
  final Mood mood;
  final int valence;
  final String? note;
  final int loggedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood': mood.name.toUpperCase(),
      'valence': valence,
      'note': note,
      'loggedAt': loggedAt,
    };
  }
}

class EnergyLog {

  EnergyLog({
    required this.id,
    required this.energyLevel,
    required this.source,
    this.note,
    required this.loggedAt,
  });

  factory EnergyLog.fromMap(Map<String, dynamic> map) {
    return EnergyLog(
      id: map['id'] as String,
      energyLevel: EnergyLevel.fromString(map['energyLevel'] as String? ?? 'MEDIUM'),
      source: map['source'] as String? ?? 'MANUAL',
      note: map['note'] as String?,
      loggedAt: map['loggedAt'] as int,
    );
  }
  final String id;
  final EnergyLevel energyLevel;
  final String source;
  final String? note;
  final int loggedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'energyLevel': energyLevel.name.toUpperCase(),
      'source': source,
      'note': note,
      'loggedAt': loggedAt,
    };
  }
}

class QuickLogResult {

  QuickLogResult({
    this.energyLevel,
    this.mood,
    this.valence,
    this.note,
  });
  final EnergyLevel? energyLevel;
  final Mood? mood;
  final int? valence;
  final String? note;
}
