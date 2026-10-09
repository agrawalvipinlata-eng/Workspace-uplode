import 'package:flutter/foundation.dart';

/// GLOBAL LANGUAGE STATE — turant change hota hai (no restart).
/// Widgets ValueListenableBuilder se sunte hain.
final ValueNotifier<String> appLanguage = ValueNotifier<String>('en');

/// Translate helper: t('English text', 'Hindi text')
String tr(String en, String hi) => appLanguage.value == 'hi' ? hi : en;
