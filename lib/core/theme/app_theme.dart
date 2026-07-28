import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static const double buttonHeight = 48;
  static const double buttonRadius = 12;
  static const double cardRadius = 16;

  static TextTheme _textTheme(TextTheme base, Color textColor) {
    return GoogleFonts.tajawalTextTheme(base).apply(
      bodyColor: textColor,
      displayColor: textColor,
    ).copyWith(
      displayLarge: GoogleFonts.tajawal(
          fontSize: 32, fontWeight: FontWeight.w800, height: 1.2, color: textColor),
      headlineSmall: GoogleFonts.tajawal(
          fontSize: 22, fontWeight: FontWeight.w700, height: 1.3, color: textColor),
      labelLarge: GoogleFonts.tajawal(
          fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
      bodyMedium: GoogleFonts.tajawal(
          fontSize: 15, fontWeight: FontWeight.w400, height: 1.6, color: textColor),
      bodyLarge: GoogleFonts.tajawal(
          fontSize: 15, fontWeight: FontWeight.w400, height: 1.6, color: textColor),
    );
  }

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.tajawal().fontFamily,
      textTheme: _textTheme(ThemeData.light().textTheme, AppColors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        indicatorColor: Colors.white,
        labelStyle: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        titleTextStyle: GoogleFonts.tajawal(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        contentTextStyle: GoogleFonts.tajawal(fontSize: 14, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.surface),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 3,
        shadowColor: AppColors.primary.withOpacity(0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.lightWash),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius)),
          textStyle:
              GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius)),
          textStyle:
              GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.lightWash,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        labelStyle: TextStyle(color: AppColors.primary.withOpacity(0.6)),
        hintStyle: TextStyle(color: AppColors.primary.withOpacity(0.4)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.lightWash),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.lightWash),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.lightWash, thickness: 1),
    );
  }

  static ThemeData get darkTheme {
    const darkSurface = Color(0xFF16294F);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.secondary,
      secondary: AppColors.secondary,
      surface: darkSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.navyDark,
      fontFamily: GoogleFonts.tajawal().fontFamily,
      textTheme: _textTheme(ThemeData.dark().textTheme, Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        indicatorColor: Colors.white,
        labelStyle: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        titleTextStyle: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: darkSurface),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius)),
          textStyle:
              GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white38),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Colors.white24, thickness: 1),
    );
  }
}