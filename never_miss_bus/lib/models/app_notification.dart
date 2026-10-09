import '../core/constants/enums.dart';

/// An item in the user's private inbox (`users/{uid}/inbox/{id}`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.read = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool read;

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) =>
      AppNotification(
        id: id,
        type: NotificationType.parse((map['type'] as String?) ?? ''),
        title: (map['title'] as String?) ?? '',
        body: (map['body'] as String?) ?? '',
        receivedAt: _toDate(map['receivedAt']) ?? DateTime.now(),
        read: (map['read'] as bool?) ?? false,
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
