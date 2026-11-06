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
}

class SanitaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SanitaColors.primary,
        primary: SanitaColors.primary,
        secondary: SanitaColors.primaryLight,
        background: SanitaColors.background,
        surface: SanitaColors.surface,
      ),
      scaffoldBackgroundColor: SanitaColors.background,
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
}