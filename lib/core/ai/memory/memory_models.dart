enum MemoryType {
  identity,
  preference,
  constraint,
  goal,
  episode,
  insight,
}

enum MemorySource {
  explicit,
  implicit,
  reflection,
}

enum MemoryStatus {
  active,
  archived,
}

class MemoryEntry {

  MemoryEntry({
    required this.id,
    required this.content,
    required this.type,
    required this.domain,
    required this.source,
    required this.importance,
    required this.pinned,
    required this.sensitive,
    required this.status,
    this.sessionId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAccessedAt,
    required this.accessCount,
    this.expiresAt,
  });

  factory MemoryEntry.fromMap(Map<String, dynamic> map) {
    return MemoryEntry(
      id: map['id'] as String,
      content: map['content'] as String,
      type: MemoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MemoryType.preference,
      ),
      domain: map['domain'] as String? ?? 'core',
      source: MemorySource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => MemorySource.implicit,
      ),
      importance: map['importance'] as int? ?? 5,
      pinned: (map['pinned'] as int? ?? 0) == 1,
      sensitive: (map['sensitive'] as int? ?? 0) == 1,
      status: MemoryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MemoryStatus.active,
      ),
      sessionId: map['sessionId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      lastAccessedAt: DateTime.fromMillisecondsSinceEpoch(map['lastAccessedAt'] as int),
      accessCount: map['accessCount'] as int? ?? 0,
      expiresAt: map['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
          : null,
    );
  }
  final String id;
  final String content;
  final MemoryType type;
  final String domain;
  final MemorySource source;
  final int importance; // 1 to 10
  final bool pinned;
  final bool sensitive;
  final MemoryStatus status;
  final String? sessionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastAccessedAt;
  final int accessCount;
  final DateTime? expiresAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'domain': domain,
      'source': source.name,
      'importance': importance,
      'pinned': pinned ? 1 : 0,
      'sensitive': sensitive ? 1 : 0,
      'status': status.name,
      'sessionId': sessionId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastAccessedAt': lastAccessedAt.millisecondsSinceEpoch,
      'accessCount': accessCount,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
    };
  }
}

class MemoryOp {

  MemoryOp({
    required this.op,
    this.id,
    required this.content,
    required this.type,
    required this.domain,
    required this.importance,
    required this.sensitive,
    this.expiresAt,
  });

  factory MemoryOp.fromJson(Map<String, dynamic> json) {
    DateTime? exp;
    if (json['expiresAt'] != null) {
      if (json['expiresAt'] is int) {
        exp = DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int);
      } else if (json['expiresAt'] is String) {
        exp = DateTime.tryParse(json['expiresAt'] as String);
      }
    }
    return MemoryOp(
      op: json['op'] as String? ?? 'ADD',
      id: json['id'] as String?,
      content: json['content'] as String? ?? '',
      type: MemoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MemoryType.preference,
      ),
      domain: json['domain'] as String? ?? 'core',
      importance: json['importance'] as int? ?? 5,
      sensitive: json['sensitive'] == true || json['sensitive'] == 1,
      expiresAt: exp,
    );
  }
  final String op; // ADD | UPDATE | DELETE | NOOP
  final String? id;
  final String content;
  final MemoryType type;
  final String domain;
  final int importance;
  final bool sensitive;
  final DateTime? expiresAt;
}
