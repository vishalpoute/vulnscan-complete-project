import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  // ── Typography helpers ──────────────────────────────────────────
  static TextStyle _inter(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle _mono(double size, FontWeight weight, Color color) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  // ── Dark Text Theme ─────────────────────────────────────────────
  static TextTheme _darkTextTheme = TextTheme(
    displayLarge: _inter(32, FontWeight.w700, AppColors.textPrimary),
    displayMedium: _inter(28, FontWeight.w700, AppColors.textPrimary),
    displaySmall: _inter(24, FontWeight.w700, AppColors.textPrimary),
    headlineLarge: _inter(22, FontWeight.w600, AppColors.textPrimary),
    headlineMedium: _inter(20, FontWeight.w600, AppColors.textPrimary),
    headlineSmall: _inter(18, FontWeight.w600, AppColors.textPrimary),
    titleLarge: _inter(16, FontWeight.w600, AppColors.textPrimary),
    titleMedium: _inter(15, FontWeight.w600, AppColors.textPrimary),
    titleSmall: _inter(14, FontWeight.w600, AppColors.textPrimary),
    bodyLarge: _inter(15, FontWeight.w400, AppColors.textPrimary),
    bodyMedium: _inter(14, FontWeight.w400, AppColors.textPrimary),
    bodySmall: _inter(12, FontWeight.w400, AppColors.textSecondary),
    labelLarge: _inter(14, FontWeight.w600, AppColors.textPrimary),
    labelMedium: _inter(12, FontWeight.w500, AppColors.textSecondary),
    labelSmall: _mono(11, FontWeight.w400, AppColors.textCode),
  );

  // ── Light Text Theme ────────────────────────────────────────────
  static TextTheme _lightTextTheme = TextTheme(
    displayLarge: _inter(32, FontWeight.w700, AppColors.textLight),
    displayMedium: _inter(28, FontWeight.w700, AppColors.textLight),
    displaySmall: _inter(24, FontWeight.w700, AppColors.textLight),
    headlineLarge: _inter(22, FontWeight.w600, AppColors.textLight),
    headlineMedium: _inter(20, FontWeight.w600, AppColors.textLight),
    headlineSmall: _inter(18, FontWeight.w600, AppColors.textLight),
    titleLarge: _inter(16, FontWeight.w600, AppColors.textLight),
    titleMedium: _inter(15, FontWeight.w600, AppColors.textLight),
    titleSmall: _inter(14, FontWeight.w600, AppColors.textLight),
    bodyLarge: _inter(15, FontWeight.w400, AppColors.textLight),
    bodyMedium: _inter(14, FontWeight.w400, AppColors.textLight),
    bodySmall: _inter(12, FontWeight.w400, AppColors.textLightSecondary),
    labelLarge: _inter(14, FontWeight.w600, AppColors.textLight),
    labelMedium: _inter(12, FontWeight.w500, AppColors.textLightSecondary),
    labelSmall: _mono(11, FontWeight.w400, AppColors.accentBlue),
  );

  // ── Shared Button Style (Dark) ───────────────────────────────────
  static final _darkElevatedBtn = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accentGreenDim,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF2ea043), width: 1),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static final _lightElevatedBtn = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accentGreenDim,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF2ea043), width: 1),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ── Input decoration (Dark) ──────────────────────────────────────
  static final _darkInputDecoration = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgSecondary,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.borderDefault),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.borderDefault),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
    labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
    hintStyle: GoogleFonts.inter(color: AppColors.textSubtle, fontSize: 14),
    prefixIconColor: AppColors.textSecondary,
    suffixIconColor: AppColors.textSecondary,
  );

  // ── Input decoration (Light) ─────────────────────────────────────
  static final _lightInputDecoration = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgLightSecondary,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
    ),
    labelStyle: GoogleFonts.inter(color: AppColors.textLightSecondary, fontSize: 14),
    hintStyle: GoogleFonts.inter(color: AppColors.textLightSecondary, fontSize: 14),
  );

  // ── DARK THEME ───────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentGreen,
      secondary: AppColors.accentBlue,
      surface: AppColors.bgPrimary,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.bgCanvas,
    canvasColor: AppColors.bgCanvas,
    cardColor: AppColors.bgPrimary,
    dividerColor: AppColors.borderDefault,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderDefault, width: 1),
      ),
    ),
    elevatedButtonTheme: _darkElevatedBtn,
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.borderDefault),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentBlue,
        textStyle: GoogleFonts.inter(fontSize: 14),
      ),
    ),
    inputDecorationTheme: _darkInputDecoration,
    textTheme: _darkTextTheme,
    cardTheme: CardThemeData(
      color: AppColors.bgPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.borderDefault, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDefault,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgSecondary,
      labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
      side: const BorderSide(color: AppColors.borderDefault),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accentGreen;
        return AppColors.textSubtle;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentGreen.withOpacity(0.3);
        }
        return AppColors.bgSecondary;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accentGreen,
      linearTrackColor: AppColors.bgSecondary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentGreenDim,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgSecondary,
      contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: AppColors.textPrimary,
      iconColor: AppColors.textSecondary,
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );

  // ── LIGHT THEME ──────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accentGreenDim,
      secondary: AppColors.accentBlue,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textLight,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    cardColor: AppColors.surfaceLight,
    dividerColor: AppColors.borderLight,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textLight, size: 20),
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.textLight,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderLight, width: 1),
      ),
    ),
    elevatedButtonTheme: _lightElevatedBtn,
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textLight,
        side: const BorderSide(color: AppColors.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentBlue,
        textStyle: GoogleFonts.inter(fontSize: 14),
      ),
    ),
    inputDecorationTheme: _lightInputDecoration,
    textTheme: _lightTextTheme,
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgLightSecondary,
      labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
      side: const BorderSide(color: AppColors.borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accentGreenDim;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentGreenDim.withOpacity(0.3);
        }
        return Colors.grey.shade300;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.accentGreenDim,
      linearTrackColor: Colors.grey.shade200,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentGreenDim,
      foregroundColor: Colors.white,
    ),
    iconTheme: const IconThemeData(color: AppColors.textLightSecondary, size: 20),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textLight,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
    ),
    listTileTheme: const ListTileThemeData(
      textColor: AppColors.textLight,
      iconColor: AppColors.textLightSecondary,
    ),
  );
}
