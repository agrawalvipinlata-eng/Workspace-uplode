import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// THEME SYSTEM — 4 themes, poore app ka color turant badalta hai.
/// (App-level ValueListenableBuilder rebuild karta hai — language jaisa.)
class AppThemeOption {
  const AppThemeOption({
    required this.id,
    required this.name,
    required this.nameHi,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.emoji,
  });

  final String id;
  final String name;
  final String nameHi;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final String emoji;
}

class AppThemeManager {
  static const List<AppThemeOption> themes = <AppThemeOption>[
    AppThemeOption(
      id: 'blue',
      name: 'Classic Blue',
      nameHi: 'क्लासिक नीला',
      primary: Color(0xFF2557D6),
      primaryDark: Color(0xFF1A3FA0),
      accent: Color(0xFFFFB300),
      emoji: '🔵',
    ),
    AppThemeOption(
      id: 'srbs',
      name: 'SRBS Sky (School Logo)',
      nameHi: 'SRBS आसमानी (स्कूल लोगो)',
      primary: Color(0xFF00A7DE), // logo ka sky-blue
      primaryDark: Color(0xFF0072A8),
      accent: Color(0xFFE31E24), // logo ka red
      emoji: '🏫',
    ),
    AppThemeOption(
      id: 'green',
      name: 'Fresh Green',
      nameHi: 'हरा',
      primary: Color(0xFF1E8E3E),
      primaryDark: Color(0xFF14602B),
      accent: Color(0xFFFFB300),
      emoji: '🟢',
    ),
    AppThemeOption(
      id: 'navy',
      name: 'Royal Navy',
      nameHi: 'गहरा नीला',
      primary: Color(0xFF3B4B8C),
      primaryDark: Color(0xFF232D54),
      accent: Color(0xFFFF7043),
      emoji: '🟣',
    ),
  ];

  static final ValueNotifier<AppThemeOption> current =
      ValueNotifier<AppThemeOption>(themes.first);

  static AppThemeOption byId(String id) => themes.firstWhere(
        (AppThemeOption t) => t.id == id,
        orElse: () => themes.first,
      );

  static Future<void> load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? id = p.getString('nmb_theme');
      if (id != null) current.value = byId(id);
    } catch (_) {}
  }

  static Future<void> set(String id) async {
    current.value = byId(id);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString('nmb_theme', id);
    } catch (_) {}
  }

  /// ThemeData current theme colors ke saath.
  static ThemeData themeData() {
    final AppThemeOption t = current.value;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: t.primary,
      primary: t.primary,
      secondary: t.accent,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF6F8FC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F8FC),
        foregroundColor: Color(0xFF17233B),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF17233B),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: t.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: t.primary.withOpacity(0.15),
        height: 68,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

/// Gradient helper — headers isse use karenge (hardcoded blue ki jagah).
LinearGradient themeGradient() {
  final AppThemeOption t = AppThemeManager.current.value;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[t.primaryDark, t.primary],
  );
}

Color themePrimary() => AppThemeManager.current.value.primary;
Color themePrimaryDark() => AppThemeManager.current.value.primaryDark;
Color themeAccent() => AppThemeManager.current.value.accent;
