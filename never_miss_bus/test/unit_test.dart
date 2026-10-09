import 'package:flutter_test/flutter_test.dart';
import 'package:never_miss_bus/core/constants/enums.dart';
import 'package:never_miss_bus/core/utils/formatters.dart';
import 'package:never_miss_bus/core/utils/validators.dart';
import 'package:never_miss_bus/models/bus_stop.dart';
import 'package:never_miss_bus/models/geo_point_data.dart';
import 'package:never_miss_bus/models/live_location.dart';
import 'package:never_miss_bus/services/eta_service.dart';

void main() {
  group('Validators', () {
    test('accepts valid email', () {
      expect(Validators.email('student@srbs.edu.in'), isNull);
    });
    test('rejects invalid email', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });
    test('password length enforced', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('longenough1'), isNull);
    });
    test('strong password requires upper + digit + length', () {
      expect(Validators.strongPassword('weakpassword'), isNotNull);
      expect(Validators.strongPassword('Weakpassword'), isNotNull);
      expect(Validators.strongPassword('Str0ngPassword'), isNull);
    });
    test('lat/lng bounds', () {
      expect(Validators.latitude('91'), isNotNull);
      expect(Validators.latitude('30.32'), isNull);
      expect(Validators.longitude('-181'), isNotNull);
      expect(Validators.longitude('78.03'), isNull);
    });
  });

  group('GeoPointData', () {
    test('haversine distance is sane (Dehradun ~1km check)', () {
      const GeoPointData a = GeoPointData(lat: 30.3165, lng: 78.0322);
      const GeoPointData b = GeoPointData(lat: 30.3255, lng: 78.0322);
      final double d = a.distanceTo(b);
      expect(d, greaterThan(900));
      expect(d, lessThan(1100));
    });
  });

  group('LiveLocation freshness (honest status)', () {
    LiveLocation fixAgedSeconds(int seconds) => LiveLocation(
          position: const GeoPointData(lat: 30, lng: 78),
          heading: 0,
          speedKmh: 20,
          accuracy: 5,
          tripId: 't1',
          updatedAt: DateTime.now().subtract(Duration(seconds: seconds)),
        );

    test('fresh fix is LIVE', () {
      expect(fixAgedSeconds(5).freshness(), LocationFreshness.live);
    });
    test('45s old fix is STALE, never live', () {
      expect(fixAgedSeconds(45).freshness(), LocationFreshness.stale);
    });
    test('4min old fix is UNAVAILABLE', () {
      expect(fixAgedSeconds(240).freshness(), LocationFreshness.unavailable);
    });
  });

  group('EtaService (never over-promises)', () {
    final List<BusStop> stops = <BusStop>[
      const BusStop(
        id: 's1',
        name: 'Stop 1',
        routeId: 'r',
        busId: 'b',
        location: GeoPointData(lat: 30.30, lng: 78.03),
        order: 1,
      ),
      const BusStop(
        id: 's2',
        name: 'Stop 2',
        routeId: 'r',
        busId: 'b',
        location: GeoPointData(lat: 30.32, lng: 78.03),
        order: 2,
      ),
    ];

    test('no live data → unavailable', () {
      final EtaResult r = EtaService().etaToStop(
        live: null,
        targetStop: stops[1],
        orderedStops: stops,
      );
      expect(r, isA<EtaUnavailable>());
    });

    test('stale data → unavailable (no fake ETA)', () {
      final LiveLocation stale = LiveLocation(
        position: const GeoPointData(lat: 30.29, lng: 78.03),
        heading: 0,
        speedKmh: 25,
        accuracy: 5,
        tripId: 't',
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      final EtaResult r = EtaService().etaToStop(
        live: stale,
        targetStop: stops[1],
        orderedStops: stops,
      );
      expect(r, isA<EtaUnavailable>());
    });

    test('fresh data → approximate ETA with floored speed', () {
      final LiveLocation live = LiveLocation(
        position: const GeoPointData(lat: 30.29, lng: 78.03),
        heading: 0,
        speedKmh: 0, // stationary: min-speed floor must prevent ∞
        accuracy: 5,
        tripId: 't',
        updatedAt: DateTime.now(),
      );
      final EtaResult r = EtaService().etaToStop(
        live: live,
        targetStop: stops[1],
        orderedStops: stops,
      );
      expect(r, isA<EtaAvailable>());
      final EtaAvailable eta = r as EtaAvailable;
      expect(eta.duration.inMinutes, lessThan(60));
      expect(eta.duration.inSeconds, greaterThan(0));
    });
  });

  group('Formatters', () {
    test('ETA wording is always approximate', () {
      expect(
        Formatters.eta(const Duration(minutes: 8)),
        contains('approximately'),
      );
      expect(Formatters.etaShort(const Duration(minutes: 8)), '~8 min');
    });
    test('relative time', () {
      expect(Formatters.relativeTime(DateTime.now()), 'just now');
      expect(
        Formatters.relativeTime(
          DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        '5 minutes ago',
      );
    });
  });

  group('Role parsing (no privilege from bad data)', () {
    test('unknown role parses to null, never defaults to admin', () {
      expect(UserRole.tryParse('superadmin'), isNull);
      expect(UserRole.tryParse(''), isNull);
      expect(UserRole.tryParse(null), isNull);
      expect(UserRole.tryParse('admin'), UserRole.admin);
    });
  });
}
