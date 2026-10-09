import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/enums.dart';
import '../core/utils/result.dart';

/// Session snapshot for the signed-in user.
///
/// FREE-MODE (Spark plan) design: the role/bus assignment lives in the
/// `users/{uid}` Firestore document and is mirrored to RTDB `/access/{uid}`.
/// Both databases' security rules read those records server-side, so a
/// modified client still cannot widen its own access. (The Blaze-plan
/// variant with custom claims + Cloud Functions is documented in
/// docs/SECURITY.md for when the school upgrades.)
class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.role,
    this.busId,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String? busId;
}

class AuthService {
  AuthService(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final AuthSession? session = await readSession(forceRefresh: true);
      if (session == null) {
        await _auth.signOut();
        return const Err<AuthSession>(
          AppFailure(
            'no-role',
            'This account is not set up yet or has been disabled. '
            'Please contact the school office.',
          ),
        );
      }
      return Ok<AuthSession>(session);
    } on FirebaseAuthException catch (e) {
      return Err<AuthSession>(_mapAuthError(e));
    } catch (_) {
      return const Err<AuthSession>(AppFailure.unknown);
    }
  }

  /// Reads role/bus from the caller's own `users/{uid}` document.
  /// Security rules only allow reading one's own doc, and every other
  /// collection's rules re-verify the role server-side on each request.
  Future<AuthSession?> readSession({bool forceRefresh = false}) async {
    final User? user = _auth.currentUser;
    if (user == null) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _db
          .collection('users')
          .doc(user.uid)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );
      final Map<String, dynamic>? data = doc.data();
      if (data == null) return null;
      return _sessionFrom(user, data);
    } catch (_) {
      // 📶 STAY LOGGED IN: network/server issue par turant logout NAHI —
      // pehle local cache try karo. User tabhi bahar hota hai jab doc
      // sach me delete/disable ho.
      try {
        final DocumentSnapshot<Map<String, dynamic>> cached = await _db
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache));
        final Map<String, dynamic>? data = cached.data();
        if (data == null) return null;
        return _sessionFrom(user, data);
      } catch (_) {
        return null;
      }
    }
  }

  AuthSession? _sessionFrom(User user, Map<String, dynamic> data) {
    final UserRole? role = UserRole.tryParse(data['role'] as String?);
    final bool active = (data['isActive'] as bool?) ?? false;
    if (role == null || !active) return null;
    return AuthSession(
      uid: user.uid,
      email: user.email ?? '',
      role: role,
      busId: data['busId'] as String?,
    );
  }

  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Ok<void>(null);
    } on FirebaseAuthException catch (e) {
      return Err<void>(_mapAuthError(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  AppFailure _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return const AppFailure(
          'invalid-credential',
          'Email or password is incorrect. Please try again.',
        );
      case 'user-disabled':
        return const AppFailure(
          'user-disabled',
          'This account has been disabled. Please contact the school office.',
        );
      case 'too-many-requests':
        return const AppFailure(
          'too-many-requests',
          'Too many attempts. Please wait a moment and try again.',
        );
      case 'network-request-failed':
        return AppFailure.network;
      default:
        return AppFailure(e.code, 'Sign-in failed. Please try again.');
    }
  }
}
