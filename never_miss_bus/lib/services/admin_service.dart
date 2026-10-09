import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart'
    hide Query, Transaction; // clashes with cloud_firestore

import '../core/constants/nmb_constants.dart';
import '../core/utils/result.dart';
import '../models/app_user.dart';

/// FREE-MODE admin operations (Spark plan — no Cloud Functions needed).
///
/// How security still holds without a server:
///  - Every write below is validated by Firestore/RTDB security rules,
///    which look up the CALLER's `users/{uid}` doc and only allow these
///    operations when `role == 'admin'`. A student/driver client calling
///    these methods gets PERMISSION_DENIED from the backend.
///  - New Auth accounts are created through a SECONDARY Firebase app
///    instance so the admin's own session is never replaced (the default
///    `createUserWithEmailAndPassword` signs in as the new user — the
///    secondary-app trick avoids that).
///  - `/access/{uid}` in RTDB mirrors each user's role+bus so RTDB rules
///    (which cannot read Firestore) can authorize live-location access.
///    That mirror is writable only by admins, per RTDB rules.
class AdminService {
  AdminService(this._db, this._rtdb);

  final FirebaseFirestore _db;
  final FirebaseDatabase _rtdb;

  Future<Result<String>> provisionUser({
    required String email,
    required String fullName,
    required String role, // 'student' | 'driver' | 'admin'
    required String temporaryPassword,
    String? busId,
    String? stopId,
    String? classSection,
    String? rollNumber,
    String? phone,
    String? contactEmail, // 📧 optional real email (student/parent ka)
  }) async {
    FirebaseApp? tempApp;
    try {
      // Secondary app: creates the Auth user WITHOUT touching our session.
      // SPEED: worker app ko REUSE karo (create/delete har baar = 1-2 sec
      // waste hota tha).
      try {
        tempApp = Firebase.app('nmb_admin_worker');
      } catch (_) {
        tempApp = await Firebase.initializeApp(
          name: 'nmb_admin_worker',
          options: Firebase.app().options,
        );
      }
      final FirebaseAuth workerAuth = FirebaseAuth.instanceFor(app: tempApp);
      String uid;
      try {
        final UserCredential cred =
            await workerAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: temporaryPassword,
        );
        uid = cred.user!.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
        // EMAIL-REUSE FIX: pehle deleted user ka Auth account abhi zinda
        // hai (free plan par Auth delete nahi hota). Agar uska PROFILE
        // Firestore me NAHI hai → woh orphan hai → naye password ke saath
        // REUSE kar lo. Profile hai → sach me duplicate, error do.
        UserCredential cred;
        try {
          cred = await workerAuth.signInWithEmailAndPassword(
            email: email.trim(),
            password: temporaryPassword,
          );
        } on FirebaseAuthException {
          return const Err<String>(
            AppFailure(
              'email-in-use',
              'This email/ID was used before with a different password. '
                  'Use a different roll number, or contact support to free '
                  'this ID.',
            ),
          );
        }
        final String candidateUid = cred.user!.uid;
        final DocumentSnapshot<Map<String, dynamic>> existing = await _db
            .collection('users')
            .doc(candidateUid)
            .get()
            .timeout(const Duration(seconds: 8));
        if (existing.exists) {
          await workerAuth.signOut();
          return const Err<String>(
            AppFailure('email-in-use', 'This ID already has an account.'),
          );
        }
        uid = candidateUid; // orphan reuse ✅
      }
      await workerAuth.signOut();

      // Profile doc — rules verify the CALLER (this admin) is admin.
      await _db.collection('users').doc(uid).set(<String, dynamic>{
        'role': role,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'busId': busId,
        'stopId': role == 'student' ? stopId : null,
        'classSection':
            (role == 'student' || role == 'teacher') ? classSection : null,
        'rollNumber': role == 'student' ? rollNumber : null,
        'phone': phone,
        'contactEmail': contactEmail,
        'isActive': true,
        'fcmTokens': <String, dynamic>{},
        // OTP-ALTERNATE: pehli login par student ko apna naya password
        // set karna hoga (school wala temp password sirf ek baar chalega).
        'settings': <String, dynamic>{
          if (role == 'student') 'mustChangePassword': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ⚡ SPEED: RTDB mirror + audit BACKGROUND me — inka wait nahi.
      // Profile ban gaya = account ready; baaki 1-2 sec me khud ho jayega.
      () async {
        try {
          await _writeAccessMirror(
            uid,
            role: role,
            busId: busId,
            active: true,
          );
        } catch (_) {/* retry on next assign */}
        try {
          await _audit(
            'USER_PROVISIONED',
            'user',
            uid,
            <String, dynamic>{'role': role, 'busId': busId},
          );
        } catch (_) {/* audit best-effort */}
      }();
      return Ok<String>(uid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return const Err<String>(
          AppFailure('email-in-use', 'This email already has an account.'),
        );
      }
      if (e.code == 'weak-password') {
        return const Err<String>(
          AppFailure('weak-password', 'Choose a stronger password.'),
        );
      }
      return Err<String>(AppFailure(e.code, 'Could not create the account.'));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const Err<String>(AppFailure.permissionDenied);
      }
      return const Err<String>(AppFailure.unknown);
    }
    // NOTE: worker app ko delete NAHI karte — agli add ke liye reuse hota
    // hai (speed). Sirf signOut kaafi hai jo upar ho chuka hai.
  }

  Future<Result<void>> assignUserToBus({
    required String uid,
    String? busId,
    String? stopId,
  }) async {
    try {
      await _db.collection('users').doc(uid).update(<String, dynamic>{
        'busId': busId,
        'stopId': stopId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection('users').doc(uid).get();
      await _writeAccessMirror(
        uid,
        role: (doc.data()?['role'] as String?) ?? 'student',
        busId: busId,
        active: (doc.data()?['isActive'] as bool?) ?? true,
      );
      await _audit(
        'STUDENT_BUS_REASSIGNED',
        'user',
        uid,
        <String, dynamic>{'busId': busId, 'stopId': stopId},
      );
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
        e.code == 'permission-denied'
            ? AppFailure.permissionDenied
            : AppFailure.unknown,
      );
    }
  }

  Future<Result<void>> assignDriverToBus({
    required String driverUid,
    String? busId,
  }) async {
    try {
      final WriteBatch batch = _db.batch();
      // Clear any bus currently pointing at this driver.
      final QuerySnapshot<Map<String, dynamic>> previous = await _db
          .collection('buses')
          .where('driverId', isEqualTo: driverUid)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d
          in previous.docs) {
        if (d.id != busId) {
          batch.update(d.reference, <String, dynamic>{'driverId': null});
        }
      }
      if (busId != null) {
        batch.update(
          _db.collection('buses').doc(busId),
          <String, dynamic>{'driverId': driverUid},
        );
      }
      batch.update(_db.collection('users').doc(driverUid), <String, dynamic>{
        'busId': busId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      await _writeAccessMirror(
        driverUid,
        role: 'driver',
        busId: busId,
        active: true,
      );
      await _audit(
        'DRIVER_BUS_REASSIGNED',
        'user',
        driverUid,
        <String, dynamic>{'busId': busId},
      );
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
        e.code == 'permission-denied'
            ? AppFailure.permissionDenied
            : AppFailure.unknown,
      );
    }
  }

  /// Admin: user profile edit (naam, class, roll, phone).
  Future<Result<void>> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection('users').doc(uid).update(<String, dynamic>{
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // ⚡ audit background me — save turant complete
      () async {
        try {
          await _audit('USER_PROFILE_UPDATED', 'user', uid, data);
        } catch (_) {}
      }();
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
        e.code == 'permission-denied'
            ? AppFailure.permissionDenied
            : AppFailure.unknown,
      );
    }
  }

  Future<Result<void>> promoteStudent({
    required String uid,
    required String classSection,
    required String rollNumber,
    required List<String> removeDocuments,
  }) async {
    if (classSection.trim().isEmpty || rollNumber.trim().isEmpty) {
      return const Err<void>(AppFailure(
        'invalid-promotion',
        'Class, section and roll number are required.',
      ));
    }
    try {
      final DocumentReference<Map<String, dynamic>> ref =
          _db.collection('users').doc(uid);
      await _db.runTransaction((Transaction tx) async {
        final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
        final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
        final List<dynamic> history =
            (data['promotionHistory'] as List?)?.toList() ?? <dynamic>[];
        history.insert(0, <String, dynamic>{
          'fromClass': data['classSection'],
          'fromRoll': data['rollNumber'],
          'toClass': classSection.trim(),
          'toRoll': rollNumber.trim(),
          'at': DateTime.now().millisecondsSinceEpoch,
        });
        final Map<String, dynamic> docs =
            ((data['documents'] as Map?) ?? <String, dynamic>{})
                .cast<String, dynamic>();
        for (final String name in removeDocuments) {
          docs.remove(name);
        }
        tx.update(ref, <String, dynamic>{
          'classSection': classSection.trim(),
          'rollNumber': rollNumber.trim(),
          'documents': docs,
          'promotionHistory': history.take(20).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      await _audit('STUDENT_PROMOTED', 'user', uid, <String, dynamic>{
        'classSection': classSection,
        'rollNumber': rollNumber,
        'removedDocuments': removeDocuments,
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(e.code == 'permission-denied'
          ? AppFailure.permissionDenied
          : AppFailure.unknown);
    }
  }

  /// FREE-MODE student password reset.
  ///
  /// Bina Cloud Functions ke kisi doosre user ka Auth password nahi badla
  /// ja sakta, isliye trick: naya "generation" Auth account banta hai
  /// (st.7b.23.g2@…) naye password ke saath. Purana account disable +
  /// uska profile naye account par shift. Student wahi Class+Roll+naya
  /// password se login karega — usse koi fark nahi dikhta.
  Future<Result<void>> resetStudentPassword({
    required AppUser student,
    required String newPassword,
  }) async {
    if (student.classSection == null || student.rollNumber == null) {
      return const Err<void>(
        AppFailure('no-roll', 'This student has no class/roll set.'),
      );
    }
    final List<String> parts = student.classSection!.split('-');
    final String klass = parts.first;
    final String section = parts.length > 1 ? parts[1] : 'A';

    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'nmb_pw_worker',
        options: Firebase.app().options,
      );
      final FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // Agli free generation dhundo aur account banao.
      String? newEmail;
      String? newUid;
      for (int gen = 2; gen <= StudentLoginId.maxGenerations; gen++) {
        final String candidate = StudentLoginId.email(
          klass: klass,
          section: section,
          roll: student.rollNumber!,
          gen: gen,
        );
        try {
          final UserCredential cred =
              await tempAuth.createUserWithEmailAndPassword(
            email: candidate,
            password: newPassword,
          );
          newEmail = candidate;
          newUid = cred.user!.uid;
          await tempAuth.signOut();
          break;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') continue; // agla gen try
          rethrow;
        }
      }
      if (newUid == null || newEmail == null) {
        return const Err<void>(
          AppFailure(
            'resets-exhausted',
            'Too many resets. Please handle via the school office.',
          ),
        );
      }

      // FULL PROFILE COPY: purane doc ka SAB data naye uid me —
      // photo, fees, documents, parents, DOB… kuch bhi miss nahi.
      Map<String, dynamic> oldData = <String, dynamic>{};
      try {
        final DocumentSnapshot<Map<String, dynamic>> oldDoc =
            await _db.collection('users').doc(student.uid).get();
        oldData = oldDoc.data() ?? <String, dynamic>{};
      } catch (_) {/* fallback below covers basics */}
      final Map<String, dynamic> profile = <String, dynamic>{
        ...oldData, // 📋 sab kuch copy (photoB64, fees, documents, etc.)
        'role': 'student',
        'fullName': student.fullName,
        'email': newEmail,
        'busId': student.busId,
        'stopId': student.stopId,
        'classSection': student.classSection,
        'rollNumber': student.rollNumber,
        'isActive': true,
        'fcmTokens': <String, dynamic>{},
        // Naya password student khud pehli login par badlega + device slot
        // fresh (purana device lock hat jata hai).
        'settings': <String, dynamic>{'mustChangePassword': true},
        'replacedBy': FieldValue.delete(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      profile.remove('replacedBy');
      await _db.collection('users').doc(newUid).set(profile);
      await _writeAccessMirror(
        newUid,
        role: 'student',
        busId: student.busId,
        active: true,
      );

      await _db.collection('users').doc(student.uid).update(
        <String, dynamic>{'isActive': false, 'replacedBy': newUid},
      );
      await _writeAccessMirror(
        student.uid,
        role: 'student',
        busId: student.busId,
        active: false,
      );

      await _audit(
        'STUDENT_PASSWORD_RESET',
        'user',
        student.uid,
        <String, dynamic>{'newUid': newUid},
      );
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
        e.code == 'permission-denied'
            ? AppFailure.permissionDenied
            : AppFailure.unknown,
      );
    } catch (_) {
      return const Err<void>(AppFailure.unknown);
    } finally {
      await tempApp?.delete();
    }
  }

  /// FEES 2.0: payment record — fees.paid += amount, history entry add.
  Future<Result<void>> recordFeePayment({
    required String uid,
    required double amount,
  }) async {
    if (amount <= 0 || !amount.isFinite) {
      return const Err<void>(
        AppFailure('invalid-amount', 'Payment amount must be positive.'),
      );
    }
    try {
      final DocumentReference<Map<String, dynamic>> ref =
          _db.collection('users').doc(uid);
      await _db.runTransaction((Transaction tx) async {
        final DocumentSnapshot<Map<String, dynamic>> doc = await tx.get(ref);
        final Map<String, dynamic> fees =
            ((doc.data()?['fees'] as Map?) ?? <String, dynamic>{})
                .cast<String, dynamic>();
        final double paid = ((fees['paid'] as num?) ?? 0).toDouble() + amount;
        final double total = ((fees['total'] as num?) ?? 0).toDouble();
        if (total > 0 && paid > total) {
          throw StateError('Payment cannot be greater than total fees.');
        }
        final List<dynamic> history = (fees['history'] as List?) ?? <dynamic>[];
        history.insert(0, <String, dynamic>{
          'amount': amount,
          'at': DateTime.now().millisecondsSinceEpoch,
        });
        tx.update(ref, <String, dynamic>{
          'fees': <String, dynamic>{
            ...fees,
            'paid': paid,
            'history': history.take(50).toList(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }).timeout(const Duration(seconds: 12));
      await _audit(
        'FEE_PAYMENT_RECORDED',
        'user',
        uid,
        <String, dynamic>{'amount': amount},
      );
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
        e.code == 'permission-denied'
            ? AppFailure.permissionDenied
            : AppFailure.unknown,
      );
    } catch (e) {
      return Err<void>(AppFailure('fee-rec', 'Failed: $e'));
    }
  }

  /// Admin: force logout — user ke activeDevice ko REVOKED mark karo.
  /// User ka phone profile-stream se yeh dekh kar turant sign out ho
  /// jaata hai ("You were signed out by the school admin").
  Future<Result<void>> forceLogout(String uid) async {
    try {
      await _db.collection('users').doc(uid).set(
        <String, dynamic>{
          'settings': <String, dynamic>{
            'activeDevice': <String, dynamic>{
              'id': 'REVOKED',
              'name': 'Signed out by admin',
              'at': DateTime.now().millisecondsSinceEpoch,
            },
          },
        },
        SetOptions(merge: true),
      );
      await _audit('FORCE_LOGOUT', 'user', uid, const <String, dynamic>{});
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
        e.code == 'permission-denied'
            ? AppFailure.permissionDenied
            : AppFailure.unknown,
      );
    }
  }

  /// PERMANENT DELETE — user ka profile, inbox, RTDB access sab hamesha
  /// ke liye delete. (Auth login entry disable ho jaati hai kyunki
  /// profile ke bina rules use andar nahi aane dete.)
  Future<Result<void>> deleteUserPermanently(AppUser user) async {
    // ROBUST DELETE: har step apna error khud sambhalta hai, koi bhi step
    // fail ho toh bhi aage badho — aur PURA operation 30s timeout me
    // guaranteed khatam hota hai (UI kabhi gray hokar nahi atkegi).
    try {
      return await _deleteUserInner(user).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return const Err<void>(
            AppFailure(
              'timeout',
              'Delete is taking too long. Check internet and try again.',
            ),
          );
        },
      );
    } catch (e) {
      return Err<void>(AppFailure('delete-failed', 'Delete failed: $e'));
    }
  }

  Future<Result<void>> _deleteUserInner(AppUser user) async {
    // INSTANT DELETE: pehle ASLI delete (profile doc — ek hi request,
    // ~0.5s), turant success return. Baaki cleanup (inbox, RTDB, bus
    // unlink, audit) background me chalta hai — user ko wait nahi.
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .delete()
          .timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      return Err<void>(
        AppFailure(
          e.code,
          e.code == 'permission-denied'
              ? 'Permission denied — Firestore rules check karo.'
              : 'Delete failed: ${e.message}',
        ),
      );
    }

    // Background cleanup — fire and forget (await NAHI).
    _cleanupAfterDelete(user);

    return const Ok<void>(null);
  }

  /// Baaki safai background me — user isko wait nahi karta.
  void _cleanupAfterDelete(AppUser user) {
    () async {
      // RTDB access remove (device kick + live access block)
      try {
        await _rtdb
            .ref('access/${user.uid}')
            .remove()
            .timeout(const Duration(seconds: 8));
      } catch (_) {}

      // Inbox purge
      try {
        QuerySnapshot<Map<String, dynamic>> inbox;
        int guard = 0;
        do {
          inbox = await _db
              .collection('users')
              .doc(user.uid)
              .collection('inbox')
              .limit(200)
              .get()
              .timeout(const Duration(seconds: 8));
          if (inbox.docs.isNotEmpty) {
            final WriteBatch b = _db.batch();
            for (final QueryDocumentSnapshot<Map<String, dynamic>> d
                in inbox.docs) {
              b.delete(d.reference);
            }
            await b.commit().timeout(const Duration(seconds: 8));
          }
          guard++;
        } while (inbox.docs.length == 200 && guard < 10);
      } catch (_) {}

      // Driver tha toh bus unlink
      try {
        if (user.role.name == 'driver') {
          final QuerySnapshot<Map<String, dynamic>> buses = await _db
              .collection('buses')
              .where('driverId', isEqualTo: user.uid)
              .get()
              .timeout(const Duration(seconds: 8));
          for (final QueryDocumentSnapshot<Map<String, dynamic>> d
              in buses.docs) {
            await d.reference.update(<String, dynamic>{'driverId': null});
          }
        }
      } catch (_) {}

      // Audit
      try {
        await _audit(
          'USER_DELETED_PERMANENTLY',
          'user',
          user.uid,
          <String, dynamic>{'name': user.fullName, 'role': user.role.name},
        );
      } catch (_) {}
    }();
  }

  Future<Result<void>> setAccountActive({
    required String uid,
    required bool active,
  }) async {
    try {
      await _db.collection('users').doc(uid).update(<String, dynamic>{
        'isActive': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection('users').doc(uid).get();
      await _writeAccessMirror(
        uid,
        role: (doc.data()?['role'] as String?) ?? 'student',
        busId: doc.data()?['busId'] as String?,
        active: active,
      );
      await _audit(
        active ? 'ACCOUNT_ENABLED' : 'ACCOUNT_DISABLED',
        'user',
        uid,
        const <String, dynamic>{},
      );
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
        e.code == 'permission-denied'
            ? AppFailure.permissionDenied
            : AppFailure.unknown,
      );
    }
  }

  /// Announcement fan-out to each recipient's private inbox.
  /// Rules allow inbox CREATE only for admins.
  Future<Result<void>> sendAnnouncement({
    required String title,
    required String body,
    required String scope, // 'all' | 'bus'
    String? busId,
    String? classSection,
  }) async {
    try {
      Query<Map<String, dynamic>> q =
          _db.collection('users').where('isActive', isEqualTo: true);
      if (scope == 'bus') {
        if (busId == null) {
          return const Err<void>(
            AppFailure('invalid', 'Choose a bus first.'),
          );
        }
        q = q.where('busId', isEqualTo: busId);
      } else if (scope == 'class') {
        if (classSection == null || classSection.trim().isEmpty) {
          return const Err<void>(
            AppFailure('invalid', 'Choose a class first.'),
          );
        }
        q = q.where('classSection', isEqualTo: classSection.trim());
      }
      final QuerySnapshot<Map<String, dynamic>> users = await q.get();

      // Firestore batches max 500 ops.
      WriteBatch batch = _db.batch();
      int ops = 0;
      for (final QueryDocumentSnapshot<Map<String, dynamic>> u in users.docs) {
        final DocumentReference<Map<String, dynamic>> ref =
            u.reference.collection('inbox').doc();
        batch.set(ref, <String, dynamic>{
          'type': 'announcement',
          'title': title.trim(),
          'body': body.trim(),
          'read': false,
          'receivedAt': FieldValue.serverTimestamp(),
        });
        ops++;
        if (ops == 450) {
          await batch.commit();
          batch = _db.batch();
          ops = 0;
        }
      }
      if (ops > 0) await batch.commit();

      await _audit(
        'ANNOUNCEMENT_SENT',
        'notification',
        scope,
        <String, dynamic>{
          'title': title,
          'busId': busId,
          'classSection': classSection,
        },
      );
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
        e.code == 'permission-denied'
            ? AppFailure.permissionDenied
            : AppFailure.unknown,
      );
    }
  }

  Future<void> _writeAccessMirror(
    String uid, {
    required String role,
    String? busId,
    required bool active,
  }) async {
    try {
      await _rtdb.ref('access/$uid').set(<String, Object?>{
        'role': role,
        'busId': busId,
        'active': active,
      }).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Access-mirror failure kabhi poora operation hang/fail nahi karega.
      // (Admin baad me 'Save assignment' se isse dobara likh sakta hai.)
    }
  }

  Future<void> _audit(
    String action,
    String targetType,
    String targetId,
    Map<String, dynamic> details,
  ) async {
    try {
      await _db.collection('auditLogs').add(<String, dynamic>{
        'actorUid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'actorRole': 'admin',
        'action': action,
        'target': <String, String>{'type': targetType, 'id': targetId},
        'details': details,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Audit failures must never block the operation itself.
    }
  }
}
