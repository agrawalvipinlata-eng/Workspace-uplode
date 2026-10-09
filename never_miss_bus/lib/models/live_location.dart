import '../core/constants/enums.dart';
import '../core/constants/nmb_constants.dart';
import 'geo_point_data.dart';

/// A single live GPS fix from `/liveLocations/{busId}` in Realtime Database.
class LiveLocation {
  const LiveLocation({
    required this.position,
    required this.heading,
    required this.speedKmh,
    required this.accuracy,
    required this.tripId,
    required this.updatedAt,
  });

  final GeoPointData position;
  final double heading;
  final double speedKmh;
  final double accuracy;
  final String tripId;
  final DateTime updatedAt;

  factory LiveLocation.fromMap(Map<Object?, Object?> map) => LiveLocation(
        position: GeoPointData(
          lat: (map['lat'] as num?)?.toDouble() ?? 0,
          lng: (map['lng'] as num?)?.toDouble() ?? 0,
        ),
        heading: (map['heading'] as num?)?.toDouble() ?? 0,
        speedKmh: (map['speedKmh'] as num?)?.toDouble() ?? 0,
        accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
        tripId: (map['tripId'] as String?) ?? '',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (map['updatedAt'] as num?)?.toInt() ?? 0,
        ),
      );

  /// Honest freshness classification — the UI must never show a stale fix
  /// as "live".
  LocationFreshness freshness({DateTime? now}) {
    final Duration age = (now ?? DateTime.now()).difference(updatedAt);
    if (age <= NmbConstants.liveThreshold) return LocationFreshness.live;
    if (age <= NmbConstants.staleThreshold) return LocationFreshness.stale;
    return LocationFreshness.unavailable;
  }
}
