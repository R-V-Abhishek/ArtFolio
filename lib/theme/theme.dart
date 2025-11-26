import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central color palette for the app - based on ArtFolio logo.
class AppColors {
  // ArtFolio logo palette
  static const Color primary = Color(
    0xFFE85D52,
  ); // Coral Red (brush stroke & "Folio")
  static const Color secondary = Color(0xFF60C4AE); // Teal Green (letter "A")
  static const Color accent = Color(0xFFE2B444); // Golden Yellow (book element)
  static const Color darkTeal = Color(0xFF155E5C); // Dark Teal (paint drop)
  static const Color neutral = Color(
    0xFF3F3029,
  ); // Brown/Deep Neutral (shading)

  // Backgrounds inspired by logo warmth
  static const Color background = Color(
    0xFFFAF8F5,
  ); // Warm Off-White with hint of golden
  static const Color surface = Color(0xFFFFFFFF); // Cards

  // Gradient backgrounds for special screens
  static const Color gradientStart = Color(0xFFF5F9F8); // Light teal tint
  static const Color gradientEnd = Color(0xFFFFF9F0); // Light golden tint

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF555555);
}

/// Manages light/dark theme mode with [ValueNotifier].
/// Defaults to system theme preference.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  void toggle() {
    if (value == ThemeMode.dark) {
      value = ThemeMode.light;
    } else {
      value = ThemeMode.dark;
    }
  }

  ThemeMode get themeMode => value;
  set themeMode(ThemeMode mode) => value = mode;

  void useSystemTheme() {
    value = ThemeMode.system;
  }
}

final ThemeController themeController = ThemeController();

ThemeData _baseLight(ColorScheme scheme) {
  final textTheme = GoogleFonts.quicksandTextTheme().apply(
    bodyColor: AppColors.textSecondary,
    displayColor: AppColors.neutral,
  );
  final display = GoogleFonts.poppinsTextTheme(textTheme).copyWith(
    headlineLarge: GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      fontSize: 28,
      color: AppColors.neutral,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 22,
      color: AppColors.neutral,
    ),
    titleLarge: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: AppColors.neutral,
    ),
    bodyMedium: GoogleFonts.quicksand(
      fontSize: 16,
      color: AppColors.textSecondary,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: display,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.darkTeal,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkTeal,
        side: BorderSide(color: AppColors.darkTeal.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
    ),
  );
}

ThemeData _baseDark(ColorScheme scheme) {
  final textTheme = GoogleFonts.quicksandTextTheme().apply(
    bodyColor: Colors.white.withValues(alpha: 0.87),
    displayColor: Colors.white,
  );
  final display = GoogleFonts.poppinsTextTheme(textTheme).copyWith(
    headlineLarge: GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      fontSize: 28,
      color: Colors.white,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 22,
      color: Colors.white.withValues(alpha: 0.95),
    ),
    titleLarge: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white.withValues(alpha: 0.95),
    ),
    bodyMedium: GoogleFonts.quicksand(
      fontSize: 16,
      color: Colors.white.withValues(alpha: 0.87),
    ),
    bodySmall: GoogleFonts.quicksand(
      fontSize: 14,
      color: Colors.white.withValues(alpha: 0.6),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(
      0xFF0D1117,
    ), // Darker for better contrast
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: display,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      filled: true,
      fillColor: const Color(0xFF21262D),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF161B22), // Better contrast surface
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.15)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
    ),
  );
}

/// Light color scheme based on ArtFolio logo palette.
final ColorScheme _lightScheme =
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
    ).copyWith(
      surface: AppColors.surface,
      primaryContainer: AppColors.secondary.withValues(alpha: 0.2),
      secondaryContainer: AppColors.accent.withValues(alpha: 0.2),
    );

/// Dark color scheme based on ArtFolio logo palette with improved contrast.
final ColorScheme _darkScheme =
    ColorScheme.fromSeed(
      seedColor: AppColors.darkTeal,
      primary: AppColors.primary.withValues(
        red: 0.95,
        green: 0.43,
        blue: 0.38,
      ), // Lighter coral for dark mode
      secondary: AppColors.secondary.withValues(
        red: 0.47,
        green: 0.83,
        blue: 0.75,
      ), // Brighter teal
      tertiary: AppColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF161B22),
      surfaceContainerHighest: const Color(0xFF21262D), // Chat message bubbles
      primaryContainer: const Color(0xFF1C4D49), // Darker teal for containers
      secondaryContainer: const Color(
        0xFF2D2419,
      ), // Darker neutral for containers
      onSurface: Colors.white.withValues(alpha: 0.87),
      onSurfaceVariant: Colors.white.withValues(alpha: 0.6),
    );

ThemeData get lightTheme => _baseLight(_lightScheme);
ThemeData get darkTheme => _baseDark(_darkScheme);
