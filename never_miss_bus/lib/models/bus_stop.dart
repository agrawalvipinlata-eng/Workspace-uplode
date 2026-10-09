import 'geo_point_data.dart';

class BusStop {
  const BusStop({
    required this.id,
    required this.name,
    required this.routeId,
    required this.busId,
    required this.location,
    required this.order,
    this.scheduledTime,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String routeId;
  final String busId;
  final GeoPointData location;
  final int order;
  final String? scheduledTime; // "07:15"
  final bool isActive;

  factory BusStop.fromMap(String id, Map<String, dynamic> map) => BusStop(
        id: id,
        name: (map['name'] as String?) ?? '',
        routeId: (map['routeId'] as String?) ?? '',
        busId: (map['busId'] as String?) ?? '',
        location: GeoPointData.fromMap(
          Map<String, dynamic>.from(map['location'] as Map? ?? {}),
        ),
        order: (map['order'] as num?)?.toInt() ?? 0,
        scheduledTime: map['scheduledTime'] as String?,
        isActive: (map['isActive'] as bool?) ?? true,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'routeId': routeId,
        'busId': busId,
        'location': location.toMap(),
        'order': order,
        if (scheduledTime != null) 'scheduledTime': scheduledTime,
        'isActive': isActive,
      };
}
