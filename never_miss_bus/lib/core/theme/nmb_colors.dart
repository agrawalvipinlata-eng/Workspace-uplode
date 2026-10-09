import 'package:flutter/material.dart';

import 'app_theme_manager.dart';

/// Never Miss Bus design-system palette.
///
/// v2.2+ THEME FIX: brand colors ab STATIC GETTERS hain jo selected theme
/// se aate hain — isliye theme change karte hi POORA app (har screen, har
/// button, har icon) turant naya color le leta hai. Semantic colors
/// (success/warning/danger) fixed rehte hain taki meaning clear rahe.
abstract final class NmbColors {
  // Brand — DYNAMIC (selected theme se)
  static Color get primary => AppThemeManager.current.value.primary;
  static Color get primaryDark => AppThemeManager.current.value.primaryDark;
  static Color get primarySoft => Color.alphaBlend(
        AppThemeManager.current.value.primary.withOpacity(0.10),
        Colors.white,
      );
  static Color get accent => AppThemeManager.current.value.accent;
  static Color get accentDark => Color.alphaBlend(
        Colors.black.withOpacity(0.45),
        AppThemeManager.current.value.accent,
      );
  static Color get accentSoft => Color.alphaBlend(
        AppThemeManager.current.value.accent.withOpacity(0.16),
        Colors.white,
      );

  // Semantic
  static const Color success = Color(0xFF1E8E3E);
  static const Color successSoft = Color(0xFFE2F3E7);
  static const Color warning = Color(0xFFB26A00);
  static const Color warningSoft = Color(0xFFFFF1DC);
  static const Color danger = Color(0xFFC5221F);
  static const Color dangerSoft = Color(0xFFFCE8E7);
  static const Color info = Color(0xFF0B6CBD);
  static const Color infoSoft = Color(0xFFE3F0FA);

  // Neutrals
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF17233B);
  static const Color textSecondary = Color(0xFF5A6779);
  static const Color textTertiary = Color(0xFF8A94A6);
  static const Color divider = Color(0xFFE4E9F2);
  static const Color disabled = Color(0xFFB9C2D0);

  // Live-tracking states
  static const Color live = success;
  static const Color stale = warning;
  static const Color offline = textTertiary;
}
