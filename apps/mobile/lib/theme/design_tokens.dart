import 'package:flutter/material.dart';

class PayNoraColors {
  // Brand Core Colors - Aesthetic Electric Blue & Pure Dark
  static const Color brandPrimary = Color(0xFF00A3FF); // Aesthetic Electric Blue
  static const Color brandSecondary = Color(0xFF00B0FF); // Vibrant Cyan
  static const Color brandDeepBlue = Color(0xFF0277BD); // Deep Electric Accent
  static const Color accentPurple = Color(0xFF6C5CE7);

  // Light Mode Tokens
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardSubtle = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Pure Dark (OLED Black) Tokens - Perfectly matches the new PayNora Logo
  static const Color darkBackground = Color(0xFF000000); // Pure OLED Black
  static const Color darkSurface = Color(0xFF0A0A0A);    // Pitch Dark Surface
  static const Color darkCard = Color(0xFF121212);       // Charcoal Card
  static const Color darkCardSubtle = Color(0xFF1A1A1A); // Dark Neutral
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA3A3A3);
  static const Color darkBorder = Color(0xFF262626);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEE2E2);

  // Compatibility aliases
  static const Color primary = brandPrimary;
  static const Color secondary = brandSecondary;
  static const Color surface = lightBackground;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color borderSubtle = lightBorder;
}

/// Global Theme State Notifier for PayNora
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier._() : super(ThemeMode.dark);
  static final ThemeNotifier instance = ThemeNotifier._();

  bool get isDarkMode => value == ThemeMode.dark;

  void toggleTheme() {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    value = mode;
  }
}

class PayNoraThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: PayNoraColors.lightBackground,
      primaryColor: PayNoraColors.brandPrimary,
      colorScheme: const ColorScheme.light(
        primary: PayNoraColors.brandPrimary,
        secondary: PayNoraColors.brandSecondary,
        surface: PayNoraColors.lightSurface,
        background: PayNoraColors.lightBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: PayNoraColors.lightTextPrimary,
        onBackground: PayNoraColors.lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: PayNoraColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: PayNoraColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PayNoraColors.lightBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PayNoraColors.lightSurface,
        selectedItemColor: PayNoraColors.brandPrimary,
        unselectedItemColor: PayNoraColors.lightTextSecondary,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: PayNoraColors.darkBackground,
      primaryColor: PayNoraColors.brandPrimary,
      colorScheme: const ColorScheme.dark(
        primary: PayNoraColors.brandPrimary,
        secondary: PayNoraColors.brandSecondary,
        surface: PayNoraColors.darkSurface,
        background: PayNoraColors.darkBackground,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: PayNoraColors.darkTextPrimary,
        onBackground: PayNoraColors.darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PayNoraColors.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: PayNoraColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PayNoraColors.darkBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PayNoraColors.darkSurface,
        selectedItemColor: PayNoraColors.brandPrimary,
        unselectedItemColor: PayNoraColors.darkTextSecondary,
      ),
    );
  }
}
