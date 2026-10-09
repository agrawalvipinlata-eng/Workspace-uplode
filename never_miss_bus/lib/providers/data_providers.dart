import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/enums.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/audit_log.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/live_location.dart';
import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'app_providers.dart';

/// During logout, active Firestore streams briefly lose permission and
/// emit permission-denied. That is EXPECTED — swallow stream errors and
/// end the stream quietly instead of crashing/error-screening the app.
Stream<T> _quiet<T>(Stream<T> source, T fallback) =>
    _resilient<T>(() => source, fallback, firstTry: true);

/// RESILIENT STREAM: error par stream marti nahi — fallback deke thodi
/// der baad RECONNECT karti hai (naya stream banakar). Pehle error ke baad
/// stream hamesha ke liye band ho jaati thi → lists freeze, naye users
/// nahi dikhte the.
Stream<T> _resilient<T>(
  Stream<T> Function() factory,
  T fallback, {
  bool firstTry = false,
}) async* {
  Stream<T>? current = firstTry ? factory() : null;
  while (true) {
    try {
      await for (final T value in current ?? factory()) {
        yield value;
      }
      return; // normal close
    } catch (_) {
      yield fallback;
      await Future<void>.delayed(const Duration(seconds: 2));
      current = null; // agla loop naya stream banayega
    }
  }
}

/// Profile of the signed-in user.
final StreamProvider<AppUser?> myProfileProvider =
    StreamProvider<AppUser?>((Ref ref) {
  final AuthSession? session = ref.watch(currentSessionProvider);
  if (session == null) return Stream<AppUser?>.value(null);
  return _quiet(
      ref.watch(firestoreServiceProvider).watchUser(session.uid), null);
});

/// The signed-in user's assigned bus (students & drivers).
/// Access is enforced by rules: the query only succeeds for the claim busId.
final StreamProvider<Bus?> myBusProvider = StreamProvider<Bus?>((Ref ref) {
  final AuthSession? session = ref.watch(currentSessionProvider);
  final String? busId = session?.busId;
  if (busId == null || busId.isEmpty) return Stream<Bus?>.value(null);
  return _quiet(ref.watch(firestoreServiceProvider).watchBus(busId), null);
});

final StreamProvider<BusRoute?> myRouteProvider =
    StreamProvider<BusRoute?>((Ref ref) {
  final String? busId = ref.watch(currentSessionProvider)?.busId;
  if (busId == null || busId.isEmpty) return Stream<BusRoute?>.value(null);
  return _quiet(
      ref.watch(firestoreServiceProvider).watchRouteOfBus(busId), null);
});

final StreamProvider<List<BusStop>> myStopsProvider =
    StreamProvider<List<BusStop>>((Ref ref) {
  final String? busId = ref.watch(currentSessionProvider)?.busId;
  if (busId == null || busId.isEmpty) {
    return Stream<List<BusStop>>.value(const <BusStop>[]);
  }
  return _quiet(ref.watch(firestoreServiceProvider).watchStopsOfBus(busId),
      const <BusStop>[]);
});

/// The student's own assigned stop.
final Provider<BusStop?> myAssignedStopProvider = Provider<BusStop?>((Ref ref) {
  final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
  final List<BusStop> stops =
      ref.watch(myStopsProvider).valueOrNull ?? const <BusStop>[];
  if (me?.stopId == null) return null;
  for (final BusStop s in stops) {
    if (s.id == me!.stopId) return s;
  }
  return null;
});

/// Active trip of my bus (null → "Bus has no active trip").
final StreamProvider<Trip?> myBusActiveTripProvider =
    StreamProvider<Trip?>((Ref ref) {
  final String? busId = ref.watch(currentSessionProvider)?.busId;
  if (busId == null || busId.isEmpty) return Stream<Trip?>.value(null);
  return _quiet(
      ref.watch(firestoreServiceProvider).watchActiveTripOfBus(busId), null);
});

/// Live location of my bus. Rules restrict this to the assigned bus.
final StreamProvider<LiveLocation?> myBusLiveLocationProvider =
    StreamProvider<LiveLocation?>((Ref ref) {
  final String? busId = ref.watch(currentSessionProvider)?.busId;
  if (busId == null || busId.isEmpty) {
    return Stream<LiveLocation?>.value(null);
  }
  return _quiet(
      ref.watch(liveLocationServiceProvider).watchBusLocation(busId), null);
});

/// Freshness ticker: re-evaluates freshness every 10s even without new data,
/// so a silent GPS flips LIVE → stale → unavailable honestly.
final StreamProvider<DateTime> freshnessTickProvider = StreamProvider<DateTime>(
  (Ref ref) => Stream<DateTime>.periodic(
    const Duration(seconds: 10),
    (_) => DateTime.now(),
  ),
);

final Provider<LocationFreshness> myBusFreshnessProvider =
    Provider<LocationFreshness>((Ref ref) {
  ref.watch(freshnessTickProvider); // tick
  final LiveLocation? live = ref.watch(myBusLiveLocationProvider).valueOrNull;
  final Trip? trip = ref.watch(myBusActiveTripProvider).valueOrNull;
  if (live == null || trip == null) return LocationFreshness.unavailable;
  return live.freshness();
});

/// Notification inbox.
final StreamProvider<List<AppNotification>> inboxProvider =
    StreamProvider<List<AppNotification>>((Ref ref) {
  final AuthSession? session = ref.watch(currentSessionProvider);
  if (session == null) {
    return Stream<List<AppNotification>>.value(const <AppNotification>[]);
  }
  return _quiet(ref.watch(firestoreServiceProvider).watchInbox(session.uid),
      const <AppNotification>[]);
});

final Provider<int> unreadCountProvider = Provider<int>((Ref ref) {
  final List<AppNotification> inbox =
      ref.watch(inboxProvider).valueOrNull ?? const <AppNotification>[];
  return inbox.where((AppNotification n) => !n.read).length;
});

/// School contact/config.
final StreamProvider<Map<String, dynamic>?> schoolConfigProvider =
    StreamProvider<Map<String, dynamic>?>(
  (Ref ref) => _quiet(
    ref.watch(firestoreServiceProvider).watchSchoolConfig(),
    null,
  ),
);

/// ── Role-scoped user streams ─────────────────────────────────────────
final StreamProvider<List<AppUser>> allStudentsProvider =
    StreamProvider<List<AppUser>>(
  (Ref ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    final FirestoreService service = ref.watch(firestoreServiceProvider);
    final String? teacherClass =
        me?.role == UserRole.teacher ? me?.classSection : null;
    final Stream<List<AppUser>> source = me?.role == UserRole.teacher
        ? (teacherClass == null
            ? Stream<List<AppUser>>.value(const <AppUser>[])
            : service.watchStudentsOfClass(teacherClass))
        : service.watchUsersByRole('student');
    return _quiet(source, const <AppUser>[]);
  },
);

final StreamProvider<List<AppUser>> allTeachersProvider =
    StreamProvider<List<AppUser>>(
  (Ref ref) => _quiet(
    ref.watch(firestoreServiceProvider).watchUsersByRole('teacher'),
    const <AppUser>[],
  ),
);

final StreamProvider<List<AppUser>> allDriversProvider =
    StreamProvider<List<AppUser>>(
  (Ref ref) => _quiet(
    ref.watch(firestoreServiceProvider).watchUsersByRole('driver'),
    const <AppUser>[],
  ),
);

final StreamProvider<List<Bus>> allBusesProvider = StreamProvider<List<Bus>>(
  (Ref ref) => _quiet(
      ref.watch(firestoreServiceProvider).watchAllBuses(), const <Bus>[]),
);

final StreamProvider<List<Trip>> activeTripsProvider =
    StreamProvider<List<Trip>>(
  (Ref ref) => _quiet(
    ref.watch(firestoreServiceProvider).watchActiveTrips(),
    const <Trip>[],
  ),
);

final StreamProvider<List<AuditLog>> auditLogsProvider =
    StreamProvider<List<AuditLog>>(
  (Ref ref) => _quiet(
    ref.watch(firestoreServiceProvider).watchAuditLogs(),
    const <AuditLog>[],
  ),
);

/// Stops of an arbitrary bus (admin screens).
final StreamProviderFamily<List<BusStop>, String> stopsOfBusProvider =
    StreamProvider.family<List<BusStop>, String>(
  (Ref ref, String busId) => _quiet(
    ref.watch(firestoreServiceProvider).watchStopsOfBus(busId),
    const <BusStop>[],
  ),
);

/// Live location of an arbitrary bus (admin monitoring only; rules permit
/// admin reads on all buses).
final StreamProviderFamily<LiveLocation?, String> busLiveLocationProvider =
    StreamProvider.family<LiveLocation?, String>(
  (Ref ref, String busId) => _quiet(
    ref.watch(liveLocationServiceProvider).watchBusLocation(busId),
    null,
  ),
);

/// Admin: recent trip history (rules: admin-only read of all trips).
final StreamProvider<List<Trip>> recentTripsProvider =
    StreamProvider<List<Trip>>(
  (Ref ref) => _quiet(
    ref.watch(firestoreServiceProvider).watchRecentTrips(),
    const <Trip>[],
  ),
);
