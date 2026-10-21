import 'package:flutter/material.dart';

class PiRowFloTheme {
  static const deepWater = Color(0xFF083B4C);
  static const water = Color(0xFF008FA6);
  static const aqua = Color(0xFF18B8C9);

  static const background = Color(0xFFF2F9FB);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF123642);
  static const secondaryText = Color(0xFF55747D);
  static const divider = Color(0xFFD7E8EC);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: water,
      brightness: Brightness.light,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: surface.withValues(alpha: 0.94),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      drawerTheme: const DrawerThemeData(backgroundColor: background),

      dividerTheme: const DividerThemeData(color: divider),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: water,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: text, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(color: text, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: secondaryText),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: aqua,
        linearTrackColor: Color(0xFFD9EEF2),
      ),
    );
  }
}
