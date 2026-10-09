import '../core/constants/nmb_constants.dart';
import '../models/bus_stop.dart';
import '../models/geo_point_data.dart';
import '../models/live_location.dart';

/// Result of an ETA computation. Either a usable approximation, or an
/// explicit "unavailable" — the UI never invents a number.
sealed class EtaResult {
  const EtaResult();
}

class EtaAvailable extends EtaResult {
  const EtaAvailable(this.duration, this.distanceMeters);
  final Duration duration;
  final double distanceMeters;
}

class EtaUnavailable extends EtaResult {
  const EtaUnavailable(this.reason);
  final String reason;
}

/// Conservative ETA: distance along the remaining stop sequence divided by a
/// rolling average speed with a sane floor. Deliberately simple and honest —
/// no traffic model, so wording elsewhere is always "approximately".
class EtaService {
  final List<double> _recentSpeeds = <double>[];

  void recordSpeed(double speedKmh) {
    if (speedKmh.isNaN || speedKmh < 0 || speedKmh > 120) return;
    _recentSpeeds.add(speedKmh);
    if (_recentSpeeds.length > 12) _recentSpeeds.removeAt(0);
  }

  EtaResult etaToStop({
    required LiveLocation? live,
    required BusStop targetStop,
    required List<BusStop> orderedStops,
  }) {
    if (live == null) {
      return const EtaUnavailable('Bus location not available');
    }

    // Never estimate from stale data.
    final Duration age = DateTime.now().difference(live.updatedAt);
    if (age > NmbConstants.staleThreshold) {
      return const EtaUnavailable('Location data too old for an estimate');
    }

    final double distance = _remainingDistanceMeters(
      from: live.position,
      target: targetStop,
      orderedStops: orderedStops,
    );

    if (distance > NmbConstants.etaMaxReliableDistanceKm * 1000) {
      return const EtaUnavailable('Bus too far for a reliable estimate');
    }
    // Bus already at/past the stop.
    if (distance < 60) {
      return EtaAvailable(const Duration(minutes: 1), distance);
    }

    final double avgSpeed = _recentSpeeds.isEmpty
        ? NmbConstants.etaMinSpeedKmh
        : _recentSpeeds.reduce((double a, double b) => a + b) /
            _recentSpeeds.length;
    final double effectiveKmh =
        avgSpeed < NmbConstants.etaMinSpeedKmh
            ? NmbConstants.etaMinSpeedKmh
            : avgSpeed;

    final double hours = (distance / 1000) / effectiveKmh;
    final Duration eta = Duration(seconds: (hours * 3600).round());

    if (eta > const Duration(hours: 2)) {
      return const EtaUnavailable('Estimate not reliable right now');
    }
    return EtaAvailable(eta, distance);
  }

  /// Distance: bus → next stop → … → target stop (follows the route order,
  /// not a straight line to the target).
  double _remainingDistanceMeters({
    required GeoPointData from,
    required BusStop target,
    required List<BusStop> orderedStops,
  }) {
    final int targetIndex =
        orderedStops.indexWhere((BusStop s) => s.id == target.id);
    if (targetIndex < 0) return from.distanceTo(target.location);

    // Find the upcoming stop = nearest stop at/before the target.
    int nearestIndex = 0;
    double nearest = double.infinity;
    for (int i = 0; i <= targetIndex; i++) {
      final double d = from.distanceTo(orderedStops[i].location);
      if (d < nearest) {
        nearest = d;
        nearestIndex = i;
      }
    }

    double total = from.distanceTo(orderedStops[nearestIndex].location);
    for (int i = nearestIndex; i < targetIndex; i++) {
      total += orderedStops[i]
          .location
          .distanceTo(orderedStops[i + 1].location);
    }
    return total;
  }
}
