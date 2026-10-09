import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nmb_colors.dart';
import 'nmb_typography.dart';

/// Single ThemeData used across Student, Driver and Admin experiences so the
/// whole product feels like one design system.
abstract final class NmbTheme {
  static const double radiusCard = 20;
  static const double radiusButton = 16;
  static const double radiusField = 14;

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: NmbColors.primary,
      primary: NmbColors.primary,
      secondary: NmbColors.accent,
      surface: NmbColors.surface,
      error: NmbColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: NmbColors.background,
      fontFamily: NmbTypography.fontFamily,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: NmbColors.background,
        foregroundColor: NmbColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: NmbTypography.screenTitle,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardTheme(
        color: NmbColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54), // large touch target
          textStyle: NmbTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: NmbTypography.button,
          side: BorderSide(color: NmbColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          textStyle: NmbTypography.button.copyWith(fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NmbColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: NmbColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: NmbColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: NmbColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: const BorderSide(color: NmbColors.danger),
        ),
        hintStyle: NmbTypography.bodySecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: NmbColors.surface,
        indicatorColor: NmbColors.primarySoft,
        height: 68,
        elevation: 3,
        labelTextStyle: WidgetStatePropertyAll(
          NmbTypography.caption.copyWith(
            color: NmbColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NmbColors.textPrimary,
        contentTextStyle:
            NmbTypography.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: NmbColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: NmbTypography.sectionTitle,
        contentTextStyle: NmbTypography.bodySecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: NmbColors.divider,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: NmbColors.textSecondary,
        titleTextStyle: NmbTypography.cardTitle,
        subtitleTextStyle: NmbTypography.bodySecondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NmbColors.primarySoft,
        labelStyle: NmbTypography.caption
            .copyWith(color: NmbColors.primaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
      ),
    );
  }
}
