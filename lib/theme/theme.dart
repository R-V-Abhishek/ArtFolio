import 'package:flutter/material.dart';

/// Central color palette for the app.
class AppColors {
  // Seed / brand colors
  static const Color seed = Color(0xFF3949AB); // Indigo shade
  static const Color accent = Color(0xFFFFB300); // Amber accent
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  // Neutral scale
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral10 = Color(0xFFF5F6F8);
  static const Color neutral20 = Color(0xFFE0E3E8);
  static const Color neutral30 = Color(0xFFCDD1D8);
  static const Color neutral40 = Color(0xFFB6BBC4);
  static const Color neutral50 = Color(0xFF9EA5B1);
  static const Color neutral60 = Color(0xFF848C99);
  static const Color neutral70 = Color(0xFF6A7280);
  static const Color neutral80 = Color(0xFF505866);
  static const Color neutral90 = Color(0xFF363E4A);
  static const Color neutral100 = Color(0xFF1E242C);
}

/// Manages light/dark theme mode with [ValueNotifier].
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);
  void toggle() {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final ThemeController themeController = ThemeController();

ThemeData _baseLight(ColorScheme scheme) => ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme:
          FloatingActionButtonThemeData(backgroundColor: scheme.primary),
    );

ThemeData _baseDark(ColorScheme scheme) => _baseLight(scheme).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scheme.surface,
    );

/// Light color scheme.
final ColorScheme _lightScheme = ColorScheme.fromSeed(
  seedColor: AppColors.seed,
  brightness: Brightness.light,
);

/// Dark color scheme.
final ColorScheme _darkScheme = ColorScheme.fromSeed(
  seedColor: AppColors.seed,
  brightness: Brightness.dark,
);

ThemeData get lightTheme => _baseLight(_lightScheme);
ThemeData get darkTheme => _baseDark(_darkScheme);
