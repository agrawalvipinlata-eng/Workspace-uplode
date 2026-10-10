import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/admin_service.dart';
import '../services/attendance_service.dart';
import '../services/leave_service.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/device_session_service.dart';
import '../services/document_vault_service.dart';
import '../services/driver_trip_service.dart';
import '../services/exam_result_service.dart';
import '../services/eta_service.dart';
import '../services/firestore_service.dart';
import '../services/live_location_service.dart';
import '../services/notification_service.dart';
import '../services/schoolwork_service.dart';
import '../services/remark_service.dart';

/// ── Service singletons ────────────────────────────────────────────────
final Provider<AuthService> authServiceProvider = Provider<AuthService>(
  (Ref ref) => AuthService(FirebaseAuth.instance, FirebaseFirestore.instance),
);

final Provider<FirestoreService> firestoreServiceProvider =
    Provider<FirestoreService>(
  (Ref ref) => FirestoreService(FirebaseFirestore.instance),
);

final Provider<LiveLocationService> liveLocationServiceProvider =
    Provider<LiveLocationService>(
  (Ref ref) => LiveLocationService(FirebaseDatabase.instance),
);

/// FREE-MODE admin operations (no Cloud Functions — see AdminService docs).
final Provider<AdminService> adminServiceProvider = Provider<AdminService>(
  (Ref ref) => AdminService(
    FirebaseFirestore.instance,
    FirebaseDatabase.instance,
  ),
);

final Provider<DriverTripService> driverTripServiceProvider =
    Provider<DriverTripService>(
  (Ref ref) => DriverTripService(
    ref.watch(firestoreServiceProvider),
    ref.watch(liveLocationServiceProvider),
  ),
);

final Provider<EtaService> etaServiceProvider =
    Provider<EtaService>((Ref ref) => EtaService());

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>(
  (Ref ref) => NotificationService(
    FirebaseMessaging.instance,
    ref.watch(firestoreServiceProvider),
  ),
);

final Provider<DeviceSessionService> deviceSessionServiceProvider =
    Provider<DeviceSessionService>(
  (Ref ref) => DeviceSessionService(),
);

final Provider<AttendanceService> attendanceServiceProvider =
    Provider<AttendanceService>(
  (Ref ref) => AttendanceService(FirebaseFirestore.instance),
);

final Provider<LeaveService> leaveServiceProvider = Provider<LeaveService>(
  (Ref ref) => LeaveService(FirebaseFirestore.instance),
);

final Provider<SchoolworkService> schoolworkServiceProvider =
    Provider<SchoolworkService>(
  (Ref ref) => SchoolworkService(FirebaseFirestore.instance),
);

final Provider<RemarkService> remarkServiceProvider = Provider<RemarkService>(
  (Ref ref) => RemarkService(FirebaseFirestore.instance),
);

final Provider<DocumentVaultService> documentVaultServiceProvider =
    Provider<DocumentVaultService>(
  (Ref ref) => DocumentVaultService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  ),
);

final Provider<ExamResultService> examResultServiceProvider =
    Provider<ExamResultService>(
  (Ref ref) => ExamResultService(FirebaseFirestore.instance),
);

final Provider<ConnectivityService> connectivityServiceProvider =
    Provider<ConnectivityService>(
  (Ref ref) => ConnectivityService(Connectivity()),
);

/// ── Session state ─────────────────────────────────────────────────────
final StreamProvider<AuthSession?> sessionProvider =
    StreamProvider<AuthSession?>((Ref ref) async* {
  final AuthService auth = ref.watch(authServiceProvider);
  await for (final User? user in auth.authStateChanges) {
    if (user == null) {
      yield null;
    } else {
      // 🔑 ONE-TIME LOGIN: session read fail ho (slow internet) to 3 baar
      // retry — user ko login screen pe TABHI bhejo jab account sach me
      // disable/delete hua ho.
      AuthSession? session = await auth.readSession();
      int tries = 0;
      while (session == null && tries < 3) {
        tries++;
        await Future<void>.delayed(const Duration(seconds: 2));
        session = await auth.readSession();
      }
      yield session;
    }
  }
});

final Provider<AuthSession?> currentSessionProvider = Provider<AuthSession?>(
  (Ref ref) => ref.watch(sessionProvider).valueOrNull,
);

/// ── Connectivity ──────────────────────────────────────────────────────
final StreamProvider<bool> isOnlineProvider =
    StreamProvider<bool>((Ref ref) async* {
  final ConnectivityService c = ref.watch(connectivityServiceProvider);
  yield await c.checkOnline();
  yield* c.isOnline;
});
