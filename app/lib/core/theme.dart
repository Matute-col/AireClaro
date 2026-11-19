import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// THE app palette (Mateo's Figma, 19-nov-2026). Every color of the app comes from here;
/// screens only reference these names. Contrast checked with the WCAG formula: text
/// ≥ 4.5:1 on its background, icons and other non-text marks ≥ 3:1.
class AppColors {
  AppColors._();

  // --- Figma -------------------------------------------------------------------------
  /// Screen background.
  static const background = Color(0xFF085DFA);

  /// Top bar (and other dark surfaces: bottom bar, dialogs, menus, notices).
  static const appBar = Color(0xFF06204F);

  /// Main text on the blue background (5.3:1) and on the top bar (15.8:1).
  static const text = Color(0xFFFFFFFF);

  /// Main buttons, with black text (15.4:1).
  static const primaryButton = Color(0xFFE0E44C);
  static const onPrimaryButton = Color(0xFF000000);

  /// Secondary buttons and links, with black text (13.6:1). Used as BACKGROUND:
  /// cyan text straight on the blue would only reach 3.45:1.
  static const secondary = Color(0xFF63E0FF);
  static const onSecondary = Color(0xFF000000);

  /// Text fields: light fill with dark text (8.9:1) and dark hint (6.3:1).
  static const field = Color(0xFFA5C3FC);
  static const onField = Color(0xFF06204F);
  static const fieldHint = Color(0xFF1E3A6E);

  /// Home cards «Nuevo reporte» (13.5:1) and «Mis reportes» (7.1:1), with black text.
  static const newReport = Color(0xFF67EA4C);
  static const myReports = Color(0xFFE163E1);
  static const onHomeCard = Color(0xFF000000);

  /// Status chips (13.6:1) and the plate in «Mis reportes» (11.6:1).
  static const chip = Color(0xFF63E0FF);
  static const onChip = Color(0xFF000000);
  static const plate = Color(0xFFE0E44C);
  static const onPlate = Color(0xFF06204F);

  // --- Names used by the screens since Sprint 1 (same names, new values) ---------------
  /// Accent for icons and highlighted text ON the blue background.
  static const primary = Color(0xFFFFFFFF);

  /// Dark container behind icons and placeholders (white icon on it: 15.8:1).
  static const primaryContainer = Color(0xFF06204F);

  /// Cards and bars that sit on the background.
  static const surface = Color(0xFF085DFA);

  /// Success icon (non-text, 3.4:1 on the blue).
  static const success = Color(0xFF67EA4C);

  /// Errors and warnings readable on the blue (light yellow, 4.75:1; 14.2:1 on the top bar).
  static const warning = Color(0xFFFFF59D);
  static const error = Color(0xFFFFF59D);

  /// Destructive text on a cyan button («Eliminar reporte», 6.5:1).
  static const danger = Color(0xFF8B0000);

  // --- Map pins (on the light OSM tiles, which are not changed) -----------------------
  static const mapPin = Color(0xFF085DFA);
  static const mapPinSelected = Color(0xFFB3261E);
}

/// Spacing and shape values (multiples of 8, radius 12).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double radius = 12;
  static const double buttonHeight = 48;
}

/// The single place where the app style is defined (Material 3).
/// Only colors and font weights changed on 19-nov-2026: sizes, spacing, shapes and
/// borders are the same as before.
ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.background,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.primaryButton,
        onPrimary: AppColors.onPrimaryButton,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.text,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        onSurfaceVariant: AppColors.text,
        surfaceContainerLowest: AppColors.appBar,
        surfaceContainerLow: AppColors.appBar,
        surfaceContainer: AppColors.appBar,
        surfaceContainerHigh: AppColors.appBar,
        surfaceContainerHighest: AppColors.appBar,
        surfaceTint: Colors.transparent,
        outline: AppColors.text,
        error: AppColors.error,
        onError: AppColors.onPrimaryButton,
      );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radius),
  );
  const buttonSize = Size.fromHeight(AppSpacing.buttonHeight);
  final fieldRadius = BorderRadius.circular(AppSpacing.radius);
  OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.appBar,
    // System font (Roboto on Android); same sizes, stronger weights in titles only.
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 16),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    iconTheme: const IconThemeData(color: AppColors.primary),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.appBar,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: shape,
        backgroundColor: AppColors.primaryButton,
        foregroundColor: AppColors.onPrimaryButton,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: shape,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        side: const BorderSide(color: AppColors.secondary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      border: fieldBorder(AppColors.onField),
      enabledBorder: fieldBorder(AppColors.onField),
      focusedBorder: fieldBorder(AppColors.onField, 2),
      disabledBorder: fieldBorder(AppColors.fieldHint),
      errorBorder: fieldBorder(AppColors.error),
      focusedErrorBorder: fieldBorder(AppColors.error, 2),
      labelStyle: const TextStyle(color: AppColors.onField),
      // The floating label sits on the field edge: its own light background keeps it legible.
      floatingLabelStyle: const TextStyle(
        color: AppColors.onField,
        backgroundColor: AppColors.field,
      ),
      hintStyle: const TextStyle(color: AppColors.fieldHint),
      helperStyle: const TextStyle(color: AppColors.text),
      counterStyle: const TextStyle(color: AppColors.text),
      errorStyle: const TextStyle(color: AppColors.error),
      prefixIconColor: AppColors.onField,
      suffixIconColor: AppColors.onField,
      iconColor: AppColors.onField,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.onField,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: const BorderSide(color: AppColors.primaryButton),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: AppColors.text,
      iconColor: AppColors.primary,
    ),
    chipTheme: ChipThemeData(
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.chip
            : AppColors.appBar,
      ),
      // Same size and weight as the default chip label (labelLarge); only the color changes.
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onChip
              : AppColors.text,
        ),
      ),
      checkmarkColor: AppColors.onChip,
      side: const BorderSide(color: AppColors.chip),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryButton
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.onPrimaryButton),
      side: const BorderSide(color: AppColors.text, width: 2),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryButton
            : AppColors.text,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryButton,
      linearTrackColor: AppColors.primaryContainer,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.appBar,
      indicatorColor: AppColors.primaryButton,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.onPrimaryButton
              : AppColors.text,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.appBar,
      contentTextStyle: TextStyle(fontSize: 16, color: AppColors.text),
      actionTextColor: AppColors.secondary,
    ),
    // Dialog title and text keep their default sizes; they are white through the text theme.
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.appBar),
  );
}
