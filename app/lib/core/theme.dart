import 'package:material_ui/material_ui.dart';

/// Colors from docs/06 (used when Figma does not define them).
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0E7C86);
  static const primaryContainer = Color(0xFFCDEFF1);
  static const background = Color(0xFFF7FAFA);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2B2D);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFED6C02);
  static const error = Color(0xFFB3261E);
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

/// The single place where the app style is defined (Material 3, light theme).
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.text,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.error,
    onError: Colors.white,
  );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radius),
  );
  const buttonSize = Size.fromHeight(AppSpacing.buttonHeight);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 16),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: buttonSize, shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: shape,
        side: const BorderSide(color: AppColors.primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: const BorderSide(color: AppColors.primaryContainer),
      ),
    ),
  );
}
