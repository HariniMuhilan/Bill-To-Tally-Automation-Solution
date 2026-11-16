import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central Design System tokens for BillBooks
class AppColors {
  // Brand Maroon Palette (Liquid Glass & Redesign)
  static const Color maroonDark = Color(0xFF5E1233);
  static const Color maroonMid = Color(0xFF7A2347);
  static const Color maroonLight = Color(0xFF9C3D62);
  static const Color brandInk = Color(0xFF4A1530);

  // Brand Accents (WCAG 2.2 AA >= 4.5:1 verified against white & warm peach)
  static const Color orange = Color(0xFFC2410C);
  static const Color orangeStart = Color(0xFFC94500);
  static const Color orangeEnd = Color(0xFFBF3B00);
  static const Color successGreen = Color(0xFF1F7A42);
  static const Color mutedText = Color(0xFF635259);

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
  static const Color textMuted = Color(0xFF5E565D);
  static const Color borderSubtle = Color(0xFFE8E0E5);
  static const Color successBg = Color(0x2868A484);
  static const Color mauveBg = Color(0x1E8F5D7E);
  static const Color errorRed = Color(0xFFB91C1C);
  static const Color errorRedBg = Color(0x1FB91C1C);

  // Semantic Surface, Glass & Status Tokens
  static const Color maroonShadow = Color(0xFF6A1634);
  static const Color pinkGlow = Color(0xFFFFBED7);
  static const Color warmPeachTint = Color(0xFFFFF0E6);
  static const Color warmOrangeShadow = Color(0xFFC86E46);
  static const Color warmSelectionBg = Color(0xFFFFF7F2);
  static const Color brandInkShadow = Color(0x334A1530);
  static const Color dividerSubtle = Color(0x22635259);

  static const Color surfaceMuted = Color(0xFFF8F6F8);
  static const Color surfaceField = Color(0xFFFDFBFD);
  static const Color surfaceCardMuted = Color(0xFFFAF7F9);
  static const Color surfaceDisabled = Color(0xFFF5F3F5);
  static const Color surfaceCoolSlate = Color(0xFFF8FAFC);
  static const Color pillPlumBg = Color(0xFFF3EBF0);
  static const Color pillPlumAltBg = Color(0xFFF3EDF2);
  static const Color pillNeutralBg = Color(0xFFF0EFF2);
  static const Color borderLavender = Color(0xFFEADBEC);
  static const Color mutedSurfaceStart = Color(0xFFEFE9EE);
  static const Color mutedSurfaceEnd = Color(0xFFE2D9E0);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color desktopBackdrop = Color(0xFF1E121E);

  static const Color warningAmber = Color(0xFFB45309);
  static const Color warningAmberBg = Color(0xFFFEF3EB);
  static const Color warningOrangeBg = Color(0xFFFFF3E0);
  static const Color warningBorder = Color(0xFFF59E0B);
  static const Color warningOrangeBorder = Color(0xFFFFB74D);
  static const Color infoBlue = Color(0xFF2563EB);

  static const Color successBadgeBg = Color(0xFFE8F5E9);
  static const Color successBadgeBgDeep = Color(0xFFC8E6C9);
  static const Color successBadgeText = Color(0xFF1B5E20);
  static const Color successBadgeBorder = Color(0xFF81C784);
  static const Color successFieldBg = Color(0xFFF0FDF4);
  static const Color successFieldText = Color(0xFF166534);
  static const Color successFieldBorder = Color(0xFFBBF7D0);
  static const Color successFocusBorder = Color(0xFF16A34A);

  static const Color postedTealBg = Color(0xFFE0F2F1);
  static const Color postedTealText = Color(0xFF004D40);
  static const Color postedTealBorder = Color(0xFF4DB6AC);

  static const Color errorFieldBg = Color(0xFFFFF1F2);
  static const Color errorFieldBorder = Color(0xFFFECDD3);
  static const Color errorHintText = Color(0xFF9F1239);

  // Backward compatibility aliases
  static const Color appleBg = blushIvory;
  static const Color appleGrey = mutedMauve;
  static const Color amazonNavy = inkNavy;
  static const Color amazonOrange = softSage;
  static const Color successGreenBg = successBg;
}

/// 4 Standard DM Sans Typography Sizes:
/// - 26px: Stat Numbers
/// - 16px: Card titles / Headers
/// - 13px: Subtitles, Button text, Body
/// - 12px: Stat labels, Nav labels, Badges (accessible >= 12px floor)
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
        fontSize: 12,
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
