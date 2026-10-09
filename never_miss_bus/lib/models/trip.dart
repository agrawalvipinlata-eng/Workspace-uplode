import '../core/constants/enums.dart';

class Trip {
  const Trip({
    required this.id,
    required this.busId,
    required this.driverId,
    required this.routeId,
    required this.direction,
    required this.status,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String busId;
  final String driverId;
  final String routeId;
  final TripDirection direction;
  final TripStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  bool get isActive => status == TripStatus.active;

  factory Trip.fromMap(String id, Map<String, dynamic> map) => Trip(
        id: id,
        busId: (map['busId'] as String?) ?? '',
        driverId: (map['driverId'] as String?) ?? '',
        routeId: (map['routeId'] as String?) ?? '',
        direction:
            TripDirection.parse((map['direction'] as String?) ?? 'pickup'),
        status: TripStatus.parse((map['status'] as String?) ?? 'completed'),
        startedAt: _toDate(map['startedAt']),
        endedAt: _toDate(map['endedAt']),
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
