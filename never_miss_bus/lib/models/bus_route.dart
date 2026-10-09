import '../core/constants/enums.dart';
import 'geo_point_data.dart';

class BusRoute {
  const BusRoute({
    required this.id,
    required this.name,
    required this.busId,
    required this.stopOrder,
    required this.schoolLocation,
    this.polyline = '',
    this.direction = TripDirection.pickup,
    this.isActive = true,
    this.recordedPath = const <GeoPointData>[],
  });

  final String id;
  final String name;
  final String busId;
  final List<String> stopOrder; // ordered stop ids
  final GeoPointData schoolLocation;
  final String polyline; // encoded polyline; may be empty (fallback: stops)
  final TripDirection direction;
  final bool isActive;

  /// GPS trace recorded from the driver's first trip — the REAL road path
  /// the bus takes (much better than straight lines between stops).
  final List<GeoPointData> recordedPath;

  factory BusRoute.fromMap(String id, Map<String, dynamic> map) => BusRoute(
        id: id,
        name: (map['name'] as String?) ?? '',
        busId: (map['busId'] as String?) ?? '',
        stopOrder: List<String>.from(map['stopOrder'] as List? ?? <String>[]),
        schoolLocation: GeoPointData.fromMap(
          Map<String, dynamic>.from(map['schoolLocation'] as Map? ?? {}),
        ),
        polyline: (map['polyline'] as String?) ?? '',
        direction:
            TripDirection.parse((map['direction'] as String?) ?? 'pickup'),
        isActive: (map['isActive'] as bool?) ?? true,
        recordedPath: ((map['recordedPath'] as List?) ?? <Object?>[])
            .map((Object? e) => GeoPointData.fromMap(
                Map<String, dynamic>.from(e as Map? ?? <String, num>{}),),)
            .toList(),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'busId': busId,
        'stopOrder': stopOrder,
        'schoolLocation': schoolLocation.toMap(),
        'polyline': polyline,
        'direction': direction.name,
        'isActive': isActive,
        if (recordedPath.isNotEmpty)
          'recordedPath':
              recordedPath.map((GeoPointData p) => p.toMap()).toList(),
      };
}
