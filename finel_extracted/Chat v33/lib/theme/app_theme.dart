import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get classic {
    final cairoFamily = GoogleFonts.cairo().fontFamily!;
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      primaryColor: AppColors.bgHeader,
      colorScheme: const ColorScheme.light(
        primary: AppColors.bgHeader,
        secondary: AppColors.primary,
        surface: AppColors.bgSecondary,
        error: AppColors.error,
        onPrimary: AppColors.textWhite,
        onSecondary: AppColors.textWhite,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: cairoFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgHeader,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: cairoFamily, fontSize: 16,
          fontWeight: FontWeight.w700, color: AppColors.textWhite,
        ),
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.bgHeader,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgHeader,
        selectedItemColor: AppColors.textWhite,
        unselectedItemColor: Color(0xFFBBBBBB),
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
      dividerColor: AppColors.borderDefault,
      dividerTheme: const DividerThemeData(color: AppColors.borderDefault, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.textMuted, fontFamily: cairoFamily, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgHeader,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 2,
          textStyle: TextStyle(fontFamily: cairoFamily, fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: TextTheme(
        titleLarge:  TextStyle(color: AppColors.textPrimary, fontFamily: cairoFamily, fontWeight: FontWeight.w700, fontSize: 18),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontFamily: cairoFamily, fontWeight: FontWeight.w600, fontSize: 15),
        bodyLarge:   TextStyle(color: AppColors.textPrimary, fontFamily: cairoFamily, fontSize: 14),
        bodyMedium:  TextStyle(color: AppColors.textSecondary, fontFamily: cairoFamily, fontSize: 13),
        bodySmall:   TextStyle(color: AppColors.textMuted, fontFamily: cairoFamily, fontSize: 11),
      ),
    );
  }

  // Keep old name for compat
  static ThemeData get dark => classic;
}
