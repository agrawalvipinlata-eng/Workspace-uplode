import 'package:firebase_database/firebase_database.dart';
import '../models/live_location.dart';

/// Reads/writes the single live-location node per bus in Realtime Database.
///
/// RTDB security rules guarantee:
///  - students can subscribe ONLY to `/liveLocations/{their claim busId}`
///  - drivers can write ONLY to their own bus node
/// so no client can browse other buses regardless of what this code does.
class LiveLocationService {
  LiveLocationService(this._rtdb);

  final FirebaseDatabase _rtdb;

  DatabaseReference _busRef(String busId) =>
      _rtdb.ref('liveLocations/$busId');

  /// Live stream of the bus location; emits null when the node is absent
  /// (no active trip) — an explicit, honest "not tracking" state.
  Stream<LiveLocation?> watchBusLocation(String busId) =>
      _busRef(busId).onValue.map((DatabaseEvent event) {
        final Object? value = event.snapshot.value;
        if (value is! Map) return null;
        return LiveLocation.fromMap(Map<Object?, Object?>.from(value));
      });

  /// Driver-side write of one GPS fix. `updatedAt` uses the SERVER timestamp
  /// so freshness checks can't be spoofed by a wrong device clock.
  Future<void> publishFix({
    required String busId,
    required String tripId,
    required double lat,
    required double lng,
    required double heading,
    required double speedKmh,
    required double accuracy,
  }) =>
      _busRef(busId).set(<String, Object?>{
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'speedKmh': speedKmh,
        'accuracy': accuracy,
        'tripId': tripId,
        'updatedAt': ServerValue.timestamp,
      });

  /// Removes the node when the trip ends so students see "not tracking"
  /// instead of a frozen old position.
  Future<void> clear(String busId) => _busRef(busId).remove();
}
