import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🧠 SMART ERROR REPORTING — app me kahin bhi error aaye to uski report
/// AUTOMATIC admin ke paas pahunch jaati hai (errorReports collection).
/// Screenshot ki zaroorat nahi — report me sab kuch hota hai:
/// error text, screen ka naam, user kaun tha, time, app version.
class ErrorReportService {
  ErrorReportService._();

  static const String appVersion = '1.0';
  static DateTime? _lastReport;

  /// Report bhejo (rate-limited: max 1 per 30s taaki spam na ho).
  static Future<void> report({
    required String where,
    required Object error,
    StackTrace? stack,
    String? extra,
  }) async {
    try {
      final DateTime now = DateTime.now();
      if (_lastReport != null &&
          now.difference(_lastReport!).inSeconds < 30) {
        return; // spam guard
      }
      _lastReport = now;

      final User? u = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('errorReports')
          .add(<String, dynamic>{
        'where': where,
        'error': error.toString().length > 800
            ? error.toString().substring(0, 800)
            : error.toString(),
        'stack': stack
            ?.toString()
            .split('\n')
            .take(8)
            .join('\n'),
        'extra': extra,
        'uid': u?.uid,
        'email': u?.email,
        'appVersion': appVersion,
        'at': FieldValue.serverTimestamp(),
        'status': 'new',
      }).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Reporting must NEVER crash the app.
    }
  }
}
