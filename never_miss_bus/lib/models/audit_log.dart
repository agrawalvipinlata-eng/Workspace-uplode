class AuditLog {
  const AuditLog({
    required this.id,
    required this.actorUid,
    this.actorName = '',
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.at,
    this.details = const <String, dynamic>{},
  });

  final String id;
  final String actorUid;
  final String actorName;
  final String actorRole;
  final String action;
  final String targetType;
  final String targetId;
  final DateTime at;
  final Map<String, dynamic> details;

  factory AuditLog.fromMap(String id, Map<String, dynamic> map) => AuditLog(
        id: id,
        actorUid: (map['actorUid'] as String?) ?? '',
        actorName: (map['actorName'] as String?) ?? '',
        actorRole: (map['actorRole'] as String?) ?? '',
        action: (map['action'] as String?) ?? '',
        targetType: ((map['target'] as Map?)?['type'] as String?) ?? '',
        targetId: ((map['target'] as Map?)?['id'] as String?) ?? '',
        at: _toDate(map['at']) ?? DateTime.now(),
        details: Map<String, dynamic>.from(map['details'] as Map? ?? {}),
      );

  static DateTime? _toDate(Object? v) {
    if (v == null) return null;
    try {
      return (v as dynamic).toDate() as DateTime?;
    } catch (_) {
      return null;
    }
  }
}
