import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../core/constants/nmb_constants.dart';
import '../core/utils/result.dart';
import '../models/geo_point_data.dart';
import 'firestore_service.dart';
import 'live_location_service.dart';

/// Orchestrates a driver trip:
///   Start Trip → create trips doc → stream GPS → publish to RTDB
///   End Trip   → stop stream → complete trips doc → clear RTDB node
///
/// Uses a foreground-service-backed stream on Android (see
/// AndroidSettings.foregroundNotificationConfig) so tracking survives the
/// screen turning off — the driver should not need to touch the phone while
/// driving.
class DriverTripService {
  DriverTripService(this._firestore, this._liveLocation);

  final FirestoreService _firestore;
  final LiveLocationService _liveLocation;

  StreamSubscription<Position>? _positionSub;
  String? _activeTripId;
  String? _activeBusId;
  String? _activeRouteId;
  String? _activeDirection;

  /// ROUTE RECORDING: GPS trace of this trip. If the bus's route has no
  /// recorded path yet, the FIRST completed trip's trace becomes the
  /// official route path shown to students.
  final List<GeoPointData> _trace = <GeoPointData>[];
  GeoPointData? _lastTracePoint;

  bool get hasLocalActiveTrip => _activeTripId != null;

  /// Checks GPS service + permission. Returns a failure describing exactly
  /// what's wrong so the UI can guide the driver.
  Future<Result<void>> ensureLocationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const Err<void>(
        AppFailure('gps-off', 'GPS is turned off. Please enable Location.'),
      );
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const Err<void>(
        AppFailure(
          'location-denied',
          'Location permission is required to share the bus position. '
          'Please allow it in Settings.',
        ),
      );
    }
    return const Ok<void>(null);
  }

  Future<Result<String>> startTrip({
    required String driverId,
    required String busId,
    required String routeId,
    required String direction,
  }) async {
    final Result<void> ready = await ensureLocationReady();
    if (ready case Err<void>(:final AppFailure failure)) {
      return Err<String>(failure);
    }

    try {
      final String tripId = await _firestore.createTrip(
        busId: busId,
        driverId: driverId,
        routeId: routeId,
        direction: direction,
      );
      _activeTripId = tripId;
      _activeBusId = busId;
      _activeRouteId = routeId;
      _activeDirection = direction;
      _trace.clear();
      _lastTracePoint = null;
      await _startPublishing(busId: busId, tripId: tripId);
      return Ok<String>(tripId);
    } catch (_) {
      return const Err<String>(
        AppFailure('trip-start', 'Could not start the trip. Please retry.'),
      );
    }
  }

  Future<void> _startPublishing({
    required String busId,
    required String tripId,
  }) async {
    await _positionSub?.cancel();

    final LocationSettings settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: NmbConstants.locationDistanceFilterMeters,
      intervalDuration: NmbConstants.locationMinInterval,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Never Miss Bus — trip active',
        notificationText: 'Sharing bus location with assigned students.',
        enableWakeLock: true,
      ),
    );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position pos) {
        // ROUTE RECORDING: keep a thinned trace (min 25 m apart, max 500
        // points) — enough to draw the real road path without bloat.
        final GeoPointData pt =
            GeoPointData(lat: pos.latitude, lng: pos.longitude);
        if (_lastTracePoint == null ||
            _lastTracePoint!.distanceTo(pt) >= 25) {
          if (_trace.length < 500) {
            _trace.add(pt);
            _lastTracePoint = pt;
          }
        }
        // Fire-and-forget: a missed packet is fine, freshness logic on the
        // student side handles gaps honestly.
        _liveLocation.publishFix(
          busId: busId,
          tripId: tripId,
          lat: pos.latitude,
          lng: pos.longitude,
          heading: pos.heading,
          speedKmh: pos.speed * 3.6,
          accuracy: pos.accuracy,
        );
      },
      onError: (_) {
        // GPS dropped — keep the subscription; geolocator resumes when the
        // signal returns. Students see "last updated X ago" meanwhile.
      },
    );
  }

  Future<Result<void>> endTrip() async {
    final String? tripId = _activeTripId;
    final String? busId = _activeBusId;
    final String? routeId = _activeRouteId;
    final String? direction = _activeDirection;
    final List<GeoPointData> trace = List<GeoPointData>.from(_trace);
    await _positionSub?.cancel();
    _positionSub = null;
    _activeTripId = null;
    _activeBusId = null;
    _activeRouteId = null;
    _activeDirection = null;
    _trace.clear();
    _lastTracePoint = null;

    if (tripId == null || busId == null) return const Ok<void>(null);
    try {
      await _firestore.endTrip(tripId);
      await _liveLocation.clear(busId);
      // ROUTE RECORDING: first useful trace becomes the official route.
      if (trace.length >= 10) {
        try {
          await _firestore.saveRecordedPathIfFirst(
            busId: busId,
            routeId: routeId,
            direction: direction ?? 'pickup',
            path: trace,
          );
        } catch (_) {/* recording failure must not block trip end */}
      }
      return const Ok<void>(null);
    } catch (_) {
      return const Err<void>(
        AppFailure(
          'trip-end',
          'Trip end could not be confirmed with the server. '
          'It will be closed automatically if you stay offline.',
        ),
      );
    }
  }

  /// Re-attach publishing after app restart while a trip is still active
  /// (e.g. driver phone rebooted mid-route).
  Future<void> resumePublishing({
    required String busId,
    required String tripId,
  }) async {
    _activeTripId = tripId;
    _activeBusId = busId;
    await _startPublishing(busId: busId, tripId: tripId);
  }

  Future<void> dispose() async => _positionSub?.cancel();
}
