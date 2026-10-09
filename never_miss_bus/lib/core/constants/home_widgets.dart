import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

/// HOME WIDGETS SYSTEM — student apna home customize karta hai:
/// kaunse widgets dikhen + kis order me. Layout local save hota hai.
class HomeWidgetsConfig {
  static const List<String> allWidgets = <String>[
    'busCard',
    'trackBanner',
    'quickActions',
    'timetable',
    'fees',
    'nextStop',
    'checkin',
    'driver',
    'notices',
    'alerts',
  ];

  static const Map<String, String> labels = <String, String>{
    'busCard': 'My Bus Card',
    'trackBanner': 'Track My Bus Banner',
    'quickActions': 'Quick Actions',
    'timetable': 'Bus Timetable',
    'fees': 'Fees Widget',
    'nextStop': 'Next Stop + Progress',
    'checkin': '"I\'m on the Bus" Check-in',
    'driver': 'My Driver Card',
    'notices': 'School Notices',
    'alerts': 'Recent Alerts',
  };

  static const Map<String, String> labelsHi = <String, String>{
    'busCard': 'मेरी बस कार्ड',
    'trackBanner': 'बस ट्रैक बैनर',
    'quickActions': 'क्विक एक्शन',
    'timetable': 'बस समय-सारणी',
    'fees': 'फीस विजेट',
    'nextStop': 'अगला स्टॉप + प्रगति',
    'checkin': '"मैं बस में हूँ" चेक-इन',
    'driver': 'मेरा ड्राइवर कार्ड',
    'notices': 'स्कूल नोटिस',
    'alerts': 'हाल की सूचनाएँ',
  };

  /// Language-aware label.
  static String labelOf(String id) => appLanguage.value == 'hi'
      ? (labelsHi[id] ?? labels[id] ?? id)
      : (labels[id] ?? id);

  /// value = ordered list of enabled widget ids
  static final ValueNotifier<List<String>> config =
      ValueNotifier<List<String>>(List<String>.from(allWidgets));

  static Future<void> load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final List<String>? saved = p.getStringList('nmb_home_widgets');
      if (saved != null && saved.isNotEmpty) {
        config.value = saved
            .where((String w) => allWidgets.contains(w))
            .toList();
      }
    } catch (_) {}
  }

  static Future<void> save(List<String> order) async {
    config.value = List<String>.from(order);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setStringList('nmb_home_widgets', order);
    } catch (_) {}
  }
}
