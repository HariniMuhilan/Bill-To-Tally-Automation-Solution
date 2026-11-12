import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central Design System tokens for BillBooks
class AppColors {
  // Brand Maroon Palette (Liquid Glass & Redesign)
  static const Color maroonDark = Color(0xFF5E1233);
  static const Color maroonMid = Color(0xFF7A2347);
  static const Color maroonLight = Color(0xFF9C3D62);
  static const Color brandInk = Color(0xFF4A1530);

  // Brand Accents
  static const Color orange = Color(0xFFF26A21);
  static const Color orangeStart = Color(0xFFFF8A3D);
  static const Color orangeEnd = Color(0xFFF0580E);
  static const Color successGreen = Color(0xFF2F9A58);
  static const Color mutedText = Color(0xFF85727A);

  // Background Gradient Anchors
  static const Color bg1 = Color(0xFFFBD9C9);
  static const Color bg2 = Color(0xFFFDE6D6);
  static const Color bg3 = Color(0xFFFCD9B8);
  static const Color bg4 = Color(0xFFFBC590);
  static const Color radialOrange = Color(0xFFFDB86A);
  static const Color radialPink = Color(0xFFFFE3EC);

  // Existing Palette Constants for full app screen compatibility
  static const Color inkNavy = Color(0xFF111522);
  static const Color forestCharcoal = Color(0xFF202A27);
  static const Color plumSlate = Color(0xFF65395E);
  static const Color mutedMauve = Color(0xFF8F5D7E);
  static const Color softSage = Color(0xFF68A484);
  static const Color blushIvory = Color(0xFFF7F2F4);
  static const Color accentOrange = softSage;
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111522);
  static const Color textMuted = Color(0xFF7E757D);
  static const Color borderSubtle = Color(0xFFE8E0E5);
  static const Color successBg = Color(0x2868A484);
  static const Color mauveBg = Color(0x1E8F5D7E);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorRedBg = Color(0x1FDC2626);

  // Backward compatibility aliases
  static const Color appleBg = blushIvory;
  static const Color appleGrey = mutedMauve;
  static const Color amazonNavy = inkNavy;
  static const Color amazonOrange = softSage;
  static const Color successGreenBg = successBg;
}

/// 3 Standard DM Sans Typography Sizes:
/// - 26px: Stat Numbers
/// - 16px: Card titles / Headers
/// - 13px: Subtitles, Button text, Body
/// - 11px: Stat labels, Nav labels, Badges
class AppTypography {
  static TextStyle fontNumber({
    FontWeight fontWeight = FontWeight.w800,
    Color color = Colors.white,
  }) =>
      GoogleFonts.dmSans(
        fontSize: 26,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle fontL({
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.brandInk,
    double letterSpacing = -0.3,
  }) =>
      GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle fontM({
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.brandInk,
    double letterSpacing = 0.0,
  }) =>
      GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle fontS({
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.mutedText,
    double letterSpacing = 0.2,
  }) =>
      GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  // Helpers
  static TextStyle brandWordmark({required Color color}) => fontL(
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.6,
      );

  static TextStyle cardTitle({Color color = Colors.white}) => fontL(
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle statNumber({Color color = Colors.white}) => fontNumber(
        color: color,
      );

  static TextStyle statLabel({Color color = Colors.white}) => fontS(
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyMedium({Color color = AppColors.brandInk}) => fontM(
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bodySmall({Color color = AppColors.mutedText}) => fontS(
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle buttonText({Color color = Colors.white}) => fontM(
        fontWeight: FontWeight.w700,
        color: color,
      );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg2,
      primaryColor: AppColors.maroonMid,
      colorScheme: const ColorScheme.light(
        primary: AppColors.maroonMid,
        secondary: AppColors.orange,
        surface: AppColors.surfaceWhite,
        error: AppColors.errorRed,
      ),
      textTheme: TextTheme(
        bodyMedium: AppTypography.fontM(),
        bodySmall: AppTypography.fontS(),
      ),
    );
  }
}
