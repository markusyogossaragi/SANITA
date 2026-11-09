import 'package:flutter/material.dart';

class SanitaColors {
  static const Color primary        = Color(0xFF1B6E4E);
  static const Color primaryLight   = Color(0xFF2FA376);
  static const Color primaryDark    = Color(0xFF104631);
  static const Color primarySurface = Color(0xFFE8F5EE);

  static const Color accentAmber    = Color(0xFFF59E0B);
  static const Color alertRed       = Color(0xFFDC2626);
  static const Color infoBlue       = Color(0xFF0284C7);

  static const Color background     = Color(0xFFF6F8F7);
  static const Color surface        = Colors.white;
  static const Color border         = Color(0xFFE2E8F0);

  static const Color textDark       = Color(0xFF1E293B);
  static const Color textMuted      = Color(0xFF64748B);
  static const Color textLight      = Colors.white;

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF0F1713);
  static const Color darkSurface    = Color(0xFF18241F);
  static const Color darkCard       = Color(0xFF1F2E27);
  static const Color darkBorder     = Color(0xFF2D3F37);
  static const Color darkText       = Color(0xFFF1F5F9);
  static const Color darkTextMuted  = Color(0xFF94A3B8);
}

class SanitaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SanitaColors.primary,
        brightness: Brightness.light,
        primary: SanitaColors.primary,
        secondary: SanitaColors.primaryLight,
        background: SanitaColors.background,
        surface: SanitaColors.surface,
      ),
      scaffoldBackgroundColor: SanitaColors.background,
      cardColor: SanitaColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: SanitaColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: SanitaColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SanitaColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SanitaColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SanitaColors.primary,
        brightness: Brightness.dark,
        primary: SanitaColors.primaryLight,
        secondary: SanitaColors.primary,
        background: SanitaColors.darkBackground,
        surface: SanitaColors.darkSurface,
      ),
      scaffoldBackgroundColor: SanitaColors.darkBackground,
      cardColor: SanitaColors.darkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: SanitaColors.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: SanitaColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SanitaColors.darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SanitaColors.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
