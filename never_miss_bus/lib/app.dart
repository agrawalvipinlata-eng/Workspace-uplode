import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_language.dart';
import 'core/constants/home_widgets.dart';
import 'core/constants/nmb_constants.dart';
import 'core/security/app_lock_manager.dart';
import 'core/theme/app_theme_manager.dart';
import 'models/app_user.dart';
import 'providers/app_providers.dart';
import 'providers/data_providers.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/device_session_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

/// Global messenger so the single-device kick-out can show a message from
/// outside any screen's context.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class NeverMissBusApp extends ConsumerStatefulWidget {
  const NeverMissBusApp({super.key});

  @override
  ConsumerState<NeverMissBusApp> createState() => _NeverMissBusAppState();
}

class _NeverMissBusAppState extends ConsumerState<NeverMissBusApp>
    with WidgetsBindingObserver {
  String? _registeredForUid;
  bool _kickInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Saved language load (instant apply)
    Future<void>.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? saved = prefs.getString('nmb_lang');
        if (saved != null) appLanguage.value = saved;
      } catch (_) {}
      await HomeWidgetsConfig.load();
      await AppThemeManager.load();
      await AppLockManager.load();
    });
    Future<void>.microtask(() async {
      if (!mounted) return;
      final NotificationService notif = ref.read(notificationServiceProvider);
      try {
        await notif.initialize();
      } catch (_) {
        // Notifications failing must never block the app.
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(authServiceProvider).readSession(forceRefresh: true);
    }
  }

  /// SINGLE-DEVICE LOGIN — register this device as the user's active one.
  /// All ref-reads happen synchronously BEFORE any await.
  void _registerDevice(AuthSession session) {
    if (_registeredForUid == session.uid) return;
    _registeredForUid = session.uid;
    final DeviceSessionService dev = ref.read(deviceSessionServiceProvider);
    final FirestoreService fs = ref.read(firestoreServiceProvider);
    final NotificationService notif = ref.read(notificationServiceProvider);

    dev.loginWriteInProgress = true;
    () async {
      try {
        final String id = await dev.getDeviceId();
        final String name = await dev.getDeviceName();
        await fs.registerActiveDevice(
          uid: session.uid,
          deviceId: id,
          deviceName: name,
        );
        await notif.registerDevice(session.uid);
      } catch (_) {
        // Registration failure must not block login.
      } finally {
        dev.loginWriteInProgress = false;
      }
    }();
  }

  /// SINGLE-DEVICE LOGIN — if another device took over, sign out here.
  /// Ref-reads captured synchronously; async work uses captured objects.
  void _enforceSingleDevice(AppUser? me) {
    if (_kickInProgress) return;
    final AuthSession? session = ref.read(currentSessionProvider);
    if (session == null || me == null) return;
    final DeviceSessionService dev = ref.read(deviceSessionServiceProvider);
    if (dev.loginWriteInProgress) return;
    final AuthService auth = ref.read(authServiceProvider);

    final Map<String, dynamic>? active = me.activeDevice;
    if (active == null) return;
    final String activeId = (active['id'] as String?) ?? '';
    if (activeId.isEmpty) return;

    _kickInProgress = true;
    () async {
      try {
        final String myId = await dev.getDeviceId();
        if (activeId == myId) return; // we are the active device — fine

        await auth.signOut();
        _registeredForUid = null;
        rootMessengerKey.currentState?.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(
              activeId == DeviceSessionService.revokedId
                  ? 'You were signed out by the school admin.'
                  : 'This account was signed in on another device. '
                      'Only one device can be logged in at a time.',
            ),
          ),
        );
      } catch (_) {
        // Never crash the app from the guard.
      } finally {
        _kickInProgress = false;
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(appRouterProvider);

    ref.listen(sessionProvider, (Object? prev, AsyncValue<AuthSession?>? next) {
      final AuthSession? session = next?.valueOrNull;
      if (session != null) {
        _registerDevice(session);
      } else {
        _registeredForUid = null;
      }
    });

    ref.listen(myProfileProvider, (Object? prev, AsyncValue<AppUser?> next) {
      _enforceSingleDevice(next.valueOrNull);
    });

    // LANGUAGE LIVE-RELOAD: appLanguage badalte hi POORI app rebuild —
    // har screen ka text turant nayi bhasha me.
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (BuildContext context, String lang, Widget? _) {
        // THEME LIVE-RELOAD: theme badalte hi poora app naya color.
        return ValueListenableBuilder<AppThemeOption>(
          valueListenable: AppThemeManager.current,
          builder: (BuildContext context, AppThemeOption t, Widget? __) {
            return ValueListenableBuilder<bool>(
              valueListenable: AppThemeManager.darkMode,
              builder: (BuildContext context, bool dark, Widget? ___) {
                return MaterialApp.router(
                  key: ValueKey<String>('app_${lang}_${t.id}_$dark'),
                  title: NmbConstants.appName,
                  debugShowCheckedModeBanner: false,
                  scaffoldMessengerKey: rootMessengerKey,
                  theme: AppThemeManager.themeData(),
                  darkTheme: AppThemeManager.themeData(dark: true),
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                  routerConfig: router,
                );
              },
            );
          },
        );
      },
    );
  }
}
