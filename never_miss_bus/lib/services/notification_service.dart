import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firestore_service.dart';

/// FCM wiring:
///  - requests notification permission (Android 13+ / iOS),
///  - registers the device token under users/{uid}.fcmTokens (rules allow
///    only the owner to write this field),
///  - shows foreground pushes via a local notification channel.
///
/// Targeting is done entirely by Cloud Functions against explicit tokens —
/// no FCM topics, because any client can subscribe to a topic and that would
/// leak bus-scoped notifications.
class NotificationService {
  NotificationService(this._messaging, this._firestore);

  final FirebaseMessaging _messaging;
  final FirestoreService _firestore;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'nmb_alerts',
    'Bus Alerts',
    description: 'Trip updates, arrival alerts and school announcements.',
    importance: Importance.high,
  );

  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;
  Future<void>? _initialization;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(initSettings);
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _permissionGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    // Foreground messages → local notification (FCM shows nothing in
    // foreground by default).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final RemoteNotification? n = message.notification;
      if (n == null) return;
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'nmb_alerts',
            'Bus Alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Call after login; keeps the token registered for this user.
  Future<void> registerDevice(String uid) async {
    try {
      // Avoid a startup race where getToken runs before Android permission
      // and the notification channel have finished initializing.
      await initialize();
      final String? token = await _messaging.getToken();
      if (token != null) await _firestore.saveFcmToken(uid, token);
      _messaging.onTokenRefresh
          .listen((String t) => _firestore.saveFcmToken(uid, t));
    } catch (_) {
      // Non-fatal: push simply won't arrive on this device.
    }
  }

  /// Call on logout so the signed-out device stops receiving user pushes.
  Future<void> unregisterDevice(String uid) async {
    try {
      final String? token = await _messaging.getToken();
      if (token != null) await _firestore.removeFcmToken(uid, token);
      await _messaging.deleteToken();
    } catch (_) {/* best effort */}
  }
}
