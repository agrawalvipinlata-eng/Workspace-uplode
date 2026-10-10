import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/audit_log.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/geo_point_data.dart';
import '../models/trip.dart';

/// All Firestore reads/writes flow through here.
///
/// IMPORTANT: every query below succeeds only if Firestore security rules
/// allow it for the caller's role — the client cannot widen its own access.
class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  // ── Users ────────────────────────────────────────────────────────────
  Stream<AppUser?> watchUser(String uid) =>
      _db.collection('users').doc(uid).snapshots().map(
            (DocumentSnapshot<Map<String, dynamic>> s) =>
                s.exists ? AppUser.fromMap(s.id, s.data()!) : null,
          );

  Stream<List<AppUser>> watchUsersByRole(String role) => _db
      .collection('users')
      .where('role', isEqualTo: role)
      .orderBy('fullName')
      .snapshots()
      .map(_mapUsers);

  /// Teacher query: Firestore rules require the class constraint to be
  /// present in the query; client-side filtering alone is not security.
  Stream<List<AppUser>> watchStudentsOfClass(String classSection) => _db
      .collection('users')
      .where('role', isEqualTo: 'student')
      .where('classSection', isEqualTo: classSection)
      .snapshots()
      .map(_mapUsers);

  Stream<List<AppUser>> watchStudentsOfBus(String busId) => _db
      .collection('users')
      .where('role', isEqualTo: 'student')
      .where('busId', isEqualTo: busId)
      .snapshots()
      .map(_mapUsers);

  Future<void> saveFcmToken(String uid, String token) =>
      _db.collection('users').doc(uid).set(
        <String, dynamic>{
          'fcmTokens': <String, dynamic>{token: FieldValue.serverTimestamp()},
        },
        SetOptions(merge: true),
      );

  Future<void> removeFcmToken(String uid, String token) =>
      _db.collection('users').doc(uid).update(<String, dynamic>{
        'fcmTokens.$token': FieldValue.delete(),
      });

  /// Single-device login: is device ko user ka active device banao.
  /// (Rules: owner sirf apne settings/fcmTokens edit kar sakta hai.)
  Future<void> registerActiveDevice({
    required String uid,
    required String deviceId,
    required String deviceName,
  }) =>
      _db.collection('users').doc(uid).set(
        <String, dynamic>{
          'settings': <String, dynamic>{
            'activeDevice': <String, dynamic>{
              'id': deviceId,
              'name': deviceName,
              'at': DateTime.now().millisecondsSinceEpoch,
            },
          },
        },
        SetOptions(merge: true),
      );

  /// Logout par apni device-entry clear karo (sirf agar abhi bhi hum hi
  /// active device hain — kisi naye login ko overwrite mat karo).
  Future<void> clearActiveDevice({
    required String uid,
    required String deviceId,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection('users').doc(uid).get();
    final Map<String, dynamic>? active =
        ((doc.data()?['settings'] as Map?)?['activeDevice'] as Map?)
            ?.cast<String, dynamic>();
    if (active?['id'] == deviceId) {
      await _db.collection('users').doc(uid).set(
        <String, dynamic>{
          'settings': <String, dynamic>{'activeDevice': null},
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<void> saveUserSettings(String uid, Map<String, dynamic> settings) =>
      _db.collection('users').doc(uid).set(
        <String, dynamic>{'settings': settings},
        SetOptions(merge: true),
      );

  // ── Buses / routes / stops ───────────────────────────────────────────
  Stream<Bus?> watchBus(String busId) =>
      _db.collection('buses').doc(busId).snapshots().map(
            (DocumentSnapshot<Map<String, dynamic>> s) =>
                s.exists ? Bus.fromMap(s.id, s.data()!) : null,
          );

  Stream<List<Bus>> watchAllBuses() =>
      _db.collection('buses').orderBy('busNumber').snapshots().map(
            (QuerySnapshot<Map<String, dynamic>> q) => q.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                      Bus.fromMap(d.id, d.data()),
                )
                .toList(),
          );

  Stream<BusRoute?> watchRouteOfBus(String busId) => _db
      .collection('routes')
      .where('busId', isEqualTo: busId)
      .where('isActive', isEqualTo: true)
      .limit(1)
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> q) => q.docs.isEmpty
            ? null
            : BusRoute.fromMap(q.docs.first.id, q.docs.first.data()),
      );

  Stream<List<BusStop>> watchStopsOfBus(String busId) => _db
      .collection('stops')
      .where('busId', isEqualTo: busId)
      .where('isActive', isEqualTo: true)
      .orderBy('order')
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> q) => q.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                  BusStop.fromMap(d.id, d.data()),
            )
            .toList(),
      );

  // Admin CRUD (rules restrict to admin claim)
  Future<String> createBus(Bus bus) async {
    final DocumentReference<Map<String, dynamic>> ref =
        await _db.collection('buses').add(<String, dynamic>{
      ...bus.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) =>
      _db.collection('buses').doc(busId).update(<String, dynamic>{
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<String> createStop(BusStop stop) async {
    final DocumentReference<Map<String, dynamic>> ref =
        await _db.collection('stops').add(<String, dynamic>{
      ...stop.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateStop(String stopId, Map<String, dynamic> data) =>
      _db.collection('stops').doc(stopId).update(data);

  /// Admin: stop delete (soft — isActive false, taaki purane trips ka data
  /// kharab na ho).
  Future<void> deactivateStop(String stopId) =>
      _db.collection('stops').doc(stopId).update(<String, dynamic>{
        'isActive': false,
      });

  /// Admin: stops ka naya order save karo (list order ke hisaab se 1,2,3…).
  Future<void> reorderStops(List<String> orderedStopIds) async {
    final WriteBatch batch = _db.batch();
    for (int i = 0; i < orderedStopIds.length; i++) {
      batch.update(
        _db.collection('stops').doc(orderedStopIds[i]),
        <String, dynamic>{'order': i + 1},
      );
    }
    await batch.commit();
  }

  /// ROUTE RECORDING: driver ki pehli completed trip ka GPS trace route
  /// ka official path ban jaata hai (agar pehle se recorded nahi hai).
  Future<void> saveRecordedPathIfFirst({
    required String busId,
    String? routeId,
    required String direction,
    required List<GeoPointData> path,
  }) async {
    final List<Map<String, dynamic>> pathMaps =
        path.map((GeoPointData p) => p.toMap()).toList();

    if (routeId != null && routeId.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection('routes').doc(routeId).get();
      final List<dynamic> existing =
          (doc.data()?['recordedPath'] as List?) ?? <dynamic>[];
      if (existing.isNotEmpty) return; // already recorded — keep first
      await _db.collection('routes').doc(routeId).update(
        <String, dynamic>{'recordedPath': pathMaps},
      );
      return;
    }

    // No route yet → create one automatically from this trip.
    final QuerySnapshot<Map<String, dynamic>> q = await _db
        .collection('routes')
        .where('busId', isEqualTo: busId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      final List<dynamic> existing =
          (q.docs.first.data()['recordedPath'] as List?) ?? <dynamic>[];
      if (existing.isEmpty) {
        await q.docs.first.reference
            .update(<String, dynamic>{'recordedPath': pathMaps});
      }
      return;
    }
    await _db.collection('routes').add(<String, dynamic>{
      'name': 'Auto route ($direction)',
      'busId': busId,
      'stopOrder': <String>[],
      'schoolLocation': <String, double>{'lat': 0, 'lng': 0},
      'polyline': '',
      'direction': direction,
      'isActive': true,
      'recordedPath': pathMaps,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: user profile fields edit (naam, class, roll, phone…).
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(<String, dynamic>{
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Admin: recent trip history (latest pehle).
  Stream<List<Trip>> watchRecentTrips({int limit = 50}) => _db
      .collection('trips')
      .orderBy('startedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> q) => q.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                  Trip.fromMap(d.id, d.data()),
            )
            .toList(),
      );

  Future<String> createRoute(BusRoute route) async {
    final DocumentReference<Map<String, dynamic>> ref =
        await _db.collection('routes').add(<String, dynamic>{
      ...route.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) =>
      _db.collection('routes').doc(routeId).update(data);

  // ── Trips ────────────────────────────────────────────────────────────
  Stream<Trip?> watchActiveTripOfBus(String busId) => _db
      .collection('trips')
      .where('busId', isEqualTo: busId)
      .where('status', isEqualTo: 'active')
      .limit(1)
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> q) => q.docs.isEmpty
            ? null
            : Trip.fromMap(q.docs.first.id, q.docs.first.data()),
      );

  Stream<List<Trip>> watchActiveTrips() => _db
      .collection('trips')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> q) => q.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                  Trip.fromMap(d.id, d.data()),
            )
            .toList(),
      );

  Future<String> createTrip({
    required String busId,
    required String driverId,
    required String routeId,
    required String direction,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref =
        await _db.collection('trips').add(<String, dynamic>{
      'busId': busId,
      'driverId': driverId,
      'routeId': routeId,
      'direction': direction,
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> endTrip(String tripId) =>
      _db.collection('trips').doc(tripId).update(<String, dynamic>{
        'status': 'completed',
        'endedAt': FieldValue.serverTimestamp(),
      });

  // ── Notifications inbox ──────────────────────────────────────────────
  Stream<List<AppNotification>> watchInbox(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('inbox')
      .orderBy('receivedAt', descending: true)
      .limit(80)
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> q) => q.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                  AppNotification.fromMap(d.id, d.data()),
            )
            .toList(),
      );

  Future<void> markInboxRead(String uid, String notifId) => _db
      .collection('users')
      .doc(uid)
      .collection('inbox')
      .doc(notifId)
      .update(<String, dynamic>{'read': true});

  // ── Audit logs (admin read-only; written by Cloud Functions) ────────
  Stream<List<AuditLog>> watchAuditLogs({int limit = 100}) => _db
      .collection('auditLogs')
      .orderBy('at', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> q) => q.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                  AuditLog.fromMap(d.id, d.data()),
            )
            .toList(),
      );

  // ── School config ────────────────────────────────────────────────────
  Stream<Map<String, dynamic>?> watchSchoolConfig() =>
      _db.collection('config').doc('school').snapshots().map(
            (DocumentSnapshot<Map<String, dynamic>> s) => s.data(),
          );

  List<AppUser> _mapUsers(QuerySnapshot<Map<String, dynamic>> q) {
    final List<AppUser> users = q.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              AppUser.fromMap(d.id, d.data()),
        )
        .toList();
    // Keep UI ordering deterministic without requiring a composite index.
    users.sort((AppUser a, AppUser b) =>
        a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return users;
  }
}
