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
  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);

  static AppThemeOption byId(String id) => themes.firstWhere(
        (AppThemeOption t) => t.id == id,
        orElse: () => themes.first,
      );

  static Future<void> load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? id = p.getString('nmb_theme');
      if (id != null) current.value = byId(id);
      darkMode.value = p.getBool('nmb_dark_mode') ?? false;
    } catch (_) {}
  }

  static Future<void> set(String id) async {
    current.value = byId(id);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString('nmb_theme', id);
    } catch (_) {}
  }

  static Future<void> setDarkMode(bool enabled) async {
    darkMode.value = enabled;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool('nmb_dark_mode', enabled);
    } catch (_) {}
  }

  /// ThemeData current theme colors ke saath.
  static ThemeData themeData({bool dark = false}) {
    final AppThemeOption t = current.value;
    final Color background =
        dark ? const Color(0xFF111827) : const Color(0xFFF7F9FC);
    final Color surface = dark ? const Color(0xFF182235) : Colors.white;
    final Color text = dark ? Colors.white : const Color(0xFF17233B);
    final Color muted =
        dark ? const Color(0xFFB8C2D4) : const Color(0xFF647087);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: t.primary,
      primary: t.primary,
      secondary: t.accent,
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: text,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: t.primary,
          side: BorderSide(color: t.primary.withOpacity(0.35)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted, fontSize: 14),
        labelStyle: TextStyle(color: muted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: t.primary.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: t.primary.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: t.primary, width: 1.8),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: t.primary,
        unselectedLabelColor: muted,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        indicatorColor: t.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: t.primary.withOpacity(0.08),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: t.primary.withOpacity(0.15),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted),
        ),
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
