import 'package:flutter/material.dart';

class AppColors {
  // User's Curated Palette
  static const Color inkNavy = Color(0xFF111522);         // #111522 INK NAVY
  static const Color forestCharcoal = Color(0xFF202A27);  // #202A27 FOREST CHARCOAL
  static const Color plumSlate = Color(0xFF493044);       // #493044 PLUM SLATE
  static const Color mutedMauve = Color(0xFF80536F);      // #80536F MUTED MAUVE
  static const Color softSage = Color(0xFF9CB9A6);        // #9CB9A6 SOFT SAGE
  static const Color blushIvory = Color(0xFFF7F2F4);      // #F7F2F4 BLUSH IVORY

  // Accents & Surfaces
  static const Color accentOrange = softSage;             // Mapped to Soft Sage from user's palette
  static const Color surfaceWhite = Color(0xFFFFFFFF);    // Cards, sheets
  static const Color textPrimary = Color(0xFF111522);     // Ink Navy text
  static const Color textMuted = Color(0xFF7E757D);       // Muted mauve-tinted grey
  static const Color borderSubtle = Color(0xFFE8E0E5);    // Subtle hairline divider
  static const Color successBg = Color(0x289CB9A6);       // Soft Sage tint
  static const Color mauveBg = Color(0x1E80536F);         // Muted Mauve tint
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorRedBg = Color(0x1FDC2626);

  // Backward compatibility aliases mapped to user's new palette
  static const Color appleBg = blushIvory;
  static const Color appleGrey = mutedMauve;
  static const Color amazonNavy = inkNavy;
  static const Color amazonOrange = softSage;
  static const Color successGreen = softSage;
  static const Color successGreenBg = successBg;
}

class AppTheme {
  static const String _fontFamily = 'Plus Jakarta Sans';
  static const List<String> _fontFallbacks = ['Inter', 'Segoe UI', 'Roboto', 'sans-serif'];

  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.blushIvory,
      primaryColor: AppColors.plumSlate,
      colorScheme: const ColorScheme.light(
        primary: AppColors.plumSlate,
        secondary: AppColors.softSage,
        surface: AppColors.surfaceWhite,
        background: AppColors.blushIvory,
        error: AppColors.errorRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.inkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _style(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      textTheme: TextTheme(
        headlineMedium: _style(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleLarge: _style(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: _style(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyMedium: _style(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodySmall: _style(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.plumSlate,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _style(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.plumSlate,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.plumSlate,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
