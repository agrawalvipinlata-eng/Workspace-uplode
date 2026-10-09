import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/error_report_service.dart';

/// True once the real app UI is up. After this point, stray background
/// errors (e.g. a stream closing during logout) must NEVER replace the
/// whole app with an error screen — they are only logged.
bool _appStarted = false;

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      // Widget-level errors: log; never tear down the running app.
      FlutterError.presentError(details);
      // 🧠 SMART REPORT: error admin ke paas auto pahunchti hai.
      ErrorReportService.report(
        where: details.library ?? 'flutter',
        error: details.exception,
        stack: details.stack,
      );
    };

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      // Android auto-initializes from google-services.json; a second init
      // throws duplicate-app which simply means "already ready".
      if (e.code != 'duplicate-app') {
        runApp(_StartupErrorApp(
          title: 'Firebase connection problem',
          details: e.toString(),
        ),);
        return;
      }
    } catch (e) {
      runApp(_StartupErrorApp(
        title: 'Firebase connection problem',
        details: e.toString(),
      ),);
      return;
    }

    runApp(const ProviderScope(child: NeverMissBusApp()));
    _appStarted = true;
  }, (Object error, StackTrace stack) {
    if (_appStarted) {
      // App is already running: background hiccups (stream permission
      // errors during logout, disposed listeners, network blips) are
      // logged only — the user keeps their working app.
      debugPrint('Background error (ignored): $error');
      ErrorReportService.report(
        where: 'background',
        error: error,
        stack: stack,
      );
      return;
    }
    // Genuine startup failure → readable screen instead of black screen.
    runApp(_StartupErrorApp(
      title: 'App failed to start',
      details: '$error',
    ),);
  });
}

/// Friendly full-screen error shown ONLY for real startup failures.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.title, required this.details});

  final String title;
  final String details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCE8E7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: Color(0xFFC5221F),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17233B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please share a screenshot of this screen so the '
                    'problem can be fixed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5A6779),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4E9F2)),
                    ),
                    child: Text(
                      details,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Color(0xFF5A6779),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
