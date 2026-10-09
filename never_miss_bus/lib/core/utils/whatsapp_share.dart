import 'package:url_launcher/url_launcher.dart';

/// 💚 WHATSAPP SHARE — 100% FREE tarika (no API, no billing):
/// login details ka message READY-TYPED WhatsApp me khul jata hai,
/// admin sirf SEND dabata hai. Number pe seedha chat khulti hai.
abstract final class WhatsAppShare {
  /// Indian numbers: 10-digit ko +91 laga do; already-coded ko waise hi.
  static String _normalize(String phone) {
    String p = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (p.length == 10) p = '91$p';
    return p;
  }

  /// Login credentials message bhejo. [phone] null/khali ho to bina
  /// number ke share sheet khulti hai (koi bhi chat choose karo).
  static Future<bool> sendCredentials({
    String? phone,
    required String studentName,
    required String className,
    required String section,
    required String roll,
    required String password,
    required String schoolName,
  }) async {
    final String msg = '''
🏫 *$schoolName*
📱 *Bus Tracking App — Login Details*

👤 Student: *$studentName*
🎓 Class: *$className-$section*  •  Roll No: *$roll*
🔑 Password: *$password*

📲 *App me login kaise karein:*
1. App kholo → STUDENT tab
2. Class, Section, Roll No. chuno
3. Upar wala password daalo
4. Pehli login par apna naya password banana hoga

⚠️ Ye password kisi ke saath share na karein.
Dhanyavaad! 🙏''';

    final String encoded = Uri.encodeComponent(msg);
    final Uri uri = (phone != null && phone.trim().isNotEmpty)
        ? Uri.parse('https://wa.me/${_normalize(phone)}?text=$encoded')
        : Uri.parse('https://wa.me/?text=$encoded');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
