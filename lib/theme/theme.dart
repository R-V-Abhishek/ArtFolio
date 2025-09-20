import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central color palette for the app.
class AppColors {
  // Luminous Canvas palette
  static const Color primary = Color(0xFFFF6B6B); // Coral Red
  static const Color secondary = Color(0xFF4ECDC4); // Turquoise Mint
  static const Color accentYellow = Color(0xFFFFD93D); // Bright Golden Yellow
  static const Color deepTeal = Color(0xFF1A535C); // For icons/app bar text

  static const Color background = Color(0xFFFAFAFA); // Soft Off-White
  static const Color surface = Color(0xFFFFFFFF); // Cards

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF555555);
}

/// Manages light/dark theme mode with [ValueNotifier].
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);
  void toggle() {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final ThemeController themeController = ThemeController();

ThemeData _baseLight(ColorScheme scheme) {
  final textTheme = GoogleFonts.quicksandTextTheme().apply(
    bodyColor: AppColors.textSecondary,
    displayColor: AppColors.textPrimary,
  );
  final display = GoogleFonts.poppinsTextTheme(textTheme).copyWith(
    headlineLarge: GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      fontSize: 28,
      color: AppColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 22,
      color: AppColors.textPrimary,
    ),
    titleLarge: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: AppColors.textPrimary,
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
      foregroundColor: AppColors.deepTeal,
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
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
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
        foregroundColor: AppColors.deepTeal,
        side: BorderSide(color: AppColors.deepTeal.withValues(alpha: 0.3)),
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
    bodyColor: Colors.white70,
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
      color: Colors.white,
    ),
    titleLarge: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white,
    ),
    bodyMedium: GoogleFonts.quicksand(fontSize: 16, color: Colors.white70),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: display,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
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

/// Light color scheme.
final ColorScheme _lightScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.light,
).copyWith(secondary: AppColors.secondary, surface: AppColors.surface);

/// Dark color scheme.
final ColorScheme _darkScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.dark,
);

ThemeData get lightTheme => _baseLight(_lightScheme);
ThemeData get darkTheme => _baseDark(_darkScheme);
