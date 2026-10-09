import 'dart:math' as math;

/// Plain lat/lng value object (keeps models free of Firebase imports).
class GeoPointData {
  const GeoPointData({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory GeoPointData.fromMap(Map<String, dynamic> map) => GeoPointData(
        lat: (map['lat'] as num?)?.toDouble() ?? 0,
        lng: (map['lng'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{'lat': lat, 'lng': lng};

  /// Haversine distance in meters.
  double distanceTo(GeoPointData other) {
    const double r = 6371000;
    final double dLat = _rad(other.lat - lat);
    final double dLng = _rad(other.lng - lng);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(other.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      other is GeoPointData && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}
